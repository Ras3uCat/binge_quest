import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/watchlist_controller.dart';

/// Toggle button to expand/collapse the watchlist filter panel.
class WatchlistFilterButton extends StatelessWidget {
  const WatchlistFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = WatchlistController.to;
      final hasFilters = controller.hasActiveFilters;
      final filterCount = controller.activeFilterCount;
      final isActive = controller.isFilterPanelActive;

      return GestureDetector(
        onTap: controller.toggleFilterPanel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md,
            vertical: ESizes.sm,
          ),
          decoration: BoxDecoration(
            color: hasFilters || isActive ? EColors.primary : EColors.surface,
            borderRadius: BorderRadius.circular(ESizes.radiusRound),
            border: Border.all(
              color: hasFilters || isActive ? EColors.primary : EColors.border,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: hasFilters || isActive
                      ? EColors.textOnPrimary
                      : EColors.textSecondary,
                ),
                const SizedBox(width: ESizes.xs),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: ESizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: hasFilters || isActive
                        ? EColors.textOnPrimary
                        : EColors.textSecondary,
                  ),
                ),
                Opacity(
                  opacity: hasFilters ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: ESizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EColors.textOnPrimary,
                          borderRadius: BorderRadius.circular(ESizes.radiusRound),
                        ),
                        child: Text(
                          '$filterCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: EColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ESizes.xs),
                Icon(
                  isActive ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: hasFilters || isActive
                      ? EColors.textOnPrimary
                      : EColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
