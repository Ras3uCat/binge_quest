import 'watchlist_item.dart';

/// Person search result from TMDB.
class TmdbPersonSearchResult {
  final int id;
  final String name;
  final String? profilePath;
  final String? knownForDepartment;
  final double popularity;
  final List<TmdbPersonKnownFor> knownFor;

  TmdbPersonSearchResult({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownForDepartment,
    required this.popularity,
    this.knownFor = const [],
  });

  factory TmdbPersonSearchResult.fromJson(Map<String, dynamic> json) {
    return TmdbPersonSearchResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      profilePath: json['profile_path'] as String?,
      knownForDepartment: json['known_for_department'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      knownFor: (json['known_for'] as List?)
              ?.map((k) => TmdbPersonKnownFor.fromJson(k))
              .toList() ??
          [],
    );
  }
}

/// Known for item from person search results.
class TmdbPersonKnownFor {
  final int id;
  final String? title;
  final String? name;
  final String? posterPath;
  final String mediaTypeString;

  TmdbPersonKnownFor({
    required this.id,
    this.title,
    this.name,
    this.posterPath,
    required this.mediaTypeString,
  });

  String get displayTitle => title ?? name ?? 'Unknown';

  MediaType get mediaType =>
      mediaTypeString == 'tv' ? MediaType.tv : MediaType.movie;

  factory TmdbPersonKnownFor.fromJson(Map<String, dynamic> json) {
    return TmdbPersonKnownFor(
      id: json['id'] as int,
      title: json['title'] as String?,
      name: json['name'] as String?,
      posterPath: json['poster_path'] as String?,
      mediaTypeString: json['media_type'] as String? ?? 'movie',
    );
  }
}

/// Detailed person information from TMDB.
class TmdbPerson {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? profilePath;
  final String? knownForDepartment;
  final double popularity;
  final List<TmdbPersonCredit> movieCredits;
  final List<TmdbPersonCredit> tvCredits;

  TmdbPerson({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment,
    required this.popularity,
    this.movieCredits = const [],
    this.tvCredits = const [],
  });

  bool get isDeceased => deathday != null && deathday!.isNotEmpty;

  String? get formattedBirthday {
    if (birthday == null || birthday!.isEmpty) return null;
    final date = DateTime.tryParse(birthday!);
    if (date == null) return birthday;
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String? get formattedDeathday {
    if (deathday == null || deathday!.isEmpty) return null;
    final date = DateTime.tryParse(deathday!);
    if (date == null) return deathday;
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  int? get age {
    if (birthday == null || birthday!.isEmpty) return null;
    final birth = DateTime.tryParse(birthday!);
    if (birth == null) return null;
    final end = deathday != null && deathday!.isNotEmpty
        ? DateTime.tryParse(deathday!) ?? DateTime.now()
        : DateTime.now();
    int age = end.year - birth.year;
    if (end.month < birth.month ||
        (end.month == birth.month && end.day < birth.day)) {
      age--;
    }
    return age;
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  factory TmdbPerson.fromJson(Map<String, dynamic> json) {
    List<TmdbPersonCredit> movieCredits = [];
    List<TmdbPersonCredit> tvCredits = [];

    if (json['combined_credits'] != null) {
      final credits = json['combined_credits'];

      if (credits['cast'] != null) {
        for (final c in credits['cast'] as List) {
          final credit = TmdbPersonCredit.fromJson(c);
          if (credit.mediaType == MediaType.movie) {
            movieCredits.add(credit);
          } else {
            tvCredits.add(credit);
          }
        }
      }
    }

    // Sort by most recent first (null/empty dates go last)
    int byDateDesc(TmdbPersonCredit a, TmdbPersonCredit b) {
      final aDate = a.releaseDate ?? '';
      final bDate = b.releaseDate ?? '';
      if (aDate.isEmpty && bDate.isEmpty) return 0;
      if (aDate.isEmpty) return 1;
      if (bDate.isEmpty) return -1;
      return bDate.compareTo(aDate);
    }
    movieCredits.sort(byDateDesc);
    tvCredits.sort(byDateDesc);

    return TmdbPerson(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      deathday: json['deathday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      profilePath: json['profile_path'] as String?,
      knownForDepartment: json['known_for_department'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      movieCredits: movieCredits,
      tvCredits: tvCredits,
    );
  }
}

/// A movie or TV credit for a person.
class TmdbPersonCredit {
  final int id;
  final String title;
  final String? posterPath;
  final String? character;
  final String? releaseDate;
  final MediaType mediaType;
  final double voteAverage;
  final double popularity;

  TmdbPersonCredit({
    required this.id,
    required this.title,
    this.posterPath,
    this.character,
    this.releaseDate,
    required this.mediaType,
    required this.voteAverage,
    required this.popularity,
  });

  String? get year {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    return releaseDate!.split('-').first;
  }

  factory TmdbPersonCredit.fromJson(Map<String, dynamic> json) {
    final mediaTypeString = json['media_type'] as String? ?? 'movie';
    final isMovie = mediaTypeString == 'movie';

    return TmdbPersonCredit(
      id: json['id'] as int,
      title: (isMovie ? json['title'] : json['name']) as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      character: json['character'] as String?,
      releaseDate: (isMovie ? json['release_date'] : json['first_air_date']) as String?,
      mediaType: isMovie ? MediaType.movie : MediaType.tv,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
