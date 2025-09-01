import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../clients/firebase_storage_client.dart';
import '../models/rating.dart';

class RatingService extends ChangeNotifier {
  final FirebaseStorageClient _storage;
  
  RatingService({FirebaseStorageClient? storage}) 
      : _storage = storage ?? const FirebaseStorageClient();

  String _ratingFileName(String champion, String opponent, String lane) {
    String clean(String s) => s.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '')
        .replaceAll("'", '');
    return '${clean(champion)}_${clean(opponent)}_${clean(lane)}_rating.json';
  }

  String _matchupFileName(String champion, String opponent, String lane) {
    String clean(String s) => s.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '')
        .replaceAll("'", '');
    return '${clean(champion)}_${clean(opponent)}_${clean(lane)}.json';
  }

  Future<Rating> getRating(String champion, String opponent, String lane) async {
    try {
      final fileName = _ratingFileName(champion, opponent, lane);
      final content = await _storage.readText('ratings/$fileName');
      
      if (content == null) {
        return Rating.empty();
      }
      
      final json = jsonDecode(content);
      return Rating.fromJson(json);
    } catch (e) {
      debugPrint('[RatingService] Error getting rating: $e');
      return Rating.empty();
    }
  }

  Future<void> upvote(String champion, String opponent, String lane) async {
    await _vote(champion, opponent, lane, isUpvote: true);
  }

  Future<void> downvote(String champion, String opponent, String lane) async {
    await _vote(champion, opponent, lane, isUpvote: false);
  }

  Future<void> _vote(String champion, String opponent, String lane, {required bool isUpvote}) async {
    try {
      final rating = await getRating(champion, opponent, lane);
      
      final updatedRating = isUpvote 
          ? rating.copyWith(
              upvotes: rating.upvotes + 1,
              lastUpdated: DateTime.now(),
            )
          : rating.copyWith(
              downvotes: rating.downvotes + 1,
              lastUpdated: DateTime.now(),
            );

      // Save updated rating
      final fileName = _ratingFileName(champion, opponent, lane);
      await _storage.writeText(
        'ratings/$fileName', 
        jsonEncode(updatedRating.toJson()),
        contentType: 'application/json',
      );

      // Check if matchup should be deleted
      if (updatedRating.shouldDelete()) {
        await _deleteMatchup(champion, opponent, lane);
        debugPrint('[RatingService] Deleted matchup due to poor rating: ${updatedRating.downvotes} downvotes, ${updatedRating.upvotes} upvotes');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[RatingService] Error voting: $e');
    }
  }

  Future<void> _deleteMatchup(String champion, String opponent, String lane) async {
    try {
      // Delete the matchup file from Firebase Storage
      final matchupFileName = _matchupFileName(champion, opponent, lane);
      
      await _storage.deleteFile('chatgpt_responses/$matchupFileName');
      debugPrint('[RatingService] Deleted matchup: chatgpt_responses/$matchupFileName');
      
    } catch (e) {
      debugPrint('[RatingService] Error deleting matchup: $e');
    }
  }
}
