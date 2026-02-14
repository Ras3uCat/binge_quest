import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../shared/models/content_cache.dart';
import '../../../shared/models/mood_tag.dart';
import '../../../shared/models/recommendation_mode.dart';
import '../../../shared/models/watchlist.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/models/watchlist_sort_mode.dart';
import '../../../shared/models/streaming_provider.dart';
import '../../../shared/models/content_cache_episode.dart';
import '../../../shared/repositories/content_cache_repository.dart';
import '../../../shared/repositories/content_cache_episodes_repository.dart';
import '../../../shared/repositories/watchlist_repository.dart';

/// Controller for managing watchlists and their items.
class WatchlistController extends GetxController {
  static WatchlistController get to => Get.find<WatchlistController>();

  // ============================================
  // OBSERVABLE STATE
  // ============================================

  final _watchlists = <Watchlist>[].obs;
  final _currentWatchlist = Rxn<Watchlist>();
  final _items = <WatchlistItem>[].obs;
  final _recommendedItems = <WatchlistItem>[].obs;
  final _stats = <String, dynamic>{}.obs;
  final _queueHealth = Rxn<dynamic>(); // QueueEfficiency from RPC
  final _isLoading = false.obs;
  final _isLoadingItems = false.obs;
  final _error = Rxn<String>();
  final _recommendationMode = RecommendationMode.recent.obs;
  final _timeBlockMinutes = Rxn<int>(); // null means no time filter
  final _selectedMoods = <MoodTag>[].obs;
  final _selectedGenreIds = <int>[].obs;
  final _selectedStreamingProviderIds = <int>[].obs;
  final _statusFilter = WatchlistStatusFilter.all.obs;
  final _sortMode = WatchlistSortMode.recentActivity.obs;
  final _sortAscending = false.obs;
  final _isFilterPanelActive = false.obs;
  bool _isBackfilling = false;
  RealtimeChannel? _watchlistChannel;

  // ============================================
  // GETTERS
  // ============================================

  List<Watchlist> get watchlists => _watchlists;
  Watchlist? get currentWatchlist => _currentWatchlist.value;
  Rxn<Watchlist> get rxCurrentWatchlist => _currentWatchlist;
  List<WatchlistItem> get items => _items;
  List<WatchlistItem> get recommendedItems => _recommendedItems;
  List<WatchlistItem> get finishFastItems =>
      _recommendedItems; // Alias for backwards compat
  dynamic get queueHealth => _queueHealth.value; // QueueEfficiency from RPC
  Rxn<dynamic> get rxQueueHealth => _queueHealth;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading.value;
  bool get isLoadingItems => _isLoadingItems.value;
  String? get error => _error.value;
  RecommendationMode get recommendationMode => _recommendationMode.value;
  int? get timeBlockMinutes => _timeBlockMinutes.value;
  bool get hasTimeBlockFilter => _timeBlockMinutes.value != null;
  List<MoodTag> get selectedMoods => _selectedMoods;
  List<int> get selectedGenreIds => _selectedGenreIds;
  List<int> get selectedStreamingProviderIds => _selectedStreamingProviderIds;
  WatchlistStatusFilter get statusFilter => _statusFilter.value;
  WatchlistSortMode get sortMode => _sortMode.value;
  bool get sortAscending => _sortAscending.value;
  bool get isFilterPanelActive => _isFilterPanelActive.value;
  bool get hasActiveFilters =>
      _selectedMoods.isNotEmpty ||
      _selectedGenreIds.isNotEmpty ||
      _selectedStreamingProviderIds.isNotEmpty ||
      _statusFilter.value != WatchlistStatusFilter.all;
  int get activeFilterCount {
    int count = 0;
    if (_selectedGenreIds.isNotEmpty) count++;
    if (_selectedStreamingProviderIds.isNotEmpty) count++;
    if (_statusFilter.value != WatchlistStatusFilter.all) count++;
    return count;
  }

  /// Get all items filtered by current mood/genre selection.
  List<WatchlistItem> get filteredItems {
    if (!hasActiveFilters) return _items;
    return _items.where(_itemMatchesFilters).toList();
  }

