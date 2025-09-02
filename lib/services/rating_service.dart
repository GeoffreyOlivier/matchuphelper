import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../clients/firebase_storage_client.dart';
import '../models/rating.dart';

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
      final fileName = _ratingFileName(champion, opponent, lane);
      final content = await _storage.readText('ratings/$fileName');

      if (content == null || content.isEmpty) {
        return Rating.empty();
      }

      // On lit la DERNIÈRE ligne du JSONL comme "état courant"
      final lastLine = content.trim().split('\n').last;
      final jsonMap = jsonDecode(lastLine);

      return Rating.fromJson(jsonMap);
    } catch (e) {
      debugPrint('[RatingService] Error getting rating: $e');
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
        'lastUpdated': updated.lastUpdated?.toIso8601String(),
        'issues_counts': issuesCounts,
        'feedback': updated.feedback,
      };

      final fileName = _ratingFileName(champion, opponent, lane);

      // 🔥 Append mode : on récupère l’ancien contenu et on ajoute une ligne
      final existing = await _storage.readText('ratings/$fileName') ?? '';
      final newContent = (existing.isNotEmpty ? existing + '\n' : '') +
          jsonEncode(record);

      await _storage.writeText(
        'ratings/$fileName',
        newContent,
        contentType: 'application/json',
      );

      if (updated.shouldDelete()) {
        await _deleteMatchup(champion, opponent, lane);
        debugPrint(
          '[RatingService] Deleted matchup due to poor rating: '
          '${updated.downvotes} downvotes, ${updated.upvotes} upvotes',
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[RatingService] Error voting: $e');
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
      await _storage.deleteFile('chatgpt_responses/$matchupFileName');
      debugPrint('[RatingService] Deleted matchup: chatgpt_responses/$matchupFileName');
    } catch (e) {
      debugPrint('[RatingService] Error deleting matchup: $e');
    }
  }
}
