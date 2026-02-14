import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../badges/controllers/badge_controller.dart';
import '../../badges/screens/badges_screen.dart';
import '../../badges/widgets/badge_card.dart';

/// Section widget displaying recent badges on the profile screen.
class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = BadgeController.to;

      return Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(controller),
            const SizedBox(height: ESizes.md),
            _buildBadgesContent(controller),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BadgeController controller) {
    return GestureDetector(
      onTap: () => Get.to(() => const BadgesScreen()),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: EColors.accent,
            size: ESizes.iconMd,
          ),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Badges',
                  style: TextStyle(
                    fontSize: ESizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                Text(
                  '${controller.earnedCount} of ${controller.totalCount} earned',
                  style: TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: EColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesContent(BadgeController controller) {
    if (controller.isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            color: EColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (controller.recentBadges.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRecentBadges(controller);
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: () => Get.to(() => const BadgesScreen()),
      child: Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
          border: Border.all(
            color: EColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EColors.surface,
                border: Border.all(color: EColors.border),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No badges yet',
                    style: TextStyle(
                      fontSize: ESizes.fontMd,
                      fontWeight: FontWeight.w500,
                      color: EColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Start watching to earn achievements!',
                    style: TextStyle(
                      fontSize: ESizes.fontSm,
                      color: EColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBadges(BadgeController controller) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.recentBadges.length,
        separatorBuilder: (context, index) => const SizedBox(width: ESizes.sm),
        itemBuilder: (context, index) {
          final userBadge = controller.recentBadges[index];
          final badge = userBadge.badge;

          if (badge == null) return const SizedBox.shrink();

          return SizedBox(
            width: 90,
            child: BadgeCard(
              badge: badge,
              isEarned: true,
              earnedAt: userBadge.earnedAt,
              onTap: () => Get.to(() => const BadgesScreen()),
            ),
          );
        },
      ),
    );
  }
}
