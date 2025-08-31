import 'package:flutter/foundation.dart';
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
      return (cached, parseMatchupResponse(cached));
    }

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
}
