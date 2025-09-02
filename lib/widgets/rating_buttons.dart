import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import 'feedback_modal.dart';

class RatingButtons extends StatefulWidget {
  final String champion;
  final String opponent;
  final String lane;
  final RatingService ratingService;

  const RatingButtons({
    super.key,
    required this.champion,
    required this.opponent,
    required this.lane,
    required this.ratingService,
  });

  @override
  State<RatingButtons> createState() => _RatingButtonsState();
}

class _RatingButtonsState extends State<RatingButtons> {
  Rating? _currentRating;
  bool _isLoading = false;
  bool _hasVoted = false;
  String _currentMatchupKey = '';

  @override
  void initState() {
    super.initState();
    _updateMatchupKey();
    _loadRating();
  }

  @override
  void didUpdateWidget(RatingButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMatchupKey = _getMatchupKey();
    if (newMatchupKey != _currentMatchupKey) {
      _updateMatchupKey();
      _hasVoted = false; // Reset voting state for new matchup
      _loadRating();
    }
  }

  void _updateMatchupKey() {
    _currentMatchupKey = _getMatchupKey();
  }

  String _getMatchupKey() {
    return '${widget.champion}_${widget.opponent}_${widget.lane}';
  }

  Future<void> _loadRating() async {
    setState(() => _isLoading = true);
    try {
      final rating = await widget.ratingService.getRating(
        widget.champion,
        widget.opponent,
        widget.lane,
      );
      setState(() => _currentRating = rating);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _upvote() async {
    if (_hasVoted) return;
    
    setState(() => _isLoading = true);
    try {
      await widget.ratingService.upvote(
        widget.champion,
        widget.opponent,
        widget.lane,
      );
      setState(() => _hasVoted = true);
    } catch (e) {
      // Handle Firebase permission errors gracefully
      debugPrint('[RatingButtons] Error voting: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downvote() async {
    if (_hasVoted) return;
    
    // Show feedback modal before processing downvote
    final feedback = await _showFeedbackModal();
    if (feedback == null) return; // User cancelled
    
    setState(() => _isLoading = true);
    try {
      await widget.ratingService.downvote(
        widget.champion,
        widget.opponent,
        widget.lane,
        feedback: feedback,
      );
      setState(() => _hasVoted = true);
    } catch (e) {
      // Handle Firebase permission errors gracefully
      debugPrint('[RatingButtons] Error voting: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, bool>?> _showFeedbackModal() async {
    return showDialog<Map<String, bool>>(
      context: context,
      builder: (BuildContext context) {
        return const FeedbackModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Show "Thanks" after voting
    if (_hasVoted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Text(
          'Thanks',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote button
        InkWell(
          onTap: _upvote,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.thumb_up_outlined,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Downvote button
        InkWell(
          onTap: _downvote,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.thumb_down_outlined,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
