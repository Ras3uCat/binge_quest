import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/stats_controller.dart';

/// Completion ring showing items completed vs remaining.
class CompletionRing extends StatelessWidget {
  const CompletionRing({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = StatsController.to.statsData?.summary;
      final total = summary?.totalItems ?? 0;
      final completed = summary?.itemsCompleted ?? 0;

      if (total == 0) {
        return _buildEmptyState();
      }

      final remaining = total - completed;
      final pct = (completed / total * 100).round();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: completed.toDouble(),
                        color: EColors.success,
                        radius: 28,
                        title: '',
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: remaining > 0 ? remaining.toDouble() : 0.001,
                        color: EColors.border,
                        radius: 28,
                        title: '',
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 44,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ESizes.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(
                color: EColors.success,
                label: 'Completed',
                value: '$completed',
              ),
              const SizedBox(height: ESizes.sm),
              _LegendRow(
                color: EColors.border,
                label: 'Remaining',
                value: '$remaining',
              ),
              const SizedBox(height: ESizes.sm),
              Text(
                '$completed of $total completed '
                '${StatsController.to.selectedWindow == StatsWindow.all ? "total" : "this ${StatsController.to.selectedWindow.value}"}',
                style: const TextStyle(
                  fontSize: ESizes.fontSm,
                  color: EColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_large, color: EColors.textTertiary, size: 40),
            SizedBox(height: ESizes.sm),
            Text(
              'No items tracked yet',
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: ESizes.xs),
        Text(
          '$label: $value',
          style: const TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
