import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../../../shared/models/friendship.dart';
import '../controllers/friend_controller.dart';
import '../widgets/friend_request_card.dart';
import 'friend_search_screen.dart';

/// Main friends screen with tabs: Friends, Requests, Blocked.
class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: EColors.background,
        appBar: AppBar(
          title: const Text('Friends'),
          backgroundColor: EColors.backgroundSecondary,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Find Friends',
              onPressed: () async {
                await Get.to(() => const FriendSearchScreen());
                FriendController.to.refresh();
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: EColors.primary,
            labelColor: EColors.textPrimary,
            unselectedLabelColor: EColors.textSecondary,
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Requests'),
              Tab(text: 'Blocked'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendsTab(),
            _RequestsTab(),
            _BlockedTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Friends Tab
// =============================================================================
class _FriendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = FriendController.to;
      if (ctrl.isLoading.value && ctrl.friends.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.friends.isEmpty) {
        return _emptyState(
          icon: Icons.people_outline,
          message: 'No friends yet',
          sub: 'Tap the + icon to find friends',
        );
      }
      return RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(ESizes.md),
          itemCount: ctrl.friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: ESizes.xs),
          itemBuilder: (_, i) => _buildFriendTile(ctrl.friends[i], ctrl),
        ),
      );
    });
  }

  Widget _buildFriendTile(Friendship f, FriendController ctrl) {
    final friend = f.friend;
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: EColors.surfaceLight,
            backgroundImage: friend?.avatarUrl != null
                ? NetworkImage(friend!.avatarUrl!)
                : null,
            child: friend?.avatarUrl == null
                ? const Icon(Icons.person, color: EColors.textSecondary)
                : null,
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend?.displayName ?? 'User',
                  style: const TextStyle(
                    color: EColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (friend?.username != null)
                  Text(
                    '@${friend!.username}',
                    style: const TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSm,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: EColors.textSecondary),
            color: EColors.surface,
            onSelected: (value) {
              if (value == 'remove') {
                _confirmRemove(ctrl, f);
              } else if (value == 'block') {
                ctrl.blockUser(
                  f.friendId(ctrl.friends.first.requesterId),
                  displayName: friend?.displayName,
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Friend',
                    style: TextStyle(color: EColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'block',
                child:
                    Text('Block User', style: TextStyle(color: EColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemove(FriendController ctrl, Friendship f) {
    EConfirmDialog.show(
      title: 'Remove Friend',
      message:
          'Remove ${f.friend?.displayName ?? "this user"} from your friends?',
      confirmLabel: 'Remove',
      isDestructive: true,
      onConfirm: () => ctrl.removeFriend(f),
    );
  }
}

// =============================================================================
// Requests Tab
// =============================================================================
class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = FriendController.to;
      final received = ctrl.pendingReceived;
      final sent = ctrl.pendingSent;

      if (received.isEmpty && sent.isEmpty) {
        return _emptyState(
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

// =============================================================================
// Blocked Tab
// =============================================================================
class _BlockedTab extends StatefulWidget {
  @override
  State<_BlockedTab> createState() => _BlockedTabState();
}

class _BlockedTabState extends State<_BlockedTab> {
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
        return _emptyState(
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: EColors.surfaceLight,
                  child:
                      const Icon(Icons.person, color: EColors.textSecondary),
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
                  child: const Text('Unblock',
                      style: TextStyle(color: EColors.primary)),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// =============================================================================
// Shared
// =============================================================================
Widget _emptyState({
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
        Text(message,
            style:
                const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontMd)),
        if (sub != null) ...[
          const SizedBox(height: ESizes.xs),
          Text(sub,
              style: const TextStyle(
                  color: EColors.textTertiary, fontSize: ESizes.fontSm)),
        ],
      ],
    ),
  );
}
