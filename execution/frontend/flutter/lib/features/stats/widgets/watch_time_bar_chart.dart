import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/stats_data.dart';
import '../controllers/stats_controller.dart';

/// Bar chart showing watch-time trend over the selected window.
class WatchTimeBarChart extends StatelessWidget {
  const WatchTimeBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = StatsController.to.statsData;
      final weekdayData = data?.watchTimeByWeekday ?? [];

      if (weekdayData.isEmpty) {
        return _buildEmptyState();
      }

      return SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            barGroups: _buildBarGroups(weekdayData),
            titlesData: _buildTitles(weekdayData),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: EColors.border, strokeWidth: 0.5),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => EColors.surface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dayData = weekdayData[groupIndex];
                  final minutes = rod.toY.round();
                  final label = minutes >= 60
                      ? '${minutes ~/ 60}h ${minutes % 60}m'
                      : '${minutes}m';
                  return BarTooltipItem(
                    '${dayData.dayName}\n$label',
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
      );
    });
  }

  List<BarChartGroupData> _buildBarGroups(List<WatchTimeWeekday> trend) {
    return trend.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.minutes.toDouble(),
            color: EColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ESizes.radiusXs),
            ),
          ),
        ],
      );
    }).toList();
  }

  FlTitlesData _buildTitles(List<WatchTimeWeekday> trend) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= trend.length) return const SizedBox.shrink();
            final label = trend[i].dayName;
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
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: EColors.textTertiary, size: 40),
            SizedBox(height: ESizes.sm),
            Text(
              'No watch data yet',
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
