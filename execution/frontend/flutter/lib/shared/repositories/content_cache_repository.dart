import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../models/content_cache.dart';
import '../models/watchlist_item.dart';

/// Repository for content cache operations.
/// Manages shared TMDB content metadata across all users.
class ContentCacheRepository {
  ContentCacheRepository._();

  static final _client = SupabaseService.client;

  /// Get cached content by TMDB ID and media type.
  static Future<ContentCache?> get(int tmdbId, MediaType mediaType) async {
    final response = await _client
        .from('content_cache')
        .select()
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value)
        .maybeSingle();

    if (response == null) return null;
    return ContentCache.fromJson(response);
  }

  /// Check if content exists in cache.
  static Future<bool> exists(int tmdbId, MediaType mediaType) async {
    final response = await _client
        .from('content_cache')
        .select('tmdb_id')
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value)
        .maybeSingle();

    return response != null;
  }

  /// Insert or update content in cache.
  static Future<ContentCache> upsert(ContentCache content) async {
    final response = await _client
        .from('content_cache')
        .upsert(content.toJson())
        .select()
        .single();

    return ContentCache.fromJson(response);
  }

  /// Insert content only if it doesn't exist.
  /// Returns existing content if already cached, otherwise inserts and returns new.
  static Future<ContentCache> ensureExists(ContentCache content) async {
    final existing = await get(content.tmdbId, content.mediaType);
    if (existing != null) return existing;

    return upsert(content);
  }

  /// Update streaming providers for content.
  static Future<void> updateStreamingProviders(
    int tmdbId,
    MediaType mediaType,
    List<StreamingProviderInfo> providers,
  ) async {
    await _client
        .from('content_cache')
        .update({
          'streaming_providers': providers.map((p) => p.toJson()).toList(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value);
  }

  /// Update popularity score for content.
  static Future<void> updatePopularity(
    int tmdbId,
    MediaType mediaType,
    double popularityScore,
  ) async {
    await _client
        .from('content_cache')
        .update({
          'popularity_score': popularityScore,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType.value);
  }

  /// Get stale content entries that need refresh.
  static Future<List<ContentCache>> getStaleEntries({
    int staleDays = 30,
    int limit = 50,
  }) async {
    final staleDate = DateTime.now().subtract(Duration(days: staleDays));

    final response = await _client
        .from('content_cache')
        .select()
        .lt('updated_at', staleDate.toIso8601String())
        .order('updated_at', ascending: true)
        .limit(limit);

    return (response as List)
        .map((json) => ContentCache.fromJson(json))
        .toList();
  }

  /// Batch insert multiple content entries.
  /// Skips entries that already exist.
  static Future<void> batchInsert(List<ContentCache> contents) async {
    if (contents.isEmpty) return;

    try {
      await _client
          .from('content_cache')
          .upsert(
            contents.map((c) => c.toJson()).toList(),
            onConflict: 'tmdb_id,media_type',
            ignoreDuplicates: true,
          );
    } catch (e) {
      debugPrint('Batch insert error: $e');
      rethrow;
    }
  }

  /// Create ContentCache from TMDB movie data.
  static ContentCache fromTmdbMovie({
    required int tmdbId,
    required String title,
    String? tagline,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? voteAverage,
    int? voteCount,
    double? popularity,
    List<int>? genreIds,
    String? status,
    DateTime? releaseDate,
    int? runtime,
    List<CastMemberInfo>? cast,
    List<StreamingProviderInfo>? streamingProviders,
  }) {
    return ContentCache(
      tmdbId: tmdbId,
      mediaType: MediaType.movie,
      title: title,
      tagline: tagline,
      posterPath: posterPath,
      backdropPath: backdropPath,
      overview: overview,
      voteAverage: voteAverage,
      voteCount: voteCount,
      popularityScore: popularity,
      genreIds: genreIds ?? const [],
      status: status,
      releaseDate: releaseDate,
      totalRuntimeMinutes: runtime ?? 0,
      castMembers: cast ?? const [],
      streamingProviders: streamingProviders ?? const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Batch fetch streaming providers for multiple TMDB IDs.
  /// Returns map of tmdbId -> providers (only for cached content).
  static Future<Map<int, List<StreamingProviderInfo>>> getStreamingProvidersForIds(
    List<int> tmdbIds,
  ) async {
    if (tmdbIds.isEmpty) return {};

    try {
      final response = await _client
          .from('content_cache')
          .select('tmdb_id, streaming_providers')
          .inFilter('tmdb_id', tmdbIds);

      final Map<int, List<StreamingProviderInfo>> result = {};

      for (final row in response as List) {
        final tmdbId = row['tmdb_id'] as int;
        final providersJson = row['streaming_providers'] as List<dynamic>?;

        if (providersJson != null && providersJson.isNotEmpty) {
          result[tmdbId] = providersJson
              .map((p) => StreamingProviderInfo.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error batch fetching streaming providers: $e');
      return {};
    }
  }

  /// Update last_accessed_at timestamp for cache management.
  static Future<void> updateLastAccessed(int tmdbId, MediaType mediaType) async {
    try {
      await _client.rpc('update_content_last_accessed', params: {
        'p_tmdb_id': tmdbId,
        'p_media_type': mediaType.value,
      });
    } catch (e) {
      // Non-critical, log and continue
      debugPrint('Error updating last_accessed_at: $e');
    }
  }

  /// Create ContentCache from TMDB TV show data.
  static ContentCache fromTmdbTvShow({
    required int tmdbId,
    required String title,
    String? tagline,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? voteAverage,
    int? voteCount,
    double? popularity,
    List<int>? genreIds,
    String? status,
    DateTime? firstAirDate,
    DateTime? lastAirDate,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    int? episodeRuntime,
    int? estimatedTotalRuntime,
    List<CastMemberInfo>? cast,
    List<StreamingProviderInfo>? streamingProviders,
  }) {
    return ContentCache(
      tmdbId: tmdbId,
      mediaType: MediaType.tv,
      title: title,
      tagline: tagline,
      posterPath: posterPath,
      backdropPath: backdropPath,
      overview: overview,
      voteAverage: voteAverage,
      voteCount: voteCount,
      popularityScore: popularity,
      genreIds: genreIds ?? const [],
      status: status,
      releaseDate: firstAirDate,
      lastAirDate: lastAirDate,
      totalRuntimeMinutes: estimatedTotalRuntime ?? 0,
      episodeRuntime: episodeRuntime,
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      castMembers: cast ?? const [],
      streamingProviders: streamingProviders ?? const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
