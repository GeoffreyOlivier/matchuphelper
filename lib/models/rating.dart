class Rating {
  final int upvotes;
  final int downvotes;
  final DateTime lastUpdated;
  final List<Map<String, dynamic>> feedback;

  const Rating({
    required this.upvotes,
    required this.downvotes,
    required this.lastUpdated,
    this.feedback = const [],
  });

  factory Rating.empty() {
    return Rating(
      upvotes: 0,
      downvotes: 0,
      lastUpdated: DateTime.now(),
      feedback: [],
    );
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      feedback: List<Map<String, dynamic>>.from(json['feedback'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upvotes': upvotes,
      'downvotes': downvotes,
      'lastUpdated': lastUpdated.toIso8601String(),
      'feedback': feedback,
    };
  }

  Rating copyWith({
    int? upvotes,
    int? downvotes,
    DateTime? lastUpdated,
    List<Map<String, dynamic>>? feedback,
  }) {
    return Rating(
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      feedback: feedback ?? this.feedback,
    );
  }

  bool shouldDelete() {
    // Delete if downvotes significantly outweigh upvotes
    return downvotes >= 3 && downvotes > upvotes * 2;
  }
}
