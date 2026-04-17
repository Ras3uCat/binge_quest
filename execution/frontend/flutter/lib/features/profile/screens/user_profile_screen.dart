import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/user_profile.dart';
import '../controllers/user_profile_controller.dart';
import '../widgets/friend_badges_section.dart';
import '../widgets/friend_stats_section.dart';
import '../../playlists/widgets/playlists_section.dart';

class UserProfileScreen extends StatelessWidget {
  final String? userId;
  final String? username;

  const UserProfileScreen({super.key, this.userId, this.username})
    : assert(userId != null || username != null);

  @override
  Widget build(BuildContext context) {
    final tag = userId ?? username!;
    final ctrl = Get.put(
      UserProfileController(userId: userId, username: username),
      tag: tag,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [EColors.backgroundSecondary, EColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(ctrl),
              Expanded(
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: EColors.primary));
                  }
                  if (ctrl.loadFailed.value || ctrl.profile.value == null) {
                    return _buildError();
                  }
                  return _buildContent(ctrl);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfileController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          Obx(() {
            final name = ctrl.profile.value?.displayLabel ?? '';
            return Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off, size: 64, color: EColors.textTertiary),
          SizedBox(height: ESizes.md),
          Text(
            'Profile not found',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontMd),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(UserProfileController ctrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Obx(() {
        final p = ctrl.profile.value!;
        return Column(
          children: [
            _buildProfileCard(p, ctrl),
            if (!ctrl.isCurrentUser) ...[
              const SizedBox(height: ESizes.xl),
              _buildFriendButton(ctrl),
            ],
            const SizedBox(height: ESizes.xl),
            FriendStatsSection(ctrl: ctrl),
            const SizedBox(height: ESizes.md),
            FriendBadgesSection(ctrl: ctrl),
            const SizedBox(height: ESizes.md),
            PlaylistsSection(userId: p.id, isOwnProfile: false),
          ],
        );
      }),
    );
  }

  Widget _buildProfileCard(UserProfile profile, UserProfileController ctrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        children: [
          _buildAvatar(profile),
          const SizedBox(height: ESizes.md),
          Text(
            profile.displayLabel,
            style: const TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (profile.username != null) ...[
            const SizedBox(height: ESizes.xs),
            Text(
              '@${profile.username}',
              style: const TextStyle(fontSize: ESizes.fontMd, color: EColors.textSecondary),
            ),
          ],
          if (profile.primaryArchetype != null) ...[
            const SizedBox(height: ESizes.md),
            _buildArchetypePill(profile.primaryArchetype!),
          ],
          if (ctrl.isCurrentUser) ...[
            const SizedBox(height: ESizes.md),
            const Text(
              'This is your profile',
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    final avatarUrl = profile.avatarUrl;
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: EColors.surfaceLight,
      );
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: EColors.surfaceLight,
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(Icons.person, size: 50, color: EColors.textSecondary),
    );
  }

  Widget _buildArchetypePill(String archetypeName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        archetypeName,
        style: const TextStyle(
          fontSize: ESizes.fontSm,
          color: EColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFriendButton(UserProfileController ctrl) {
    return Obx(() {
      if (ctrl.isFriend.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.sm),
          decoration: BoxDecoration(
            color: EColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            border: Border.all(color: EColors.success.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: EColors.success, size: 20),
              SizedBox(width: ESizes.sm),
              Text(
                'Friends',
                style: TextStyle(color: EColors.success, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }

      if (ctrl.hasPendingRequest.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.sm),
          decoration: BoxDecoration(
            color: EColors.surfaceLight,
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            border: Border.all(color: EColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, color: EColors.textSecondary, size: 20),
              SizedBox(width: ESizes.sm),
              Text(
                'Request Sent',
                style: TextStyle(color: EColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        height: ESizes.buttonHeightLg,
        child: ElevatedButton.icon(
          onPressed: ctrl.isSendingRequest.value ? null : ctrl.sendFriendRequest,
          icon: ctrl.isSendingRequest.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: EColors.textOnPrimary),
                )
              : const Icon(Icons.person_add),
          label: const Text('Add Friend'),
        ),
      );
    });
  }
}
