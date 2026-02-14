import 'watchlist_item.dart';

/// Base class for TMDB content (movies and TV shows).
abstract class TmdbContent {
  int get id;
  String get title;
  String? get posterPath;
  String? get backdropPath;
  String? get overview;
  double get voteAverage;
  MediaType get mediaType;
}

/// Search result from TMDB multi-search.
class TmdbSearchResult implements TmdbContent {
  @override
  final int id;
  final String? name; // TV shows use 'name'
  final String? titleField; // Movies use 'title'
  @override
  final String? posterPath;
  @override
  final String? backdropPath;
  @override
  final String? overview;
  @override
  final double voteAverage;
  final String mediaTypeString;
  final String? releaseDate; // Movies
  final String? firstAirDate; // TV shows
  final double? popularity;

  TmdbSearchResult({
    required this.id,
    this.name,
    this.titleField,
    this.posterPath,
    this.backdropPath,
    this.overview,
    required this.voteAverage,
    required this.mediaTypeString,
    this.releaseDate,
    this.firstAirDate,
    this.popularity,
  });

  @override
  String get title => titleField ?? name ?? 'Unknown';

  @override
  MediaType get mediaType =>
      mediaTypeString == 'tv' ? MediaType.tv : MediaType.movie;

  String? get year {
    final date = releaseDate ?? firstAirDate;
    if (date == null || date.isEmpty) return null;
    return date.split('-').first;
  }

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    return TmdbSearchResult(
      id: json['id'] as int,
      name: json['name'] as String?,
      titleField: json['title'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      mediaTypeString: json['media_type'] as String? ?? 'movie',
      releaseDate: json['release_date'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble(),
    );
  }
}

/// Detailed movie information from TMDB.
class TmdbMovie implements TmdbContent {
  @override
  final int id;
  @override
  final String title;
  @override
  final String? posterPath;
  @override
  final String? backdropPath;
  @override
  final String? overview;
  @override
  final double voteAverage;
  final int? voteCount;
  final double? popularity;
  final int? runtime; // in minutes
  final String? releaseDate;
  final List<TmdbGenre> genres;
  final String? tagline;
  final String? status;
  final List<TmdbCastMember>? cast;

  @override
  MediaType get mediaType => MediaType.movie;

  TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    required this.voteAverage,
    this.voteCount,
    this.popularity,
    this.runtime,
    this.releaseDate,
    this.genres = const [],
    this.tagline,
    this.status,
    this.cast,
  });

  String? get year {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    return releaseDate!.split('-').first;
  }

  DateTime? get releaseDateParsed {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    return DateTime.tryParse(releaseDate!);
  }

  String get formattedRuntime {
    if (runtime == null || runtime == 0) return 'N/A';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    List<TmdbCastMember>? castList;
    if (json['credits'] != null && json['credits']['cast'] != null) {
      castList = (json['credits']['cast'] as List)
          .take(10)
          .map((c) => TmdbCastMember.fromJson(c))
          .toList();
    }

    return TmdbMovie(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int?,
      popularity: (json['popularity'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
      releaseDate: json['release_date'] as String?,
      genres: (json['genres'] as List?)
              ?.map((g) => TmdbGenre.fromJson(g))
              .toList() ??
          [],
      tagline: json['tagline'] as String?,
      status: json['status'] as String?,
      cast: castList,
    );
  }
}

/// Detailed TV show information from TMDB.
class TmdbTvShow implements TmdbContent {
  @override
  final int id;
  final String name;
  @override
  final String? posterPath;
  @override
  final String? backdropPath;
  @override
  final String? overview;
  @override
  final double voteAverage;
  final int? voteCount;
  final double? popularity;
  final String? firstAirDate;
  final String? lastAirDate;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final List<TmdbGenre> genres;
  final String? tagline;
  final String? status;
  final List<TmdbSeason> seasons;
  final List<int>? episodeRunTime;
  final List<TmdbCastMember>? cast;

  @override
  String get title => name;

  @override
  MediaType get mediaType => MediaType.tv;

  TmdbTvShow({
    required this.id,
    required this.name,
    this.posterPath,
    this.backdropPath,
    this.overview,
    required this.voteAverage,
    this.voteCount,
    this.popularity,
    this.firstAirDate,
    this.lastAirDate,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    this.genres = const [],
    this.tagline,
    this.status,
    this.seasons = const [],
    this.episodeRunTime,
    this.cast,
  });

  String? get year {
    if (firstAirDate == null || firstAirDate!.isEmpty) return null;
    return firstAirDate!.split('-').first;
  }

  DateTime? get firstAirDateParsed {
    if (firstAirDate == null || firstAirDate!.isEmpty) return null;
    return DateTime.tryParse(firstAirDate!);
  }

  /// Average episode runtime in minutes.
  int get averageEpisodeRuntime {
    if (episodeRunTime == null || episodeRunTime!.isEmpty) return 45;
    return (episodeRunTime!.reduce((a, b) => a + b) / episodeRunTime!.length)
        .round();
  }

  /// Estimated total runtime for all episodes.
  int get estimatedTotalRuntime => numberOfEpisodes * averageEpisodeRuntime;

  factory TmdbTvShow.fromJson(Map<String, dynamic> json) {
    List<TmdbCastMember>? castList;
    if (json['credits'] != null && json['credits']['cast'] != null) {
      castList = (json['credits']['cast'] as List)
          .take(10)
          .map((c) => TmdbCastMember.fromJson(c))
          .toList();
    }

    return TmdbTvShow(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int?,
      popularity: (json['popularity'] as num?)?.toDouble(),
      firstAirDate: json['first_air_date'] as String?,
      lastAirDate: json['last_air_date'] as String?,
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
      genres: (json['genres'] as List?)
              ?.map((g) => TmdbGenre.fromJson(g))
              .toList() ??
          [],
      tagline: json['tagline'] as String?,
      status: json['status'] as String?,
      seasons: (json['seasons'] as List?)
              ?.map((s) => TmdbSeason.fromJson(s))
              .where((s) => s.seasonNumber > 0) // Exclude specials (season 0)
              .toList() ??
          [],
      episodeRunTime: (json['episode_run_time'] as List?)?.cast<int>(),
      cast: castList,
    );
  }
}

/// TV show season information.
class TmdbSeason {
  final int id;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final String? airDate;
  final List<TmdbEpisode>? episodes;

  TmdbSeason({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    required this.episodeCount,
    this.airDate,
    this.episodes,
  });

  factory TmdbSeason.fromJson(Map<String, dynamic> json) {
    return TmdbSeason(
      id: json['id'] as int,
      seasonNumber: json['season_number'] as int,
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
      airDate: json['air_date'] as String?,
      episodes: (json['episodes'] as List?)
          ?.map((e) => TmdbEpisode.fromJson(e))
          .toList(),
    );
  }
}

/// TV show episode information.
class TmdbEpisode {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final int? runtime;
  final String? stillPath;
  final String? airDate;
  final double voteAverage;

  TmdbEpisode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.runtime,
    this.stillPath,
    this.airDate,
    required this.voteAverage,
  });

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) {
    return TmdbEpisode(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int,
      seasonNumber: json['season_number'] as int,
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      runtime: json['runtime'] as int?,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Genre information.
class TmdbGenre {
  final int id;
  final String name;

  TmdbGenre({required this.id, required this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

/// Cast member information.
class TmdbCastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  TmdbCastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory TmdbCastMember.fromJson(Map<String, dynamic> json) {
    return TmdbCastMember(
      id: json['id'] as int,
      name: json['name'] as String,
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }
}
