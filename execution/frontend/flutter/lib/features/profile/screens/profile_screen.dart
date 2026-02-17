import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../../settings/screens/settings_screen.dart';
import '../../social/controllers/friend_controller.dart';
import '../../social/widgets/friends_section.dart';
import '../../social/widgets/username_claim_sheet.dart';
import '../controllers/profile_controller.dart';
import '../widgets/badges_section.dart';
import '../widgets/following_section.dart';
import '../widgets/streaming_breakdown_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EColors.backgroundSecondary,
              EColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ESizes.lg),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: ESizes.lg),
                      _buildStatsSection(),
                      const SizedBox(height: ESizes.lg),
                      const StreamingBreakdownSection(),
                      const SizedBox(height: ESizes.lg),
                      const BadgesSection(),
                      const SizedBox(height: ESizes.lg),
                      const FollowingSection(),
                      const SizedBox(height: ESizes.lg),
                      const FriendsSection(),
                      const SizedBox(height: ESizes.lg),
                      _buildActionsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Text(
            EText.profile,
            style: TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final controller = ProfileController.to;

    return Container(
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        gradient: EColors.primaryGradient,
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
      ),
      child: Column(
        children: [
          // Avatar
          Obx(() {
            final avatarUrl = controller.avatarUrl;
            if (avatarUrl != null) {
              return CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: EColors.surface,
              );
            }
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: EColors.surface,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: EColors.textSecondary,
              ),
            );
          }),
          const SizedBox(height: ESizes.md),
          // Name
          Obx(() => Text(
                controller.displayName,
                style: const TextStyle(
                  fontSize: ESizes.fontXxl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textOnPrimary,
                ),
              )),
          // Username
          Obx(() {
            final uname = Get.isRegistered<FriendController>()
                ? FriendController.to.username.value
                : null;
            return GestureDetector(
              onTap: uname == null ? () => UsernameClaimSheet.show() : null,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  uname != null ? '@$uname' : 'Set username',
                  style: TextStyle(
                    fontSize: ESizes.fontMd,
                    fontWeight: FontWeight.w500,
                    color: uname != null
                        ? EColors.textOnPrimary.withValues(alpha: 0.9)
                        : EColors.tertiary,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: ESizes.xs),
          // Email
          Obx(() => Text(
                controller.email,
                style: TextStyle(
                  fontSize: ESizes.fontMd,
                  color: EColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final controller = ProfileController.to;

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
          const Text(
            'Your Stats',
            style: TextStyle(
              fontSize: ESizes.fontLg,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
          const SizedBox(height: ESizes.md),
          Obx(() {
            if (controller.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(ESizes.lg),
                  child: CircularProgressIndicator(color: EColors.primary),
                ),
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.schedule,
                        label: 'Time Watched',
                        value: controller.formattedWatchTime,
                        color: EColors.primary,
                      ),
                    ),
                    const SizedBox(width: ESizes.md),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        label: 'Episodes',
                        value: '${controller.episodesWatched}',
                        color: EColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ESizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.movie,
                        label: 'Movies',
                        value: '${controller.moviesCompleted}',
                        color: EColors.accent,
                      ),
                    ),
                    const SizedBox(width: ESizes.md),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.tv,
                        label: 'Shows',
                        value: '${controller.showsCompleted}',
                        color: EColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: ESizes.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: ESizes.fontXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: ESizes.fontXs,
              color: EColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.settings,
          label: EText.settings,
          onTap: () => Get.to(() => const SettingsScreen()),
        ),
        const SizedBox(height: ESizes.sm),
        _buildActionTile(
          icon: Icons.refresh,
          label: 'Refresh Stats',
          onTap: () => ProfileController.to.loadStats(),
        ),
        const SizedBox(height: ESizes.sm),
        _buildActionTile(
          icon: Icons.logout,
          label: EText.signOut,
          onTap: () => _confirmSignOut(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? EColors.error : EColors.textPrimary;

    return Material(
      color: EColors.surface,
      borderRadius: BorderRadius.circular(ESizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive
                  ? EColors.error.withValues(alpha: 0.3)
                  : EColors.border,
            ),
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: ESizes.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: ESizes.fontMd,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut() {
    EConfirmDialog.show(
      title: EText.signOut,
      message: EText.signOutConfirm,
      confirmLabel: EText.signOut,
      isDestructive: true,
      onConfirm: () => ProfileController.to.signOut(),
    );
  }
}
