import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/followed_talent.dart';
import '../models/talent_content_event.dart';

/// Repository for followed talent database operations.
class FollowedTalentRepository {
  final SupabaseClient _supabase;

  FollowedTalentRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get all talent followed by a user, ordered by most recent.
  Future<List<FollowedTalent>> getFollowedTalent(String userId) async {
    final response = await _supabase
        .from('followed_talent')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => FollowedTalent.fromJson(e))
        .toList();
  }

  /// Follow a talent person. Uses upsert to handle duplicates.
  Future<void> followTalent({
    required String userId,
    required int tmdbPersonId,
    required String personName,
    required String personType,
    String? profilePath,
  }) async {
    await _supabase.from('followed_talent').upsert(
      {
        'user_id': userId,
        'tmdb_person_id': tmdbPersonId,
        'person_name': personName,
        'person_type': personType,
        'profile_path': profilePath,
      },
      onConflict: 'user_id, tmdb_person_id',
    );
  }

  /// Unfollow a talent person.
  Future<void> unfollowTalent({
    required String userId,
    required int tmdbPersonId,
  }) async {
    await _supabase
        .from('followed_talent')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_person_id', tmdbPersonId);
  }

  /// Check if a user is following a specific person.
  Future<bool> isFollowing({
    required String userId,
    required int tmdbPersonId,
  }) async {
    final response = await _supabase
        .from('followed_talent')
        .select('id')
        .eq('user_id', userId)
        .eq('tmdb_person_id', tmdbPersonId)
        .maybeSingle();

    return response != null;
  }

  /// Get content events for a specific person.
  Future<List<TalentContentEvent>> getContentEventsForPerson(
    int tmdbPersonId,
  ) async {
    final response = await _supabase
        .from('talent_content_events')
        .select()
        .eq('tmdb_person_id', tmdbPersonId)
        .order('detected_at', ascending: false);

    return (response as List)
        .map((e) => TalentContentEvent.fromJson(e))
        .toList();
  }
}
