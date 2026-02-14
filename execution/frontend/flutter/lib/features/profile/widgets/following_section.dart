import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/followed_talent.dart';
import '../../search/screens/person_detail_screen.dart';
import '../controllers/followed_talent_controller.dart';

/// Displays the list of followed talent on the profile screen.
class FollowingSection extends StatelessWidget {
  const FollowingSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    if (!Get.isRegistered<FollowedTalentController>()) {
      Get.put(FollowedTalentController());
    }

    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: ESizes.md),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.people_alt, color: EColors.secondary, size: 20),
        SizedBox(width: ESizes.sm),
        Text(
          'Following',
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.bold,
            color: EColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Obx(() {
      final controller = FollowedTalentController.to;

      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(ESizes.md),
            child: CircularProgressIndicator(color: EColors.primary),
          ),
        );
      }

      if (controller.followedTalent.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: controller.followedTalent
            .map((talent) => _FollowedTalentTile(talent: talent))
            .toList(),
      );
    });
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: ESizes.lg),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.person_search,
              size: 40,
              color: EColors.textTertiary,
            ),
            SizedBox(height: ESizes.sm),
            Text(
              'Not following anyone yet',
              style: TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textSecondary,
              ),
            ),
            SizedBox(height: ESizes.xs),
            Text(
              'Follow actors and directors to get notified\nabout their new releases',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single talent tile in the following list.
class _FollowedTalentTile extends StatelessWidget {
  final FollowedTalent talent;

  const _FollowedTalentTile({required this.talent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPersonDetail(),
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ESizes.sm,
              horizontal: ESizes.xs,
            ),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: ESizes.md),
                Expanded(child: _buildInfo()),
                _buildUnfollowButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: EColors.surfaceLight,
      backgroundImage: talent.profilePath != null
          ? CachedNetworkImageProvider(
              EImages.tmdbProfile(talent.profilePath),
            )
          : null,
      child: talent.profilePath == null
          ? const Icon(Icons.person, color: EColors.textTertiary)
          : null,
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          talent.personName,
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.w500,
            color: EColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: ESizes.xs),
        _buildTypeBadge(),
      ],
    );
  }

  Widget _buildTypeBadge() {
    final isActor = talent.isActor;
    final color = isActor ? EColors.primary : EColors.accent;
    final label = isActor ? 'Actor' : 'Director';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: ESizes.fontXs,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUnfollowButton() {
    return IconButton(
      onPressed: _handleUnfollow,
      icon: const Icon(
        Icons.favorite,
        color: EColors.secondary,
        size: 20,
      ),
      tooltip: 'Unfollow ${talent.personName}',
    );
  }

  void _navigateToPersonDetail() {
    Get.to(() => PersonDetailScreen(personId: talent.tmdbPersonId));
  }

  void _handleUnfollow() {
    final controller = FollowedTalentController.to;
    controller.toggleFollow(
      tmdbPersonId: talent.tmdbPersonId,
      personName: talent.personName,
      personType: talent.personType,
      profilePath: talent.profilePath,
    );
  }
}
