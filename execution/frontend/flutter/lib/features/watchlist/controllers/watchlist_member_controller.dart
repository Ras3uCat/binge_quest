import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../shared/models/watchlist_member.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/repositories/watchlist_member_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/friend_controller.dart';
import 'watchlist_controller.dart';

/// Controller for watchlist co-curator management.
class WatchlistMemberController extends GetxController {
  static WatchlistMemberController get to => Get.find();

  final WatchlistMemberRepository _repository = WatchlistMemberRepository();

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------
  final members = <WatchlistMember>[].obs;
  final pendingInvites = <WatchlistMember>[].obs;
  final sharedWatchlistIds = <String>{}.obs;
  final isLoading = false.obs;

  String? get _userId => AuthController.to.user?.id;

  int get pendingInviteCount => pendingInvites.length;

  /// Check if a watchlist is shared (has co-curators).
  bool isShared(String watchlistId) => sharedWatchlistIds.contains(watchlistId);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_userId == null) return;
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _repository.getPendingInvites(),
        _repository.getSharedWatchlistIds(),
      ]);
      pendingInvites.assignAll(results[0] as List<WatchlistMember>);
      sharedWatchlistIds.assignAll(results[1] as Set<String>);
    } catch (e) {
      debugPrint('Error loading watchlist member data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => _loadInitialData();

  // ---------------------------------------------------------------------------
  // Members for a specific watchlist
  // ---------------------------------------------------------------------------

  /// Load all members (including pending) for a watchlist.
  Future<void> loadMembers(String watchlistId) async {
    try {
      isLoading.value = true;
      final result = await _repository.getAllMembers(watchlistId);
      members.assignAll(result);
    } catch (e) {
      debugPrint('Error loading members: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Invite
  // ---------------------------------------------------------------------------

  /// Invite a friend as co-curator of a watchlist.
  Future<void> inviteFriend({
    required String watchlistId,
    required String watchlistName,
    required UserProfile friend,
  }) async {
    try {
      await _repository.inviteFriend(
        watchlistId: watchlistId,
        friendId: friend.id,
      );
      // Send notification
      final inviterName =
          AuthController.to.user?.userMetadata?['full_name'] as String? ??
          (Get.isRegistered<FriendController>()
              ? FriendController.to.username.value
              : null) ??
          'Someone';
      await _repository.notifyCoOwnerInvite(
        inviteeId: friend.id,
        inviterName: inviterName,
        watchlistName: watchlistName,
        watchlistId: watchlistId,
      );
      // Reload members for this watchlist
      await loadMembers(watchlistId);
      Get.snackbar('Invited', '${friend.displayLabel} invited as co-curator');
    } catch (e) {
      debugPrint('Error inviting friend: $e');
      Get.snackbar('Error', 'Failed to send invite');
    }
  }

  // ---------------------------------------------------------------------------
  // Accept / Decline invites
  // ---------------------------------------------------------------------------

  /// Accept a co-curator invite.
  Future<void> acceptInvite(WatchlistMember invite) async {
    pendingInvites.removeWhere((i) => i.id == invite.id);
    try {
      await _repository.acceptInvite(invite.id);
      sharedWatchlistIds.add(invite.watchlistId);
      // Reload watchlists so the shared list appears in the dropdown.
      WatchlistController.to.loadWatchlists();
      Get.snackbar('Accepted', 'You are now a co-curator');
    } catch (e) {
      pendingInvites.insert(0, invite);
      debugPrint('Error accepting invite: $e');
      Get.snackbar('Error', 'Failed to accept invite');
    }
  }

  /// Decline a co-curator invite.
  Future<void> declineInvite(WatchlistMember invite) async {
    pendingInvites.removeWhere((i) => i.id == invite.id);
    try {
      await _repository.declineInvite(invite.id);
    } catch (e) {
      pendingInvites.insert(0, invite);
      debugPrint('Error declining invite: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Remove / Leave
  // ---------------------------------------------------------------------------

  /// Remove a co-curator (curator action).
  Future<void> removeMember(WatchlistMember member) async {
    members.removeWhere((m) => m.id == member.id);
    try {
      await _repository.removeMember(member.id);
      Get.snackbar('Removed', '${member.user?.displayLabel ?? "User"} removed');
    } catch (e) {
      members.add(member);
      debugPrint('Error removing member: $e');
      Get.snackbar('Error', 'Failed to remove member');
    }
  }

  /// Leave a shared watchlist (co-curator action).
  Future<void> leaveWatchlist(WatchlistMember membership) async {
    try {
      await _repository.removeMember(membership.id);
      sharedWatchlistIds.remove(membership.watchlistId);
      Get.snackbar('Left', 'You left the shared watchlist');
    } catch (e) {
      sharedWatchlistIds.add(membership.watchlistId);
      debugPrint('Error leaving watchlist: $e');
      Get.snackbar('Error', 'Failed to leave watchlist');
    }
  }
}
