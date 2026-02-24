import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../controllers/followed_talent_controller.dart';
import '../screens/following_list_screen.dart';

/// Compact following card for the profile screen.
/// Shows talent count, avatars, and navigates to full list on tap.
class FollowingSection extends StatelessWidget {
  const FollowingSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FollowedTalentController>()) {
      Get.put(FollowedTalentController());
    }

    return Obx(() {
      final ctrl = FollowedTalentController.to;
      final count = ctrl.followedTalent.length;

      return GestureDetector(
        onTap: () => Get.to(() => const FollowingListScreen()),
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
                  const Icon(Icons.people_alt, color: EColors.secondary,
                      size: 20),
                  const SizedBox(width: ESizes.sm),
                  const Text(
                    'Following',
                    style: TextStyle(
                      fontSize: ESizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: EColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: EColors.textTertiary),
                ],
              ),
              const SizedBox(height: ESizes.sm),
              if (ctrl.isLoading.value)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (count == 0)
                const Text(
                  'Not following anyone yet',
                  style: TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                )
              else
                _buildTalentAvatars(ctrl),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTalentAvatars(FollowedTalentController ctrl) {
    final display = ctrl.followedTalent.take(5).toList();
    final total = ctrl.followedTalent.length;
    final remaining = total - display.length;

    return Row(
      children: [
        ...display.map((t) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: EColors.surfaceLight,
              backgroundImage: t.profilePath != null
                  ? CachedNetworkImageProvider(
                      EImages.tmdbProfile(t.profilePath))
                  : null,
              child: t.profilePath == null
                  ? const Icon(Icons.person, size: 16,
                      color: EColors.textSecondary)
                  : null,
            ),
          );
        }),
        const SizedBox(width: ESizes.xs),
        Text(
          '$total following${remaining > 0 ? ' (+$remaining more)' : ''}',
          style: const TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSm,
          ),
        ),
      ],
    );
  }
}
