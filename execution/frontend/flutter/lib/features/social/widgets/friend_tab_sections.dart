import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/friend_controller.dart';
import '../controllers/watch_party_controller.dart';
import '../screens/watch_party_screen.dart';
import '../../../shared/models/watch_party.dart';
import 'friend_request_card.dart';

// ---------------------------------------------------------------------------
// Shared empty state helper
// ---------------------------------------------------------------------------

Widget friendEmptyState({
  required IconData icon,
  required String message,
  String? sub,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(height: ESizes.md),
        Text(
          message,
          style: const TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontMd,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: ESizes.xs),
          Text(
            sub,
            style: const TextStyle(
              color: EColors.textTertiary,
              fontSize: ESizes.fontSm,
            ),
          ),
        ],
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Requests Tab
// ---------------------------------------------------------------------------

class FriendRequestsTab extends StatefulWidget {
  const FriendRequestsTab({super.key});

  @override
  State<FriendRequestsTab> createState() => _FriendRequestsTabState();
}

class _FriendRequestsTabState extends State<FriendRequestsTab> {
  @override
  void initState() {
    super.initState();
    FriendController.to.refresh();
    WatchPartyController.to.loadParties();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final friendCtrl = FriendController.to;
      final received = friendCtrl.pendingReceived;
      final sent = friendCtrl.pendingSent;
      final partyInvites = WatchPartyController.to.pendingParties;

      if (received.isEmpty && sent.isEmpty && partyInvites.isEmpty) {
        return friendEmptyState(
          icon: Icons.mail_outline,
          message: 'No pending requests',
        );
      }

      return ListView(
        padding: const EdgeInsets.all(ESizes.md),
        children: [
          if (partyInvites.isNotEmpty) ...[
            _sectionHeader('Watch Party Invites (${partyInvites.length})'),
            ...partyInvites.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: _WatchPartyInviteCard(party: p),
                )),
            if (received.isNotEmpty || sent.isNotEmpty)
              const SizedBox(height: ESizes.md),
          ],
          if (received.isNotEmpty) ...[
            _sectionHeader('Received (${received.length})'),
            ...received.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: FriendRequestCard(
                    friendship: f,
                    onAccept: () => friendCtrl.acceptRequest(f),
                    onDecline: () => friendCtrl.declineRequest(f),
                  ),
                )),
          ],
          if (sent.isNotEmpty) ...[
            if (received.isNotEmpty) const SizedBox(height: ESizes.md),
            _sectionHeader('Sent (${sent.length})'),
            ...sent.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: FriendRequestCard(
                    friendship: f,
                    onCancel: () => friendCtrl.cancelRequest(f),
                  ),
                )),
          ],
        ],
      );
    });
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Text(
        title,
        style: const TextStyle(
          color: EColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontSm,
        ),
      ),
    );
  }
}

class _WatchPartyInviteCard extends StatelessWidget {
  final WatchParty party;
  const _WatchPartyInviteCard({required this.party});

  @override
  Widget build(BuildContext context) {
    final ctrl = WatchPartyController.to;
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EColors.surfaceLight,
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
            child: const Icon(
              Icons.groups,
              color: EColors.primary,
              size: ESizes.iconMd,
            ),
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.name,
                  style: const TextStyle(
                    color: EColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: ESizes.fontMd,
                  ),
                ),
                const SizedBox(height: ESizes.xs),
                Text(
                  party.creatorUsername != null
                      ? '${party.creatorUsername} invited you'
                      : 'Invited you to watch together',
                  style: const TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              await ctrl.acceptInvite(party.id);
              await Get.to(
                () => WatchPartyScreen(
                  partyId: party.id,
                  tmdbId: party.tmdbId,
                  mediaType: party.mediaType,
                  partyName: party.name,
                ),
              );
            },
            child: const Text(
              'Accept',
              style: TextStyle(color: EColors.primary, fontSize: ESizes.fontSm),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => ctrl.declineInvite(party.id),
            child: const Text(
              'Decline',
              style: TextStyle(
                  color: EColors.textSecondary, fontSize: ESizes.fontSm),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blocked Tab
// ---------------------------------------------------------------------------

class FriendBlockedTab extends StatefulWidget {
  const FriendBlockedTab({super.key});

  @override
  State<FriendBlockedTab> createState() => _FriendBlockedTabState();
}

class _FriendBlockedTabState extends State<FriendBlockedTab> {
  @override
  void initState() {
    super.initState();
    FriendController.to.loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final blocked = FriendController.to.blockedUsers;
      if (blocked.isEmpty) {
        return friendEmptyState(
          icon: Icons.block,
          message: 'No blocked users',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(ESizes.md),
        itemCount: blocked.length,
        separatorBuilder: (_, __) => const SizedBox(height: ESizes.xs),
        itemBuilder: (_, i) {
          final block = blocked[i];
          final user = block.blockedUser;
          return Container(
            padding: const EdgeInsets.all(ESizes.md),
            decoration: BoxDecoration(
              color: EColors.surface,
              borderRadius: BorderRadius.circular(ESizes.md),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: EColors.surfaceLight,
                  child: Icon(Icons.person, color: EColors.textSecondary),
                ),
                const SizedBox(width: ESizes.md),
                Expanded(
                  child: Text(
                    user?.displayName ?? 'Blocked User',
                    style: const TextStyle(color: EColors.textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      FriendController.to.unblockUser(block.blockedId),
                  child: const Text(
                    'Unblock',
                    style: TextStyle(color: EColors.primary),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
