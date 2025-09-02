import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../clients/firebase_storage_client.dart';
import '../models/rating.dart';
import '../utils/log.dart';

class RatingService extends ChangeNotifier {
  final FirebaseStorageClient _storage;

  RatingService({FirebaseStorageClient? storage})
      : _storage = storage ?? const FirebaseStorageClient();

  String _clean(String s) => s
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll('&', 'and')
      .replaceAll('.', '')
      .replaceAll("'", '');

  String _ratingFileName(String champion, String opponent, String lane) {
    // extension en .jsonl pour être clair
    return '${_clean(champion)}_${_clean(opponent)}_${_clean(lane)}_rating.jsonl';
  }

  String _matchupFileName(String champion, String opponent, String lane) {
    return '${_clean(champion)}_${_clean(opponent)}_${_clean(lane)}.json';
  }

  Future<Rating> getRating(String champion, String opponent, String lane) async {
    try {
      final totalSw = Stopwatch()..start();
      final fileName = _ratingFileName(champion, opponent, lane);
      final swRead = Stopwatch()..start();
      final content = await _storage.readText('ratings/$fileName');
      swRead.stop();
      logd('[Perf][Rating] Read ratings/$fileName in ${swRead.elapsedMilliseconds} ms');

      if (content == null || content.isEmpty) {
        totalSw.stop();
        logd('[Perf][Rating] TOTAL ${totalSw.elapsedMilliseconds} ms (empty)');
        return Rating.empty();
      }

      // On lit la DERNIÈRE ligne du JSONL comme "état courant"
      final lastLine = content.trim().split('\n').last;
      final swDecode = Stopwatch()..start();
      final jsonMap = jsonDecode(lastLine);
      swDecode.stop();
      totalSw.stop();
      logd('[Perf][Rating] Decode ${swDecode.elapsedMilliseconds} ms, TOTAL ${totalSw.elapsedMilliseconds} ms');

      return Rating.fromJson(jsonMap);
    } catch (e) {
      logd('[RatingService] Error getting rating: $e');
      return Rating.empty();
    }
  }

  Future<void> upvote(String champion, String opponent, String lane) async {
    await _vote(champion, opponent, lane, isUpvote: true);
  }

  Future<void> downvote(
    String champion,
    String opponent,
    String lane, {
    Map<String, bool>? feedback,
  }) async {
    await _vote(
      champion,
      opponent,
      lane,
      isUpvote: false,
      feedback: feedback,
    );
  }

  Future<void> _vote(
    String champion,
    String opponent,
    String lane, {
    required bool isUpvote,
    Map<String, bool>? feedback,
  }) async {
    try {
      final totalSw = Stopwatch()..start();
      final prev = await getRating(champion, opponent, lane);
      final now = DateTime.now();

      final updated = isUpvote
          ? prev.copyWith(upvotes: prev.upvotes + 1, lastUpdated: now)
          : prev.copyWith(
              downvotes: prev.downvotes + 1,
              lastUpdated: now,
              feedback: feedback != null
                  ? [
                      ...prev.feedback,
                      {
                        'timestamp': now.toIso8601String(),
                        'issues': feedback,
                      }
                    ]
                  : prev.feedback,
            );

      final issuesCounts = _aggregateIssues(updated.feedback);

      // objet à écrire comme UNE ligne JSON
      final record = {
        'champion': champion,
        'opponent': opponent,
        'lane': lane,
        'upvotes': updated.upvotes,
        'downvotes': updated.downvotes,
        'lastUpdated': updated.lastUpdated.toIso8601String(),
        'issues_counts': issuesCounts,
        'feedback': updated.feedback,
      };

      final fileName = _ratingFileName(champion, opponent, lane);

      // 🔥 Append mode : on récupère l’ancien contenu et on ajoute une ligne
      final swRead = Stopwatch()..start();
      final existing = await _storage.readText('ratings/$fileName') ?? '';
      swRead.stop();
      logd('[Perf][Rating] Read before write ratings/$fileName in ${swRead.elapsedMilliseconds} ms');
      final newContent = (existing.isNotEmpty ? existing + '\n' : '') +
          jsonEncode(record);

      final swWrite = Stopwatch()..start();
      await _storage.writeText(
        'ratings/$fileName',
        newContent,
        contentType: 'application/json',
      );
      swWrite.stop();
      logd('[Perf][Rating] Write ratings/$fileName in ${swWrite.elapsedMilliseconds} ms');

      if (updated.shouldDelete()) {
        final swDelete = Stopwatch()..start();
        await _deleteMatchup(champion, opponent, lane);
        swDelete.stop();
        logd('[Perf][Rating] Delete matchup in ${swDelete.elapsedMilliseconds} ms');
        logd(
          '[RatingService] Deleted matchup due to poor rating: '
          '${updated.downvotes} downvotes, ${updated.upvotes} upvotes',
        );
      }

      notifyListeners();
      totalSw.stop();
      logd('[Perf][Rating] TOTAL vote ${totalSw.elapsedMilliseconds} ms');
    } catch (e) {
      logd('[RatingService] Error voting: $e');
    }
  }

  Map<String, int> _aggregateIssues(List<dynamic> feedbackList) {
    final keys = const [
      'images_manquantes',
      'texte_faux',
      'texte_incomprehensible',
      'kit_absent',
      'autre',
    ];

    final counts = {for (final k in keys) k: 0};

    for (final fb in feedbackList) {
      final issues = (fb is Map && fb['issues'] is Map) ? fb['issues'] as Map : {};
      for (final k in keys) {
        final v = issues[k];
        if (v == true) counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> _deleteMatchup(
      String champion, String opponent, String lane) async {
    try {
      final matchupFileName = _matchupFileName(champion, opponent, lane);
      final sw = Stopwatch()..start();
      await _storage.deleteFile('chatgpt_responses/$matchupFileName');
      sw.stop();
      logd('[Perf][Rating] Firebase delete chatgpt_responses/$matchupFileName in ${sw.elapsedMilliseconds} ms');
      logd('[RatingService] Deleted matchup: chatgpt_responses/$matchupFileName');
    } catch (e) {
      logd('[RatingService] Error deleting matchup: $e');
    }
  }
}
