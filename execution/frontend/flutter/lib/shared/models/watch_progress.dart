import 'package:intl/intl.dart';

/// Watch progress model for tracking movie/episode completion.
///
/// For episodes: all metadata comes from content_cache_episodes join
/// For movies: runtime comes from content_cache join via watchlist_items
class WatchProgress {
  final String id;
  final String watchlistItemId;
  final String?
  episodeCacheId; // FK to content_cache_episodes (null for movies)
  final int minutesWatched; // For partial progress tracking
  final bool watched;
  final DateTime? watchedAt;

  // Data from joins (not stored in watch_progress table)
  final int? seasonNumber; // From content_cache_episodes
  final int? episodeNumber; // From content_cache_episodes
  final int runtimeMinutes; // From content_cache_episodes or content_cache
  final String? episodeName; // From content_cache_episodes
  final String? episodeOverview; // From content_cache_episodes
  final String? stillPath; // From content_cache_episodes
  final DateTime? airDate; // From content_cache_episodes

  const WatchProgress({
    required this.id,
    required this.watchlistItemId,
    this.episodeCacheId,
    this.minutesWatched = 0,
    required this.watched,
    this.watchedAt,
    // Join data
    this.seasonNumber,
    this.episodeNumber,
    required this.runtimeMinutes,
    this.episodeName,
    this.episodeOverview,
    this.stillPath,
    this.airDate,
  });

  bool get hasAired => airDate != null && airDate!.isBefore(DateTime.now());
  bool get isUpcoming => airDate != null && airDate!.isAfter(DateTime.now());

  String get airDateDisplay {
    if (airDate == null) return 'TBA';
    final formatter = DateFormat.yMMMd();
    if (isUpcoming) return 'Airs: ${formatter.format(airDate!)}';
    return 'Aired: ${formatter.format(airDate!)}';
  }

  /// True if this is a movie progress entry (no episode cache).
  bool get isMovie => episodeCacheId == null;

  /// True if this is a TV episode progress entry.
  bool get isEpisode => episodeCacheId != null;

  /// Progress percentage (0-100).
  double get progressPercentage {
    if (watched) return 100;
    if (runtimeMinutes == 0) return 0;
    return (minutesWatched / runtimeMinutes * 100).clamp(0, 100);
  }

  /// Remaining minutes.
  int get remainingMinutes {
    if (watched) return 0;
    return (runtimeMinutes - minutesWatched).clamp(0, runtimeMinutes);
  }

  /// Formatted episode identifier (e.g., "S01E05").
  String get episodeCode {
    if (!isEpisode || seasonNumber == null || episodeNumber == null) return '';
    final s = seasonNumber.toString().padLeft(2, '0');
    final e = episodeNumber.toString().padLeft(2, '0');
    return 'S${s}E$e';
  }

  /// Display title for episode: name if available, otherwise "Episode X".
  String get displayTitle {
    if (episodeName != null && episodeName!.isNotEmpty) {
      return episodeName!;
    }
    if (episodeNumber != null) {
      return 'Episode $episodeNumber';
    }
    return '';
  }

  factory WatchProgress.fromJson(
    Map<String, dynamic> json, {
    int? movieRuntime,
  }) {
    // Handle joined episode data from content_cache_episodes
    final episodeCache =
        json['content_cache_episodes'] as Map<String, dynamic>?;

    // Determine runtime: episodes from episode cache, movies from passed parameter
    int runtime = 0;
    if (episodeCache != null) {
      runtime = episodeCache['runtime_minutes'] as int? ?? 0;
    } else if (movieRuntime != null) {
      runtime = movieRuntime;
    }

    return WatchProgress(
      id: json['id'] as String,
      watchlistItemId: json['watchlist_item_id'] as String,
      episodeCacheId: json['episode_cache_id'] as String?,
      minutesWatched: json['minutes_watched'] as int? ?? 0,
      watched: json['watched'] as bool? ?? false,
      watchedAt: json['watched_at'] != null
          ? DateTime.parse(json['watched_at'] as String)
          : null,
      // Episode metadata from join
      seasonNumber: episodeCache?['season_number'] as int?,
      episodeNumber: episodeCache?['episode_number'] as int?,
      runtimeMinutes: runtime,
      episodeName: episodeCache?['episode_name'] as String?,
      episodeOverview: episodeCache?['episode_overview'] as String?,
      stillPath: episodeCache?['still_path'] as String?,
      airDate: episodeCache?['air_date'] != null
          ? DateTime.tryParse(episodeCache?['air_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'watchlist_item_id': watchlistItemId,
      'episode_cache_id': episodeCacheId,
      'minutes_watched': minutesWatched,
      'watched': watched,
      'watched_at': watchedAt?.toIso8601String(),
    };
  }

  WatchProgress copyWith({
    String? id,
    String? watchlistItemId,
    String? episodeCacheId,
    int? minutesWatched,
    bool? watched,
    DateTime? watchedAt,
    int? seasonNumber,
    int? episodeNumber,
    int? runtimeMinutes,
    String? episodeName,
    String? episodeOverview,
    String? stillPath,
  }) {
    return WatchProgress(
      id: id ?? this.id,
      watchlistItemId: watchlistItemId ?? this.watchlistItemId,
      episodeCacheId: episodeCacheId ?? this.episodeCacheId,
      minutesWatched: minutesWatched ?? this.minutesWatched,
      watched: watched ?? this.watched,
      watchedAt: watchedAt ?? this.watchedAt,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      episodeName: episodeName ?? this.episodeName,
      episodeOverview: episodeOverview ?? this.episodeOverview,
      stillPath: stillPath ?? this.stillPath,
      airDate: airDate ?? airDate,
    );
  }
}

/// Season progress summary for TV shows.
class SeasonProgress {
  final int seasonNumber;
  final List<WatchProgress> episodes;

  const SeasonProgress({required this.seasonNumber, required this.episodes});

  int get totalEpisodes => episodes.length;
  int get watchedEpisodes => episodes.where((e) => e.watched).length;
  int get totalMinutes => episodes.fold(0, (sum, e) => sum + e.runtimeMinutes);
  int get watchedMinutes => episodes.fold(0, (sum, e) {
    if (e.watched) return sum + e.runtimeMinutes;
    return sum + e.minutesWatched; // Include partial progress
  });
  int get remainingMinutes => totalMinutes - watchedMinutes;

  double get progressPercentage {
    if (totalEpisodes == 0) return 0;
    return (watchedEpisodes / totalEpisodes) * 100;
  }

  bool get isComplete => watchedEpisodes == totalEpisodes && totalEpisodes > 0;
  bool get isStarted => watchedEpisodes > 0;

  String get progressText => '$watchedEpisodes / $totalEpisodes';
}
