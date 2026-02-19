import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';
import '../models/dashboard_data.dart';
import '../models/watchlist.dart';
import '../models/watchlist_item.dart';
import '../models/queue_efficiency.dart';
import '../models/streaming_breakdown.dart';
import '../models/friend_watching.dart';

/// Repository for watchlist-related database operations.
class WatchlistRepository {
  WatchlistRepository._();

  static final _client = SupabaseService.client;

  /// Select query that joins with content_cache to get full item data.
  static const _itemSelectWithContent = '''
    id,
    watchlist_id,
    tmdb_id,
    media_type,
    added_at,
    content_cache (
      tmdb_id,
      media_type,
      title,
      tagline,
      poster_path,
      backdrop_path,
      overview,
      vote_average,
      vote_count,
      popularity_score,
      genre_ids,
      status,
      release_date,
      last_air_date,
      total_runtime_minutes,
      episode_runtime,
      number_of_seasons,
      number_of_episodes,
      streaming_providers,
      cast_members,
      created_at,
      updated_at
    )
  ''';

  // ============================================
  // WATCHLIST OPERATIONS
  // ============================================

  /// Get all watchlists for the current user (owned + co-owned).
  /// RLS ensures only visible watchlists are returned.
  static Future<List<Watchlist>> getWatchlists() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Fetch owned watchlists
    final owned = await _client
        .from('watchlists')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);

    // Fetch co-owned watchlist IDs
    final coOwnedRows = await _client
        .from('watchlist_members')
        .select('watchlist_id')
        .eq('user_id', userId)
        .eq('status', 'accepted');

    final ownedLists = (owned as List)
        .map((json) => Watchlist.fromJson(json))
        .toList();

    final ownedIds = ownedLists.map((w) => w.id).toSet();

    // Exclude co-owned IDs that are already in the owned list
    final coOwnedIds = (coOwnedRows as List)
        .map((r) => r['watchlist_id'] as String)
        .where((id) => !ownedIds.contains(id))
        .toList();

    if (coOwnedIds.isEmpty) return ownedLists;

    // Fetch co-owned watchlist details
    final coOwned = await _client
        .from('watchlists')
        .select()
        .inFilter('id', coOwnedIds)
        .order('created_at', ascending: true);

    final coOwnedLists = (coOwned as List)
        .map((json) => Watchlist.fromJson(json))
        .toList();

    return [...ownedLists, ...coOwnedLists];
  }

  /// Get a single watchlist by ID.
  static Future<Watchlist?> getWatchlist(String id) async {
    final response = await _client
        .from('watchlists')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Watchlist.fromJson(response);
  }

  /// Get the default watchlist for the current user.
  static Future<Watchlist?> getDefaultWatchlist() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('watchlists')
        .select()
        .eq('user_id', userId)
        .eq('is_default', true)
        .maybeSingle();

    if (response == null) return null;
    return Watchlist.fromJson(response);
  }

  /// Create a new watchlist.
  static Future<Watchlist> createWatchlist({
    required String name,
    bool isDefault = false,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // If this is the default, unset any existing default
    if (isDefault) {
      await _client
          .from('watchlists')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    }

    final response = await _client
        .from('watchlists')
        .insert({'user_id': userId, 'name': name, 'is_default': isDefault})
        .select()
        .single();

    return Watchlist.fromJson(response);
  }

  /// Update a watchlist.
  static Future<Watchlist> updateWatchlist({
    required String id,
    String? name,
    bool? isDefault,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (isDefault != null) {
      updates['is_default'] = isDefault;
      // Unset any existing default if setting this one
      if (isDefault) {
        await _client
            .from('watchlists')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true)
            .neq('id', id);
      }
    }

    final response = await _client
        .from('watchlists')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Watchlist.fromJson(response);
  }

  /// Delete a watchlist.
  static Future<void> deleteWatchlist(String id) async {
    await _client.from('watchlists').delete().eq('id', id);
  }

  /// Create default watchlist for new user if none exists.
  static Future<Watchlist> ensureDefaultWatchlist() async {
    final existing = await getDefaultWatchlist();
    if (existing != null) return existing;

    return createWatchlist(name: 'My Queue', isDefault: true);
  }

  // ============================================
  // WATCHLIST ITEM OPERATIONS
  // ============================================

  /// Get all items in a watchlist with computed progress fields.
  /// Joins with content_cache to get full content metadata.
  static Future<List<WatchlistItem>> getWatchlistItems(
    String watchlistId,
  ) async {
    try {
      final response = await _client
          .from('watchlist_items')
          .select(_itemSelectWithContent)
          .eq('watchlist_id', watchlistId)
          .order('added_at', ascending: false);

      final items = (response as List)
          .map((json) => WatchlistItem.fromJson(json))
          .toList();

      // Calculate progress for each item
      final itemsWithProgress = <WatchlistItem>[];
      for (final item in items) {
        final progress = await _getItemProgress(item.id);
        itemsWithProgress.add(
          item.copyWith(
            minutesRemaining: progress['minutes_remaining'] as int?,
            completionPercentage: progress['completion_percentage'] as double?,
            nextEpisodeRuntime: progress['next_episode_runtime'] as int?,
            nextEpisodeRemaining: progress['next_episode_remaining'] as int?,
            lastActivityAt: progress['last_activity_at'] as DateTime?,
          ),
        );
      }

      return itemsWithProgress;
    } catch (e) {
      // Fallback: load items without content_cache join
      try {
        final response = await _client
            .from('watchlist_items')
            .select('id, watchlist_id, tmdb_id, media_type, added_at')
            .eq('watchlist_id', watchlistId)
            .order('added_at', ascending: false);

        final items = (response as List)
            .map(
              (json) => WatchlistItem(
                id: json['id'] as String,
                watchlistId: json['watchlist_id'] as String,
                tmdbId: json['tmdb_id'] as int,
                mediaType: MediaType.fromString(json['media_type'] as String),
                addedAt: DateTime.parse(json['added_at'] as String),
              ),
            )
            .toList();

        // Calculate progress for each item
        final itemsWithProgress = <WatchlistItem>[];
        for (final item in items) {
          final progress = await _getItemProgress(item.id);
          itemsWithProgress.add(
            item.copyWith(
              minutesRemaining: progress['minutes_remaining'] as int?,
              completionPercentage:
                  progress['completion_percentage'] as double?,
              nextEpisodeRuntime: progress['next_episode_runtime'] as int?,
              lastActivityAt: progress['last_activity_at'] as DateTime?,
            ),
          );
        }

        return itemsWithProgress;
      } catch (fallbackError) {
        rethrow;
      }
    }
  }

  /// Get a single watchlist item by ID with content data.
  static Future<WatchlistItem?> getWatchlistItem(String itemId) async {
    final response = await _client
        .from('watchlist_items')
        .select(_itemSelectWithContent)
        .eq('id', itemId)
        .maybeSingle();

    if (response == null) return null;

    final item = WatchlistItem.fromJson(response);
    final progress = await _getItemProgress(item.id);

    return item.copyWith(
      minutesRemaining: progress['minutes_remaining'] as int?,
      completionPercentage: progress['completion_percentage'] as double?,
      nextEpisodeRuntime: progress['next_episode_runtime'] as int?,
      lastActivityAt: progress['last_activity_at'] as DateTime?,
    );
  }

  /// Get items sorted by minutes remaining (Finish Fast algorithm).
  static Future<List<WatchlistItem>> getFinishFastItems(
    String watchlistId, {
    int limit = 5,
  }) async {
    final items = await getWatchlistItems(watchlistId);

    // Filter to items in progress (not completed, has remaining time)
    final inProgress = items
        .where(
          (item) =>
              !item.isCompleted &&
              (item.minutesRemaining ?? item.totalRuntimeMinutes) > 0,
        )
        .toList();

    // Sort by minutes remaining (ascending)
    inProgress.sort((a, b) {
      final aRemaining = a.minutesRemaining ?? a.totalRuntimeMinutes;
      final bRemaining = b.minutesRemaining ?? b.totalRuntimeMinutes;
      return aRemaining.compareTo(bRemaining);
    });

    return inProgress.take(limit).toList();
  }

  /// Get items sorted by recent activity (Recent Progress mode).
  /// Excludes items with no progress (not started) and completed items.
  static Future<List<WatchlistItem>> getRecentProgressItems(
    String watchlistId, {
    int limit = 5,
  }) async {
    final items = await getWatchlistItems(watchlistId);

    // Filter to items with progress (started but not completed)
    final inProgress = items
        .where(
          (item) =>
              !item.isCompleted &&
              !item.isNotStarted &&
              item.lastActivityAt != null,
        )
        .toList();

    // Sort by last activity (descending - most recent first)
    inProgress.sort((a, b) {
      final aActivity = a.lastActivityAt ?? DateTime(1900);
      final bActivity = b.lastActivityAt ?? DateTime(1900);
      return bActivity.compareTo(aActivity);
    });

    return inProgress.take(limit).toList();
  }

  /// Add an item to a watchlist.
  /// Content must already exist in content_cache (ensured by the caller).
  static Future<WatchlistItem> addItem({
    required String watchlistId,
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    final response = await _client
        .from('watchlist_items')
        .insert({
          'watchlist_id': watchlistId,
          'tmdb_id': tmdbId,
          'media_type': mediaType.value,
        })
        .select(_itemSelectWithContent)
        .single();

    return WatchlistItem.fromJson(response);
  }

  /// Check if an item already exists in a specific watchlist.
  static Future<bool> itemExistsInWatchlist({
    required String watchlistId,
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    final response = await _client
        .from('watchlist_items')
        .select('id')
        .eq('watchlist_id', watchlistId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value)
        .maybeSingle();

    return response != null;
  }

  /// Move a watchlist item to a different watchlist.
  /// Preserves all watch progress (linked to item ID, not watchlist ID).
  /// Returns true if successful, false if item already exists in destination.
  static Future<bool> moveItemToWatchlist({
    required String itemId,
    required String toWatchlistId,
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    // Check if item already exists in destination watchlist
    final exists = await itemExistsInWatchlist(
      watchlistId: toWatchlistId,
      tmdbId: tmdbId,
      mediaType: mediaType,
    );

    if (exists) return false;

    // Move the item by updating its watchlist_id
    // All watch_progress entries are preserved (they reference watchlist_item_id)
    await _client
        .from('watchlist_items')
        .update({'watchlist_id': toWatchlistId})
        .eq('id', itemId);

    return true;
  }

  /// Get IDs of watchlists that contain a specific item.
  static Future<Set<String>> getWatchlistsContainingItem({
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Get all user's watchlists first
    final watchlists = await getWatchlists();
    final watchlistIds = watchlists.map((w) => w.id).toList();

    if (watchlistIds.isEmpty) return {};

    // Find which watchlists contain this item
    final response = await _client
        .from('watchlist_items')
        .select('watchlist_id')
        .inFilter('watchlist_id', watchlistIds)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value);

    return (response as List)
        .map((row) => row['watchlist_id'] as String)
        .toSet();
  }

  /// Get a watchlist item by TMDB ID and media type.
  /// Returns the first matching item across all user's watchlists.
  static Future<WatchlistItem?> getItemByTmdbId({
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    // Get all user's watchlists first
    final watchlists = await getWatchlists();
    final watchlistIds = watchlists.map((w) => w.id).toList();

    if (watchlistIds.isEmpty) return null;

    final response = await _client
        .from('watchlist_items')
        .select(_itemSelectWithContent)
        .inFilter('watchlist_id', watchlistIds)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final item = WatchlistItem.fromJson(response);
    final progress = await _getItemProgress(item.id);

    return item.copyWith(
      minutesRemaining: progress['minutes_remaining'] as int?,
      completionPercentage: progress['completion_percentage'] as double?,
      nextEpisodeRuntime: progress['next_episode_runtime'] as int?,
      lastActivityAt: progress['last_activity_at'] as DateTime?,
    );
  }

  /// Add an item to multiple watchlists at once.
  /// Content must already exist in content_cache (ensured by the caller).
  static Future<List<WatchlistItem>> addItemToMultipleWatchlists({
    required List<String> watchlistIds,
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    if (watchlistIds.isEmpty) return [];

    final insertData = watchlistIds
        .map(
          (watchlistId) => {
            'watchlist_id': watchlistId,
            'tmdb_id': tmdbId,
            'media_type': mediaType.value,
          },
        )
        .toList();

    final response = await _client
        .from('watchlist_items')
        .insert(insertData)
        .select(_itemSelectWithContent);

    return (response as List)
        .map((json) => WatchlistItem.fromJson(json))
        .toList();
  }

  /// Remove an item from a watchlist.
  static Future<void> removeItem(String itemId) async {
    await _client.from('watchlist_items').delete().eq('id', itemId);
  }

  // ============================================
  // SOCIAL OPERATIONS
  // ============================================

  /// Get friends who are also watching a specific content item.
  /// Respects friends' privacy settings server-side.
  static Future<List<FriendWatching>> getFriendsWatching({
    required int tmdbId,
    required MediaType mediaType,
    required List<String> friendIds,
  }) async {
    if (friendIds.isEmpty) return [];

    final response = await _client.rpc(
      'get_friends_watching_content',
      params: {
        'p_tmdb_id': tmdbId,
        'p_media_type': mediaType.value,
        'p_friend_ids': friendIds,
      },
    );

    if (response == null) return [];

    return (response as List)
        .map((json) => FriendWatching.fromJson(json))
        .toList();
  }

  // ============================================
  // PROGRESS OPERATIONS
  // ============================================

  /// Check if a watch_progress entry exists for a specific episode
  static Future<bool> watchProgressExistsForEpisode(
    String watchlistItemId,
    String episodeCacheId,
  ) async {
    final response = await _client
        .from('watch_progress')
        .select('id')
        .eq('watchlist_item_id', watchlistItemId)
        .eq('episode_cache_id', episodeCacheId)
        .maybeSingle();

    return response != null;
  }

  /// Create a watch progress entry for a movie or episode.
  /// For episodes: episodeCacheId links to content_cache_episodes (has runtime, season, episode)
  /// For movies: episodeCacheId is null, runtime comes from content_cache via join
  /// Set [isBackfill] to true when creating entries for multiple episodes at once
  /// (e.g. adding a whole show or syncing new season episodes).
  static Future<void> createWatchProgress({
    required String watchlistItemId,
    String? episodeCacheId, // FK to content_cache_episodes (null for movies)
    bool isBackfill = false,
  }) async {
    await _client.from('watch_progress').insert({
      'watchlist_item_id': watchlistItemId,
      'episode_cache_id': episodeCacheId,
      'watched': false,
      'is_backfill': isBackfill,
    });
  }

  /// Mark a watch progress entry as watched/unwatched.
  /// Updates watched_at on any progress change to support Recent Progress mode.
  /// Set [isBackfill] to true when updating multiple entries at once
  /// (e.g. mark season watched, mark all watched).
  static Future<void> updateWatchProgress({
    required String progressId,
    required bool watched,
    int? minutesWatched,
    bool isBackfill = false,
  }) async {
    final updates = <String, dynamic>{
      'watched': watched,
      'watched_at': DateTime.now().toIso8601String(),
      'is_backfill': isBackfill,
    };
    if (minutesWatched != null) {
      updates['minutes_watched'] = minutesWatched;
    }
    await _client.from('watch_progress').update(updates).eq('id', progressId);
  }

  /// Update partial progress for a movie (percentage-based).
  /// Updates watched_at on any progress change to support Recent Progress mode.
  static Future<void> updateMovieProgress({
    required String progressId,
    required int minutesWatched,
    required int totalMinutes,
  }) async {
    final watched = minutesWatched >= totalMinutes;
    await _client
        .from('watch_progress')
        .update({
          'minutes_watched': minutesWatched,
          'watched': watched,
          'watched_at': DateTime.now().toIso8601String(),
        })
        .eq('id', progressId);
  }

  /// Get all progress entries for a watchlist item.
  /// Joins with content_cache_episodes for episode data.
  static Future<List<Map<String, dynamic>>> getProgressEntries(
    String watchlistItemId,
  ) async {
    final response = await _client
        .from('watch_progress')
        .select('''
          id,
          watchlist_item_id,
          episode_cache_id,
          minutes_watched,
          watched,
          watched_at,
          content_cache_episodes (
            season_number,
            episode_number,
            episode_name,
            episode_overview,
            runtime_minutes,
            still_path,
            air_date
          )
        ''')
        .eq('watchlist_item_id', watchlistItemId);

    // Sort by season/episode from the joined data
    final entries = (response as List).cast<Map<String, dynamic>>();
    entries.sort((a, b) {
      final aEp = a['content_cache_episodes'] as Map<String, dynamic>?;
      final bEp = b['content_cache_episodes'] as Map<String, dynamic>?;

      // Movies (no episode cache) come first
      if (aEp == null && bEp == null) return 0;
      if (aEp == null) return -1;
      if (bEp == null) return 1;

      // Sort by season, then episode
      final seasonCompare = (aEp['season_number'] as int? ?? 0).compareTo(
        bEp['season_number'] as int? ?? 0,
      );
      if (seasonCompare != 0) return seasonCompare;

      return (aEp['episode_number'] as int? ?? 0).compareTo(
        bEp['episode_number'] as int? ?? 0,
      );
    });

    return entries;
  }

  /// Get movie runtime from content_cache for a watchlist item.
  static Future<int> getMovieRuntime(String watchlistItemId) async {
    // First get the tmdb_id and media_type from watchlist_items
    final itemResponse = await _client
        .from('watchlist_items')
        .select('tmdb_id, media_type')
        .eq('id', watchlistItemId)
        .single();

    final tmdbId = itemResponse['tmdb_id'] as int;
    final mediaType = itemResponse['media_type'] as String;

    // Then get runtime from content_cache
    final cacheResponse = await _client
        .from('content_cache')
        .select('total_runtime_minutes')
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType)
        .maybeSingle();

    return cacheResponse?['total_runtime_minutes'] as int? ?? 0;
  }

  /// Get progress stats for a watchlist item.
  static Future<Map<String, dynamic>> _getItemProgress(String itemId) async {
    // Get all progress entries with joined data for runtime
    final entries = await getProgressEntries(itemId);

    if (entries.isEmpty) {
      return {
        'minutes_remaining': null,
        'completion_percentage': null,
        'next_episode_runtime': null,
        'last_activity_at': null,
      };
    }

    // Check if this is a movie (no episode_cache_id) and fetch runtime
    int? movieRuntime;
    final firstEntry = entries.first;
    if (firstEntry['episode_cache_id'] == null) {
      movieRuntime = await getMovieRuntime(itemId);
    }

    int totalMinutes = 0;
    int watchedMinutes = 0;
    int? nextEpisodeRuntime;
    int? nextEpisodeRemaining;
    DateTime? lastActivityAt;

    for (final entry in entries) {
      // Get runtime from episode cache or movie runtime
      final episodeCache =
          entry['content_cache_episodes'] as Map<String, dynamic>?;

      int runtime = 0;
      if (episodeCache != null) {
        runtime = episodeCache['runtime_minutes'] as int? ?? 0;
      } else if (movieRuntime != null) {
        runtime = movieRuntime;
      }

      final watched = entry['watched'] as bool? ?? false;
      final partialMinutes = entry['minutes_watched'] as int? ?? 0;
      totalMinutes += runtime;

      // Track latest activity timestamp
      final watchedAtStr = entry['watched_at'] as String?;
      if (watchedAtStr != null) {
        final watchedAt = DateTime.tryParse(watchedAtStr);
        if (watchedAt != null &&
            (lastActivityAt == null || watchedAt.isAfter(lastActivityAt))) {
          lastActivityAt = watchedAt;
        }
      }

      if (watched) {
        // Fully watched - count full runtime
        watchedMinutes += runtime;
      } else {
        // Not fully watched
        if (partialMinutes > 0) {
          // Partially watched - count actual minutes watched
          watchedMinutes += partialMinutes;
        }
        // Track first unwatched episode's runtime and remaining time (for TV shows)
        if (nextEpisodeRuntime == null && episodeCache != null) {
          nextEpisodeRuntime = runtime;
          // Calculate remaining time for this episode (accounts for partial progress)
          nextEpisodeRemaining = runtime - partialMinutes;
        }
      }
    }

    return {
      'minutes_remaining': totalMinutes - watchedMinutes,
      // Calculate percentage based on minutes watched, not entry count
      // This correctly handles partial movie progress
      'completion_percentage': totalMinutes > 0
          ? (watchedMinutes / totalMinutes) * 100
          : 0.0,
      'next_episode_runtime': nextEpisodeRuntime,
      'next_episode_remaining': nextEpisodeRemaining,
      'last_activity_at': lastActivityAt,
    };
  }

  // ============================================
  // STATS
  // ============================================

  /// Get overall stats for a watchlist.
  static Future<Map<String, dynamic>> getWatchlistStats(
    String watchlistId,
  ) async {
    final items = await getWatchlistItems(watchlistId);

    int totalMinutesRemaining = 0;
    int almostDoneCount = 0;
    int completedCount = 0;

    for (final item in items) {
      final remaining = item.minutesRemaining ?? item.totalRuntimeMinutes;
      totalMinutesRemaining += remaining;

      if (item.isAlmostDone) almostDoneCount++;
      if (item.isCompleted) completedCount++;
    }

    final totalItems = items.length;
    final overallPercentage = totalItems > 0
        ? (completedCount / totalItems) * 100
        : 0.0;

    return {
      'total_items': totalItems,
      'completed_count': completedCount,
      'almost_done_count': almostDoneCount,
      'total_minutes_remaining': totalMinutesRemaining,
      'total_hours_remaining': (totalMinutesRemaining / 60).round(),
      'overall_percentage': overallPercentage,
    };
  }

  /// Get all dashboard data in a single RPC call.
  /// Returns items, stats, and queue health for the specified watchlist.
  /// Falls back to individual queries if RPC is not available.
  static Future<DashboardData?> getDashboardData(String watchlistId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    try {
      debugPrint('[Dashboard RPC] Calling get_dashboard_data...');
      final stopwatch = Stopwatch()..start();

      final response = await _client.rpc(
        'get_dashboard_data',
        params: {'p_user_id': userId, 'p_watchlist_id': watchlistId},
      );

      stopwatch.stop();
      debugPrint(
        '[Dashboard RPC] Completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (response != null && (response as List).isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        debugPrint(
          '[Dashboard RPC] Got data with ${(data['items'] as List?)?.length ?? 0} items',
        );
        return DashboardData.fromJson(data);
      }
      debugPrint('[Dashboard RPC] Empty response');
    } catch (e) {
      debugPrint('[Dashboard RPC] Failed: $e');
    }

    return null;
  }

  /// Get user's overall watching stats across all watchlists.
  /// Uses optimized RPC for performance (single query instead of N+1).
  static Future<Map<String, dynamic>> getUserStats() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Use optimized RPC (single query)
      final response = await _client.rpc(
        'get_user_stats',
        params: {'p_user_id': userId},
      );

      if (response != null && (response as List).isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return {
          'items_completed': (data['items_completed'] as num?)?.toInt() ?? 0,
          'minutes_watched': (data['minutes_watched'] as num?)?.toInt() ?? 0,
          'movies_completed': (data['movies_completed'] as num?)?.toInt() ?? 0,
          'shows_completed': (data['shows_completed'] as num?)?.toInt() ?? 0,
          'episodes_watched': (data['episodes_watched'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (e) {
      // RPC might not exist yet, fall back to local calculation
      debugPrint('get_user_stats RPC failed, using fallback: $e');
    }

    // Fallback: calculate locally (slower but works without RPC)
    return _calculateUserStatsLocally();
  }

  /// Fallback local calculation for user stats.
  /// Fixes the bug where runtime was read from wrong field.
  static Future<Map<String, dynamic>> _calculateUserStatsLocally() async {
    final watchlists = await getWatchlists();

    int totalItemsCompleted = 0;
    int totalMinutesWatched = 0;
    int moviesCompleted = 0;
    int showsCompleted = 0;
    int episodesWatched = 0;

    for (final watchlist in watchlists) {
      final items = await getWatchlistItems(watchlist.id);

      for (final item in items) {
        final progressEntries = await getProgressEntries(item.id);

        for (final entry in progressEntries) {
          if (entry['watched'] == true) {
            // Fix: Get runtime from nested content_cache_episodes
            final episodeData =
                entry['content_cache_episodes'] as Map<String, dynamic>?;
            final runtime = (episodeData?['runtime_minutes'] as int?) ?? 0;
            totalMinutesWatched += runtime;

            // Only count as episode if it has episode_cache_id
            if (entry['episode_cache_id'] != null) {
              episodesWatched++;
            }
          }
        }

        if (item.isCompleted) {
          totalItemsCompleted++;
          if (item.mediaType == MediaType.movie) {
            moviesCompleted++;
            // Add movie runtime (from content_cache, not episodes)
            totalMinutesWatched += item.totalRuntimeMinutes;
          } else {
            showsCompleted++;
          }
        }
      }
    }

    return {
      'items_completed': totalItemsCompleted,
      'minutes_watched': totalMinutesWatched,
      'movies_completed': moviesCompleted,
      'shows_completed': showsCompleted,
      'episodes_watched': episodesWatched,
    };
  }

  // ============================================
  // QUEUE EFFICIENCY
  // ============================================

  /// Get queue efficiency metrics for a specific watchlist or all watchlists.
  /// If [watchlistId] is provided, calculates for that watchlist only.
  /// Uses database function if available, falls back to local calculation.
  static Future<QueueEfficiency> getQueueEfficiency({
    String? watchlistId,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // If watchlistId is provided, use local calculation for that watchlist
    if (watchlistId != null) {
      return _calculateEfficiencyForWatchlist(watchlistId);
    }

    try {
      // Try to use the database function (for all watchlists)
      final response = await _client.rpc(
        'calculate_queue_efficiency',
        params: {'p_user_id': userId},
      );

      if (response != null && (response as List).isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return QueueEfficiency.fromJson(data);
      }
    } catch (e) {
      // Database function might not exist yet, fall back to local calculation
    }

    // Fallback: calculate locally for all watchlists
    return _calculateEfficiencyLocally();
  }

  /// Calculate efficiency for a specific watchlist.
  static Future<QueueEfficiency> _calculateEfficiencyForWatchlist(
    String watchlistId,
  ) async {
    final items = await getWatchlistItems(watchlistId);
    return _calculateEfficiencyFromItems(items);
  }

  /// Calculate efficiency locally from all watchlist items.
  static Future<QueueEfficiency> _calculateEfficiencyLocally() async {
    final watchlists = await getWatchlists();
    final allItems = <WatchlistItem>[];

    for (final watchlist in watchlists) {
      final items = await getWatchlistItems(watchlist.id);
      allItems.addAll(items);
    }

    return _calculateEfficiencyFromItems(allItems);
  }

  /// Returns true if an item is available to watch (not unreleased, has streaming).
  static bool _isItemAvailable(WatchlistItem item) {
    const unreleasedStatuses = {
      'In Production',
      'Planned',
      'Post Production',
      'Rumored',
    };

    // Unreleased by date
    if (item.releaseDate != null && item.releaseDate!.isAfter(DateTime.now())) {
      return false;
    }

    // Unreleased by status
    if (item.content?.status != null &&
        unreleasedStatuses.contains(item.content!.status)) {
      return false;
    }

    // No streaming providers
    if (item.streamingProviders.isEmpty) {
      return false;
    }

    return true;
  }

  /// Calculate efficiency from a list of items.
  static QueueEfficiency _calculateEfficiencyFromItems(
    List<WatchlistItem> items,
  ) {
    // Separate available vs excluded items
    final available = <WatchlistItem>[];
    int excluded = 0;
    for (final item in items) {
      if (_isItemAvailable(item)) {
        available.add(item);
      } else {
        excluded++;
      }
    }

    int total = available.length;
    int completed = 0;
    int active = 0;
    int idle = 0;
    int stale = 0;
    int recentCompletions = 0;

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (final item in available) {
      final status = item.calculatedStatus;

      switch (status) {
        case ItemStatus.completed:
          completed++;
          // Check if completed recently
          if (item.lastActivityAt != null &&
              item.lastActivityAt!.isAfter(sevenDaysAgo)) {
            recentCompletions++;
          }
          break;
        case ItemStatus.active:
          active++;
          break;
        case ItemStatus.idle:
          idle++;
          break;
        case ItemStatus.stale:
          stale++;
          break;
      }
    }

    return QueueEfficiency.calculate(
      total: total,
      completed: completed,
      active: active,
      idle: idle,
      stale: stale,
      recentCompletions: recentCompletions,
      excluded: excluded,
    );
  }

  /// Get items grouped by status.
  static Future<Map<ItemStatus, List<WatchlistItem>>> getItemsByStatus() async {
    final watchlists = await getWatchlists();
    final itemsByStatus = <ItemStatus, List<WatchlistItem>>{
      ItemStatus.active: [],
      ItemStatus.idle: [],
      ItemStatus.stale: [],
      ItemStatus.completed: [],
    };

    for (final watchlist in watchlists) {
      final items = await getWatchlistItems(watchlist.id);
      for (final item in items) {
        final status = item.calculatedStatus;
        itemsByStatus[status]!.add(item);
      }
    }

    return itemsByStatus;
  }

  /// Get stale items that need attention.
  /// If [watchlistId] is provided, only returns stale items from that watchlist.
  static Future<List<WatchlistItem>> getStaleItems({
    int limit = 10,
    String? watchlistId,
  }) async {
    List<WatchlistItem> staleItems = [];

    if (watchlistId != null) {
      // Get items from specific watchlist
      final items = await getWatchlistItems(watchlistId);
      staleItems = items
          .where((item) => item.calculatedStatus == ItemStatus.stale)
          .toList();
    } else {
      // Get from all watchlists
      final itemsByStatus = await getItemsByStatus();
      staleItems = itemsByStatus[ItemStatus.stale] ?? [];
    }

    // Sort by days since activity (most stale first)
    staleItems.sort(
      (a, b) => b.daysSinceActivity.compareTo(a.daysSinceActivity),
    );

    return staleItems.take(limit).toList();
  }

  // ============================================
  // STREAMING BREAKDOWN
  // ============================================

  /// Get streaming provider breakdown for all user's watchlist items.
  /// Uses server-side RPC for efficient aggregation.
  static Future<List<StreamingBreakdownItem>> getStreamingBreakdown() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    try {
      // Use server-side RPC for efficient aggregation
      final response = await _client.rpc(
        'get_streaming_breakdown',
        params: {'p_user_id': userId},
      );

      if (response == null) return [];

      return (response as List).map((row) {
        return StreamingBreakdownItem(
          providerId: row['provider_id'] as int,
          providerName: row['provider_name'] as String? ?? 'Unknown',
          logoPath: row['logo_path'] as String?,
          itemCount: row['item_count'] as int,
        );
      }).toList();
    } catch (e) {
      // Fallback to client-side if RPC not available
      return _getStreamingBreakdownFallback();
    }
  }

  // Allowed provider IDs (matches StreamingProviders.all)
  static const _allowedProviderIds = {8, 9, 15, 337, 350, 386, 531, 1899};

  /// Fallback client-side aggregation if RPC unavailable.
  static Future<List<StreamingBreakdownItem>>
  _getStreamingBreakdownFallback() async {
    try {
      final watchlists = await getWatchlists();
      final watchlistIds = watchlists.map((w) => w.id).toList();
      if (watchlistIds.isEmpty) return [];

      final response = await _client
          .from('watchlist_items')
          .select('content_cache(streaming_providers)')
          .inFilter('watchlist_id', watchlistIds);

      final providerCounts = <int, StreamingBreakdownItem>{};

      for (final row in response as List) {
        final contentCache = row['content_cache'] as Map<String, dynamic>?;
        if (contentCache == null) continue;

        final providers = contentCache['streaming_providers'] as List? ?? [];
        for (final provider in providers) {
          final id = provider['id'] as int;

          // Only include allowed providers
          if (!_allowedProviderIds.contains(id)) continue;

          final existing = providerCounts[id];
          providerCounts[id] = StreamingBreakdownItem(
            providerId: id,
            providerName: provider['name'] as String? ?? 'Unknown',
            logoPath: provider['logo_path'] as String?,
            itemCount: (existing?.itemCount ?? 0) + 1,
          );
        }
      }

      return providerCounts.values.toList()
        ..sort((a, b) => b.itemCount.compareTo(a.itemCount));
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // USER COUNT
  // ============================================

  /// Get count of users who have this content in their watchlist.
  static Future<int> getUserCount({
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final response = await _client.rpc(
        'get_user_count_for_content',
        params: {'p_tmdb_id': tmdbId, 'p_media_type': mediaType},
      );
      return response as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
