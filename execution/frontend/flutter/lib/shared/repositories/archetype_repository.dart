import '../../core/services/supabase_service.dart';
import '../models/archetype.dart';

/// Repository for archetype reference data and per-user computed scores.
class ArchetypeRepository {
  ArchetypeRepository._();

  static final _client = SupabaseService.client;

  // ── Reference data ──────────────────────────────────────────────────────

  /// All 12 archetypes sorted by display order.
  static Future<List<Archetype>> fetchAllArchetypes() async {
    final response = await _client.from('archetypes').select().order('sort_order');

    return (response as List).map((json) => Archetype.fromJson(json)).toList();
  }

  // ── Per-user scores ──────────────────────────────────────────────────────

  /// All 12 scores from the user's most recent compute run, sorted by rank.
  /// Returns an empty list if the user has no archetype data yet.
  static Future<List<UserArchetype>> fetchUserCurrentScores(String userId) async {
    // Step 1: find the latest computed_at timestamp for this user.
    final latest = await _client
        .from('user_archetypes')
        .select('computed_at')
        .eq('user_id', userId)
        .order('computed_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latest == null) return [];

    final computedAt = latest['computed_at'] as String;

    // Step 2: fetch all 12 rows for that timestamp with joined archetype data.
    final response = await _client
        .from('user_archetypes')
        .select('*, archetypes(*)')
        .eq('user_id', userId)
        .eq('computed_at', computedAt)
        .order('rank');

    return (response as List).map((json) => UserArchetype.fromJson(json)).toList();
  }

  /// Triggers archetype computation for [userId] (own profile only).
  /// The SQL function enforces a 7-day cooldown and skips if already up-to-date.
  static Future<void> requestCompute(String userId) async {
    await _client.rpc('compute_user_archetype', params: {'p_user_id': userId});
  }

  /// Rank-1 archetype row per past compute run — powers the history timeline.
  /// Capped at the 20 most recent runs.
  static Future<List<UserArchetype>> fetchArchetypeHistory(String userId) async {
    final response = await _client
        .from('user_archetypes')
        .select('*, archetypes(*)')
        .eq('user_id', userId)
        .eq('rank', 1)
        .order('computed_at', ascending: false)
        .limit(20);

    return (response as List).map((json) => UserArchetype.fromJson(json)).toList();
  }
}
