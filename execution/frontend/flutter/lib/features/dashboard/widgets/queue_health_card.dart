import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/queue_efficiency.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../controllers/queue_health_controller.dart';
import 'time_block_sheet.dart';
import 'efficiency_detail_sheet.dart';
import '../../../shared/widgets/queue_efficiency_guide_sheet.dart';

class QueueHealthCard extends StatelessWidget {
  const QueueHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    if (!Get.isRegistered<QueueHealthController>()) {
      Get.put(QueueHealthController());
    }

    return Obx(() {
      final watchlistCtrl = WatchlistController.to;
      final healthCtrl = QueueHealthController.to;

      if (watchlistCtrl.isLoadingItems || healthCtrl.isLoading) {
        return const QueueHealthCardSkeleton();
      }

      final hoursRemaining = watchlistCtrl.totalHoursRemaining;
      final almostDone = watchlistCtrl.almostDoneCount;
      final totalItems = watchlistCtrl.totalItems;
      final efficiencyScore = healthCtrl.efficiencyScore;
      final rating = healthCtrl.rating;

      return GestureDetector(
        onTap: () => EfficiencyDetailSheet.show(),
        child: Container(
          padding: const EdgeInsets.all(ESizes.lg),
          decoration: BoxDecoration(
            gradient: EColors.primaryGradient,
            borderRadius: BorderRadius.circular(ESizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: EColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        EText.queueHealth,
                        style: TextStyle(
                          fontSize: ESizes.fontLg,
                          fontWeight: FontWeight.w600,
                          color: EColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(width: ESizes.sm),
                      InkWell(
                        onTap: QueueEfficiencyGuideSheet.show,
                        child: Icon(
                          Icons.info_outline,
                          color: EColors.textOnPrimary.withValues(alpha: 0.7),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  // Efficiency badge
                  _buildEfficiencyBadge(efficiencyScore, rating),
                ],
              ),
              const SizedBox(height: ESizes.md),
              Row(
                children: [
                  // Efficiency Score Ring
                  _buildEfficiencyRing(efficiencyScore),
                  const SizedBox(width: ESizes.lg),
                  // Stats
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatRow(
                          Icons.timer,
                          EText.hoursRemaining,
                          hoursRemaining.toString(),
                        ),
                        const SizedBox(height: ESizes.sm),
                        _buildStatRow(
                          Icons.check_circle,
                          EText.almostDone,
                          almostDone.toString(),
                        ),
                        const SizedBox(height: ESizes.sm),
                        _buildStatRow(
                          Icons.list,
                          EText.totalItems,
                          totalItems.toString(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Status breakdown bar
              const SizedBox(height: ESizes.sm),
              _buildStatusBar(healthCtrl),
              const SizedBox(height: ESizes.sm),
              // Time Block Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: TimeBlockSheet.show,
                  icon: const Icon(Icons.timer, size: 16),
                  label: const Text('I Have Time For...'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EColors.textOnPrimary,
                    side: BorderSide(
                      color: EColors.textOnPrimary.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: ESizes.xs),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEfficiencyBadge(int score, EfficiencyRating rating) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.sm,
        vertical: ESizes.xs,
      ),
      decoration: BoxDecoration(
        color: EColors.textOnPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rating.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: ESizes.xs),
          Text(
            rating.label,
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              fontWeight: FontWeight.w600,
              color: EColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyRing(int score) {
    return SizedBox(
      width: ESizes.progressRingMd,
      height: ESizes.progressRingMd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: ESizes.progressRingMd,
            height: ESizes.progressRingMd,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: EColors.textOnPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textOnPrimary,
                ),
              ),
              Text(
                'Score',
                style: TextStyle(
                  fontSize: ESizes.fontXs,
                  color: EColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return EColors.success;
    if (score >= 60) return EColors.textOnPrimary;
    if (score >= 40) return EColors.warning;
    return EColors.error;
  }

  Widget _buildStatusBar(QueueHealthController ctrl) {
    final total = ctrl.totalCount;
    if (total == 0) return const SizedBox.shrink();

    final completed = ctrl.completedCount;
    final active = ctrl.activeCount;
    final idle = ctrl.idleCount;
    final stale = ctrl.staleCount;

    // Calculate percentages based on total items
    final completedPercent = (completed / total) * 100;
    final activePercent = (active / total) * 100;
    final idlePercent = (idle / total) * 100;
    final stalePercent = (stale / total) * 100;

    return Column(
      children: [
        // Status bar
        ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (completedPercent > 0)
                  Flexible(
                    flex: completedPercent.round().clamp(1, 100),
                    child: Container(color: EColors.primary),
                  ),
                if (activePercent > 0)
                  Flexible(
                    flex: activePercent.round().clamp(1, 100),
                    child: Container(color: EColors.success),
                  ),
                if (idlePercent > 0)
                  Flexible(
                    flex: idlePercent.round().clamp(1, 100),
                    child: Container(color: EColors.warning),
                  ),
                if (stalePercent > 0)
                  Flexible(
                    flex: stalePercent.round().clamp(1, 100),
                    child: Container(color: EColors.error),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ESizes.xs),
        // Legend - wrap for smaller screens
        Wrap(
          alignment: WrapAlignment.center,
          spacing: ESizes.sm,
          runSpacing: ESizes.xs,
          children: [
            if (completed > 0)
              _buildLegendItem('Done', EColors.primary, completed),
            _buildLegendItem('Active', EColors.success, active),
            _buildLegendItem('Idle', EColors.warning, idle),
            _buildLegendItem('Stale', EColors.error, stale),
          ],
        ),
        if (ctrl.excludedCount > 0) ...[
          const SizedBox(height: ESizes.xs),
          Text(
            '${ctrl.excludedCount} item${ctrl.excludedCount == 1 ? '' : 's'} excluded (not yet available)',
            style: TextStyle(
              fontSize: ESizes.fontXs,
              color: EColors.textOnPrimary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: ESizes.fontXs,
            color: EColors.textOnPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: EColors.textOnPrimary.withValues(alpha: 0.8),
          size: 18,
        ),
        const SizedBox(width: ESizes.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textOnPrimary.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.bold,
            color: EColors.textOnPrimary,
          ),
        ),
      ],
    );
  }
}
