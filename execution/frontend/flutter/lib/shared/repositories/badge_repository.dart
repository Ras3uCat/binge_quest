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
    final response = await _client
        .from('badges')
        .select()
        .eq('id', id)
        .maybeSingle();

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
        .insert({
          'user_id': userId,
          'badge_id': badgeId,
        })
        .select('*, badges(*)')
        .single();

    return UserBadge.fromJson(response);
  }

  /// Check and award all eligible badges based on user stats.
  /// Returns list of newly awarded badges.
  static Future<List<Badge>> checkAndAwardBadges(
    Map<String, dynamic> stats,
  ) async {
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
