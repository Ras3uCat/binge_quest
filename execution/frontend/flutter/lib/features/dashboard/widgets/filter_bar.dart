import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = WatchlistController.to;
      final hasFilters = controller.hasActiveFilters;
      final moodCount = controller.selectedMoods.length;

      return Row(
        children: [
          // Active filters summary
          if (moodCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.sm,
                vertical: ESizes.xs,
              ),
              decoration: BoxDecoration(
                color: EColors.surfaceLight,
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: Text(
                '$moodCount mood${moodCount > 1 ? 's' : ''} selected',
                style: const TextStyle(
                  fontSize: ESizes.fontXs,
                  color: EColors.textSecondary,
                ),
              ),
            ),
          const Spacer(),
          // Clear all button
          if (hasFilters)
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: EColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
              ),
            ),
        ],
      );
    });
  }
}
