import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for TMDB API integration.
/// Handles movie and TV show search, details, and metadata.
class TmdbService {
  TmdbService._();

  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static String? _apiKey;

  /// Initialize TMDB service with API key.
  /// Call this during app initialization.
  static void initialize({required String apiKey}) {
    _apiKey = apiKey;
  }

  static String get _apiKeyParam {
    if (_apiKey == null) {
      throw Exception('TMDB API key not initialized. Call TmdbService.initialize() first.');
    }
    return 'api_key=$_apiKey';
  }

  /// Search for movies and TV shows.
  static Future<Map<String, dynamic>> multiSearch(String query, {int page = 1}) async {
    final url = '$_baseUrl/search/multi?$_apiKeyParam&query=${Uri.encodeComponent(query)}&page=$page';
    return _get(url);
  }

  /// Search for movies only.
  static Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    final url = '$_baseUrl/search/movie?$_apiKeyParam&query=${Uri.encodeComponent(query)}&page=$page';
    return _get(url);
  }

  /// Search for TV shows only.
  static Future<Map<String, dynamic>> searchTvShows(String query, {int page = 1}) async {
    final url = '$_baseUrl/search/tv?$_apiKeyParam&query=${Uri.encodeComponent(query)}&page=$page';
    return _get(url);
  }

  /// Get movie details by ID.
  static Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final url = '$_baseUrl/movie/$movieId?$_apiKeyParam&append_to_response=credits';
    return _get(url);
  }

  /// Get TV show details by ID.
  static Future<Map<String, dynamic>> getTvShowDetails(int tvId) async {
    final url = '$_baseUrl/tv/$tvId?$_apiKeyParam&append_to_response=credits';
    return _get(url);
  }

  /// Get TV season details.
  static Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) async {
    final url = '$_baseUrl/tv/$tvId/season/$seasonNumber?$_apiKeyParam';
    return _get(url);
  }

  /// Get TV episode details.
  static Future<Map<String, dynamic>> getEpisodeDetails(int tvId, int seasonNumber, int episodeNumber) async {
    final url = '$_baseUrl/tv/$tvId/season/$seasonNumber/episode/$episodeNumber?$_apiKeyParam';
    return _get(url);
  }

  // ============================================
  // PERSON/ACTOR SEARCH
  // ============================================

  /// Search for people (actors, directors, etc.).
  static Future<Map<String, dynamic>> searchPerson(String query, {int page = 1}) async {
    final url = '$_baseUrl/search/person?$_apiKeyParam&query=${Uri.encodeComponent(query)}&page=$page';
    return _get(url);
  }

  /// Get person details with combined credits.
  static Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final url = '$_baseUrl/person/$personId?$_apiKeyParam&append_to_response=combined_credits';
    return _get(url);
  }

  // ============================================
  // VIDEOS / TRAILERS
  // ============================================

  /// Get videos (trailers, teasers, etc.) for a movie.
  static Future<Map<String, dynamic>> getMovieVideos(int movieId) async {
    final url = '$_baseUrl/movie/$movieId/videos?$_apiKeyParam';
    return _get(url);
  }

  /// Get videos (trailers, teasers, etc.) for a TV show.
  static Future<Map<String, dynamic>> getTvShowVideos(int tvId) async {
    final url = '$_baseUrl/tv/$tvId/videos?$_apiKeyParam';
    return _get(url);
  }

  // ============================================
  // WATCH PROVIDERS
  // ============================================

  /// Get watch providers (streaming services) for a movie.
  static Future<Map<String, dynamic>> getMovieWatchProviders(int movieId) async {
    final url = '$_baseUrl/movie/$movieId/watch/providers?$_apiKeyParam';
    return _get(url);
  }

  /// Get list of available watch providers for a region.
  static Future<Map<String, dynamic>> getWatchProviderList({
    String type = 'movie',
    String region = 'US',
  }) async {
    final url = '$_baseUrl/watch/providers/$type?$_apiKeyParam&watch_region=$region';
    return _get(url);
  }

  // ============================================
  // DISCOVER (with provider filtering)
  // ============================================

  /// Discover movies with optional filters.
  static Future<Map<String, dynamic>> discoverMovies({
    int page = 1,
    String? watchRegion,
    List<int>? withWatchProviders,
    List<int>? withGenres,
    String? sortBy,
    String? releaseDateGte,
    String? releaseDateLte,
    double? voteAverageGte,
    int? voteCountGte,
    String? withOriginalLanguage,
  }) async {
    var url = '$_baseUrl/discover/movie?$_apiKeyParam&page=$page';

    if (watchRegion != null) {
      url += '&watch_region=$watchRegion';
    }
    if (withWatchProviders != null && withWatchProviders.isNotEmpty) {
      url += '&with_watch_providers=${withWatchProviders.join('|')}';
    }
    if (withGenres != null && withGenres.isNotEmpty) {
      url += '&with_genres=${withGenres.join('|')}';
    }
    if (sortBy != null) {
      url += '&sort_by=$sortBy';
    }
    if (releaseDateGte != null) {
      url += '&primary_release_date.gte=$releaseDateGte';
    }
    if (releaseDateLte != null) {
      url += '&primary_release_date.lte=$releaseDateLte';
    }
    if (voteAverageGte != null) {
      url += '&vote_average.gte=$voteAverageGte';
    }
    if (voteCountGte != null) {
      url += '&vote_count.gte=$voteCountGte';
    }
    if (withOriginalLanguage != null) {
      url += '&with_original_language=$withOriginalLanguage';
    }

    return _get(url);
  }

  /// Discover TV shows with optional filters.
  static Future<Map<String, dynamic>> discoverTvShows({
    int page = 1,
    String? watchRegion,
    List<int>? withWatchProviders,
    List<int>? withGenres,
    String? sortBy,
    String? firstAirDateGte,
    String? firstAirDateLte,
    double? voteAverageGte,
    int? voteCountGte,
    String? withOriginalLanguage,
  }) async {
    var url = '$_baseUrl/discover/tv?$_apiKeyParam&page=$page';

    if (watchRegion != null) {
      url += '&watch_region=$watchRegion';
    }
    if (withWatchProviders != null && withWatchProviders.isNotEmpty) {
      url += '&with_watch_providers=${withWatchProviders.join('|')}';
    }
    if (withGenres != null && withGenres.isNotEmpty) {
      url += '&with_genres=${withGenres.join('|')}';
    }
    if (sortBy != null) {
      url += '&sort_by=$sortBy';
    }
    if (firstAirDateGte != null) {
      url += '&first_air_date.gte=$firstAirDateGte';
    }
    if (firstAirDateLte != null) {
      url += '&first_air_date.lte=$firstAirDateLte';
    }
    if (voteAverageGte != null) {
      url += '&vote_average.gte=$voteAverageGte';
    }
    if (voteCountGte != null) {
      url += '&vote_count.gte=$voteCountGte';
    }
    if (withOriginalLanguage != null) {
      url += '&with_original_language=$withOriginalLanguage';
    }

    return _get(url);
  }

  /// Get watch providers (streaming services) for a TV show.
  static Future<Map<String, dynamic>> getTvShowWatchProviders(int tvId) async {
    final url = '$_baseUrl/tv/$tvId/watch/providers?$_apiKeyParam';
    return _get(url);
  }

  /// Generic GET request handler.
  static Future<Map<String, dynamic>> _get(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw TmdbException(
        'TMDB API request failed',
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

/// Exception class for TMDB API errors.
class TmdbException implements Exception {
  final String error;
  final int? statusCode;
  final String? message;

  TmdbException(this.error, {this.statusCode, this.message});

  @override
  String toString() => 'TmdbException: $error (status: $statusCode)';
}
