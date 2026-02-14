import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/watchlist_member.dart';

/// Repository for watchlist co-owner membership operations.
class WatchlistMemberRepository {
  final SupabaseClient _supabase;

  WatchlistMemberRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  /// Get all accepted members of a watchlist with profiles.
  Future<List<WatchlistMember>> getMembers(String watchlistId) async {
    final rows = await _supabase
        .from('watchlist_members')
        .select()
        .eq('watchlist_id', watchlistId)
        .eq('status', 'accepted')
        .order('created_at');

    return _attachProfiles(rows);
  }

  /// Get all members (including pending) for a watchlist.
  Future<List<WatchlistMember>> getAllMembers(String watchlistId) async {
    final rows = await _supabase
        .from('watchlist_members')
        .select()
        .eq('watchlist_id', watchlistId)
        .order('created_at');

    return _attachProfiles(rows);
  }

  /// Get pending co-owner invites received by the current user.
  Future<List<WatchlistMember>> getPendingInvites() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final rows = await _supabase
        .from('watchlist_members')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return _attachInviterProfiles(rows);
  }

  /// Check if a watchlist has any accepted co-owners.
  Future<bool> isSharedWatchlist(String watchlistId) async {
    final row = await _supabase
        .from('watchlist_members')
        .select('id')
        .eq('watchlist_id', watchlistId)
        .eq('status', 'accepted')
        .limit(1)
        .maybeSingle();
    return row != null;
  }

  /// Get the count of accepted co-owners for a watchlist.
  Future<int> getMemberCount(String watchlistId) async {
    final rows = await _supabase
        .from('watchlist_members')
        .select('id')
        .eq('watchlist_id', watchlistId)
        .eq('status', 'accepted');
    return (rows as List).length;
  }

  /// Get shared watchlist IDs for the current user (where they are a co-owner).
  Future<Set<String>> getSharedWatchlistIds() async {
    final userId = _currentUserId;
    if (userId == null) return {};

    final rows = await _supabase.rpc('get_user_shared_watchlist_ids');
    return (rows as List).map((id) => id as String).toSet();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Invite a friend as co-owner.
  Future<void> inviteFriend({
    required String watchlistId,
    required String friendId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase.from('watchlist_members').insert({
      'watchlist_id': watchlistId,
      'user_id': friendId,
      'role': 'co_owner',
      'invited_by': userId,
    });
  }

  /// Accept a co-owner invite.
  Future<void> acceptInvite(String memberId) async {
    await _supabase
        .from('watchlist_members')
        .update({
          'status': 'accepted',
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', memberId);
  }

  /// Decline a co-owner invite.
  Future<void> declineInvite(String memberId) async {
    await _supabase
        .from('watchlist_members')
        .update({'status': 'declined'})
        .eq('id', memberId);
  }

  /// Remove a co-owner (owner action) or leave a watchlist (co-owner action).
  Future<void> removeMember(String memberId) async {
    await _supabase.from('watchlist_members').delete().eq('id', memberId);
  }

  /// Notify the invitee of a co-owner invite via in-app notification.
  Future<void> notifyCoOwnerInvite({
    required String inviteeId,
    required String inviterName,
    required String watchlistName,
    required String watchlistId,
  }) async {
    await _supabase.rpc(
      'notify_co_owner_invite',
      params: {
        'invitee_id': inviteeId,
        'inviter_name': inviterName,
        'watchlist_name': watchlistName,
        'p_watchlist_id': watchlistId,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Attach user profiles to member rows.
  Future<List<WatchlistMember>> _attachProfiles(List<dynamic> rows) async {
    if (rows.isEmpty) return [];

    final userIds = rows.map((r) => r['user_id'] as String).toSet();
    final profiles = await _supabase
        .from('users')
        .select()
        .inFilter('id', userIds.toList());

    final profileMap = <String, UserProfile>{};
    for (final p in profiles) {
      final profile = UserProfile.fromJson(p);
      profileMap[profile.id] = profile;
    }

    return rows
        .map(
          (row) => WatchlistMember.fromJson(
            row,
            user: profileMap[row['user_id'] as String],
          ),
        )
        .toList();
  }

  /// Attach inviter profiles (for pending invites view).
  Future<List<WatchlistMember>> _attachInviterProfiles(
    List<dynamic> rows,
  ) async {
    if (rows.isEmpty) return [];

    final inviterIds = rows.map((r) => r['invited_by'] as String).toSet();
    final profiles = await _supabase
        .from('users')
        .select()
        .inFilter('id', inviterIds.toList());

    final profileMap = <String, UserProfile>{};
    for (final p in profiles) {
      final profile = UserProfile.fromJson(p);
      profileMap[profile.id] = profile;
    }

    // Use inviter profile as the "user" for display purposes
    return rows
        .map(
          (row) => WatchlistMember.fromJson(
            row,
            user: profileMap[row['invited_by'] as String],
          ),
        )
        .toList();
  }
}
