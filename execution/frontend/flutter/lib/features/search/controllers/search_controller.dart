import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../shared/models/content_cache.dart';
import '../../../shared/models/streaming_provider.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/tmdb_person.dart';
import '../../../shared/models/tmdb_video.dart';
import '../../../shared/models/tmdb_watch_provider.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/content_cache_repository.dart';
import '../../../shared/repositories/content_cache_episodes_repository.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

/// Filter type for search results.
enum SearchFilter { all, movies, tvShows, people }

/// Controller for TMDB content search.
class ContentSearchController extends GetxController {
  static ContentSearchController get to => Get.find<ContentSearchController>();

  // Text editing controller for search input
  final textController = TextEditingController();

  // Observable state
  final _searchResults = <TmdbSearchResult>[].obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _searchQuery = ''.obs;
  final _filter = SearchFilter.all.obs;
  final _selectedContent = Rxn<TmdbContent>();
  final _isLoadingDetails = false.obs;
  final _isAddingToWatchlist = false.obs;

  // Person search state
  final _personResults = <TmdbPersonSearchResult>[].obs;
  final _selectedPerson = Rxn<TmdbPerson>();
  final _isLoadingPerson = false.obs;

  // Video/Trailer state
  final _videos = <TmdbVideo>[].obs;
  final _isLoadingVideos = false.obs;

  // Watch provider state
  final _watchProviders = Rxn<TmdbWatchProviderResult>();
  final _isLoadingProviders = false.obs;

  // Streaming provider filter state
  final _selectedProviders = <StreamingProvider>[].obs;
  final _isProviderFilterActive = false.obs;

  // Search suggestions state
  final _suggestions = <TmdbSearchResult>[].obs;
  final _isLoadingSuggestions = false.obs;
  final _suggestionsLoaded = false.obs;

  // Cached streaming providers for search results
  final _cachedStreamingProviders = <int, List<StreamingProviderInfo>>{}.obs;

  // Getters
  List<TmdbSearchResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  String get searchQuery => _searchQuery.value;
  SearchFilter get filter => _filter.value;
  TmdbContent? get selectedContent => _selectedContent.value;
  bool get isLoadingDetails => _isLoadingDetails.value;
  bool get isAddingToWatchlist => _isAddingToWatchlist.value;
  bool get hasMorePages => _currentPage.value < _totalPages.value;

  // Person getters
  List<TmdbPersonSearchResult> get personResults => _personResults;
  TmdbPerson? get selectedPerson => _selectedPerson.value;
  bool get isLoadingPerson => _isLoadingPerson.value;
  bool get isPeopleSearch => _filter.value == SearchFilter.people;

  // Video/Trailer getters
  List<TmdbVideo> get videos => _videos;
  bool get isLoadingVideos => _isLoadingVideos.value;
  TmdbVideo? get bestTrailer => TmdbVideoList(videos: _videos).bestTrailer;
  bool get hasTrailer => bestTrailer != null;

  // Watch provider getters
  TmdbWatchProviderResult? get watchProviders => _watchProviders.value;
  bool get isLoadingProviders => _isLoadingProviders.value;
  bool get hasWatchProviders => _watchProviders.value?.hasAnyProvider ?? false;

  // Streaming provider filter getters
  List<StreamingProvider> get selectedProviders => _selectedProviders;
  bool get isProviderFilterActive => _isProviderFilterActive.value;
  bool get hasSelectedProviders => _selectedProviders.isNotEmpty;
  List<StreamingProvider> get availableProviders => StreamingProviders.all;

  // Suggestions getters
  List<TmdbSearchResult> get suggestions => _filteredSuggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions.value;
  bool get suggestionsLoaded => _suggestionsLoaded.value;
  bool get showSuggestions =>
      _searchQuery.value.isEmpty && !hasSelectedProviders;

  // Cached streaming providers getter
  Map<int, List<StreamingProviderInfo>> get cachedStreamingProviders =>
      _cachedStreamingProviders;

  /// Get streaming providers for a specific TMDB ID from cache.
  List<StreamingProviderInfo>? getStreamingProviders(int tmdbId) {
    return _cachedStreamingProviders[tmdbId];
  }

