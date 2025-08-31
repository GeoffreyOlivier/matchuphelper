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

  String _fileName(String c1, String c2) {
    String clean(String s) => s.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '')
        .replaceAll("'", '');
    return '${clean(c1)}_${clean(c2)}.json';
  }

  Future<(String raw, Map<String, dynamic>? parsed)> getAdvice(
      {required String champion, required String opponent, required String lane, required String apiKey}) async {
    final file = _fileName(champion, opponent);

    // 1) Remote cache (Firebase)
    String? cached = await remote.readText('chatgpt_responses/$file');

    // 2) Local cache (Documents)
    cached ??= await local.readText(file);

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
      await local.writeText(file, raw);
      if (kIsWeb == false) {
        // On mobile/desktop, Firebase may be configured
        await remote.writeText('chatgpt_responses/$file', raw, contentType: 'application/json');
      }
    } catch (_) {}

    return (raw, parseMatchupResponse(raw));
  }
}
