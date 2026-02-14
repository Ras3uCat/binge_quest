import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/friendship.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/friend_controller.dart';
import '../controllers/watchlist_member_controller.dart';

/// Bottom sheet for inviting a friend as watchlist co-curator.
class InviteFriendSheet {
  InviteFriendSheet._();

  static Future<void> show({
    required String watchlistId,
    required String watchlistName,
    Set<String> existingMemberIds = const {},
  }) async {
    final ctrl = FriendController.to;
    final userId = AuthController.to.user?.id ?? '';

    // Ensure friend data is loaded (controller may have just been created).
    if (ctrl.friends.isEmpty && ctrl.isLoading.value) {
      await ctrl.refresh();
    }

    final availableFriends = ctrl.friends.where((f) {
      final friendId = f.friendId(userId);
      return !existingMemberIds.contains(friendId);
    }).toList();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: const BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ESizes.radiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invite Co-Curator',
                  style: TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  color: EColors.textSecondary,
                ),
              ],
            ),
            Text(
              'Choose a friend to share "$watchlistName"',
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESizes.md),
            if (availableFriends.isEmpty)
              Padding(
                padding: const EdgeInsets.all(ESizes.xl),
                child: Center(
                  child: Text(
                    ctrl.friends.isEmpty
                        ? 'No friends yet. Add friends first!'
                        : 'All friends are already members.',
                    style: const TextStyle(color: EColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableFriends.length,
                itemBuilder: (_, i) {
                  final f = availableFriends[i];
                  final friend = f.friend;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: EColors.surfaceLight,
                      backgroundImage: friend?.avatarUrl != null
                          ? NetworkImage(friend!.avatarUrl!)
                          : null,
                      child: friend?.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              color: EColors.textSecondary,
                            )
                          : null,
                    ),
                    title: Text(
                      friend?.displayName ?? 'User',
                      style: const TextStyle(
                        color: EColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: friend?.username != null
                        ? Text(
                            '@${friend!.username}',
                            style: const TextStyle(
                              color: EColors.textSecondary,
                              fontSize: ESizes.fontSm,
                            ),
                          )
                        : null,
                    trailing: TextButton(
                      onPressed: () {
                        if (friend == null) return;
                        WatchlistMemberController.to.inviteFriend(
                          watchlistId: watchlistId,
                          watchlistName: watchlistName,
                          friend: friend,
                        );
                        Get.back();
                      },
                      child: const Text(
                        'Invite',
                        style: TextStyle(color: EColors.primary),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ESizes.radiusMd),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
