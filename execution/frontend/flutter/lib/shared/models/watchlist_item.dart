import 'content_cache.dart';

/// Media type enum for watchlist items.
enum MediaType {
  movie,
  tv;

  String get value => name;

  static MediaType fromString(String value) {
    return MediaType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MediaType.movie,
    );
  }
}

/// Item activity status based on last_activity_at.
enum ItemStatus {
  active,   // Activity within last 7 days
  idle,     // Activity within 7-30 days
  stale,    // No activity for 30+ days
  completed;

  String get displayName => switch (this) {
    ItemStatus.active => 'Active',
    ItemStatus.idle => 'Idle',
    ItemStatus.stale => 'Stale',
    ItemStatus.completed => 'Completed',
  };

  static ItemStatus fromString(String value) {
    return ItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ItemStatus.active,
    );
  }
}

/// Watchlist item model representing a movie or TV show in a watchlist.
/// Content metadata is loaded from the joined content_cache table.
class WatchlistItem {
  final String id;
  final String watchlistId;
  final int tmdbId;
  final MediaType mediaType;
  final DateTime addedAt;
  final DateTime? lastActivityAt;

  // Content data from content_cache (joined)
  final ContentCache? content;

  // Computed fields (not stored in DB, calculated from watch_progress)
  final int? minutesRemaining;
  final double? completionPercentage;
  final int? nextEpisodeRuntime;
  final int? nextEpisodeRemaining; // Remaining time for next episode (accounts for partial progress)
  final ItemStatus? status;

  const WatchlistItem({
    required this.id,
    required this.watchlistId,
    required this.tmdbId,
    required this.mediaType,
    required this.addedAt,
    this.lastActivityAt,
    this.content,
    this.minutesRemaining,
    this.completionPercentage,
    this.nextEpisodeRuntime,
    this.nextEpisodeRemaining,
    this.status,
  });

  // ============================================
  // CONTENT ACCESSORS (delegated to content_cache)
  // ============================================

  /// Title from content cache.
  String get title => content?.title ?? 'Unknown';

  /// Poster path from content cache.
  String? get posterPath => content?.posterPath;

  /// Total runtime in minutes from content cache.
  int get totalRuntimeMinutes => content?.totalRuntimeMinutes ?? 0;

  /// Episode runtime for TV shows from content cache.
  int? get episodeRuntime => content?.episodeRuntime;

  /// Genre IDs from content cache.
  List<int> get genreIds => content?.genreIds ?? const [];

  /// Release date from content cache.
  DateTime? get releaseDate => content?.releaseDate;

  /// Popularity score from content cache.
  double? get popularityScore => content?.popularityScore;

  /// Streaming providers from content cache.
  List<StreamingProviderInfo> get streamingProviders =>
      content?.streamingProviders ?? const [];

  /// Overview/description from content cache.
  String? get overview => content?.overview;

  /// Vote average from content cache.
  double? get voteAverage => content?.voteAverage;

  /// Number of seasons (TV only) from content cache.
  int? get numberOfSeasons => content?.numberOfSeasons;

  /// Number of episodes (TV only) from content cache.
  int? get numberOfEpisodes => content?.numberOfEpisodes;

  // ============================================
  // FACTORY CONSTRUCTORS
  // ============================================

  /// Parse from JSON with joined content_cache data.
  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    // Parse content cache from joined data
    ContentCache? contentCache;
    if (json['content_cache'] != null) {
      contentCache = ContentCache.fromJson(
        json['content_cache'] as Map<String, dynamic>,
      );
    }