  /// Get all items filtered and sorted by current settings.
  /// This is the main getter for the watchlist screen.
  List<WatchlistItem> get filteredAndSortedItems {
    var itemList = List<WatchlistItem>.from(_items);

    // Apply status filter
    if (_statusFilter.value != WatchlistStatusFilter.all) {
      itemList = itemList.where((item) {
        switch (_statusFilter.value) {
          case WatchlistStatusFilter.notStarted:
            return item.isNotStarted;
          case WatchlistStatusFilter.inProgress:
            return !item.isNotStarted && !item.isCompleted;
          case WatchlistStatusFilter.completed:
            return item.isCompleted;
          case WatchlistStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply genre filter (OR logic - item matches any selected genre)
    if (_selectedGenreIds.isNotEmpty) {
      itemList = itemList
          .where(
            (item) => item.genreIds.any((id) => _selectedGenreIds.contains(id)),
          )
          .toList();
    }

    // Apply streaming provider filter (OR logic)
    if (_selectedStreamingProviderIds.isNotEmpty) {
      itemList = itemList
          .where(
            (item) => item.streamingProviders.any(
              (p) => _selectedStreamingProviderIds.contains(p.id),
            ),
          )
          .toList();
    }

    // Apply sorting
    itemList.sort((a, b) {
      int comparison;
      switch (_sortMode.value) {
        case WatchlistSortMode.recentActivity:
          final aActivity = a.lastActivityAt ?? a.addedAt;
          final bActivity = b.lastActivityAt ?? b.addedAt;
          comparison = bActivity.compareTo(aActivity);
          break;
        case WatchlistSortMode.alphabetical:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case WatchlistSortMode.popularity:
          final aPopularity = a.popularityScore ?? 0;
          final bPopularity = b.popularityScore ?? 0;
          comparison = bPopularity.compareTo(aPopularity);
          break;
        case WatchlistSortMode.minutesRemaining:
          final aRemaining = a.minutesRemaining ?? a.totalRuntimeMinutes;
          final bRemaining = b.minutesRemaining ?? b.totalRuntimeMinutes;
          comparison = aRemaining.compareTo(bRemaining);
          break;
        case WatchlistSortMode.releaseDate:
          final aDate = a.releaseDate ?? DateTime(1900);
          final bDate = b.releaseDate ?? DateTime(1900);
          comparison = bDate.compareTo(aDate);
          break;
      }
      return _sortAscending.value ? -comparison : comparison;
    });

    return itemList;
  }

  /// Get curated list of major streaming providers (same as search page).
  List<StreamingProviderInfo> get availableStreamingProviders {
    return StreamingProviders.all
        .map(
          (p) => StreamingProviderInfo(
            id: p.id,
            name: p.name,
            logoPath: p.logoPath,
          ),
        )
        .toList();
  }

  /// Get all unique genre IDs from current watchlist items.
  Set<int> get availableGenreIds {
    final ids = <int>{};
    for (final item in _items) {
      ids.addAll(item.genreIds);
    }
    return ids;
  }

  /// Get all items sorted by the current recommendation mode.
  List<WatchlistItem> get sortedItems {
    final itemList = List<WatchlistItem>.from(_items);

    switch (_recommendationMode.value) {
      case RecommendationMode.recent:
        // Sort by last activity (descending - most recent first)
        // Exclude items with 0% progress (not started)
        itemList.removeWhere((item) => item.isNotStarted);
        itemList.sort((a, b) {
          final aActivity = a.lastActivityAt ?? DateTime(1900);
          final bActivity = b.lastActivityAt ?? DateTime(1900);
          return bActivity.compareTo(aActivity);
        });
        break;

      case RecommendationMode.finishFast:
        // Sort by minutes remaining (ascending - least time first)
        itemList.sort((a, b) {
          final aRemaining = a.minutesRemaining ?? a.totalRuntimeMinutes;
          final bRemaining = b.minutesRemaining ?? b.totalRuntimeMinutes;
          return aRemaining.compareTo(bRemaining);
        });
        break;

      case RecommendationMode.freshFirst:
        // Sort by release date (descending - newest first)
        itemList.sort((a, b) {
          final aDate = a.releaseDate ?? DateTime(1900);
          final bDate = b.releaseDate ?? DateTime(1900);
          return bDate.compareTo(aDate);
        });
        break;

      case RecommendationMode.viralHits:
        // Sort by popularity score (descending - most popular first)
        itemList.sort((a, b) {
          final aPopularity = a.popularityScore ?? 0;
          final bPopularity = b.popularityScore ?? 0;
          return bPopularity.compareTo(aPopularity);
        });
        break;
    }

    return itemList;
  }

  /// Get items that fit within the time block.
  /// For movies: remaining time must fit.
  /// For TV shows: next episode remaining time must fit OR total remaining fits.
  /// Uses nextEpisodeRemaining for partially watched episodes (accounts for partial progress).
  List<WatchlistItem> get timeBlockItems {
    if (_timeBlockMinutes.value == null) return [];

    final targetMinutes = _timeBlockMinutes.value!;

    // Get items that can be watched in the time block
    final fittingItems = _items.where((item) {
      if (item.isCompleted) return false;
      final remaining = item.minutesRemaining ?? item.totalRuntimeMinutes;
      if (remaining <= 0) return false;

      // For movies: remaining time must fit
      if (item.mediaType == MediaType.movie) {
        return remaining <= targetMinutes;
      }

      // For TV shows: use remaining time for next episode (accounts for partial progress)
      // Falls back to full episode runtime if no partial progress
      final nextEpTime =
          item.nextEpisodeRemaining ??
          item.nextEpisodeRuntime ??
          item.episodeRuntime ??
          45;
      return nextEpTime <= targetMinutes || remaining <= targetMinutes;
    }).toList();

    // Sort: movies by remaining time, TV shows by next episode remaining time
    fittingItems.sort((a, b) {
      int aTime, bTime;

      if (a.mediaType == MediaType.movie) {
        aTime = a.minutesRemaining ?? a.totalRuntimeMinutes;
      } else {
        // Use remaining time for partially watched episodes
        aTime =
            a.nextEpisodeRemaining ??
            a.nextEpisodeRuntime ??
            a.episodeRuntime ??
            45;
      }

      if (b.mediaType == MediaType.movie) {
        bTime = b.minutesRemaining ?? b.totalRuntimeMinutes;
      } else {
        // Use remaining time for partially watched episodes
        bTime =
            b.nextEpisodeRemaining ??
            b.nextEpisodeRuntime ??
            b.episodeRuntime ??
            45;
      }

      // Sort descending so items closest to the target time are first
      return bTime.compareTo(aTime);
    });

    return fittingItems;
  }

  // Computed getters from stats
  int get totalItems => stats['total_items'] as int? ?? 0;
  int get completedCount => stats['completed_count'] as int? ?? 0;
  int get almostDoneCount => stats['almost_done_count'] as int? ?? 0;
  int get totalHoursRemaining => stats['total_hours_remaining'] as int? ?? 0;
  double get overallPercentage => stats['overall_percentage'] as double? ?? 0.0;

  // ============================================
  // LIFECYCLE
  // ============================================

  @override
  void onInit() {
    super.onInit();
    loadWatchlists();
  }

  @override
  void onClose() {
    _watchlistChannel?.unsubscribe();
    super.onClose();
  }

  // ============================================
  // REALTIME
  // ============================================

  /// Subscribe to realtime changes for the given watchlist.
  /// Re-subscribes each time the user switches watchlists.
  void _subscribeToWatchlist(String watchlistId) {
    // Tear down previous subscription.
    _watchlistChannel?.unsubscribe();

    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _watchlistChannel = Supabase.instance.client
        .channel('watchlist:$watchlistId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'watchlist_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'watchlist_id',
            value: watchlistId,
          ),
          callback: (_) => _onRealtimeChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'watch_progress',
          callback: (_) => _onRealtimeChange(),
        )
        .subscribe();
  }

  /// Called on any realtime change — debounce-refresh the current view.
  void _onRealtimeChange() {
    if (!_isLoadingItems.value) {
      _loadCurrentWatchlistData();
    }
  }

  // ============================================
  // WATCHLIST OPERATIONS
  // ============================================

  /// Load all watchlists for the current user.
  Future<void> loadWatchlists() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // Ensure default watchlist exists
      await WatchlistRepository.ensureDefaultWatchlist();

      // Load all watchlists
      final lists = await WatchlistRepository.getWatchlists();
      _watchlists.assignAll(lists);

      // Select default or first watchlist
      if (_currentWatchlist.value == null && lists.isNotEmpty) {
        final defaultList = lists.firstWhereOrNull((w) => w.isDefault);
        await selectWatchlist(defaultList ?? lists.first);
      } else if (_currentWatchlist.value != null) {
        // Refresh current watchlist data
        await _loadCurrentWatchlistData();
      }
    } catch (e) {
      _error.value = 'Failed to load watchlists: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Select a watchlist and load its items.
  Future<void> selectWatchlist(Watchlist watchlist) async {
    _currentWatchlist.value = watchlist;
    _subscribeToWatchlist(watchlist.id);
    await _loadCurrentWatchlistData();
  }

  /// Create a new watchlist.
  Future<Watchlist?> createWatchlist({
    required String name,
    bool isDefault = false,
  }) async {
    try {
      _error.value = null;
      final watchlist = await WatchlistRepository.createWatchlist(
        name: name,
        isDefault: isDefault,
      );
      AnalyticsService.logCreateWatchlist(name);

      await loadWatchlists();

      if (isDefault) {
        await selectWatchlist(watchlist);
      }

      return watchlist;
    } catch (e) {
      _error.value = 'Failed to create watchlist: $e';
      return null;
    }
  }

  /// Update a watchlist.
  Future<bool> updateWatchlist({
    required String id,
    String? name,
    bool? isDefault,
  }) async {
    try {
      _error.value = null;
      await WatchlistRepository.updateWatchlist(
        id: id,
        name: name,
        isDefault: isDefault,
      );

      await loadWatchlists();
      return true;
    } catch (e) {
      _error.value = 'Failed to update watchlist: $e';
      return false;
    }
  }

  /// Delete a watchlist.
  Future<bool> deleteWatchlist(String id) async {
    try {
      _error.value = null;

      // Don't allow deleting the last watchlist
      if (_watchlists.length <= 1) {
        _error.value = 'Cannot delete the last watchlist';
        return false;
      }

      // Don't allow deleting while it's selected without switching first
      final isCurrentlySelected = _currentWatchlist.value?.id == id;

      await WatchlistRepository.deleteWatchlist(id);
      AnalyticsService.logDeleteWatchlist();

      // Reload and select another if needed
      await loadWatchlists();

      if (isCurrentlySelected && _watchlists.isNotEmpty) {
        final newDefault = _watchlists.firstWhereOrNull((w) => w.isDefault);
        await selectWatchlist(newDefault ?? _watchlists.first);
      }

      return true;
    } catch (e) {
      _error.value = 'Failed to delete watchlist: $e';
      return false;
    }
  }

  // ============================================
  // ITEM OPERATIONS
  // ============================================

  /// Add an item to the current watchlist.
  /// Note: Content must already exist in content_cache before calling this.
  /// Use ContentSearchController.addMovieToWatchlist or addTvShowToWatchlist
  /// for the full flow including caching.
  Future<WatchlistItem?> addItem({
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    if (_currentWatchlist.value == null) {
      _error.value = 'No watchlist selected';
      return null;
    }

    try {
      _error.value = null;

      // Check for duplicates
      final exists = await WatchlistRepository.itemExistsInWatchlist(
        watchlistId: _currentWatchlist.value!.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );

      if (exists) {
        _error.value = 'Item already in watchlist';
        return null;
      }

      final item = await WatchlistRepository.addItem(
        watchlistId: _currentWatchlist.value!.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      AnalyticsService.logAddToWatchlist(
        tmdbId: tmdbId,
        mediaType: mediaType == MediaType.movie ? 'movie' : 'tv',
      );

      await _loadCurrentWatchlistData();
      return item;
    } catch (e) {
      _error.value = 'Failed to add item: $e';
      return null;
    }
  }

  /// Remove an item from the current watchlist.
  Future<bool> removeItem(String itemId) async {
    try {
      _error.value = null;
      await WatchlistRepository.removeItem(itemId);
      AnalyticsService.logRemoveFromWatchlist();
      await _loadCurrentWatchlistData();
      return true;
    } catch (e) {
      _error.value = 'Failed to remove item: $e';
      return false;
    }
  }

  /// Move an item to another watchlist.
  Future<bool> moveItem(WatchlistItem item, String toWatchlistId) async {
    try {
      _error.value = null;
      final success = await WatchlistRepository.moveItemToWatchlist(
        itemId: item.id,
        toWatchlistId: toWatchlistId,
        tmdbId: item.tmdbId,
        mediaType: item.mediaType,
      );

      if (success) {
        AnalyticsService.logMoveItem();
        // If the item was in the current watchlist, reload to reflect the change
        if (item.watchlistId == _currentWatchlist.value?.id) {
          await _loadCurrentWatchlistData();
        }
        return true;
      } else {
        _error.value = 'Item already exists in destination watchlist';
        return false;
      }
    } catch (e) {
      _error.value = 'Failed to move item: $e';
      return false;
    }
  }

  /// Check if an item exists in the current watchlist.
  Future<bool> itemExists({
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    if (_currentWatchlist.value == null) return false;

    return WatchlistRepository.itemExistsInWatchlist(
      watchlistId: _currentWatchlist.value!.id,
      tmdbId: tmdbId,
      mediaType: mediaType,
    );
  }

  // ============================================
  // RECOMMENDATION MODES
  // ============================================

  /// Change the recommendation mode and update recommendations.
  void setRecommendationMode(RecommendationMode mode) {
    if (_recommendationMode.value == mode) return;
    _recommendationMode.value = mode;
    _updateRecommendedItems();
  }

  // ============================================
  // TIME BLOCKS
  // ============================================

  /// Set time block filter in minutes.
  void setTimeBlock(int minutes) {
    _timeBlockMinutes.value = minutes;
  }

  /// Clear time block filter.
  void clearTimeBlock() {
    _timeBlockMinutes.value = null;
  }

  // ============================================
  // MOOD & GENRE FILTERS
  // ============================================

  /// Toggle a mood tag filter.
  void toggleMood(MoodTag mood) {
    if (_selectedMoods.contains(mood)) {
      _selectedMoods.remove(mood);
    } else {
      _selectedMoods.add(mood);
    }
    _updateRecommendedItems();
  }

  /// Toggle a genre filter by ID.
  void toggleGenre(int genreId) {
    if (_selectedGenreIds.contains(genreId)) {
      _selectedGenreIds.remove(genreId);
    } else {
      _selectedGenreIds.add(genreId);
    }
    _updateRecommendedItems();
  }

  /// Toggle a streaming provider filter by ID.
  void toggleStreamingProvider(int providerId) {
    if (_selectedStreamingProviderIds.contains(providerId)) {
      _selectedStreamingProviderIds.remove(providerId);
    } else {
      _selectedStreamingProviderIds.add(providerId);
    }
  }

  /// Set the status filter.
  void setStatusFilter(WatchlistStatusFilter status) {
    _statusFilter.value = status;
  }

  /// Set the sort mode.
  void setSortMode(WatchlistSortMode mode) {
    _sortMode.value = mode;
    // Sync recommendation mode for dashboard
    _recommendationMode.value = recommendationFromSortMode(mode);
  }

  /// Convert recommendation mode to sort mode for dashboard → watchlist sync.
  WatchlistSortMode sortModeFromRecommendation(RecommendationMode mode) {
    switch (mode) {
      case RecommendationMode.recent:
        return WatchlistSortMode.recentActivity;
      case RecommendationMode.freshFirst:
        return WatchlistSortMode.releaseDate;
      case RecommendationMode.viralHits:
        return WatchlistSortMode.popularity;
      case RecommendationMode.finishFast:
        return WatchlistSortMode.minutesRemaining;
    }
  }

  /// Convert sort mode to recommendation mode for watchlist → dashboard sync.
  RecommendationMode recommendationFromSortMode(WatchlistSortMode mode) {
    switch (mode) {
      case WatchlistSortMode.recentActivity:
        return RecommendationMode.recent;
      case WatchlistSortMode.releaseDate:
        return RecommendationMode.freshFirst;
      case WatchlistSortMode.popularity:
        return RecommendationMode.viralHits;
      case WatchlistSortMode.minutesRemaining:
        return RecommendationMode.finishFast;
      case WatchlistSortMode.alphabetical:
        return RecommendationMode.recent; // fallback
    }
  }

  /// Toggle sort direction.
  void toggleSortDirection() {
    _sortAscending.value = !_sortAscending.value;
  }

  /// Toggle filter panel visibility.
  void toggleFilterPanel() {
    _isFilterPanelActive.value = !_isFilterPanelActive.value;
  }

  /// Close the filter panel.
  void closeFilterPanel() {
    _isFilterPanelActive.value = false;
  }

  /// Clear all mood and genre filters.
  void clearFilters() {
    _selectedMoods.clear();
    _selectedGenreIds.clear();
    _selectedStreamingProviderIds.clear();
    _statusFilter.value = WatchlistStatusFilter.all;
    _updateRecommendedItems();
  }

  /// Clear all filters and reset sort.
  void clearAllFiltersAndSort() {
    clearFilters();
    _sortMode.value = WatchlistSortMode.recentActivity;
    _sortAscending.value = false;
  }

  /// Get all active genre IDs (from moods + direct selection).
  Set<int> get _activeGenreIds {
    final ids = <int>{};
    // Add mood-based genres
    for (final mood in _selectedMoods) {
      ids.addAll(mood.genreIds);
    }
    // Add directly selected genres
    ids.addAll(_selectedGenreIds);
    return ids;
  }

  /// Check if an item matches current filters.
  bool _itemMatchesFilters(WatchlistItem item) {
    if (!hasActiveFilters) return true;

    final activeGenres = _activeGenreIds;
    if (activeGenres.isEmpty) return true;

    // Items without genres pass through (backward compatibility)
    if (item.genreIds.isEmpty) return true;

    // Check if any of item's genres match any active genre (OR logic)
    return item.genreIds.any((id) => activeGenres.contains(id));
  }

  // ============================================
  // DATA BACKFILL
  // ============================================

  /// Backfill content cache for items missing data.
  /// This fetches content data from TMDB and updates the shared content_cache.
  Future<void> backfillContentCache({bool force = false}) async {
    if (_isBackfilling) return;
    _isBackfilling = true;

    try {
      // Find items with missing or incomplete content
      final itemsNeedingBackfill = force
          ? _items.toList()
          : _items.where((item) => _needsBackfill(item)).toList();

      if (itemsNeedingBackfill.isEmpty) return;

      for (final item in itemsNeedingBackfill) {
        try {
          if (item.mediaType == MediaType.movie) {
            await _backfillMovie(item.tmdbId);
          } else {
            await _backfillTvShow(item.tmdbId);
          }
        } catch (e) {
          // Silently continue on error
        }
      }

      // Note: Don't reload here to avoid double-loading cycle.
      // The backfill updates content_cache, which will be reflected on next refresh.
    } finally {
      _isBackfilling = false;
    }
  }

  /// Check if an item needs backfill (missing critical content data).
  bool _needsBackfill(WatchlistItem item) {
    final content = item.content;
    if (content == null) return true;

    // Check for missing critical fields that indicate incomplete data
    return content.overview == null ||
        content.overview!.isEmpty ||
        content.backdropPath == null ||
        content.voteAverage == null ||
        content.popularityScore == null ||
        content.genreIds.isEmpty ||
        content.castMembers.isEmpty;
  }

  /// Force backfill all content in the current watchlist.
  /// Use this to refresh all cached TMDB data.
  Future<void> forceBackfillAll() async {
    await backfillContentCache(force: true);
  }

  /// Backfill a single movie's content cache with all TMDB data.
  Future<void> _backfillMovie(int tmdbId) async {
    final details = await TmdbService.getMovieDetails(tmdbId);

    final genreIds =
        (details['genres'] as List<dynamic>?)
            ?.map((g) => g['id'] as int)
            .toList() ??
        [];

    final releaseDateStr = details['release_date'] as String?;
    final releaseDate = releaseDateStr != null && releaseDateStr.isNotEmpty
        ? DateTime.tryParse(releaseDateStr)
        : null;

    // Parse cast from credits
    List<CastMemberInfo>? castMembers;
    if (details['credits'] != null && details['credits']['cast'] != null) {
      castMembers = (details['credits']['cast'] as List)
          .take(10)
          .map(
            (c) => CastMemberInfo(
              id: c['id'] as int,
              name: c['name'] as String,
              character: c['character'] as String?,
              profilePath: c['profile_path'] as String?,
            ),
          )
          .toList();
    }

    final content = ContentCacheRepository.fromTmdbMovie(
      tmdbId: tmdbId,
      title: details['title'] as String? ?? 'Unknown',
      tagline: details['tagline'] as String?,
      posterPath: details['poster_path'] as String?,
      backdropPath: details['backdrop_path'] as String?,
      overview: details['overview'] as String?,
      voteAverage: (details['vote_average'] as num?)?.toDouble(),
      voteCount: details['vote_count'] as int?,
      popularity: (details['popularity'] as num?)?.toDouble(),
      genreIds: genreIds,
      status: details['status'] as String?,
      releaseDate: releaseDate,
      runtime: details['runtime'] as int?,
      cast: castMembers,
    );

    await ContentCacheRepository.upsert(content);

    // Also fetch and update streaming providers
    await _updateStreamingProviders(tmdbId, MediaType.movie);
  }

  /// Backfill a single TV show's content cache with all TMDB data.
  Future<void> _backfillTvShow(int tmdbId) async {
    final details = await TmdbService.getTvShowDetails(tmdbId);

    final genreIds =
        (details['genres'] as List<dynamic>?)
            ?.map((g) => g['id'] as int)
            .toList() ??
        [];

    final firstAirDateStr = details['first_air_date'] as String?;
    final firstAirDate = firstAirDateStr != null && firstAirDateStr.isNotEmpty
        ? DateTime.tryParse(firstAirDateStr)
        : null;

    final lastAirDateStr = details['last_air_date'] as String?;
    final lastAirDate = lastAirDateStr != null && lastAirDateStr.isNotEmpty
        ? DateTime.tryParse(lastAirDateStr)
        : null;

    final episodeRuntime =
        (details['episode_run_time'] as List?)?.isNotEmpty == true
        ? (details['episode_run_time'] as List).first as int
        : null;

    final numberOfEpisodes = details['number_of_episodes'] as int? ?? 0;
    final estimatedRuntime = numberOfEpisodes * (episodeRuntime ?? 45);

    // Parse cast from credits
    List<CastMemberInfo>? castMembers;
    if (details['credits'] != null && details['credits']['cast'] != null) {
      castMembers = (details['credits']['cast'] as List)
          .take(10)
          .map(
            (c) => CastMemberInfo(
              id: c['id'] as int,
              name: c['name'] as String,
              character: c['character'] as String?,
              profilePath: c['profile_path'] as String?,
            ),
          )
          .toList();
    }

    final content = ContentCacheRepository.fromTmdbTvShow(
      tmdbId: tmdbId,
      title: details['name'] as String? ?? 'Unknown',
      tagline: details['tagline'] as String?,
      posterPath: details['poster_path'] as String?,
      backdropPath: details['backdrop_path'] as String?,
      overview: details['overview'] as String?,
      voteAverage: (details['vote_average'] as num?)?.toDouble(),
      voteCount: details['vote_count'] as int?,
      popularity: (details['popularity'] as num?)?.toDouble(),
      genreIds: genreIds,
      status: details['status'] as String?,
      firstAirDate: firstAirDate,
      lastAirDate: lastAirDate,
      numberOfSeasons: details['number_of_seasons'] as int?,
      numberOfEpisodes: numberOfEpisodes,
      episodeRuntime: episodeRuntime,
      estimatedTotalRuntime: estimatedRuntime,
      cast: castMembers,
    );

    await ContentCacheRepository.upsert(content);

    // Also fetch and update streaming providers
    await _updateStreamingProviders(tmdbId, MediaType.tv);

    // After updating content cache, sync new episodes
    await _syncNewEpisodesForShow(tmdbId, details);
  }

  /// Sync new episodes discovered during backfill.
  /// Creates watch_progress entries for any episodes not yet tracked.
  Future<void> _syncNewEpisodesForShow(
    int tmdbId,
    Map<String, dynamic> showDetails,
  ) async {
    try {
      // Get current cached episodes
      final cachedEpisodes =
          await ContentCacheEpisodesRepository.getAllEpisodesForShow(tmdbId);
      final cachedSet = cachedEpisodes
          .map((e) => '${e.seasonNumber}:${e.episodeNumber}')
          .toSet();

      // Get all seasons from TMDB response
      final seasons = (showDetails['seasons'] as List?) ?? [];
      final newEpisodes = <ContentCacheEpisode>[];

      for (final season in seasons) {
        final seasonNumber = season['season_number'] as int;
        if (seasonNumber == 0) continue; // Skip specials

        // Fetch season details to get episodes
        final seasonData = await TmdbService.getSeasonDetails(
          tmdbId,
          seasonNumber,
        );
        final episodes = (seasonData['episodes'] as List?) ?? [];

        for (final epJson in episodes) {
          final epNum = epJson['episode_number'] as int;
          final key = '$seasonNumber:$epNum';

          // Check if this episode is already cached
          if (!cachedSet.contains(key)) {
            final episode = ContentCacheEpisode.fromTmdbJson(
              tmdbId,
              seasonNumber,
              epJson,
            );
            newEpisodes.add(episode);
          }
        }
      }

      if (newEpisodes.isEmpty) return;

      // Batch insert new episodes into cache
      final insertedEpisodes = await ContentCacheEpisodesRepository.batchInsert(
        newEpisodes,
      );

      // Find the user's watchlist_item for this show
      final item = _items.firstWhereOrNull(
        (i) => i.tmdbId == tmdbId && i.mediaType == MediaType.tv,
      );

      if (item == null) return;

      // Create watch_progress entries for each new episode
      for (final episode in insertedEpisodes) {
        final exists = await WatchlistRepository.watchProgressExistsForEpisode(
          item.id,
          episode.id,
        );

        if (!exists) {
          await WatchlistRepository.createWatchProgress(
            watchlistItemId: item.id,
            episodeCacheId: episode.id,
          );
        }
      }

      debugPrint(
        'Synced ${newEpisodes.length} new episodes for tmdbId: $tmdbId',
      );

      // Record new episode event for notifications
      await _recordNewEpisodeEvent(tmdbId, newEpisodes);
    } catch (e) {
      debugPrint('Error syncing new episodes for $tmdbId: $e');
    }
  }

  /// Fetch and update streaming providers for content.
  /// Detects new providers and logs streaming change events.
  Future<void> _updateStreamingProviders(
    int tmdbId,
    MediaType mediaType,
  ) async {
    try {
      // Capture old providers before TMDB fetch
      final cached = await ContentCacheRepository.get(tmdbId, mediaType);
      final oldProviderIds = <int>{};
      if (cached?.streamingProviders != null) {
        for (final p in cached!.streamingProviders!) {
          oldProviderIds.add(p.id);
        }
      }

      final response = mediaType == MediaType.movie
          ? await TmdbService.getMovieWatchProviders(tmdbId)
          : await TmdbService.getTvShowWatchProviders(tmdbId);

      final results = response['results'] as Map<String, dynamic>?;
      if (results == null) return;

      // Get US providers (or could be made configurable)
      final usData = results['US'] as Map<String, dynamic>?;
      if (usData == null) return;

      // Combine flatrate (subscription) and free providers
      final providers = <StreamingProviderInfo>[];

      final flatrate = usData['flatrate'] as List<dynamic>?;
      if (flatrate != null) {
        for (final p in flatrate) {
          providers.add(
            StreamingProviderInfo(
              id: p['provider_id'] as int,
              name: p['provider_name'] as String,
              logoPath: p['logo_path'] as String?,
            ),
          );
        }
      }

      final free = usData['free'] as List<dynamic>?;
      if (free != null) {
        for (final p in free) {
          // Avoid duplicates
          final id = p['provider_id'] as int;
          if (!providers.any((existing) => existing.id == id)) {
            providers.add(
              StreamingProviderInfo(
                id: id,
                name: p['provider_name'] as String,
                logoPath: p['logo_path'] as String?,
              ),
            );
          }
        }
      }

      if (providers.isNotEmpty) {
        await ContentCacheRepository.updateStreamingProviders(
          tmdbId,
          mediaType,
          providers,
        );

        // Detect new providers (client-side opportunistic detection)
        if (oldProviderIds.isNotEmpty) {
          final newProviders = providers
              .where((p) => !oldProviderIds.contains(p.id))
              .toList();
          if (newProviders.isNotEmpty) {
            debugPrint(
              'Streaming change detected for $tmdbId: '
              '${newProviders.map((p) => p.name).join(", ")}',
            );
            _logStreamingChanges(
              tmdbId: tmdbId,
              mediaType: mediaType,
              title: cached?.title ?? '',
              newProviders: newProviders,
            );
          }
        }
      }
    } catch (e) {
      // Silently continue - streaming providers are optional
    }
  }

  /// Trigger server-side streaming change check for this content.
  /// The Edge Function handles event logging and notification dispatch
  /// with service_role (bypasses RLS on streaming_change_events).
  Future<void> _logStreamingChanges({
    required int tmdbId,
    required MediaType mediaType,
    required String title,
    required List<StreamingProviderInfo> newProviders,
  }) async {
    try {
      debugPrint(
        'New streaming providers for "$title": '
        '${newProviders.map((p) => p.name).join(", ")}',
      );
      // Server-side Edge Function (check-streaming-changes) handles
      // authoritative event logging and user notifications via service_role.
      // Client-side detection is informational only — logged for debugging.
    } catch (e) {
      debugPrint('Error in streaming change detection: $e');
    }
  }

  /// Update recommended items based on current mode.
  void _updateRecommendedItems() {
    // Get items in progress (not completed, with time remaining)
    var inProgress = _items.where((item) {
      // Exclude completed items
      if (item.isCompleted) return false;

      // For TV shows: check next episode has time (excludes unreleased seasons)
      if (item.mediaType == MediaType.tv) {
        final episodeRemaining =
            item.nextEpisodeRemaining ??
            item.nextEpisodeRuntime ??
            item.episodeRuntime;
        // Exclude if next episode is 0m (unreleased) or no episode data
        if (episodeRemaining == null || episodeRemaining <= 0) return false;
      } else {
        // For movies: check total remaining time
        final remaining = item.minutesRemaining ?? item.totalRuntimeMinutes;
        if (remaining <= 0) return false;
      }

      return true;
    }).toList();

    // For recent mode, also exclude items that haven't been started
    if (_recommendationMode.value == RecommendationMode.recent) {
      inProgress = inProgress.where((item) => !item.isNotStarted).toList();
    }

    // Apply mood/genre filters
    if (hasActiveFilters) {
      inProgress = inProgress.where(_itemMatchesFilters).toList();
    }

    switch (_recommendationMode.value) {
      case RecommendationMode.recent:
        // Sort by last activity (descending - most recent first)
        inProgress.sort((a, b) {
          final aActivity = a.lastActivityAt ?? DateTime(1900);
          final bActivity = b.lastActivityAt ?? DateTime(1900);
          return bActivity.compareTo(aActivity);
        });
        break;

      case RecommendationMode.finishFast:
        // Sort by minutes remaining (ascending - least time first)
        inProgress.sort((a, b) {
          final aRemaining = a.minutesRemaining ?? a.totalRuntimeMinutes;
          final bRemaining = b.minutesRemaining ?? b.totalRuntimeMinutes;
          return aRemaining.compareTo(bRemaining);
        });
        break;

      case RecommendationMode.freshFirst:
        // Sort by release date (descending - newest first)
        inProgress.sort((a, b) {
          final aDate = a.releaseDate ?? DateTime(1900);
          final bDate = b.releaseDate ?? DateTime(1900);
          return bDate.compareTo(aDate);
        });
        break;

      case RecommendationMode.viralHits:
        // Sort by popularity score (descending - most popular first)
        inProgress.sort((a, b) {
          final aPopularity = a.popularityScore ?? 0;
          final bPopularity = b.popularityScore ?? 0;
          return bPopularity.compareTo(aPopularity);
        });
        break;
    }

    _recommendedItems.assignAll(inProgress.take(5).toList());
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  Future<void> _loadCurrentWatchlistData() async {
    if (_currentWatchlist.value == null) return;

    try {
      _isLoadingItems.value = true;

      final watchlistId = _currentWatchlist.value!.id;

      // Try combined RPC first (single round trip)
      final dashboardData = await WatchlistRepository.getDashboardData(
        watchlistId,
      );

      if (dashboardData != null) {
        // RPC succeeded - use combined data
        _items.assignAll(dashboardData.items);
        _stats.assignAll(dashboardData.stats);
        _queueHealth.value =
            dashboardData.queueHealth; // Share with QueueHealthController
      } else {
        // Fallback: Load items and stats in parallel (2 round trips)
        final results = await Future.wait([
          WatchlistRepository.getWatchlistItems(watchlistId),
          WatchlistRepository.getWatchlistStats(watchlistId),
        ]);

        final items = results[0] as List<WatchlistItem>;
        _items.assignAll(items);
        _stats.assignAll(results[1] as Map<String, dynamic>);
        _queueHealth.value =
            null; // Clear so QueueHealthController fetches its own
      }

      // Update recommended items based on current mode
      _updateRecommendedItems();

      // Backfill missing data for items (non-blocking)
      _backfillDataIfNeeded();
    } catch (e) {
      _error.value = 'Failed to load watchlist data: $e';
    } finally {
      _isLoadingItems.value = false;
    }
  }

  /// Non-blocking backfill for items missing content data.
  void _backfillDataIfNeeded() {
    final needsBackfill = _items.any(_needsBackfill);

    if (needsBackfill) {
      // Run backfill in background without awaiting
      backfillContentCache();
    }
  }

  /// Refresh current watchlist data.
  @override
  Future<void> refresh() async {
    await _loadCurrentWatchlistData();
  }

  /// Clear error state.
  void clearError() {
    _error.value = null;
  }

  /// Record new episode event for future notifications
  Future<void> _recordNewEpisodeEvent(
    int tmdbId,
    List<ContentCacheEpisode> newEpisodes,
  ) async {
    try {
      // Group by season
      final bySeasonMap = <int, int>{};
      for (final ep in newEpisodes) {
        bySeasonMap[ep.seasonNumber] = (bySeasonMap[ep.seasonNumber] ?? 0) + 1;
      }

      // Insert events for each season
      for (final entry in bySeasonMap.entries) {
        await SupabaseService.client.from('new_episode_events').upsert({
          'tmdb_id': tmdbId,
          'season_number': entry.key,
          'episode_count': entry.value,
          'detected_at': DateTime.now().toIso8601String(),
        }, onConflict: 'tmdb_id,season_number,detected_at');
      }

      debugPrint('Recorded new episode events for tmdbId: $tmdbId');
    } catch (e) {
      debugPrint('Error recording new episode event: $e');
    }
  }
}
