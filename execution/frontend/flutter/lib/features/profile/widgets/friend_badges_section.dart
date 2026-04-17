import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../badges/widgets/badge_card.dart';
import '../controllers/user_profile_controller.dart';

class FriendBadgesSection extends StatelessWidget {
  final UserProfileController ctrl;

  const FriendBadgesSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final badges = ctrl.earnedBadges;
      if (badges.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusLg),
          border: Border.all(color: EColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges (${badges.length})',
              style: const TextStyle(
                fontSize: ESizes.fontMd,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.md),
            Wrap(
              spacing: ESizes.sm,
              runSpacing: ESizes.sm,
              children: badges
                  .where((ub) => ub.badge != null)
                  .map(
                    (ub) => SizedBox(
                      width: 80,
                      child: BadgeCard(badge: ub.badge!, isEarned: true, earnedAt: ub.earnedAt),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    });
  }
}
