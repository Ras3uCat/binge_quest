import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watchlist_member.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/watchlist_member_controller.dart';
import '../widgets/invite_friend_sheet.dart';

/// Screen for managing co-owners of a watchlist.
class ManageMembersScreen extends StatefulWidget {
  final String watchlistId;
  final String watchlistName;
  final String ownerId;

  const ManageMembersScreen({
    super.key,
    required this.watchlistId,
    required this.watchlistName,
    required this.ownerId,
  });

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  bool get _isOwner => AuthController.to.user?.id == widget.ownerId;

  @override
  void initState() {
    super.initState();
    WatchlistMemberController.to.loadMembers(widget.watchlistId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: EColors.backgroundSecondary,
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Invite Co-Curator',
              onPressed: _showInviteSheet,
            ),
        ],
      ),
      body: Obx(() {
        final ctrl = WatchlistMemberController.to;
        if (ctrl.isLoading.value && ctrl.members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMembers = ctrl.members;
        if (allMembers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.loadMembers(widget.watchlistId),
          child: ListView.separated(
            padding: const EdgeInsets.all(ESizes.md),
            itemCount: allMembers.length + 1, // +1 for owner header
            separatorBuilder: (_, __) => const SizedBox(height: ESizes.xs),
            itemBuilder: (_, i) {
              if (i == 0) return _buildOwnerCard();
              return _buildMemberCard(allMembers[i - 1]);
            },
          ),
        );
      }),
    );
  }

  Widget _buildOwnerCard() {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      margin: const EdgeInsets.only(bottom: ESizes.sm),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.md),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: EColors.primary,
            child: Icon(Icons.star, color: EColors.textPrimary, size: 20),
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOwner ? 'You (Curator)' : 'Curator',
                  style: const TextStyle(
                    color: EColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.watchlistName,
                  style: const TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(WatchlistMember member) {
    final user = member.user;
    final isMe = member.userId == AuthController.to.user?.id;

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
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? const Icon(Icons.person, color: EColors.textSecondary)
                : null,
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You' : user?.displayName ?? 'User',
                  style: const TextStyle(
                    color: EColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  member.isPending ? 'Pending...' : 'Co-Curator',
                  style: TextStyle(
                    color: member.isPending
                        ? EColors.accent
                        : EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                ),
              ],
            ),
          ),
          if (_isOwner && !isMe)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: EColors.error,
              ),
              tooltip: 'Remove',
              onPressed: () => _confirmRemove(member),
            )
          else if (isMe && !_isOwner)
            TextButton(
              onPressed: () => _confirmLeave(member),
              child: const Text(
                'Leave',
                style: TextStyle(color: EColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: ESizes.md),
          const Text(
            'No co-curators yet',
            style: TextStyle(color: EColors.textSecondary),
          ),
          if (_isOwner) ...[
            const SizedBox(height: ESizes.md),
            ElevatedButton.icon(
              onPressed: _showInviteSheet,
              icon: const Icon(Icons.person_add),
              label: const Text('Invite a Friend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.primary,
                foregroundColor: EColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showInviteSheet() {
    final existingIds = WatchlistMemberController.to.members
        .map((m) => m.userId)
        .toSet();
    InviteFriendSheet.show(
      watchlistId: widget.watchlistId,
      watchlistName: widget.watchlistName,
      existingMemberIds: existingIds,
    );
  }

  void _confirmRemove(WatchlistMember member) {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          'Remove Co-Curator',
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: Text(
          'Remove ${member.user?.displayLabel ?? "this user"} from the watchlist?',
          style: const TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              WatchlistMemberController.to.removeMember(member);
            },
            child: const Text('Remove', style: TextStyle(color: EColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(WatchlistMember membership) {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          'Leave Watchlist',
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: const Text(
          'You will no longer be able to see or edit this watchlist.',
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              WatchlistMemberController.to.leaveWatchlist(membership);
              Get.back(); // Return to watchlist screen
            },
            child: const Text('Leave', style: TextStyle(color: EColors.error)),
          ),
        ],
      ),
    );
  }
}