    return WatchlistItem(
      id: json['id'] as String,
      watchlistId: json['watchlist_id'] as String,
      tmdbId: json['tmdb_id'] as int,
      mediaType: MediaType.fromString(json['media_type'] as String),
      addedAt: DateTime.parse(json['added_at'] as String),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at'] as String)
          : null,
      content: contentCache,
      minutesRemaining: json['minutes_remaining'] as int?,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble(),
      nextEpisodeRuntime: json['next_episode_runtime'] as int?,
      nextEpisodeRemaining: json['next_episode_remaining'] as int?,
      status: json['status'] != null
          ? ItemStatus.fromString(json['status'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'watchlist_id': watchlistId,
      'tmdb_id': tmdbId,
      'media_type': mediaType.value,
      'added_at': addedAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
    };
  }

  /// Creates a new item for insertion (minimal fields, content must exist in cache).
  Map<String, dynamic> toInsertJson() {
    return {
      'watchlist_id': watchlistId,
      'tmdb_id': tmdbId,
      'media_type': mediaType.value,
    };
  }

  /// Parse from dashboard RPC JSON format.
  /// The RPC returns a different structure with 'content' and 'progress' objects.
  factory WatchlistItem.fromDashboardRpc(Map<String, dynamic> json) {
    // Parse content from RPC format
    ContentCache? contentCache;
    final contentJson = json['content'] as Map<String, dynamic>?;
    if (contentJson != null) {
      // RPC returns flat content object, adapt to ContentCache format
      contentCache = ContentCache(
        tmdbId: json['tmdb_id'] as int,
        mediaType: MediaType.fromString(json['media_type'] as String),
        title: contentJson['title'] as String? ?? 'Unknown',
        tagline: contentJson['tagline'] as String?,
        posterPath: contentJson['poster_path'] as String?,
        backdropPath: contentJson['backdrop_path'] as String?,
        overview: contentJson['overview'] as String?,
        voteAverage: (contentJson['vote_average'] as num?)?.toDouble(),
        voteCount: contentJson['vote_count'] as int?,
        popularityScore: (contentJson['popularity_score'] as num?)?.toDouble(),
        genreIds: (contentJson['genre_ids'] as List?)?.cast<int>() ?? [],
        status: contentJson['status'] as String?,
        releaseDate: contentJson['release_date'] != null
            ? DateTime.tryParse(contentJson['release_date'] as String)
            : null,
        lastAirDate: contentJson['last_air_date'] != null
            ? DateTime.tryParse(contentJson['last_air_date'] as String)
            : null,
        totalRuntimeMinutes: contentJson['total_runtime_minutes'] as int? ?? 0,
        episodeRuntime: contentJson['episode_runtime'] as int?,
        numberOfSeasons: contentJson['number_of_seasons'] as int?,
        numberOfEpisodes: contentJson['number_of_episodes'] as int?,
        streamingProviders: _parseStreamingProviders(contentJson['streaming_providers']),
        castMembers: _parseCastMembers(contentJson['cast_members']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Parse progress data
    final progressJson = json['progress'] as Map<String, dynamic>?;
    final totalEntries = (progressJson?['total_entries'] as num?)?.toInt() ?? 0;
    final watchedEntries = (progressJson?['watched_entries'] as num?)?.toInt() ?? 0;
    final minutesWatched = (progressJson?['minutes_watched'] as num?)?.toInt() ?? 0;
    final lastActivityAt = progressJson?['last_activity_at'] != null
        ? DateTime.tryParse(progressJson!['last_activity_at'] as String)
        : null;

    // Parse new partial progress fields
    final nextEpisodeRuntime = (progressJson?['next_episode_runtime'] as num?)?.toInt();
    final nextEpisodeRemaining = (progressJson?['next_episode_remaining'] as num?)?.toInt();

    // Calculate completion percentage
    // Use episode-count for "is complete" check, time-based for partial progress display
    final totalRuntime = contentCache?.totalRuntimeMinutes ?? 0;
    double? completionPercentage;

    // If all episodes are watched, it's 100% complete
    final allEpisodesWatched = totalEntries > 0 && watchedEntries >= totalEntries;
    if (allEpisodesWatched) {
      completionPercentage = 100.0;
    } else if (totalRuntime > 0) {
      // Time-based percentage for partial progress, clamped to 0-99.9%
      completionPercentage = ((minutesWatched / totalRuntime) * 100).clamp(0.0, 99.9);
    } else if (totalEntries > 0) {
      // Fallback to episode-count based if no runtime data
      completionPercentage = (watchedEntries / totalEntries) * 100;
    }

    // Calculate minutes remaining
    final minutesRemaining = (totalRuntime - minutesWatched).clamp(0, totalRuntime);

    return WatchlistItem(
      id: json['id'] as String,
      watchlistId: json['watchlist_id'] as String,
      tmdbId: json['tmdb_id'] as int,
      mediaType: MediaType.fromString(json['media_type'] as String),
      addedAt: DateTime.parse(json['added_at'] as String),
      lastActivityAt: lastActivityAt,
      content: contentCache,
      minutesRemaining: minutesRemaining,
      completionPercentage: completionPercentage,
      nextEpisodeRuntime: nextEpisodeRuntime,
      nextEpisodeRemaining: nextEpisodeRemaining,
    );
  }

  /// Helper to parse streaming providers from JSON.
  static List<StreamingProviderInfo> _parseStreamingProviders(dynamic json) {
    if (json == null) return [];
    final list = json as List;
    return list.map((p) {
      final provider = p as Map<String, dynamic>;
      return StreamingProviderInfo(
        id: provider['id'] as int,
        name: provider['name'] as String? ?? 'Unknown',
        logoPath: provider['logo_path'] as String?,
      );
    }).toList();
  }

  /// Helper to parse cast members from JSON.
  static List<CastMemberInfo> _parseCastMembers(dynamic json) {
    if (json == null) return [];
    final list = json as List;
    return list.map((c) {
      final cast = c as Map<String, dynamic>;
      return CastMemberInfo(
        id: cast['id'] as int,
        name: cast['name'] as String? ?? 'Unknown',
        character: cast['character'] as String?,
        profilePath: cast['profile_path'] as String?,
      );
    }).toList();
  }

  // ============================================
  // COMPUTED PROPERTIES
  // ============================================

  /// Returns true if item is almost done (< 60 minutes remaining).
  bool get isAlmostDone =>
      minutesRemaining != null && minutesRemaining! > 0 && minutesRemaining! < 60;

  /// Returns true if item is completed.
  bool get isCompleted =>
      completionPercentage != null && completionPercentage! >= 100;

  /// Returns true if item hasn't been started.
  /// Checks both completion percentage and partial episode progress.
  bool get isNotStarted {
    if (completionPercentage != null && completionPercentage! > 0) return false;
    // Also check if there's partial progress on current episode
    if (nextEpisodeRemaining != null && nextEpisodeRuntime != null) {
      return nextEpisodeRemaining == nextEpisodeRuntime; // No progress made
    }
    return true;
  }

  /// Days since last activity.
  int get daysSinceActivity {
    if (lastActivityAt == null) return 999;
    return DateTime.now().difference(lastActivityAt!).inDays;
  }

  /// Calculates item status based on local data.
  ItemStatus get calculatedStatus {
    if (isCompleted) return ItemStatus.completed;
    final days = daysSinceActivity;
    if (days < 7) return ItemStatus.active;
    if (days < 30) return ItemStatus.idle;
    return ItemStatus.stale;
  }

  /// Formatted runtime string.
  /// For TV shows: shows remaining time for current episode (accounts for partial)
  /// For movies: shows total remaining time
  String get formattedRuntime {
    int mins;
    if (mediaType == MediaType.tv) {
      // For TV: show remaining time for current episode
      mins = nextEpisodeRemaining ?? nextEpisodeRuntime ?? episodeRuntime ?? 45;
    } else {
      // For movies: show total remaining
      mins = minutesRemaining ?? totalRuntimeMinutes;
    }

    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return '${hours}h ${remainingMins}m';
    }
    return '${mins}m';
  }

  // ============================================
  // COPY WITH
  // ============================================

  WatchlistItem copyWith({
    String? id,
    String? watchlistId,
    int? tmdbId,
    MediaType? mediaType,
    DateTime? addedAt,
    DateTime? lastActivityAt,
    ContentCache? content,
    int? minutesRemaining,
    double? completionPercentage,
    int? nextEpisodeRuntime,
    int? nextEpisodeRemaining,
    ItemStatus? status,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      watchlistId: watchlistId ?? this.watchlistId,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      addedAt: addedAt ?? this.addedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      content: content ?? this.content,
      minutesRemaining: minutesRemaining ?? this.minutesRemaining,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      nextEpisodeRuntime: nextEpisodeRuntime ?? this.nextEpisodeRuntime,
      nextEpisodeRemaining: nextEpisodeRemaining ?? this.nextEpisodeRemaining,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
