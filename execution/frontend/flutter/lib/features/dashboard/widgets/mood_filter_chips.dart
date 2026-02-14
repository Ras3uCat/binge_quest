import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/mood_tag.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

class MoodFilterChips extends StatelessWidget {
  const MoodFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = WatchlistController.to;
      final selectedMoods = controller.selectedMoods;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
        child: Row(
          children: [
            ...MoodTag.values.map((mood) {
              final isSelected = selectedMoods.contains(mood);
              return Padding(
                padding: const EdgeInsets.only(right: ESizes.sm),
                child: _MoodChip(
                  mood: mood,
                  isSelected: isSelected,
                  onTap: () => controller.toggleMood(mood),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _MoodChip extends StatelessWidget {
  final MoodTag mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md,
          vertical: ESizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? mood.color : EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
          border: Border.all(color: isSelected ? mood.color : EColors.border),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mood.icon,
                size: 16,
                color: isSelected
                    ? EColors.textOnPrimary
                    : EColors.textSecondary,
              ),
              const SizedBox(width: ESizes.xs),
              Text(
                mood.displayName,
                style: TextStyle(
                  fontSize: ESizes.fontSm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? EColors.textOnPrimary
                      : EColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
