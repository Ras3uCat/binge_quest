import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import 'package:share_plus/share_plus.dart';
import '../../settings/screens/settings_screen.dart';
import '../../social/controllers/friend_controller.dart';
import '../../social/widgets/username_claim_sheet.dart';
import '../../../core/services/supabase_service.dart';
import '../controllers/archetype_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/archetype_badge.dart';
import '../widgets/archetype_section.dart';
import '../widgets/badges_section.dart';
import '../widgets/profile_actions_section.dart';
import '../widgets/profile_stats_section.dart';
import '../screens/archetype_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ESizes.lg),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: ESizes.lg),
                      const ProfileStatsSection(),
                      const SizedBox(height: ESizes.lg),
                      const ArchetypeSection(),
                      const SizedBox(height: ESizes.lg),
                      const BadgesSection(),
                      const SizedBox(height: ESizes.lg),
                      const ProfileActionsSection(),
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
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.lg),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
            onPressed: () => Get.back(),
          ),
          const Expanded(
            child: Text(
              EText.profile,
              style: TextStyle(
                fontSize: ESizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: EColors.textPrimary,
            tooltip: 'Share Profile',
            onPressed: _shareProfile,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: EColors.textPrimary,
            tooltip: 'Settings',
            onPressed: () => Get.to(() => const SettingsScreen()),
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
              child: const Icon(Icons.person, size: 50, color: EColors.textSecondary),
            );
          }),
          const SizedBox(height: ESizes.md),
          Obx(
            () => Text(
              controller.displayName,
              style: const TextStyle(
                fontSize: ESizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: EColors.textOnPrimary,
              ),
            ),
          ),
          Obx(() {
            final archCtrl = ArchetypeController.to;
            return Padding(
              padding: const EdgeInsets.only(top: ESizes.sm),
              child: ArchetypeBadge(
                primary: archCtrl.primary,
                secondary: archCtrl.secondary,
                showTagline: true,
                onTap: archCtrl.primary != null
                    ? () => Get.to(() => const ArchetypeScreen())
                    : null,
              ),
            );
          }),
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
          Obx(
            () => Text(
              controller.email,
              style: TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textOnPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _shareProfile() {
    final username = Get.isRegistered<FriendController>()
        ? FriendController.to.username.value
        : null;
    final userId = SupabaseService.currentUserId;
    final link = username != null
        ? 'https://raspucat.com/bingequest/profile?u=$username'
        : 'https://raspucat.com/bingequest/profile?id=$userId';
    Share.share('Find me on BingeQuest! $link');
  }
}
