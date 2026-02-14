import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/tmdb_service.dart';
import '../models/tmdb_content.dart';
import 'content_cache_episodes_repository.dart';

/// Utility repository for backfilling episode metadata for existing watch_progress entries.
///
/// IMPORTANT: Run this BEFORE migration 014_cleanup_watch_progress.sql!
/// This backfill uses the season_number and episode_number columns to identify
/// which episodes need linking. After migration 014, those columns are dropped.
///
/// Usage:
/// 1. Run this backfill from Settings > Data > Sync Episode Metadata
/// 2. Then run migration 014_cleanup_watch_progress.sql in Supabase
class EpisodeBackfillRepository {
  EpisodeBackfillRepository._();

  static final _client = SupabaseService.client;

  /// Backfill all watch_progress entries that have season/episode but no episode_cache_id.
  /// Returns the number of entries updated.
  ///
  /// Must run BEFORE migration 014 drops the season_number/episode_number columns.
  static Future<int> backfillAll({
    Function(String)? onProgress,
  }) async {
    onProgress?.call('Checking migration status...');

    // Check if columns still exist (pre-migration 014)
    final columnsExist = await _checkColumnsExist();
    if (!columnsExist) {
      onProgress?.call('ERROR: season_number/episode_number columns not found.');
      onProgress?.call('Migration 014 may have already run.');
      onProgress?.call('Backfill must run BEFORE that migration.');
      return 0;
    }

    onProgress?.call('Finding entries to backfill...');

    // Get all watch_progress entries with season/episode but no episode_cache_id
    // Join with watchlist_items to get tmdb_id
    final response = await _client
        .from('watch_progress')
        .select('''
          id,
          watchlist_item_id,
          season_number,
          episode_number,
          watchlist_items!inner (
            tmdb_id,
            media_type
          )
        ''')
        .isFilter('episode_cache_id', null)
        .not('season_number', 'is', null)
        .not('episode_number', 'is', null);

    final entries = response as List;
    if (entries.isEmpty) {
      onProgress?.call('No entries need backfilling.');
      return 0;
    }

    onProgress?.call('Found ${entries.length} entries to backfill.');

    // Group by tmdb_id to minimize API calls
    final groupedByShow = <int, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final watchlistItem = entry['watchlist_items'] as Map<String, dynamic>;
      final tmdbId = watchlistItem['tmdb_id'] as int;
      final mediaType = watchlistItem['media_type'] as String;

      // Only process TV shows
      if (mediaType != 'tv') continue;

      groupedByShow.putIfAbsent(tmdbId, () => []);
      groupedByShow[tmdbId]!.add(entry);
    }

    onProgress?.call('Processing ${groupedByShow.length} TV shows...');

    int updatedCount = 0;
    int showIndex = 0;

    for (final entry in groupedByShow.entries) {
      final tmdbId = entry.key;
      final progressEntries = entry.value;
      showIndex++;

      onProgress?.call('Processing show $showIndex/${groupedByShow.length} (TMDB ID: $tmdbId)...');

      // Group entries by season
      final entriesBySeason = <int, List<Map<String, dynamic>>>{};
      for (final pe in progressEntries) {
        final season = pe['season_number'] as int;
        entriesBySeason.putIfAbsent(season, () => []);
        entriesBySeason[season]!.add(pe);
      }

      // Fetch and cache each season's episodes
      for (final seasonEntry in entriesBySeason.entries) {
        final seasonNumber = seasonEntry.key;
        final seasonProgressEntries = seasonEntry.value;

        try {
          // Fetch season details from TMDB
          final seasonData = await TmdbService.getSeasonDetails(tmdbId, seasonNumber);
          final episodes = (seasonData['episodes'] as List?) ?? [];

          // Build a map of episode_number -> TmdbEpisode
          final episodeMap = <int, TmdbEpisode>{};
          for (final epJson in episodes) {
            final ep = TmdbEpisode.fromJson(epJson);
            episodeMap[ep.episodeNumber] = ep;
          }

          // Cache and link each progress entry
          for (final pe in seasonProgressEntries) {
            final episodeNumber = pe['episode_number'] as int;
            final progressId = pe['id'] as String;

            final tmdbEpisode = episodeMap[episodeNumber];
            if (tmdbEpisode == null) {
              debugPrint('Episode S${seasonNumber}E$episodeNumber not found in TMDB data');
              continue;
            }

            // Cache the episode
            final cachedEpisode = await ContentCacheEpisodesRepository.ensureExists(
              ContentCacheEpisodesRepository.fromTmdbEpisode(tmdbId, tmdbEpisode),
            );

            // Update watch_progress with episode_cache_id
            await _client
                .from('watch_progress')
                .update({'episode_cache_id': cachedEpisode.id})
                .eq('id', progressId);

            updatedCount++;
          }

          onProgress?.call('  Season $seasonNumber: ${seasonProgressEntries.length} episodes linked');
        } catch (e) {
          debugPrint('Failed to fetch season $seasonNumber for show $tmdbId: $e');
          onProgress?.call('  Season $seasonNumber: FAILED - $e');
        }
      }

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 250));
    }

    onProgress?.call('Backfill complete! Updated $updatedCount entries.');
    onProgress?.call('');
    onProgress?.call('You can now run migration 014_cleanup_watch_progress.sql');
    return updatedCount;
  }

  /// Check if the old columns still exist (pre-migration 014).
  static Future<bool> _checkColumnsExist() async {
    try {
      // Try to select the old columns - will fail if they don't exist
      await _client
          .from('watch_progress')
          .select('season_number, episode_number')
          .limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check how many entries need backfilling.
  static Future<int> countEntriesNeedingBackfill() async {
    try {
      final response = await _client
          .from('watch_progress')
          .select('id')
          .isFilter('episode_cache_id', null)
          .not('season_number', 'is', null)
          .not('episode_number', 'is', null);

      return (response as List).length;
    } catch (e) {
      // Columns may not exist (post-migration)
      return 0;
    }
  }
}
