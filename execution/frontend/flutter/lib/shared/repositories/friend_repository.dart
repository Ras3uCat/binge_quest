import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship.dart';
import '../models/user_block.dart';
import '../models/user_profile.dart';

/// Repository for friendships, blocks, and user profile lookups.
class FriendRepository {
  final SupabaseClient _supabase;

  FriendRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Username
  // ---------------------------------------------------------------------------

  /// Get the current user's username from public.users.
  Future<String?> getUsername() async {
    final userId = _currentUserId;
    if (userId == null) return null;
    final row = await _supabase
        .from('users')
        .select('username')
        .eq('id', userId)
        .maybeSingle();
    return row?['username'] as String?;
  }

  /// Set or update the current user's username.
  Future<void> setUsername(String username) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase
        .from('users')
        .update({'username': username})
        .eq('id', userId);
  }

  /// Check if a username is available.
  Future<bool> isUsernameAvailable(String username) async {
    final row = await _supabase
        .from('users')
        .select('id')
        .eq('username', username.toLowerCase())
        .maybeSingle();
    return row == null;
  }

  // ---------------------------------------------------------------------------
  // Privacy
  // ---------------------------------------------------------------------------

  /// Get the current user's privacy setting for sharing watching activity.
  Future<bool> getShareWatchingActivity() async {
    final userId = _currentUserId;
    if (userId == null) return true; // Default to true if not logged in

    final row = await _supabase
        .from('users')
        .select('share_watching_activity')
        .eq('id', userId)
        .maybeSingle();

    return row?['share_watching_activity'] as bool? ?? true;
  }

  /// Update the current user's privacy setting for sharing watching activity.
  Future<void> setShareWatchingActivity(bool share) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _supabase
        .from('users')
        .update({'share_watching_activity': share})
        .eq('id', userId);
  }

  // ---------------------------------------------------------------------------
  // User Search
  // ---------------------------------------------------------------------------

  /// Search users by email (exact match) or name/username (prefix match).
  /// Excludes current user and blocked users.
  Future<List<UserProfile>> searchUsers(String query) async {
    final userId = _currentUserId;
    if (userId == null || query.trim().isEmpty) return [];

    final cleanQuery = query.toLowerCase().trim();

    // Get blocked user IDs to exclude
    final blockedRows = await _supabase
        .from('user_blocks')
        .select('blocked_id, blocker_id')
        .or('blocker_id.eq.$userId,blocked_id.eq.$userId');

    final excludeIds = <String>{userId};
    for (final row in blockedRows) {
      excludeIds.add(row['blocked_id'] as String);
      excludeIds.add(row['blocker_id'] as String);
    }

    final isEmail = cleanQuery.contains('@');
    List<dynamic> response;

    if (isEmail) {
      // Exact email match
      response = await _supabase
          .from('users')
          .select()
          .eq('email', cleanQuery)
          .not('id', 'in', '(${excludeIds.join(",")})')
          .limit(5);
    } else {
      // Search by username prefix or display name
      response = await _supabase
          .from('users')
          .select()
          .or('username.ilike.$cleanQuery%,display_name.ilike.%$cleanQuery%')
          .not('id', 'in', '(${excludeIds.join(",")})')
          .limit(20);
    }

    return (response).map((e) => UserProfile.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Friendships
  // ---------------------------------------------------------------------------

  /// Get all accepted friends with profiles.
  Future<List<Friendship>> getFriends() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final rows = await _supabase
        .from('friendships')
        .select()
        .eq('status', 'accepted')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .order('updated_at', ascending: false);

    return _attachProfiles(rows, userId);
  }

  /// Get pending requests received by the current user.
  Future<List<Friendship>> getPendingReceived() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final rows = await _supabase
        .from('friendships')
        .select()
        .eq('status', 'pending')
        .eq('addressee_id', userId)
        .order('created_at', ascending: false);

    return _attachProfiles(rows, userId);
  }

  /// Get pending requests sent by the current user.
  Future<List<Friendship>> getPendingSent() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final rows = await _supabase
        .from('friendships')
        .select()
        .eq('status', 'pending')
        .eq('requester_id', userId)
        .order('created_at', ascending: false);

    return _attachProfiles(rows, userId);
  }

  /// Send a friend request.
  Future<void> sendFriendRequest(String addresseeId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase.from('friendships').insert({
      'requester_id': userId,
      'addressee_id': addresseeId,
    });
  }

  /// Send in-app + push notification for a friend request via edge function.
  Future<void> sendFriendRequestNotification({
    required String addresseeId,
    required String requesterName,
  }) async {
    await _supabase.functions.invoke(
      'send-notification',
      body: {
        'user_id': addresseeId,
        'category': 'social',
        'title': 'Friend Request',
        'body': '$requesterName sent you a friend request',
        'data': {'type': 'friend_request'},
      },
    );
  }

  /// Accept a friend request (only the addressee can do this).
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _supabase
        .from('friendships')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId);
  }

  /// Decline or cancel a friend request (deletes the row).
  Future<void> deleteFriendship(String friendshipId) async {
    await _supabase.from('friendships').delete().eq('id', friendshipId);
  }

  /// Check friendship status between current user and another user.
  /// Returns null if no relationship, or the Friendship object.
  Future<Friendship?> getFriendshipWith(String otherUserId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final row = await _supabase
        .from('friendships')
        .select()
        .or(
          'and(requester_id.eq.$userId,addressee_id.eq.$otherUserId),'
          'and(requester_id.eq.$otherUserId,addressee_id.eq.$userId)',
        )
        .maybeSingle();

    if (row == null) return null;
    return Friendship.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  /// Block a user.
  Future<void> blockUser(String blockedId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase.from('user_blocks').insert({
      'blocker_id': userId,
      'blocked_id': blockedId,
    });
  }

  /// Unblock a user.
  Future<void> unblockUser(String blockedId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase
        .from('user_blocks')
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', blockedId);
  }

  /// Get all blocked users with profiles.
  Future<List<UserBlock>> getBlockedUsers() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final rows = await _supabase
        .from('user_blocks')
        .select()
        .eq('blocker_id', userId)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final blockedIds = rows.map((r) => r['blocked_id'] as String).toList();

    final profiles = await _supabase
        .from('users')
        .select()
        .inFilter('id', blockedIds);

    final profileMap = <String, UserProfile>{};
    for (final p in profiles) {
      final profile = UserProfile.fromJson(p);
      profileMap[profile.id] = profile;
    }

    return rows
        .map(
          (row) => UserBlock.fromJson(
            row,
            blockedUser: profileMap[row['blocked_id'] as String],
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Attach user profiles to friendship rows via batch lookup.
  Future<List<Friendship>> _attachProfiles(
    List<dynamic> rows,
    String currentUserId,
  ) async {
    if (rows.isEmpty) return [];

    final friendIds = <String>{};
    for (final row in rows) {
      final rId = row['requester_id'] as String;
      final aId = row['addressee_id'] as String;
      friendIds.add(rId == currentUserId ? aId : rId);
    }

    final profiles = await _supabase
        .from('users')
        .select()
        .inFilter('id', friendIds.toList());

    final profileMap = <String, UserProfile>{};
    for (final p in profiles) {
      final profile = UserProfile.fromJson(p);
      profileMap[profile.id] = profile;
    }

    return rows.map((row) {
      final rId = row['requester_id'] as String;
      final aId = row['addressee_id'] as String;
      final friendId = rId == currentUserId ? aId : rId;
      return Friendship.fromJson(row, friend: profileMap[friendId]);
    }).toList();
  }
}
