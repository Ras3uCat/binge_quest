import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/friend_controller.dart';
import '../screens/friend_list_screen.dart';

/// Compact friends section for the profile screen.
/// Shows friend count, pending badge, and navigation to full friend list.
class FriendsSection extends StatelessWidget {
  const FriendsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = FriendController.to;
      final friendCount = ctrl.friendCount;
      final pendingCount = ctrl.pendingCount;

      return GestureDetector(
        onTap: () => Get.to(() => const FriendListScreen()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ESizes.lg),
          decoration: BoxDecoration(
            color: EColors.surface,
            borderRadius: BorderRadius.circular(ESizes.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: EColors.primary, size: 20),
                  const SizedBox(width: ESizes.sm),
                  const Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: ESizes.fontMd,
                      fontWeight: FontWeight.bold,
                      color: EColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EColors.accent,
                        borderRadius: BorderRadius.circular(ESizes.sm),
                      ),
                      child: Text(
                        '$pendingCount new',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: EColors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(width: ESizes.sm),
                  const Icon(Icons.chevron_right, color: EColors.textTertiary),
                ],
              ),
              const SizedBox(height: ESizes.sm),
              if (ctrl.isLoading.value)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (friendCount == 0)
                const Text(
                  'Find friends to share your watching journey',
                  style: TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                )
              else
                _buildFriendAvatars(ctrl),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFriendAvatars(FriendController ctrl) {
    final displayFriends = ctrl.friends.take(5).toList();
    final remaining = ctrl.friendCount - displayFriends.length;

    return Row(
      children: [
        ...displayFriends.map((f) {
          final avatarUrl = f.friend?.avatarUrl;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: EColors.surfaceLight,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 16, color: EColors.textSecondary)
                  : null,
            ),
          );
        }),
        const SizedBox(width: ESizes.xs),
        Text(
          '${ctrl.friendCount} friend${ctrl.friendCount == 1 ? '' : 's'}${remaining > 0 ? ' (+$remaining more)' : ''}',
          style: const TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSm,
          ),
        ),
      ],
    );
  }
}
