import 'content_cache.dart'; // For StreamingProviderInfo

class TopContent {
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterPath;
  final int userCount;
  final double? averageRating;
  final int reviewCount;
  final List<StreamingProviderInfo> streamingProviders;

  const TopContent({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.userCount = 0,
    this.averageRating,
    this.reviewCount = 0,
    this.streamingProviders = const [],
  });

  factory TopContent.fromUserCountJson(Map<String, dynamic> json) {
    return TopContent(
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type'] as String,
      title: json['title'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      userCount: (json['user_count'] as num?)?.toInt() ?? 0,
      streamingProviders: _parseProviders(json['streaming_providers']),
    );
  }

  factory TopContent.fromRatingJson(Map<String, dynamic> json) {
    return TopContent(
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type'] as String,
      title: json['title'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : null,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      streamingProviders: _parseProviders(json['streaming_providers']),
    );
  }

  /// Parse streaming providers from JSON.
  static List<StreamingProviderInfo> _parseProviders(dynamic json) {
    if (json == null) return [];
    return (json as List)
        .map((p) => StreamingProviderInfo.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';

  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
}
