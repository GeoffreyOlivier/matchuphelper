import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../clients/openai_client.dart';
import '../clients/firebase_storage_client.dart';
import '../storage/local_storage.dart';
import '../utils/response_parser.dart';

class MatchupRepository {
  MatchupRepository({
    required this.client,
    required this.remote,
    required this.local,
  });

  final OpenAIClient client;
  final FirebaseStorageClient remote;
  final LocalStorage local;

  // Session-level fallback counters if file storage fails
  static int? _sessionWindowStartMs;
  static int _sessionCount = 0;

  String _fileName(String c1, String c2, String lane) {
    String clean(String s) => s.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '')
        .replaceAll("'", '');
    return '${clean(c1)}_${clean(c2)}_${clean(lane)}.json';
  }

  Future<(String raw, Map<String, dynamic>? parsed)> getAdvice(
      {required String champion, required String opponent, required String lane, required String apiKey}) async {
    final laneFile = _fileName(champion, opponent, lane);
    final legacyFile = () {
      // Old naming without lane
      String clean(String s) => s.toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('&', 'and')
          .replaceAll('.', '')
          .replaceAll("'", '');
      return '${clean(champion)}_${clean(opponent)}.json';
    }();

    // 1) Remote cache (Firebase)
    String? cached = await remote.readText('chatgpt_responses/$laneFile');
    cached ??= await remote.readText('chatgpt_responses/$legacyFile');

    // 2) Local cache (Documents)
    cached ??= await local.readText(laneFile);
    cached ??= await local.readText(legacyFile);

    if (cached != null) {
      debugPrint('[MatchupRepository] Cache hit for $laneFile / $legacyFile');
      return (cached, parseMatchupResponse(cached));
    }

    // 2.5) Rate limit for anonymous users on mobile only (iOS/Android) when no cache
    await _enforceMobileHourlyRateLimit();

    // 3) Network call
    final raw = await client.getMatchupRaw(
      champion: champion,
      opponent: opponent,
      lane: lane,
    );

    // 4) Persist
    try {
      await local.writeText(laneFile, raw);
      if (kIsWeb == false) {
        // On mobile/desktop, Firebase may be configured
        await remote.writeText('chatgpt_responses/$laneFile', raw, contentType: 'application/json');
      }
    } catch (_) {}

    return (raw, parseMatchupResponse(raw));
  }

  // Enforces max 5 prompts per rolling hour per device (anonymous) on iOS/Android only.
  // No-op on Web or other platforms. Uses a small JSON file in chatgpt_responses/ via LocalStorage.
  Future<void> _enforceMobileHourlyRateLimit() async {
    // Skip on web
    if (kIsWeb) return;

    // Check platform without importing dart:io (safe for web builds)
    final isMobile = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    debugPrint('[RateLimit] Platform: ${defaultTargetPlatform.name}, isMobile=$isMobile');
    if (!isMobile) return;

    const fileName = '_rate_limit.json';
    const maxPerHour = 5;
    const windowMs = 60 * 60 * 1000; // 1 hour

    String? txt;
    try {
      txt = await local.readText(fileName);
    } catch (_) {
      // ignore read failures; treat as no prior state
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    int windowStart = now;
    int count = 0;

    if (txt != null) {
      try {
        final data = jsonDecode(txt);
        if (data is Map<String, dynamic>) {
          windowStart = (data['windowStart'] as int?) ?? now;
          count = (data['count'] as int?) ?? 0;
        }
      } catch (_) {
        // ignore parse errors; start fresh
      }
    }

    // Reset window if expired
    if (now - windowStart >= windowMs) {
      windowStart = now;
      count = 0;
    }

    // If no file state, use session fallback as a backup
    if (txt == null) {
      if (_sessionWindowStartMs == null || now - _sessionWindowStartMs! >= windowMs) {
        _sessionWindowStartMs = now;
        _sessionCount = 0;
      }
      // Use the higher of the two counts to be conservative
      count = count > _sessionCount ? count : _sessionCount;
      windowStart = _sessionWindowStartMs ?? windowStart;
      debugPrint('[RateLimit][SessionFallback] using session counters: count=$_sessionCount, windowStart=$_sessionWindowStartMs');
    }

    debugPrint('[RateLimit] Before check: count=$count, windowStart=$windowStart, now=$now');
    // Enforce limit (do not swallow this exception)
    if (count >= maxPerHour) {
      debugPrint('[RateLimit] BLOCKED: count=$count >= $maxPerHour');
      throw Exception('Rate limit reached: maximum $maxPerHour prompts per hour on mobile for anonymous users.');
    }

    // Increment and persist (best-effort)
    count += 1;
    debugPrint('[RateLimit] After increment: count=$count');
    final updated = jsonEncode({
      'windowStart': windowStart,
      'count': count,
    });
    try {
      await local.writeText(fileName, updated);
    } catch (_) {
      // If write fails, update session fallback to enforce within this app session
      if (_sessionWindowStartMs == null) _sessionWindowStartMs = windowStart;
      _sessionCount = count;
      debugPrint('[RateLimit][SessionFallback] write failed, sessionCount=$_sessionCount');
    }
  }
}
