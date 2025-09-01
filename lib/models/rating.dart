class Rating {
  final int upvotes;
  final int downvotes;
  final DateTime lastUpdated;

  const Rating({
    required this.upvotes,
    required this.downvotes,
    required this.lastUpdated,
  });

  factory Rating.empty() {
    return Rating(
      upvotes: 0,
      downvotes: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upvotes': upvotes,
      'downvotes': downvotes,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  Rating copyWith({
    int? upvotes,
    int? downvotes,
    DateTime? lastUpdated,
  }) {
    return Rating(
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Logic: 3 downvotes and not double positive = should delete
  bool shouldDelete() {
    return downvotes >= 3 && upvotes < (downvotes * 2);
  }

  int get totalVotes => upvotes + downvotes;
  double get positiveRatio => totalVotes == 0 ? 0.0 : upvotes / totalVotes;
}
