import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';
import '../models/review.dart';

class ReviewRepository {
  ReviewRepository._();

  static final _client = SupabaseService.client;

  /// Get all reviews for content (with display names).
  static Future<List<Review>> getReviews({
    required int tmdbId,
    required String mediaType,
  }) async {
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
  static Future<Review?> getUserReview({
    required int tmdbId,
    required String mediaType,
  }) async {
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
  static Future<void> deleteReview({
    required int tmdbId,
    required String mediaType,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    await _client
        .from('reviews')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }
}
