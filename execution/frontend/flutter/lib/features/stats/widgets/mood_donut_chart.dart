import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/mood_tag.dart';
import '../controllers/stats_controller.dart';

/// Donut chart showing mood distribution of watched content.
class MoodDonutChart extends StatefulWidget {
  const MoodDonutChart({super.key});

  @override
  State<MoodDonutChart> createState() => _MoodDonutChartState();
}

class _MoodDonutChartState extends State<MoodDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final moodStats = StatsController.to.moodStats;

      final total = moodStats.values.fold(0, (s, m) => s + m.totalMinutes);

      if (total == 0) {
        return _buildEmptyState();
      }

      final moods = MoodTag.values;
      final sections = moods.asMap().entries.map((entry) {
        final i = entry.key;
        final mood = entry.value;
        final stats = moodStats[mood]!;
        final isTouched = _touchedIndex == i;

        return PieChartSectionData(
          value: stats.totalMinutes.toDouble(),
          color: mood.color,
          radius: isTouched ? 64.0 : 56.0,
          title: '',
          showTitle: false,
        );
      }).toList();

      final touchedMood = _touchedIndex != null && _touchedIndex! < moods.length
          ? moods[_touchedIndex!]
          : null;
      final touchedStats = touchedMood != null ? moodStats[touchedMood] : null;
      final pct = touchedStats != null && total > 0
          ? (touchedStats.totalMinutes / total * 100).round()
          : null;

      return Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null ||
                        response.touchedSection!.touchedSectionIndex == -1) {
                      setState(() => _touchedIndex = null);
                      return;
                    }
                    setState(() {
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: ESizes.md),
          if (touchedMood != null && pct != null)
            _buildTouchLabel(touchedMood, pct)
          else
            _buildLegend(moodStats, total),
        ],
      );
    });
  }

  Widget _buildTouchLabel(MoodTag mood, int pct) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(mood.icon, color: mood.color, size: ESizes.iconSm),
        const SizedBox(width: ESizes.xs),
        Text(
          '${mood.displayName}  $pct%',
          style: TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.bold,
            color: mood.color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Map<MoodTag, dynamic> moodStats, int total) {
    return Wrap(
      spacing: ESizes.md,
      runSpacing: ESizes.xs,
      alignment: WrapAlignment.center,
      children: MoodTag.values.map((mood) {
        final stats = moodStats[mood];
        if (stats == null || (stats.totalMinutes as int) == 0) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: mood.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: ESizes.xs),
            Text(
              mood.displayName,
              style: const TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.pie_chart_outline,
              color: EColors.textTertiary,
              size: 40,
            ),
            SizedBox(height: ESizes.sm),
            Text(
              'No mood data yet',
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
