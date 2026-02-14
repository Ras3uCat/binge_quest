import 'watchlist_item.dart';

/// Streaming provider info from TMDB.
class StreamingProviderInfo {
  final int id;
  final String name;
  final String? logoPath;

  const StreamingProviderInfo({
    required this.id,
    required this.name,
    this.logoPath,
  });

  factory StreamingProviderInfo.fromJson(Map<String, dynamic> json) {
    return StreamingProviderInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      logoPath: json['logo_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_path': logoPath,
  };
}

/// Cast member info from TMDB.
class CastMemberInfo {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  const CastMemberInfo({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory CastMemberInfo.fromJson(Map<String, dynamic> json) {
    return CastMemberInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'character': character,
    'profile_path': profilePath,
  };
}

/// Cached content metadata from TMDB.
/// One row per unique (tmdb_id, media_type) combination, shared across all users.
class ContentCache {
  final int tmdbId;
  final MediaType mediaType;

  // Basic info
  final String title;
  final String? tagline;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;

  // Ratings & popularity
  final double? voteAverage;
  final int? voteCount;
  final double? popularityScore;

  // Categorization
  final List<int> genreIds;
  final String? status;

  // Dates
  final DateTime? releaseDate;
  final DateTime? lastAirDate; // TV only

  // Runtime
  final int totalRuntimeMinutes;
  final int? episodeRuntime;

  // TV-specific
  final int? numberOfSeasons;
  final int? numberOfEpisodes;

  // Streaming availability
  final List<StreamingProviderInfo> streamingProviders;

  // Cast (top 10)
  final List<CastMemberInfo> castMembers;

  // Freshness tracking
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentCache({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.tagline,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.voteCount,
    this.popularityScore,
    this.genreIds = const [],
    this.status,
    this.releaseDate,
    this.lastAirDate,
    this.totalRuntimeMinutes = 0,
    this.episodeRuntime,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.streamingProviders = const [],
    this.castMembers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentCache.fromJson(Map<String, dynamic> json) {
    // Parse streaming providers from JSONB
    List<StreamingProviderInfo> providers = [];
    if (json['streaming_providers'] != null) {
      final providersList = json['streaming_providers'] as List<dynamic>;
      providers = providersList
          .map((p) => StreamingProviderInfo.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // Parse cast members from JSONB
    List<CastMemberInfo> cast = [];
    if (json['cast_members'] != null) {
      final castList = json['cast_members'] as List<dynamic>;
      cast = castList
          .map((c) => CastMemberInfo.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return ContentCache(
      tmdbId: json['tmdb_id'] as int,
      mediaType: MediaType.fromString(json['media_type'] as String),
      title: json['title'] as String,
      tagline: json['tagline'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      popularityScore: (json['popularity_score'] as num?)?.toDouble(),
      genreIds: (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? const [],
      status: json['status'] as String?,
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'] as String)
          : null,
      lastAirDate: json['last_air_date'] != null
          ? DateTime.tryParse(json['last_air_date'] as String)
          : null,
      totalRuntimeMinutes: json['total_runtime_minutes'] as int? ?? 0,
      episodeRuntime: json['episode_runtime'] as int?,
      numberOfSeasons: json['number_of_seasons'] as int?,
      numberOfEpisodes: json['number_of_episodes'] as int?,
      streamingProviders: providers,
      castMembers: cast,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tmdb_id': tmdbId,
      'media_type': mediaType.value,
      'title': title,
      'tagline': tagline,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'overview': overview,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'popularity_score': popularityScore,
      'genre_ids': genreIds,
      'status': status,
      'release_date': releaseDate?.toIso8601String().split('T').first,
      'last_air_date': lastAirDate?.toIso8601String().split('T').first,
      'total_runtime_minutes': totalRuntimeMinutes,
      'episode_runtime': episodeRuntime,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
      'streaming_providers': streamingProviders.map((p) => p.toJson()).toList(),
      'cast_members': castMembers.map((c) => c.toJson()).toList(),
    };
  }

  /// Check if content data is stale and needs refresh.
  bool get isStale {
    final age = DateTime.now().difference(updatedAt);
    return age.inDays > 30;
  }

  /// Check if streaming provider data is stale.
  bool get isStreamingStale {
    final age = DateTime.now().difference(updatedAt);
    return age.inDays > 7;
  }

  ContentCache copyWith({
    int? tmdbId,
    MediaType? mediaType,
    String? title,
    String? tagline,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? voteAverage,
    int? voteCount,
    double? popularityScore,
    List<int>? genreIds,
    String? status,
    DateTime? releaseDate,
    DateTime? lastAirDate,
    int? totalRuntimeMinutes,
    int? episodeRuntime,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    List<StreamingProviderInfo>? streamingProviders,
    List<CastMemberInfo>? castMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentCache(
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      popularityScore: popularityScore ?? this.popularityScore,
      genreIds: genreIds ?? this.genreIds,
      status: status ?? this.status,
      releaseDate: releaseDate ?? this.releaseDate,
      lastAirDate: lastAirDate ?? this.lastAirDate,
      totalRuntimeMinutes: totalRuntimeMinutes ?? this.totalRuntimeMinutes,
      episodeRuntime: episodeRuntime ?? this.episodeRuntime,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      streamingProviders: streamingProviders ?? this.streamingProviders,
      castMembers: castMembers ?? this.castMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentCache &&
          runtimeType == other.runtimeType &&
          tmdbId == other.tmdbId &&
          mediaType == other.mediaType;

  @override
  int get hashCode => Object.hash(tmdbId, mediaType);
}
