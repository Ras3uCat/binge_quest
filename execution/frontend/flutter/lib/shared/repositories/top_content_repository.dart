import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../models/top_content.dart';

class TopContentRepository {
  TopContentRepository._();

  static final _client = SupabaseService.client;

  /// Get top 10 by user count (most watched)
  static Future<List<TopContent>> getTop10ByUsers() async {
    try {
      final response = await _client.rpc('get_top_10_by_users');
      return (response as List)
          .map((json) => TopContent.fromUserCountJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting top 10 by users: $e');
      return [];
    }
  }

  /// Get top 10 by average rating (top rated)
  static Future<List<TopContent>> getTop10ByRating() async {
    try {
      final response = await _client.rpc('get_top_10_by_rating');
      return (response as List)
          .map((json) => TopContent.fromRatingJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting top 10 by rating: $e');
      return [];
    }
  }
}
