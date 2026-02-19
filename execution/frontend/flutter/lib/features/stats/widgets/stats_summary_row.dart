import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/stats_controller.dart';

/// Compact 2-column summary row shown at the top of the stats screen.
class StatsSummaryRow extends StatelessWidget {
  const StatsSummaryRow({super.key});

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = StatsController.to.statsData;
      final summary = data?.summary;
      final pace = data?.episodePace;

      final paceStr = pace != null && pace.episodesPerDay > 0
          ? '${pace.episodesPerDay.toStringAsFixed(1)} eps/day'
          : '—';

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: ESizes.sm,
        crossAxisSpacing: ESizes.sm,
        childAspectRatio: 2.4,
        children: [
          _SummaryTile(
            icon: Icons.schedule,
            color: EColors.primary,
            value: summary != null
                ? _formatMinutes(summary.minutesWatched)
                : '—',
            label: 'Time Watched',
          ),
          _SummaryTile(
            icon: Icons.play_circle_outline,
            color: EColors.info,
            value: summary != null ? '${summary.episodesWatched}' : '—',
            label: 'Episodes',
          ),
          _SummaryTile(
            icon: Icons.check_circle_outline,
            color: EColors.success,
            value: summary != null ? '${summary.itemsCompleted}' : '—',
            label: 'Completed',
          ),
          _SummaryTile(
            icon: Icons.speed,
            color: EColors.accent,
            value: paceStr,
            label: 'Pace',
          ),
        ],
      );
    });
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: ESizes.iconSm),
          const SizedBox(width: ESizes.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ESizes.fontMd,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: ESizes.fontXs,
                    color: EColors.textSecondary,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
