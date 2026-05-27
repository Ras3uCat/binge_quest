import '../../core/services/supabase_service.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';

/// Repository for badge-related database operations.
class BadgeRepository {
  BadgeRepository._();

  static final _client = SupabaseService.client;

  // ============================================
  // BADGE OPERATIONS
  // ============================================

  /// Get all available badges.
  static Future<List<Badge>> getAllBadges() async {
    final response = await _client
        .from('badges')
        .select()
        .order('category', ascending: true)
        .order('name', ascending: true);

    return (response as List).map((json) => Badge.fromJson(json)).toList();
  }

  /// Get a single badge by ID.
  static Future<Badge?> getBadge(String id) async {
    final response = await _client.from('badges').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return Badge.fromJson(response);
  }

  // ============================================
  // USER BADGE OPERATIONS
  // ============================================

  /// Get all badges earned by the current user.
  static Future<List<UserBadge>> getUserBadges() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_badges')
        .select('*, badges(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);

    return (response as List).map((json) => UserBadge.fromJson(json)).toList();
  }

  /// Check if user has earned a specific badge.
  static Future<bool> hasBadge(String badgeId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_badges')
        .select('id')
        .eq('user_id', userId)
        .eq('badge_id', badgeId)
        .maybeSingle();

    return response != null;
  }

  /// Award a badge to the current user.
  static Future<UserBadge> awardBadge(String badgeId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_badges')
        .insert({'user_id': userId, 'badge_id': badgeId})
        .select('*, badges(*)')
        .single();

    return UserBadge.fromJson(response);
  }

  /// Check and award all eligible badges based on user stats.
  /// Returns list of newly awarded badges.
  static Future<List<Badge>> checkAndAwardBadges(Map<String, dynamic> stats) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Get all badges and user's existing badges
    final allBadges = await getAllBadges();
    final userBadges = await getUserBadges();
    final earnedBadgeIds = userBadges.map((ub) => ub.badgeId).toSet();

    final newlyAwarded = <Badge>[];

    for (final badge in allBadges) {
      // Skip if already earned
      if (earnedBadgeIds.contains(badge.id)) continue;

      // Check if badge criteria is met
      if (badge.isEarned(stats)) {
        try {
          await awardBadge(badge.id);
          newlyAwarded.add(badge);
        } catch (e) {
          // Ignore duplicate key errors (race condition protection)
          if (!e.toString().contains('duplicate')) rethrow;
        }
      }
    }

    return newlyAwarded;
  }

  /// Get badges grouped by category.
  static Future<Map<BadgeCategory, List<Badge>>> getBadgesByCategory() async {
    final badges = await getAllBadges();
    final grouped = <BadgeCategory, List<Badge>>{};

    for (final badge in badges) {
      grouped.putIfAbsent(badge.category, () => []).add(badge);
    }

    return grouped;
  }

  /// Get count of earned badges for current user.
  static Future<int> getEarnedBadgeCount() async {
    final userBadges = await getUserBadges();
    return userBadges.length;
  }

  /// Get social engagement stats for badge checking.
  static Future<Map<String, dynamic>> getSocialStats() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    try {
      final results = await Future.wait([
        _client.from('reviews').select('id').eq('user_id', userId),
        _client.from('playlists').select('id').eq('user_id', userId),
        _client
            .from('watchlist_members')
            .select('user_id')
            .eq('invited_by', userId)
            .eq('status', 'accepted')
            .neq('user_id', userId),
        _client
            .from('friendships')
            .select('id')
            .or('requester_id.eq.$userId,addressee_id.eq.$userId')
            .eq('status', 'accepted'),
        _client.from('watch_parties').select('id').eq('created_by', userId),
        _client
            .from('watch_party_members')
            .select('party_id')
            .eq('user_id', userId)
            .eq('status', 'active'),
      ]);

      final reviewRows = results[0] as List;
      final playlistRows = results[1] as List;
      final cocuratorRows = results[2] as List;
      final friendRows = results[3] as List;
      final hostedRows = results[4] as List;
      final memberRows = results[5] as List;

      final hostedIds = hostedRows.map((r) => r['id'] as String).toSet();
      final joinedCount = memberRows
          .where((r) => !hostedIds.contains(r['party_id'] as String))
          .length;

      return {
        'reviews_left': reviewRows.length,
        'playlists_created': playlistRows.length,
        'cocurators_added': cocuratorRows.length,
        'friends_added': friendRows.length,
        'watch_parties_hosted': hostedRows.length,
        'watch_parties_joined': joinedCount,
      };
    } catch (_) {
      return {};
    }
  }

  /// Get recently earned badges (last 3).
  static Future<List<UserBadge>> getRecentBadges({int limit = 3}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_badges')
        .select('*, badges(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => UserBadge.fromJson(json)).toList();
  }
}
