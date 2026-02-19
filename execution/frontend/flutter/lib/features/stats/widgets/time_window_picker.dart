import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/stats_controller.dart';

/// Segmented control for selecting the stats time window.
class TimeWindowPicker extends StatelessWidget {
  const TimeWindowPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = StatsController.to;
      final selected = controller.selectedWindow;

      return Container(
        padding: const EdgeInsets.all(ESizes.xs),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.border),
        ),
        child: Row(
          children: StatsWindow.values.map((window) {
            final isSelected = window == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.loadStats(window),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(ESizes.radiusSm),
                  ),
                  child: Text(
                    window.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ESizes.fontSm,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? EColors.textOnPrimary
                          : EColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
