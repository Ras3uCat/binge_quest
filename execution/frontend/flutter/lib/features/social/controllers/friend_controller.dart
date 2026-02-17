import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/models/friendship.dart';
import '../../../shared/models/user_block.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/repositories/friend_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Controller for friend system state and actions.
class FriendController extends GetxController {
  static FriendController get to => Get.find();

  final FriendRepository _repository = FriendRepository();

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------
  final friends = <Friendship>[].obs;
  final pendingReceived = <Friendship>[].obs;
  final pendingSent = <Friendship>[].obs;
  final blockedUsers = <UserBlock>[].obs;
  final searchResults = <UserProfile>[].obs;

  final username = Rxn<String>();
  final isLoading = false.obs;
  final isSearching = false.obs;
  final shareWatchingActivity = true.obs;

  /// True if the current user has not set a username yet.
  bool get needsUsername => username.value == null;

  int get friendCount => friends.length;
  int get pendingCount => pendingReceived.length;

  String? get _userId => AuthController.to.user?.id;

  /// Set of friend user IDs for quick lookups.
  Set<String> get friendIds =>
      friends.map((f) => f.friendId(_userId ?? '')).toSet();

  RealtimeChannel? _friendshipsChannel;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _setupRealtime();
  }

  @override
  void onClose() {
    _friendshipsChannel?.unsubscribe();
    super.onClose();
  }

  Future<void> _loadInitialData() async {
    if (_userId == null) return;
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _repository.getUsername(),
        _repository.getFriends(),
        _repository.getPendingReceived(),
        _repository.getPendingSent(),
        _repository.getShareWatchingActivity(),
      ]);
      username.value = results[0] as String?;
      friends.assignAll(results[1] as List<Friendship>);
      pendingReceived.assignAll(results[2] as List<Friendship>);
      pendingSent.assignAll(results[3] as List<Friendship>);
      shareWatchingActivity.value = results[4] as bool;
    } catch (e) {
      debugPrint('Error loading friend data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reload all friend data.
  @override
  Future<void> refresh() => _loadInitialData();

  // ---------------------------------------------------------------------------
  // Realtime
  // ---------------------------------------------------------------------------

  void _setupRealtime() {
    final userId = _userId;
    if (userId == null) return;

    _friendshipsChannel = Supabase.instance.client
        .channel('friendships:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requester_id',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'addressee_id',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe();
  }

  // ---------------------------------------------------------------------------
  // Username
  // ---------------------------------------------------------------------------

  /// Check if a username is available.
  Future<bool> isUsernameAvailable(String value) =>
      _repository.isUsernameAvailable(value);

  /// Claim a username for the current user.
  Future<bool> setUsername(String value) async {
    try {
      await _repository.setUsername(value.toLowerCase());
      username.value = value.toLowerCase();
      AnalyticsService.logClaimUsername();
      return true;
    } catch (e) {
      debugPrint('Error setting username: $e');
      Get.snackbar('Error', 'Username may already be taken');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Privacy
  // ---------------------------------------------------------------------------

  Future<void> toggleShareWatchingActivity(bool value) async {
    shareWatchingActivity.value = value;
    try {
      await _repository.setShareWatchingActivity(value);
      AnalyticsService.logTogglePrivacy(shareWatching: value);
    } catch (e) {
      // Revert on error
      shareWatchingActivity.value = !value;
      debugPrint('Error toggling privacy: $e');
      Get.snackbar('Error', 'Failed to update privacy settings');
    }
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Search users by email or name.
  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      searchResults.clear();
      return;
    }
    try {
      isSearching.value = true;
      final results = await _repository.searchUsers(query);
      searchResults.assignAll(results);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() => searchResults.clear();

  // ---------------------------------------------------------------------------
  // Friend Requests
  // ---------------------------------------------------------------------------

  /// Send a friend request. Returns true on success.
  /// NOTE: Caller is responsible for showing success feedback and navigation
  /// to avoid Get.snackbar/Get.back overlay conflicts.
  Future<bool> sendFriendRequest(UserProfile user) async {
    try {
      await _repository.sendFriendRequest(user.id);
      AnalyticsService.logSendFriendRequest();
      // Reload sent requests to get the real friendship object
      final sent = await _repository.getPendingSent();
      pendingSent.assignAll(sent);
      // Fire-and-forget: send notification (don't block the UI)
      _sendRequestNotification(user);
      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      Get.snackbar('Error', 'Failed to send friend request');
      return false;
    }
  }

  /// Background notification send — errors are logged, not surfaced.
  void _sendRequestNotification(UserProfile user) async {
    try {
      final requesterName =
          AuthController.to.user?.userMetadata?['full_name'] as String? ??
          username.value ??
          'Someone';
      await _repository.sendFriendRequestNotification(
        addresseeId: user.id,
        requesterName: requesterName,
      );
    } catch (e) {
      debugPrint('Error sending friend request notification: $e');
    }
  }

  /// Accept a pending friend request.
  Future<void> acceptRequest(Friendship request) async {
    // Optimistic: move from pending to friends
    pendingReceived.removeWhere((f) => f.id == request.id);
    friends.insert(
      0,
      Friendship(
        id: request.id,
        requesterId: request.requesterId,
        addresseeId: request.addresseeId,
        status: 'accepted',
        createdAt: request.createdAt,
        updatedAt: DateTime.now(),
        friend: request.friend,
      ),
    );

    try {
      await _repository.acceptFriendRequest(request.id);
      AnalyticsService.logAcceptFriendRequest();
    } catch (e) {
      // Revert
      friends.removeWhere((f) => f.id == request.id);
      pendingReceived.insert(0, request);
      debugPrint('Error accepting request: $e');
      Get.snackbar('Error', 'Failed to accept request');
    }
  }

  /// Decline a pending friend request.
  Future<void> declineRequest(Friendship request) async {
    pendingReceived.removeWhere((f) => f.id == request.id);
    try {
      await _repository.deleteFriendship(request.id);
    } catch (e) {
      pendingReceived.insert(0, request);
      debugPrint('Error declining request: $e');
      Get.snackbar('Error', 'Failed to decline request');
    }
  }

  /// Cancel a sent friend request.
  Future<void> cancelRequest(Friendship request) async {
    pendingSent.removeWhere((f) => f.id == request.id);
    try {
      await _repository.deleteFriendship(request.id);
    } catch (e) {
      pendingSent.insert(0, request);
      debugPrint('Error cancelling request: $e');
    }
  }

  /// Remove an existing friend.
  Future<void> removeFriend(Friendship friendship) async {
    final index = friends.indexOf(friendship);
    friends.remove(friendship);
    try {
      await _repository.deleteFriendship(friendship.id);
      Get.snackbar('Removed', 'Friend removed');
    } catch (e) {
      friends.insert(index.clamp(0, friends.length), friendship);
      debugPrint('Error removing friend: $e');
      Get.snackbar('Error', 'Failed to remove friend');
    }
  }

  // ---------------------------------------------------------------------------
  // Relationship helpers (for UI buttons)
  // ---------------------------------------------------------------------------

  /// Check the relationship status with a given user ID.
  /// Returns 'friends', 'pending_sent', 'pending_received', or 'none'.
  String relationshipStatus(String otherUserId) {
    final userId = _userId ?? '';
    for (final f in friends) {
      if (f.friendId(userId) == otherUserId) return 'friends';
    }
    for (final f in pendingSent) {
      if (f.addresseeId == otherUserId) return 'pending_sent';
    }
    for (final f in pendingReceived) {
      if (f.requesterId == otherUserId) return 'pending_received';
    }
    return 'none';
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  /// Block a user. Auto-removes friendship (via DB trigger).
  Future<void> blockUser(String userId, {String? displayName}) async {
    try {
      await _repository.blockUser(userId);
      AnalyticsService.logBlockUser();
      // Remove from friends/pending lists locally
      friends.removeWhere((f) => f.friendId(_userId ?? '') == userId);
      pendingReceived.removeWhere((f) => f.requesterId == userId);
      pendingSent.removeWhere((f) => f.addresseeId == userId);
      // Reload blocks
      blockedUsers.assignAll(await _repository.getBlockedUsers());
      Get.snackbar('Blocked', '${displayName ?? "User"} has been blocked');
    } catch (e) {
      debugPrint('Error blocking user: $e');
      Get.snackbar('Error', 'Failed to block user');
    }
  }

  /// Unblock a user.
  Future<void> unblockUser(String userId) async {
    final index = blockedUsers.indexWhere((b) => b.blockedId == userId);
    if (index == -1) return;
    final removed = blockedUsers.removeAt(index);
    try {
      await _repository.unblockUser(userId);
    } catch (e) {
      blockedUsers.insert(index, removed);
      debugPrint('Error unblocking user: $e');
      Get.snackbar('Error', 'Failed to unblock user');
    }
  }

  /// Load blocked users list (lazy — only when needed).
  Future<void> loadBlockedUsers() async {
    try {
      blockedUsers.assignAll(await _repository.getBlockedUsers());
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
  }
}
