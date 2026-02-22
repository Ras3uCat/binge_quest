import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/friend_controller.dart';
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

class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = FriendController.to;
      final received = ctrl.pendingReceived;
      final sent = ctrl.pendingSent;

      if (received.isEmpty && sent.isEmpty) {
        return friendEmptyState(
          icon: Icons.mail_outline,
          message: 'No pending requests',
        );
      }

      return ListView(
        padding: const EdgeInsets.all(ESizes.md),
        children: [
          if (received.isNotEmpty) ...[
            _sectionHeader('Received (${received.length})'),
            ...received.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: FriendRequestCard(
                    friendship: f,
                    onAccept: () => ctrl.acceptRequest(f),
                    onDecline: () => ctrl.declineRequest(f),
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
                    onCancel: () => ctrl.cancelRequest(f),
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
