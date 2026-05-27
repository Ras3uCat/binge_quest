import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';
import '../models/review.dart';

enum ReviewSort { dateDesc, dateAsc, ratingDesc, ratingAsc }

class ReviewRepository {
  ReviewRepository._();

  static final _client = SupabaseService.client;

  /// Get all reviews for content (with display names).
  static Future<List<Review>> getReviews({required int tmdbId, required String mediaType}) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, users(display_name, username)')
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting reviews: $e');
      // Fallback without join if FK not set up
      try {
        final response = await _client
            .from('reviews')
            .select('*')
            .eq('tmdb_id', tmdbId)
            .eq('media_type', mediaType)
            .order('created_at', ascending: false);
        return (response as List).map((json) => Review.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('Fallback error: $e2');
        return [];
      }
    }
  }

  /// Get current user's review for content (if exists).
  static Future<Review?> getUserReview({required int tmdbId, required String mediaType}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return Review.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user review: $e');
      return null;
    }
  }

  /// Get average rating and review count.
  static Future<({double? average, int count})> getAverageRating({
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final response = await _client.rpc(
        'get_average_rating',
        params: {'p_tmdb_id': tmdbId, 'p_media_type': mediaType},
      );

      if (response != null && (response as List).isNotEmpty) {
        final data = response[0];
        return (
          average: data['average_rating'] != null
              ? double.parse(data['average_rating'].toString())
              : null,
          count: data['review_count'] as int? ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error getting average rating: $e');
    }
    return (average: null, count: 0);
  }

  /// Create or update a review.
  static Future<Review?> upsertReview({
    required int tmdbId,
    required String mediaType,
    required int rating,
    String? reviewText,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('reviews')
        .upsert({
          'user_id': userId,
          'tmdb_id': tmdbId,
          'media_type': mediaType,
          'rating': rating,
          'review_text': reviewText,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,tmdb_id,media_type')
        .select()
        .single();

    return Review.fromJson(response);
  }

  /// Delete user's review.
  static Future<void> deleteReview({required int tmdbId, required String mediaType}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    await _client
        .from('reviews')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }

  /// Get all reviews by a user, merged with content_cache for title/poster.
  /// Uses a two-step fetch: reviews first, then batch content_cache by media_type.
  /// Sorting is intentionally omitted — callers sort the returned list client-side.
  static Future<List<Review>> getReviewsByUser(String userId) async {
    try {
      final reviewsData = await _client
          .from('reviews')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if ((reviewsData as List).isEmpty) return [];

      final reviews = reviewsData.map((j) => Review.fromJson(j)).toList();

      final movieIds = reviews
          .where((r) => r.mediaType == 'movie')
          .map((r) => r.tmdbId)
          .toSet()
          .toList();
      final tvIds = reviews.where((r) => r.mediaType == 'tv').map((r) => r.tmdbId).toSet().toList();

      final cacheMap = <String, Map<String, dynamic>>{};

      if (movieIds.isNotEmpty) {
        final res = await _client
            .from('content_cache')
            .select('tmdb_id, media_type, title, poster_path')
            .eq('media_type', 'movie')
            .inFilter('tmdb_id', movieIds);
        for (final row in (res as List)) {
          final r = row as Map<String, dynamic>;
          cacheMap['${r['tmdb_id']}_movie'] = r;
        }
      }

      if (tvIds.isNotEmpty) {
        final res = await _client
            .from('content_cache')
            .select('tmdb_id, media_type, title, poster_path')
            .eq('media_type', 'tv')
            .inFilter('tmdb_id', tvIds);
        for (final row in (res as List)) {
          final r = row as Map<String, dynamic>;
          cacheMap['${r['tmdb_id']}_tv'] = r;
        }
      }

      return reviews.map((review) {
        final cache = cacheMap['${review.tmdbId}_${review.mediaType}'];
        if (cache == null) return review;
        return review.copyWith(
          title: cache['title'] as String?,
          posterPath: cache['poster_path'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user reviews: $e');
      return [];
    }
  }
}
