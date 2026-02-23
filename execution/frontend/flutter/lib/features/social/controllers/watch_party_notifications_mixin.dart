import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/watch_party.dart';
import '../../../shared/repositories/watch_party_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Notification-sending helpers for WatchPartyController.
/// Extracted to keep the main controller under 300 lines.
mixin WatchPartyNotificationsMixin {
  WatchPartyRepository get repository;

  String get _currentUserLabel {
    try {
      return AuthController.to.user?.userMetadata?['full_name'] as String? ??
          'Someone';
    } catch (_) {
      return 'Someone';
    }
  }

  void sendJoinNotification(WatchParty party) async {
    try {
      await repository.sendNotification(
        userId: party.createdBy,
        category: 'watch_party_join',
        title: 'Watch Party',
        body: '$_currentUserLabel joined your ${party.name} watch party',
        data: {'party_id': party.id},
      );
    } catch (e) {
      debugPrint('WatchPartyNotificationsMixin.sendJoinNotification error: $e');
    }
  }

  void sendDeletedNotifications(
    WatchParty party,
    List<String> memberIds,
    String? currentId,
  ) async {
    final name = _currentUserLabel;
    for (final uid in memberIds) {
      if (uid == currentId) continue;
      try {
        await repository.sendNotification(
          userId: uid,
          category: 'watch_party_deleted',
          title: 'Watch Party Ended',
          body: '${party.name} watch party was ended by $name',
          data: {'party_id': party.id},
        );
      } catch (e) {
        debugPrint('WatchPartyNotificationsMixin.sendDeletedNotifications: $e');
      }
    }
  }

  Future<void> notifyPartyProgress({
    required String partyId,
    required String partyName,
    required String episodeLabel,
  }) async {
    try {
      final currentId = Supabase.instance.client.auth.currentUser?.id;
      final memberIds = await repository.fetchActiveMemberIds(partyId);
      final name = _currentUserLabel;
      for (final uid in memberIds) {
        if (uid == currentId) continue;
        await repository.sendNotification(
          userId: uid,
          category: 'watch_party_progress',
          title: partyName,
          body: '$name just watched $episodeLabel',
          data: {'party_id': partyId},
        );
      }
    } catch (e) {
      debugPrint('WatchPartyNotificationsMixin.notifyPartyProgress error: $e');
    }
  }

  Future<void> inviteAndNotify({
    required WatchParty party,
    required String inviteeUserId,
  }) async {
    try {
      await repository.inviteMember(party.id, inviteeUserId);
      await repository.sendNotification(
        userId: inviteeUserId,
        category: 'watch_party_invite',
        title: '${party.name} Watch Party',
        body: '$_currentUserLabel invited you to a watch party',
        data: {'party_id': party.id, 'party_name': party.name},
      );
    } catch (e) {
      debugPrint('WatchPartyNotificationsMixin.inviteAndNotify error: $e');
    }
  }
}
