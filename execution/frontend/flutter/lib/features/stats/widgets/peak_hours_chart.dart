import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/stats_data.dart';
import '../controllers/stats_controller.dart';

/// Bar chart showing viewing activity across all 24 hours.
class PeakHoursChart extends StatelessWidget {
  const PeakHoursChart({super.key});

  String _hourLabel(int hour) {
    if (hour == 0) return '12am';
    if (hour == 6) return '6am';
    if (hour == 12) return '12pm';
    if (hour == 18) return '6pm';
    return '';
  }

  String _peakLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = StatsController.to.statsData;
      final peaks = data?.peakHours ?? [];

      final allZero = peaks.every((p) => p.minutes == 0);
      if (peaks.isEmpty || allZero) {
        return _buildEmptyState();
      }

      // Build a full 24-hour list; fill gaps with 0.
      final hourMap = {for (final p in peaks) p.hour: p.minutes};
      final hours = List.generate(24, (i) => PeakHour(hour: i, minutes: hourMap[i] ?? 0));

      // Find peak hour for callout.
      final peakHour = hours.reduce((a, b) => a.minutes >= b.minutes ? a : b);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: hours.map((h) {
                  return BarChartGroupData(
                    x: h.hour,
                    barRods: [
                      BarChartRodData(
                        toY: h.minutes.toDouble(),
                        color: EColors.accent,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(ESizes.radiusXs),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final label = _hourLabel(value.toInt());
                        if (label.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: EColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: EColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => EColors.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final mins = rod.toY.round();
                      return BarTooltipItem(
                        '${_peakLabel(group.x)}  ${mins}m',
                        const TextStyle(
                          color: EColors.textPrimary,
                          fontSize: ESizes.fontXs,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (peakHour.minutes > 0) ...[
            const SizedBox(height: ESizes.sm),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: ESizes.iconXs, color: EColors.accent),
                const SizedBox(width: ESizes.xs),
                Text(
                  'You watch most at ${_peakLabel(peakHour.hour)}',
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, color: EColors.textTertiary, size: 40),
            SizedBox(height: ESizes.sm),
            Text(
              'No peak hour data yet',
              style: TextStyle(
                  color: EColors.textSecondary, fontSize: ESizes.fontSm),
            ),
          ],
        ),
      ),
    );
  }
}