  /// Filter suggestions based on current filter (Movies/TV Shows/All).
  List<TmdbSearchResult> get _filteredSuggestions {
    switch (_filter.value) {
      case SearchFilter.movies:
        return _suggestions
            .where((r) => r.mediaType == MediaType.movie)
            .toList();
      case SearchFilter.tvShows:
        return _suggestions.where((r) => r.mediaType == MediaType.tv).toList();
      case SearchFilter.all:
        return _suggestions.toList();
      case SearchFilter.people:
        return []; // No suggestions for people search
    }
  }

  // Filtered results based on current filter
  List<TmdbSearchResult> get filteredResults {
    switch (_filter.value) {
      case SearchFilter.movies:
        return _searchResults
            .where((r) => r.mediaType == MediaType.movie)
            .toList();
      case SearchFilter.tvShows:
        return _searchResults
            .where((r) => r.mediaType == MediaType.tv)
            .toList();
      case SearchFilter.all:
        return _searchResults
            .where(
              (r) =>
                  r.mediaType == MediaType.movie || r.mediaType == MediaType.tv,
            )
            .toList();
      case SearchFilter.people:
        // Person results are stored separately, return empty for content results
        return [];
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  /// Search for content on TMDB.
  Future<void> search(String query, {bool resetResults = true}) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _personResults.clear();
      _searchQuery.value = '';
      return;
    }

    // Handle person search separately
    if (_filter.value == SearchFilter.people) {
      await _searchPeople(query, resetResults: resetResults);
      return;
    }

    if (resetResults) {
      _searchResults.clear();
      _currentPage.value = 1;
    }

    _searchQuery.value = query;
    _isLoading.value = true;
    _error.value = null;

    try {
      final response = await TmdbService.multiSearch(
        query,
        page: _currentPage.value,
      );

      final results = (response['results'] as List)
          .map((json) => TmdbSearchResult.fromJson(json))
          .where(
            (r) => r.mediaTypeString == 'movie' || r.mediaTypeString == 'tv',
          )
          .toList();

      if (resetResults) {
        _searchResults.assignAll(results);
      } else {
        _searchResults.addAll(results);
      }

      _totalPages.value = response['total_pages'] as int? ?? 1;

      // Batch fetch streaming providers for search results
      _fetchStreamingProvidersForResults(results);
    } catch (e) {
      _error.value = 'Search failed. Please try again.';
      debugPrint('Search error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Fetch streaming providers from cache for search results.
  Future<void> _fetchStreamingProvidersForResults(
    List<TmdbSearchResult> results,
  ) async {
    if (results.isEmpty) return;

    final tmdbIds = results.map((r) => r.id).toList();
    final providers =
        await ContentCacheRepository.getStreamingProvidersForIds(tmdbIds);

    // Merge with existing cached providers
    _cachedStreamingProviders.addAll(providers);
  }

  /// Search for people (actors, directors, etc.).
  Future<void> _searchPeople(String query, {bool resetResults = true}) async {
    if (resetResults) {
      _personResults.clear();
      _currentPage.value = 1;
    }

    _searchQuery.value = query;
    _isLoading.value = true;
    _error.value = null;

    try {
      final response = await TmdbService.searchPerson(
        query,
        page: _currentPage.value,
      );

      final results = (response['results'] as List)
          .map((json) => TmdbPersonSearchResult.fromJson(json))
          .toList();

      if (resetResults) {
        _personResults.assignAll(results);
      } else {
        _personResults.addAll(results);
      }

      _totalPages.value = response['total_pages'] as int? ?? 1;
    } catch (e) {
      _error.value = 'Search failed. Please try again.';
      debugPrint('Person search error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more results (pagination).
  Future<void> loadMore() async {
    if (_isLoading.value || !hasMorePages) return;

    if (hasSelectedProviders) {
      await loadMoreProviderResults();
      return;
    }

    _currentPage.value++;
    await search(_searchQuery.value, resetResults: false);
  }

  /// Set the search filter.
  void setFilter(SearchFilter newFilter) {
    if (_filter.value == newFilter) return;

    final wasPeopleSearch = _filter.value == SearchFilter.people;
    final isPeopleSearch = newFilter == SearchFilter.people;

    _filter.value = newFilter;

    // Re-search if we have a query and switching between content/people
    if (_searchQuery.value.isNotEmpty && (wasPeopleSearch != isPeopleSearch)) {
      search(_searchQuery.value);
    }
  }

  /// Clear search results and query.
  void clearSearch() {
    textController.clear();
    _searchResults.clear();
    _personResults.clear();
    _cachedStreamingProviders.clear();
    _searchQuery.value = '';
    _currentPage.value = 1;
    _totalPages.value = 1;
    _error.value = null;
  }

  // ============================================
  // STREAMING PROVIDER FILTER METHODS
  // ============================================

  /// Toggle a streaming provider in the filter.
  void toggleProvider(StreamingProvider provider) {
    if (_selectedProviders.contains(provider)) {
      _selectedProviders.remove(provider);
    } else {
      _selectedProviders.add(provider);
    }

    // Refresh results if we have providers selected
    if (_selectedProviders.isNotEmpty) {
      _discoverByProviders();
    } else if (_searchQuery.value.isNotEmpty) {
      // If no providers selected, go back to regular search
      search(_searchQuery.value);
    } else {
      _searchResults.clear();
    }
  }

  /// Clear all selected providers.
  void clearProviders() {
    _selectedProviders.clear();
    _isProviderFilterActive.value = false;

    if (_searchQuery.value.isNotEmpty) {
      search(_searchQuery.value);
    } else {
      _searchResults.clear();
    }
  }

  /// Toggle the provider filter panel visibility.
  void toggleProviderFilter() {
    _isProviderFilterActive.value = !_isProviderFilterActive.value;
  }

  /// Check if a provider is selected.
  bool isProviderSelected(StreamingProvider provider) {
    return _selectedProviders.contains(provider);
  }

  /// Discover content by selected providers.
  Future<void> _discoverByProviders({bool resetResults = true}) async {
    if (_selectedProviders.isEmpty) return;

    if (resetResults) {
      _searchResults.clear();
      _currentPage.value = 1;
    }

    _isLoading.value = true;
    _error.value = null;

    try {
      final providerIds = _selectedProviders.map((p) => p.id).toList();
      final results = <TmdbSearchResult>[];

      // Based on filter, discover movies, TV shows, or both
      if (_filter.value == SearchFilter.all ||
          _filter.value == SearchFilter.movies) {
        final movieResponse = await TmdbService.discoverMovies(
          page: _currentPage.value,
          watchRegion: 'US',
          withWatchProviders: providerIds,
          sortBy: 'popularity.desc',
        );

        final movieResults = (movieResponse['results'] as List)
            .map(
              (json) =>
                  TmdbSearchResult.fromJson({...json, 'media_type': 'movie'}),
            )
            .toList();
        results.addAll(movieResults);
      }

      if (_filter.value == SearchFilter.all ||
          _filter.value == SearchFilter.tvShows) {
        final tvResponse = await TmdbService.discoverTvShows(
          page: _currentPage.value,
          watchRegion: 'US',
          withWatchProviders: providerIds,
          sortBy: 'popularity.desc',
        );

        final tvResults = (tvResponse['results'] as List)
            .map(
              (json) =>
                  TmdbSearchResult.fromJson({...json, 'media_type': 'tv'}),
            )
            .toList();
        results.addAll(tvResults);
      }

      // Sort combined results by popularity
      results.sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));

      if (resetResults) {
        _searchResults.assignAll(results);
      } else {
        _searchResults.addAll(results);
      }

      // For discover, we'll estimate total pages
      _totalPages.value = 10;

      // For provider-filtered results, ALL results are on the selected providers
      // Inject selected providers into cache for each result
      _injectSelectedProvidersForResults(results);
    } catch (e) {
      _error.value = 'Failed to load content. Please try again.';
      debugPrint('Discover error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Inject selected providers into cache for discover results.
  /// When filtering by provider, ALL results are guaranteed to be available
  /// on those providers, so we can confidently assign them.
  void _injectSelectedProvidersForResults(List<TmdbSearchResult> results) {
    if (_selectedProviders.isEmpty || results.isEmpty) return;

    // Convert selected StreamingProvider to StreamingProviderInfo
    final providerInfoList = _selectedProviders
        .map(
          (p) => StreamingProviderInfo(
            id: p.id,
            name: p.name,
            logoPath: p.logoPath,
          ),
        )
        .toList();

    // Assign to all results
    for (final result in results) {
      _cachedStreamingProviders[result.id] = providerInfoList;
    }
  }

  /// Load more provider-filtered results.
  Future<void> loadMoreProviderResults() async {
    if (_isLoading.value || _currentPage.value >= _totalPages.value) return;

    _currentPage.value++;
    await _discoverByProviders(resetResults: false);
  }

  /// Get detailed information for a movie.
  /// Also caches the content and updates last_accessed_at.
  Future<TmdbMovie?> getMovieDetails(int movieId) async {
    _isLoadingDetails.value = true;
    _error.value = null;

    try {
      // Check if content exists in cache first
      final cached = await ContentCacheRepository.get(movieId, MediaType.movie);
      if (cached != null) {
        // Update last_accessed_at for cache management
        ContentCacheRepository.updateLastAccessed(movieId, MediaType.movie);
      }

      final response = await TmdbService.getMovieDetails(movieId);
      final movie = TmdbMovie.fromJson(response);
      _selectedContent.value = movie;

      // Cache the content if not already cached
      if (cached == null) {
        await _cacheMovie(movie);
      }

      return movie;
    } catch (e) {
      _error.value = 'Failed to load movie details.';
      debugPrint('Movie details error: $e');
      return null;
    } finally {
      _isLoadingDetails.value = false;
    }
  }

  /// Get detailed information for a TV show.
  /// Also caches the content and updates last_accessed_at.
  Future<TmdbTvShow?> getTvShowDetails(int tvId) async {
    _isLoadingDetails.value = true;
    _error.value = null;

    try {
      // Check if content exists in cache first
      final cached = await ContentCacheRepository.get(tvId, MediaType.tv);
      if (cached != null) {
        // Update last_accessed_at for cache management
        ContentCacheRepository.updateLastAccessed(tvId, MediaType.tv);
      }

      final response = await TmdbService.getTvShowDetails(tvId);
      final tvShow = TmdbTvShow.fromJson(response);
      _selectedContent.value = tvShow;

      // Cache the content if not already cached
      if (cached == null) {
        await _cacheTvShow(tvShow);
      }

      return tvShow;
    } catch (e) {
      _error.value = 'Failed to load TV show details.';
      debugPrint('TV show details error: $e');
      return null;
    } finally {
      _isLoadingDetails.value = false;
    }
  }

  /// Get details for content based on type.
  Future<TmdbContent?> getContentDetails(TmdbSearchResult result) async {
    if (result.mediaType == MediaType.movie) {
      return getMovieDetails(result.id);
    } else {
      return getTvShowDetails(result.id);
    }
  }

  /// Clear selected content.
  void clearSelectedContent() {
    _selectedContent.value = null;
  }

  /// Add movie to current watchlist.
  Future<bool> addMovieToWatchlist(TmdbMovie movie) async {
    final watchlistController = WatchlistController.to;
    final currentWatchlist = watchlistController.currentWatchlist;

    if (currentWatchlist == null) {
      _error.value = 'No watchlist selected';
      return false;
    }

    _isAddingToWatchlist.value = true;
    _error.value = null;

    try {
      // Check for duplicates
      final exists = await WatchlistRepository.itemExistsInWatchlist(
        watchlistId: currentWatchlist.id,
        tmdbId: movie.id,
        mediaType: MediaType.movie,
      );

      if (exists) {
        _error.value = 'Already in watchlist';
        return false;
      }

      // Ensure content is cached first
      await _cacheMovie(movie);

      // Add to watchlist (content already in cache)
      final item = await WatchlistRepository.addItem(
        watchlistId: currentWatchlist.id,
        tmdbId: movie.id,
        mediaType: MediaType.movie,
      );

      // Create watch progress entry for the movie
      await _createMovieProgress(item.id);

      // Refresh watchlist
      await watchlistController.refresh();

      return true;
    } catch (e) {
      _error.value = 'Failed to add to watchlist';
      debugPrint('Add movie error: $e');
      return false;
    } finally {
      _isAddingToWatchlist.value = false;
    }
  }

  /// Add TV show to current watchlist with all episodes.
  Future<bool> addTvShowToWatchlist(TmdbTvShow tvShow) async {
    final watchlistController = WatchlistController.to;
    final currentWatchlist = watchlistController.currentWatchlist;

    if (currentWatchlist == null) {
      _error.value = 'No watchlist selected';
      return false;
    }

    _isAddingToWatchlist.value = true;
    _error.value = null;

    try {
      // Check for duplicates
      final exists = await WatchlistRepository.itemExistsInWatchlist(
        watchlistId: currentWatchlist.id,
        tmdbId: tvShow.id,
        mediaType: MediaType.tv,
      );

      if (exists) {
        _error.value = 'Already in watchlist';
        return false;
      }

      // Ensure content is cached first
      await _cacheTvShow(tvShow);

      // Add to watchlist (content already in cache)
      final item = await WatchlistRepository.addItem(
        watchlistId: currentWatchlist.id,
        tmdbId: tvShow.id,
        mediaType: MediaType.tv,
      );

      // Fetch and create progress entries for all episodes
      await _createTvShowProgress(item.id, tvShow);

      // Refresh watchlist
      await watchlistController.refresh();

      return true;
    } catch (e) {
      _error.value = 'Failed to add to watchlist';
      debugPrint('Add TV show error: $e');
      return false;
    } finally {
      _isAddingToWatchlist.value = false;
    }
  }

  /// Create watch progress entry for a movie.
  /// Movie runtime comes from content_cache via join, not stored in watch_progress.
  Future<void> _createMovieProgress(String itemId) async {
    await WatchlistRepository.createWatchProgress(watchlistItemId: itemId);
  }

  /// Create watch progress entries for all episodes of a TV show.
  /// Caches episode metadata in content_cache_episodes before creating progress.
  Future<void> _createTvShowProgress(String itemId, TmdbTvShow tvShow) async {
    // Fetch detailed season info for each season
    for (final season in tvShow.seasons) {
      try {
        final seasonData = await TmdbService.getSeasonDetails(
          tvShow.id,
          season.seasonNumber,
        );

        final episodes = (seasonData['episodes'] as List?) ?? [];

        for (final episodeJson in episodes) {
          final episode = TmdbEpisode.fromJson(episodeJson);

          // 1. Cache episode metadata first (includes runtime, season, episode)
          final cachedEpisode =
              await ContentCacheEpisodesRepository.ensureExists(
                ContentCacheEpisodesRepository.fromTmdbEpisode(
                  tvShow.id,
                  episode,
                ),
              );

          // 2. Create progress entry with FK reference only
          await WatchlistRepository.createWatchProgress(
            watchlistItemId: itemId,
            episodeCacheId: cachedEpisode.id,
          );
        }
      } catch (e) {
        // If we can't fetch season details, we can't create episodes
        // (we need TMDB data to populate the episode cache)
        debugPrint('Failed to fetch season ${season.seasonNumber}: $e');
      }
    }
  }

  /// Check if content is already in current watchlist.
  Future<bool> isInWatchlist(int tmdbId, MediaType mediaType) async {
    final watchlistController = WatchlistController.to;
    final currentWatchlist = watchlistController.currentWatchlist;

    if (currentWatchlist == null) return false;

    return WatchlistRepository.itemExistsInWatchlist(
      watchlistId: currentWatchlist.id,
      tmdbId: tmdbId,
      mediaType: mediaType,
    );
  }

  /// Check if content is in any watchlist.
  Future<bool> isInAnyWatchlist(int tmdbId, MediaType mediaType) async {
    final existingIds = await WatchlistRepository.getWatchlistsContainingItem(
      tmdbId: tmdbId,
      mediaType: mediaType,
    );
    return existingIds.isNotEmpty;
  }

  /// Add movie to multiple watchlists.
  Future<bool> addMovieToWatchlists(
    TmdbMovie movie,
    List<String> watchlistIds,
  ) async {
    if (watchlistIds.isEmpty) return false;

    _isAddingToWatchlist.value = true;
    _error.value = null;

    try {
      // Ensure content is cached first
      await _cacheMovie(movie);

      // Add to all selected watchlists (content already in cache)
      final items = await WatchlistRepository.addItemToMultipleWatchlists(
        watchlistIds: watchlistIds,
        tmdbId: movie.id,
        mediaType: MediaType.movie,
      );

      // Create watch progress for each item
      for (final item in items) {
        await _createMovieProgress(item.id);
      }

      // Refresh watchlist
      await WatchlistController.to.refresh();

      return true;
    } catch (e) {
      _error.value = 'Failed to add to watchlists';
      debugPrint('Add movie to watchlists error: $e');
      return false;
    } finally {
      _isAddingToWatchlist.value = false;
    }
  }

  /// Add TV show to multiple watchlists.
  Future<bool> addTvShowToWatchlists(
    TmdbTvShow tvShow,
    List<String> watchlistIds,
  ) async {
    if (watchlistIds.isEmpty) return false;

    _isAddingToWatchlist.value = true;
    _error.value = null;

    try {
      // Ensure content is cached first
      await _cacheTvShow(tvShow);

      // Add to all selected watchlists (content already in cache)
      final items = await WatchlistRepository.addItemToMultipleWatchlists(
        watchlistIds: watchlistIds,
        tmdbId: tvShow.id,
        mediaType: MediaType.tv,
      );

      // Create progress entries for each item
      for (final item in items) {
        await _createTvShowProgress(item.id, tvShow);
      }

      // Refresh watchlist
      await WatchlistController.to.refresh();

      return true;
    } catch (e) {
      _error.value = 'Failed to add to watchlists';
      debugPrint('Add TV show to watchlists error: $e');
      return false;
    } finally {
      _isAddingToWatchlist.value = false;
    }
  }

  // ============================================
  // CONTENT CACHE HELPERS
  // ============================================

  /// Cache movie content in the shared content_cache table.
  Future<void> _cacheMovie(TmdbMovie movie) async {
    // Convert cast to CastMemberInfo
    final castMembers = movie.cast
        ?.map(
          (c) => CastMemberInfo(
            id: c.id,
            name: c.name,
            character: c.character,
            profilePath: c.profilePath,
          ),
        )
        .toList();

    // Fetch streaming providers
    List<StreamingProviderInfo> streamingProviders = [];
    try {
      final providersResponse = await TmdbService.getMovieWatchProviders(movie.id);
      final results = providersResponse['results'] as Map<String, dynamic>?;
      final usData = results?['US'] as Map<String, dynamic>?;
      if (usData != null) {
        // Get flatrate (subscription) providers
        final flatrate = usData['flatrate'] as List<dynamic>? ?? [];
        for (final p in flatrate) {
          streamingProviders.add(StreamingProviderInfo(
            id: p['provider_id'] as int,
            name: p['provider_name'] as String,
            logoPath: p['logo_path'] as String?,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error fetching streaming providers: $e');
    }

    final content = ContentCacheRepository.fromTmdbMovie(
      tmdbId: movie.id,
      title: movie.title,
      tagline: movie.tagline,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      overview: movie.overview,
      voteAverage: movie.voteAverage,
      voteCount: movie.voteCount,
      popularity: movie.popularity,
      genreIds: movie.genres.map((g) => g.id).toList(),
      status: movie.status,
      releaseDate: movie.releaseDateParsed,
      runtime: movie.runtime,
      cast: castMembers,
      streamingProviders: streamingProviders,
    );
    await ContentCacheRepository.upsert(content);
  }

  /// Cache TV show content in the shared content_cache table.
  Future<void> _cacheTvShow(TmdbTvShow tvShow) async {
    // Convert cast to CastMemberInfo
    final castMembers = tvShow.cast
        ?.map(
          (c) => CastMemberInfo(
            id: c.id,
            name: c.name,
            character: c.character,
            profilePath: c.profilePath,
          ),
        )
        .toList();

    // Parse lastAirDate
    final lastAirDate =
        tvShow.lastAirDate != null && tvShow.lastAirDate!.isNotEmpty
        ? DateTime.tryParse(tvShow.lastAirDate!)
        : null;

    // Fetch streaming providers
    List<StreamingProviderInfo> streamingProviders = [];
    try {
      final providersResponse = await TmdbService.getTvShowWatchProviders(tvShow.id);
      final results = providersResponse['results'] as Map<String, dynamic>?;
      final usData = results?['US'] as Map<String, dynamic>?;
      if (usData != null) {
        // Get flatrate (subscription) providers
        final flatrate = usData['flatrate'] as List<dynamic>? ?? [];
        for (final p in flatrate) {
          streamingProviders.add(StreamingProviderInfo(
            id: p['provider_id'] as int,
            name: p['provider_name'] as String,
            logoPath: p['logo_path'] as String?,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error fetching streaming providers: $e');
    }

    final content = ContentCacheRepository.fromTmdbTvShow(
      tmdbId: tvShow.id,
      title: tvShow.title,
      tagline: tvShow.tagline,
      posterPath: tvShow.posterPath,
      backdropPath: tvShow.backdropPath,
      overview: tvShow.overview,
      voteAverage: tvShow.voteAverage,
      voteCount: tvShow.voteCount,
      popularity: tvShow.popularity,
      genreIds: tvShow.genres.map((g) => g.id).toList(),
      status: tvShow.status,
      firstAirDate: tvShow.firstAirDateParsed,
      lastAirDate: lastAirDate,
      numberOfSeasons: tvShow.numberOfSeasons,
      numberOfEpisodes: tvShow.numberOfEpisodes,
      episodeRuntime: tvShow.averageEpisodeRuntime,
      estimatedTotalRuntime: tvShow.estimatedTotalRuntime,
      cast: castMembers,
      streamingProviders: streamingProviders,
    );
    await ContentCacheRepository.upsert(content);
  }

  /// Clear error.
  void clearError() {
    _error.value = null;
  }

  // ============================================
  // PERSON METHODS
  // ============================================

  /// Get detailed information for a person.
  Future<TmdbPerson?> getPersonDetails(int personId) async {
    _selectedPerson.value = null;
    _isLoadingPerson.value = true;
    _error.value = null;

    try {
      final response = await TmdbService.getPersonDetails(personId);
      final person = TmdbPerson.fromJson(response);
      _selectedPerson.value = person;
      return person;
    } catch (e) {
      _error.value = 'Failed to load person details.';
      debugPrint('Person details error: $e');
      return null;
    } finally {
      _isLoadingPerson.value = false;
    }
  }

  /// Clear selected person.
  void clearSelectedPerson() {
    _selectedPerson.value = null;
  }

  // ============================================
  // VIDEO/TRAILER METHODS
  // ============================================

  /// Get videos (trailers) for a movie.
  Future<void> loadMovieVideos(int movieId) async {
    _isLoadingVideos.value = true;
    _videos.clear();

    try {
      final response = await TmdbService.getMovieVideos(movieId);
      final videoList = TmdbVideoList.fromJson(response);
      _videos.assignAll(videoList.youtubeVideos);
    } catch (e) {
      debugPrint('Movie videos error: $e');
    } finally {
      _isLoadingVideos.value = false;
    }
  }

  /// Get videos (trailers) for a TV show.
  Future<void> loadTvShowVideos(int tvId) async {
    _isLoadingVideos.value = true;
    _videos.clear();

    try {
      final response = await TmdbService.getTvShowVideos(tvId);
      final videoList = TmdbVideoList.fromJson(response);
      _videos.assignAll(videoList.youtubeVideos);
    } catch (e) {
      debugPrint('TV show videos error: $e');
    } finally {
      _isLoadingVideos.value = false;
    }
  }

  /// Load videos based on content type.
  Future<void> loadVideos(int id, MediaType mediaType) async {
    if (mediaType == MediaType.movie) {
      await loadMovieVideos(id);
    } else {
      await loadTvShowVideos(id);
    }
  }

  /// Clear videos.
  void clearVideos() {
    _videos.clear();
  }

  // ============================================
  // WATCH PROVIDER METHODS
  // ============================================

  /// Get watch providers for a movie.
  Future<void> loadMovieWatchProviders(
    int movieId, {
    String country = 'US',
  }) async {
    _isLoadingProviders.value = true;
    _watchProviders.value = null;

    try {
      final response = await TmdbService.getMovieWatchProviders(movieId);
      final providers = TmdbWatchProviders.fromJson(response);
      _watchProviders.value = providers.forCountry(country);
    } catch (e) {
      debugPrint('Movie watch providers error: $e');
    } finally {
      _isLoadingProviders.value = false;
    }
  }

  /// Get watch providers for a TV show.
  Future<void> loadTvShowWatchProviders(
    int tvId, {
    String country = 'US',
  }) async {
    _isLoadingProviders.value = true;
    _watchProviders.value = null;

    try {
      final response = await TmdbService.getTvShowWatchProviders(tvId);
      final providers = TmdbWatchProviders.fromJson(response);
      _watchProviders.value = providers.forCountry(country);
    } catch (e) {
      debugPrint('TV show watch providers error: $e');
    } finally {
      _isLoadingProviders.value = false;
    }
  }

  /// Load watch providers based on content type.
  Future<void> loadWatchProviders(
    int id,
    MediaType mediaType, {
    String country = 'US',
  }) async {
    if (mediaType == MediaType.movie) {
      await loadMovieWatchProviders(id, country: country);
    } else {
      await loadTvShowWatchProviders(id, country: country);
    }
  }

  /// Clear watch providers.
  void clearWatchProviders() {
    _watchProviders.value = null;
  }

  // ============================================
  // SEARCH SUGGESTIONS METHODS
  // ============================================

  /// Load personalized suggestions based on user's watchlist genres.
  Future<void> loadSuggestions() async {
    if (_isLoadingSuggestions.value || _suggestionsLoaded.value) return;

    _isLoadingSuggestions.value = true;

    try {
      // Get user's watchlist items to analyze genre preferences
      final watchlistController = WatchlistController.to;
      final items = watchlistController.items;

      if (items.isEmpty) {
        // No watchlist items - fetch popular content instead
        await _loadPopularContent();
        return;
      }

      // Count genre frequency from watchlist
      final genreCount = <int, int>{};
      for (final item in items) {
        for (final genreId in item.genreIds) {
          genreCount[genreId] = (genreCount[genreId] ?? 0) + 1;
        }
      }

      // Sort genres by frequency, take top 3
      final sortedGenres = genreCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topGenreIds = sortedGenres.take(3).map((e) => e.key).toList();

      if (topGenreIds.isEmpty) {
        await _loadPopularContent();
        return;
      }

      // Get TMDB IDs already in watchlist to exclude
      final watchlistTmdbIds = items.map((item) => item.tmdbId).toSet();

      // Fetch movies with user's preferred genres (popular + quality)
      final movieResponse = await TmdbService.discoverMovies(
        withGenres: topGenreIds,
        sortBy: 'popularity.desc',
        voteAverageGte: 6.0,
        voteCountGte: 100,
        withOriginalLanguage: 'en',
      );
      final movieResults = (movieResponse['results'] as List)
          .map(
            (json) =>
                TmdbSearchResult.fromJson({...json, 'media_type': 'movie'}),
          )
          .where((r) => !watchlistTmdbIds.contains(r.id))
          .toList();

      // Fetch TV shows with user's preferred genres (popular + quality)
      final tvResponse = await TmdbService.discoverTvShows(
        withGenres: topGenreIds,
        sortBy: 'popularity.desc',
        voteAverageGte: 6.0,
        voteCountGte: 100,
        withOriginalLanguage: 'en',
      );
      final tvResults = (tvResponse['results'] as List)
          .map(
            (json) => TmdbSearchResult.fromJson({...json, 'media_type': 'tv'}),
          )
          .where((r) => !watchlistTmdbIds.contains(r.id))
          .toList();

      // Interleave movies and TV shows for balanced mix
      final interleaved = _interleaveResults(movieResults, tvResults);
      _suggestions.assignAll(interleaved.take(20).toList());
      _suggestionsLoaded.value = true;
    } catch (e) {
      debugPrint('Load suggestions error: $e');
    } finally {
      _isLoadingSuggestions.value = false;
    }
  }

  /// Load popular content as fallback suggestions.
  Future<void> _loadPopularContent() async {
    try {
      final movieResponse = await TmdbService.discoverMovies(
        sortBy: 'popularity.desc',
        voteAverageGte: 6.0,
        voteCountGte: 100,
        withOriginalLanguage: 'en',
      );
      final movieResults = (movieResponse['results'] as List)
          .map(
            (json) =>
                TmdbSearchResult.fromJson({...json, 'media_type': 'movie'}),
          )
          .toList();

      final tvResponse = await TmdbService.discoverTvShows(
        sortBy: 'popularity.desc',
        voteAverageGte: 6.0,
        voteCountGte: 100,
        withOriginalLanguage: 'en',
      );
      final tvResults = (tvResponse['results'] as List)
          .map(
            (json) => TmdbSearchResult.fromJson({...json, 'media_type': 'tv'}),
          )
          .toList();

      // Interleave for balanced mix
      final interleaved = _interleaveResults(movieResults, tvResults);
      _suggestions.assignAll(interleaved.take(20).toList());
      _suggestionsLoaded.value = true;
    } catch (e) {
      debugPrint('Load popular content error: $e');
    }
  }

  /// Interleave two lists for balanced mix (alternates items).
  List<TmdbSearchResult> _interleaveResults(
    List<TmdbSearchResult> movies,
    List<TmdbSearchResult> tvShows,
  ) {
    final result = <TmdbSearchResult>[];
    final maxLen = movies.length > tvShows.length
        ? movies.length
        : tvShows.length;

    for (var i = 0; i < maxLen; i++) {
      if (i < movies.length) result.add(movies[i]);
      if (i < tvShows.length) result.add(tvShows[i]);
    }

    return result;
  }

  /// Clear suggestions and reload.
  void refreshSuggestions() {
    _suggestions.clear();
    _suggestionsLoaded.value = false;
    loadSuggestions();
  }
}
