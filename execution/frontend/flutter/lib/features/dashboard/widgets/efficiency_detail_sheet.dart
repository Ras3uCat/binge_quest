import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watchlist_item.dart';
import '../controllers/queue_health_controller.dart';

/// Bottom sheet showing detailed queue efficiency information.
class EfficiencyDetailSheet extends StatelessWidget {
  const EfficiencyDetailSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const EfficiencyDetailSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESizes.lg),
              child: Obx(() {
                final ctrl = QueueHealthController.to;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(ctrl),
                    const SizedBox(height: ESizes.xl),
                    _buildScoreSection(ctrl),
                    const SizedBox(height: ESizes.xl),
                    _buildBreakdownSection(ctrl),
                    if (ctrl.staleItems.isNotEmpty) ...[
                      const SizedBox(height: ESizes.xl),
                      _buildStaleItemsSection(ctrl),
                    ],
                    const SizedBox(height: ESizes.xl),
                    _buildTipsSection(ctrl),
                    const SizedBox(height: ESizes.lg),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: ESizes.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: EColors.border,
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
    );
  }

  Widget _buildHeader(QueueHealthController ctrl) {
    final rating = ctrl.rating;
    return Row(
      children: [
        Text(
          rating.emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: ESizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Queue Efficiency',
                style: TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
              Text(
                rating.message,
                style: const TextStyle(
                  fontSize: ESizes.fontSm,
                  color: EColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(QueueHealthController ctrl) {
    final score = ctrl.efficiencyScore;
    final rating = ctrl.rating;

    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        gradient: EColors.primaryGradient,
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
      ),
      child: Row(
        children: [
          // Large score display
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: EColors.textOnPrimary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(score),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: EColors.textOnPrimary,
                      ),
                    ),
                    Text(
                      'Score',
                      style: TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: ESizes.lg),
          // Score breakdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.label,
                  style: const TextStyle(
                    fontSize: ESizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: EColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: ESizes.sm),
                _buildScoreDetail(
                  'Completion Rate',
                  '${ctrl.completionRate.toStringAsFixed(1)}%',
                ),
                _buildScoreDetail(
                  'Recent Completions',
                  '+${ctrl.recentCompletions}',
                ),
                _buildScoreDetail(
                  'Stale Penalty',
                  '-${ctrl.staleCount * 2}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ESizes.fontSm,
              color: EColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
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

  Widget _buildBreakdownSection(QueueHealthController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Queue Breakdown',
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.bold,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.md),
        _buildStatusCard(
          'Active',
          'Watched in last 7 days',
          ctrl.activeCount,
          EColors.success,
          Icons.play_circle,
        ),
        const SizedBox(height: ESizes.sm),
        _buildStatusCard(
          'Idle',
          'No activity for 7-30 days',
          ctrl.idleCount,
          EColors.warning,
          Icons.pause_circle,
        ),
        const SizedBox(height: ESizes.sm),
        _buildStatusCard(
          'Stale',
          'No activity for 30+ days',
          ctrl.staleCount,
          EColors.error,
          Icons.remove_circle,
        ),
        const SizedBox(height: ESizes.sm),
        _buildStatusCard(
          'Completed',
          'Finished watching',
          ctrl.completedCount,
          EColors.primary,
          Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String title,
    String subtitle,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESizes.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: ESizes.fontMd,
                    fontWeight: FontWeight.w600,
                    color: EColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: ESizes.fontXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaleItemsSection(QueueHealthController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: EColors.warning, size: 20),
            const SizedBox(width: ESizes.sm),
            const Text(
              'Needs Attention',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: ESizes.sm),
        const Text(
          'These items have been sitting in your queue. Consider finishing or removing them.',
          style: TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textSecondary,
          ),
        ),
        const SizedBox(height: ESizes.md),
        ...ctrl.staleItems.map((item) => _buildStaleItem(item)),
      ],
    );
  }

  Widget _buildStaleItem(WatchlistItem item) {
    final daysStale = item.daysSinceActivity;
    final progress = item.completionPercentage ?? 0;

    // Format the idle message
    String idleMessage;
    if (item.lastActivityAt == null) {
      idleMessage = 'Never started';
    } else if (daysStale >= 365) {
      final years = daysStale ~/ 365;
      idleMessage = '$years ${years == 1 ? 'year' : 'years'} idle';
    } else if (daysStale >= 30) {
      final months = daysStale ~/ 30;
      idleMessage = '$months ${months == 1 ? 'month' : 'months'} idle';
    } else {
      idleMessage = '$daysStale days idle';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.sm),
      padding: const EdgeInsets.all(ESizes.sm),
      decoration: BoxDecoration(
        color: EColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.radiusSm),
            child: item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: EImages.tmdbPoster(item.posterPath, size: 'w92'),
                    width: 45,
                    height: 65,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 45,
                    height: 65,
                    color: EColors.surfaceLight,
                    child: const Icon(Icons.movie, color: EColors.textTertiary),
                  ),
          ),
          const SizedBox(width: ESizes.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: ESizes.fontMd,
                    fontWeight: FontWeight.w600,
                    color: EColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  idleMessage,
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: EColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(EColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ESizes.sm),
          // Progress text
          Text(
            '${progress.round()}%',
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              fontWeight: FontWeight.w600,
              color: EColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(QueueHealthController ctrl) {
    final tips = _getTips(ctrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: EColors.accent, size: 20),
            SizedBox(width: ESizes.sm),
            Text(
              'Tips to Improve',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: ESizes.md),
        ...tips.map((tip) => _buildTip(tip)),
      ],
    );
  }

  List<String> _getTips(QueueHealthController ctrl) {
    final tips = <String>[];

    if (ctrl.staleCount > 0) {
      tips.add('Focus on your ${ctrl.staleCount} stale items - pick one to finish or remove it.');
    }

    if (ctrl.idleCount > ctrl.activeCount) {
      tips.add('Try watching something from your idle list to keep things moving.');
    }

    if (ctrl.recentCompletions == 0) {
      tips.add('Completing items gives you a score bonus! Finish something this week.');
    }

    if (ctrl.totalCount > 20) {
      tips.add('Consider trimming your queue - a focused list is easier to complete.');
    }

    if (tips.isEmpty) {
      tips.add('Keep up the great work! Consistent watching improves your score.');
    }

    return tips;
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: ESizes.fontMd,
              color: EColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textSecondary,
              ),
            ),
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
}
