import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/watch_party.dart';
import '../../../shared/repositories/watch_party_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import 'watch_party_realtime_mixin.dart';

/// GetX controller for Watch Party state management.
/// Registered with Get.lazyPut(fenix: true).
class WatchPartyController extends GetxController with WatchPartyRealtimeMixin {
  static WatchPartyController get to => Get.find();

  @override
  final WatchPartyRepository repository = WatchPartyRepository();

  // Alias for internal use (avoids breaking existing call sites)
  WatchPartyRepository get _repository => repository;

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  final activeParties = <WatchParty>[].obs;
  final pendingParties = <WatchParty>[].obs;

  @override
  final progressByParty = <String, List<WatchPartyMemberProgress>>{}.obs;

  final selectedSeason = 1.obs;
  final isLoading = false.obs;

  RealtimeChannel? _activeChannel;
  String? _openPartyId;

  @override
  String? get openPartyId => _openPartyId;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onClose() {
    closeParty();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Party list
  // ---------------------------------------------------------------------------

  Future<void> loadParties() async {
    try {
      isLoading.value = true;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final all = await _repository.fetchUserParties();

      final memberRows = await Supabase.instance.client
          .from('watch_party_members')
          .select('party_id, status')
          .eq('user_id', userId)
          .inFilter('status', ['active', 'pending']);

      final pendingIds = <String>{};
      final activeIds = <String>{};
      for (final row in memberRows as List) {
        final pid = row['party_id'] as String;
        if (row['status'] == 'pending') {
          pendingIds.add(pid);
        } else {
          activeIds.add(pid);
        }
      }

      pendingParties.assignAll(all.where((p) => pendingIds.contains(p.id)));
      activeParties.assignAll(all.where((p) => activeIds.contains(p.id)));
    } catch (e) {
      debugPrint('WatchPartyController.loadParties error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Party detail + Realtime
  // ---------------------------------------------------------------------------

  Future<void> openParty(String partyId) async {
    closeParty();
    _openPartyId = partyId;

    try {
      isLoading.value = true;
      final progress = await _repository.fetchProgress(partyId);
      progressByParty[partyId] = progress;
    } catch (e) {
      debugPrint('WatchPartyController.openParty fetch error: $e');
    } finally {
      isLoading.value = false;
    }

    _activeChannel = _repository.subscribeToProgress(
      partyId,
      handleRealtimeUpdate,
    );
  }

  void closeParty() {
    if (_activeChannel != null) {
      _repository.unsubscribeFromProgress(_activeChannel!);
      _activeChannel = null;
    }
    _openPartyId = null;
  }

  // ---------------------------------------------------------------------------
  // Member actions
  // ---------------------------------------------------------------------------

  Future<void> acceptInvite(String partyId) async {
    try {
      await _repository.acceptInvite(partyId);
      await loadParties();
      // C4b: notify party creator that current user joined
      final party = activeParties.firstWhereOrNull((p) => p.id == partyId);
      if (party != null) _sendJoinNotification(party);
    } catch (e) {
      debugPrint('WatchPartyController.acceptInvite error: $e');
      Get.snackbar('Error', 'Failed to accept invite');
    }
  }

  void _sendJoinNotification(WatchParty party) async {
    try {
      await _repository.sendNotification(
        userId: party.createdBy,
        category: 'watch_party_join',
        title: 'Watch Party',
        body: '${_currentUserLabel} joined your ${party.name} watch party',
        data: {'party_id': party.id},
      );
    } catch (e) {
      debugPrint('WatchPartyController._sendJoinNotification error: $e');
    }
  }

  Future<void> declineInvite(String partyId) async {
    try {
      await _repository.declineInvite(partyId);
      await loadParties();
    } catch (e) {
      debugPrint('WatchPartyController.declineInvite error: $e');
      Get.snackbar('Error', 'Failed to decline invite');
    }
  }

  Future<void> leaveParty(String partyId) async {
    try {
      await _repository.leaveParty(partyId);
      closeParty();
      await loadParties();
      Get.back();
    } catch (e) {
      debugPrint('WatchPartyController.leaveParty error: $e');
      Get.snackbar('Error', 'Failed to leave party');
    }
  }

  Future<void> deleteParty(String partyId) async {
    try {
      // C4d: capture members before delete so we can notify them
      final party = activeParties.firstWhereOrNull((p) => p.id == partyId);
      final memberIds = await _repository.fetchActiveMemberIds(partyId);
      final currentId = Supabase.instance.client.auth.currentUser?.id;

      await _repository.deleteParty(partyId);
      closeParty();
      await loadParties();
      Get.back();

      if (party != null) {
        _sendDeletedNotifications(party, memberIds, currentId);
      }
    } catch (e) {
      debugPrint('WatchPartyController.deleteParty error: $e');
      Get.snackbar('Error', 'Failed to delete party');
    }
  }

  void _sendDeletedNotifications(
    WatchParty party,
    List<String> memberIds,
    String? currentId,
  ) async {
    final name = _currentUserLabel;
    for (final uid in memberIds) {
      if (uid == currentId) continue;
      try {
        await _repository.sendNotification(
          userId: uid,
          category: 'watch_party_deleted',
          title: 'Watch Party Ended',
          body: '${party.name} watch party was ended by $name',
          data: {'party_id': party.id},
        );
      } catch (e) {
        debugPrint('_sendDeletedNotifications error: $e');
      }
    }
  }

  Future<WatchParty?> createParty({
    required String name,
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final party = await _repository.createParty(name, tmdbId, mediaType);
      await loadParties();
      return party;
    } catch (e) {
      debugPrint('WatchPartyController.createParty error: $e');
      Get.snackbar('Error', 'Failed to create watch party');
      return null;
    }
  }

  Future<void> inviteMember(String partyId, String userId) async {
    try {
      await _repository.inviteMember(partyId, userId);
    } catch (e) {
      debugPrint('WatchPartyController.inviteMember error: $e');
    }
  }

  /// C4a: Invite and notify the invitee via push notification.
  Future<void> inviteAndNotify({
    required WatchParty party,
    required String inviteeUserId,
  }) async {
    try {
      await _repository.inviteMember(party.id, inviteeUserId);
      await _repository.sendNotification(
        userId: inviteeUserId,
        category: 'watch_party_invite',
        title: '${party.name} Watch Party',
        body: '${_currentUserLabel} invited you to a watch party',
        data: {'party_id': party.id, 'party_name': party.name},
      );
    } catch (e) {
      debugPrint('WatchPartyController.inviteAndNotify error: $e');
    }
  }

  /// C4c: Notify all other active members that current user watched content.
  Future<void> notifyPartyProgress({
    required String partyId,
    required String partyName,
    required String episodeLabel,
  }) async {
    try {
      final currentId = Supabase.instance.client.auth.currentUser?.id;
      final memberIds = await _repository.fetchActiveMemberIds(partyId);
      final name = _currentUserLabel;
      for (final uid in memberIds) {
        if (uid == currentId) continue;
        await _repository.sendNotification(
          userId: uid,
          category: 'watch_party_progress',
          title: partyName,
          body: '$name just watched $episodeLabel',
          data: {'party_id': partyId},
        );
      }
    } catch (e) {
      debugPrint('WatchPartyController.notifyPartyProgress error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _currentUserLabel {
    try {
      return AuthController.to.user?.userMetadata?['full_name'] as String? ??
          'Someone';
    } catch (_) {
      return 'Someone';
    }
  }
}
