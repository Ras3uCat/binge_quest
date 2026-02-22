import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/services/share_service.dart';
import '../../../shared/widgets/tv_rating_selector.dart';
import '../controllers/progress_controller.dart';

/// Card shown when a watchlist item is fully completed.
/// Allows the user to rate and share the achievement.
class CompletedRatingCard extends StatelessWidget {
  final ProgressController controller;
  final VoidCallback onEditThoughts;

  const CompletedRatingCard({
    super.key,
    required this.controller,
    required this.onEditThoughts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.check, size: 28, color: Colors.white),
              ),
              const SizedBox(width: ESizes.md),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed!',
                      style: TextStyle(
                        fontSize: ESizes.fontLg,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Rate your experience',
                      style: TextStyle(
                        fontSize: ESizes.fontMd,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.lg),
          Obx(() {
            if (controller.isLoadingReview) {
              return const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            return Column(
              children: [
                TvRatingSelector(
                  rating: controller.userRating,
                  onRatingChanged: (rating) => controller.submitRating(rating),
                  iconColor: Colors.white,
                  selectedColor: Colors.amber,
                ),
                const SizedBox(height: ESizes.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onEditThoughts,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                    ),
                    child: Text(
                      controller.hasReviewText
                          ? 'Edit Your Thoughts'
                          : 'Share Your Thoughts',
                    ),
                  ),
                ),
                const SizedBox(height: ESizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ShareService.to.shareCompletionMilestone(
                      controller.item,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share Achievement'),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// In-progress summary card (shown when item is not yet complete).
// ---------------------------------------------------------------------------

/// Card shown when a watchlist item is in progress or not started.
class InProgressCard extends StatelessWidget {
  final ProgressController controller;

  const InProgressCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final progress = controller.progressPercentage;
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        gradient: EColors.primaryGradient,
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress / 100,
                        strokeWidth: 8,
                        backgroundColor:
                            EColors.textOnPrimary.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            EColors.textOnPrimary),
                      ),
                    ),
                    Text(
                      '${progress.round()}%',
                      style: const TextStyle(
                          fontSize: ESizes.fontXl,
                          fontWeight: FontWeight.bold,
                          color: EColors.textOnPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ESizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isStarted
                          ? EText.inProgress
                          : EText.notStarted,
                      style: const TextStyle(
                          fontSize: ESizes.fontLg,
                          fontWeight: FontWeight.bold,
                          color: EColors.textOnPrimary),
                    ),
                    const SizedBox(height: ESizes.xs),
                    Text(
                      controller.formattedRemaining,
                      style: TextStyle(
                          fontSize: ESizes.fontMd,
                          color:
                              EColors.textOnPrimary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.markAllWatched(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EColors.textOnPrimary,
                    side: BorderSide(
                        color: EColors.textOnPrimary.withValues(alpha: 0.5)),
                  ),
                  child: const Text('Mark All Watched'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
