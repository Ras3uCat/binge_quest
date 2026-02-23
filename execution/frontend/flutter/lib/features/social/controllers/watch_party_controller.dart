import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/watch_party.dart';
import '../../../shared/repositories/watch_party_repository.dart';
import '../utils/watch_party_sayings.dart';
import 'watch_party_notifications_mixin.dart';
import 'watch_party_realtime_mixin.dart';

/// GetX controller for Watch Party state management.
/// Registered with Get.lazyPut(fenix: true).
class WatchPartyController extends GetxController
    with WatchPartyRealtimeMixin, WatchPartyNotificationsMixin {
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

  final membersByParty = <String, List<WatchPartyMember>>{}.obs;

  final selectedSeason = 1.obs;
  final isLoading = false.obs;

  // Saying indices — randomised once per openParty() call, stable until refresh.
  int firstPlaceSayingIndex = 0;
  int lastPlaceSayingIndex = 0;
  int middleSayingIndex = 0;
  int notStartedSayingIndex = 0;
  int completedSayingIndex = 0;
  int tiedSayingIndex = 0;

  // Nudge rate-limit: key = nudged userId, value = last sent DateTime.
  final _lastNudgeSent = <String, DateTime>{};

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

    // Randomise saying indices once per session open.
    final rng = Random();
    firstPlaceSayingIndex = rng.nextInt(10);
    lastPlaceSayingIndex = rng.nextInt(10);
    tiedSayingIndex = rng.nextInt(10);
    middleSayingIndex = rng.nextInt(20);
    notStartedSayingIndex = rng.nextInt(6);
    completedSayingIndex = rng.nextInt(6);

    try {
      isLoading.value = true;
      final results = await Future.wait([
        _repository.fetchProgress(partyId),
        _repository.fetchPartyMembers(partyId),
      ]);
      progressByParty[partyId] = results[0] as List<WatchPartyMemberProgress>;
      membersByParty[partyId] = results[1] as List<WatchPartyMember>;
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
      // C4b: notify party creator that current user joined.
      final party = activeParties.firstWhereOrNull((p) => p.id == partyId);
      if (party != null) sendJoinNotification(party);
    } catch (e) {
      debugPrint('WatchPartyController.acceptInvite error: $e');
      Get.snackbar('Error', 'Failed to accept invite');
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
      // C4d: capture members before delete so we can notify them.
      final party = activeParties.firstWhereOrNull((p) => p.id == partyId);
      final memberIds = await _repository.fetchActiveMemberIds(partyId);
      final currentId = Supabase.instance.client.auth.currentUser?.id;

      await _repository.deleteParty(partyId);
      closeParty();
      await loadParties();
      Get.back();

      if (party != null) {
        sendDeletedNotifications(party, memberIds, currentId);
      }
    } catch (e) {
      debugPrint('WatchPartyController.deleteParty error: $e');
      Get.snackbar('Error', 'Failed to delete party');
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

  // ---------------------------------------------------------------------------
  // Nudge
  // ---------------------------------------------------------------------------

  /// Returns true when [userId] has not been nudged within the last 24 hours.
  bool canNudge(String userId) {
    final last = _lastNudgeSent[userId];
    return last == null ||
        DateTime.now().difference(last) > const Duration(hours: 24);
  }

  Future<void> nudgeMember({
    required String partyId,
    required String partyName,
    required String nudgedUserId,
  }) async {
    if (!canNudge(nudgedUserId)) return;
    _lastNudgeSent[nudgedUserId] = DateTime.now();
    final saying = kNudgeSayings[Random().nextInt(kNudgeSayings.length)];
    try {
      await _repository.sendNotification(
        userId: nudgedUserId,
        category: 'watch_party_nudge',
        title: partyName,
        body: saying,
        data: {'party_id': partyId},
      );
    } catch (e) {
      debugPrint('WatchPartyController.nudgeMember error: $e');
    }
  }
}
