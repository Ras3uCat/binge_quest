import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';
import '../../features/profile/controllers/followed_talent_controller.dart';

/// Reusable follow/unfollow button for talent (actors/directors).
/// Displays a heart icon toggle that uses [FollowedTalentController].
class FollowTalentButton extends StatelessWidget {
  final int tmdbPersonId;
  final String personName;
  final String personType;
  final String? profilePath;
  final bool showLabel;
  final double iconSize;

  const FollowTalentButton({
    super.key,
    required this.tmdbPersonId,
    required this.personName,
    required this.personType,
    this.profilePath,
    this.showLabel = false,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    if (!Get.isRegistered<FollowedTalentController>()) {
      Get.put(FollowedTalentController());
    }

    return Obx(() {
      final controller = FollowedTalentController.to;
      final following = controller.isFollowing(tmdbPersonId);

      if (showLabel) {
        return _buildLabelButton(controller, following);
      }

      return _buildIconButton(controller, following);
    });
  }

  Widget _buildIconButton(
    FollowedTalentController controller,
    bool following,
  ) {
    return IconButton(
      onPressed: () => _handleTap(controller),
      icon: Icon(
        following ? Icons.favorite : Icons.favorite_border,
        color: following ? EColors.secondary : EColors.textSecondary,
        size: iconSize,
      ),
      tooltip: following ? 'Unfollow $personName' : 'Follow $personName',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: iconSize + ESizes.sm,
        minHeight: iconSize + ESizes.sm,
      ),
    );
  }

  Widget _buildLabelButton(
    FollowedTalentController controller,
    bool following,
  ) {
    final activeColor = following ? EColors.secondary : EColors.textPrimary;
    final borderColor = following
        ? EColors.secondary.withValues(alpha: 0.5)
        : EColors.textPrimary.withValues(alpha: 0.6);

    return SizedBox(
      height: ESizes.buttonHeightSm,
      child: OutlinedButton.icon(
        onPressed: () => _handleTap(controller),
        icon: Icon(
          following ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: activeColor,
        ),
        label: Text(
          following ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: ESizes.fontSm,
            color: activeColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusRound),
          ),
        ),
      ),
    );
  }

  void _handleTap(FollowedTalentController controller) {
    controller.toggleFollow(
      tmdbPersonId: tmdbPersonId,
      personName: personName,
      personType: personType,
      profilePath: profilePath,
    );
  }
}
