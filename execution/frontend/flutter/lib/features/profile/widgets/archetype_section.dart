import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/archetype_controller.dart';
import '../screens/archetype_screen.dart';
import 'archetype_badge.dart';

/// Profile section card that shows the current archetype and navigates
/// to ArchetypeScreen on tap — mirrors BadgesSection structure.
class ArchetypeSection extends StatelessWidget {
  const ArchetypeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = ArchetypeController.to;
      return Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: ESizes.md),
            _buildContent(ctrl),
          ],
        ),
      );
    });
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => Get.to(() => const ArchetypeScreen()),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: EColors.primary, size: ESizes.iconMd),
          const SizedBox(width: ESizes.sm),
          const Expanded(
            child: Text(
              'Archetypes',
              style: TextStyle(
                fontSize: ESizes.fontMd,
                fontWeight: FontWeight.w600,
                color: EColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: EColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildContent(ArchetypeController ctrl) {
    if (ctrl.primary == null) {
      return const Text(
        'Watch more to unlock your archetype',
        style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
      );
    }
    return Center(
      child: ArchetypeBadge(
        primary: ctrl.primary,
        secondary: ctrl.secondary,
        showTagline: true,
        onTap: () => Get.to(() => const ArchetypeScreen()),
      ),
    );
  }
}
