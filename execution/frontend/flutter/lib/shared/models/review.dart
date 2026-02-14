class Review {
  final String id;
  final String userId;
  final String? displayName; // From users table join
  final int tmdbId;
  final String mediaType;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.userId,
    this.displayName,
    required this.tmdbId,
    required this.mediaType,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle nested users join
    final users = json['users'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: users?['display_name'] as String?,
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'tmdb_id': tmdbId,
    'media_type': mediaType,
    'rating': rating,
    'review_text': reviewText,
  };

  bool get hasText => reviewText != null && reviewText!.isNotEmpty;

  String get reviewerName => displayName ?? 'Anonymous';
}
