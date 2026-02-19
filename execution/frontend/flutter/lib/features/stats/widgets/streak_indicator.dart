import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/stats_controller.dart';

/// Displays current streak, best streak, and a 7-day activity dot row.
class StreakIndicator extends StatelessWidget {
  const StreakIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = StatsController.to.statsData;
      final streaks = data?.streaks;
      final currentWeekActivity =
          data?.currentWeekActivity ?? List.filled(7, false);

      final current = streaks?.currentStreak ?? 0;
      final longest = streaks?.longestStreak ?? 0;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StreakStat(
                value: '$current',
                label: 'day streak',
                color: EColors.accent,
              ),
              Container(width: 1, height: 48, color: EColors.border),
              _StreakStat(
                value: '$longest',
                label: 'best streak',
                color: EColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: ESizes.md),
          _buildWeekDots(currentWeekActivity),
        ],
      );
    });
  }

  Widget _buildWeekDots(List<bool> activity) {
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final isActive = i < activity.length ? activity[i] : false;
        final label = dayLabels[i];

        return Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? EColors.primary : EColors.border,
              ),
            ),
            const SizedBox(height: ESizes.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? EColors.textSecondary : EColors.textTertiary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StreakStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: ESizes.fontDisplay,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
