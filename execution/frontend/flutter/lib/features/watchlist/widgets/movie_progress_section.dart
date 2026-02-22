import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/widgets/progress_slider.dart';
import '../controllers/progress_controller.dart';

/// Renders the movie progress controls for ItemDetailScreen.
class MovieProgressSection extends StatelessWidget {
  final ProgressController controller;
  final String itemTitle;

  const MovieProgressSection({
    super.key,
    required this.controller,
    required this.itemTitle,
  });

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = controller.movieProgress;
    if (progress == null) return const SizedBox.shrink();

    final currentPercentage = controller.movieProgressPercentage.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          EText.progress,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.md),
        Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: EColors.surface,
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            border: Border.all(color: EColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemTitle,
                          style: const TextStyle(
                            fontSize: ESizes.fontMd,
                            fontWeight: FontWeight.w600,
                            color: EColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: ESizes.xs),
                        Text(
                          '${_formatMinutes(progress.minutesWatched)} of '
                          '${_formatMinutes(progress.runtimeMinutes)} watched',
                          style: const TextStyle(
                            fontSize: ESizes.fontSm,
                            color: EColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$currentPercentage%',
                    style: TextStyle(
                      fontSize: ESizes.fontXl,
                      fontWeight: FontWeight.bold,
                      color: progress.watched
                          ? EColors.success
                          : EColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ESizes.md),
              ProgressSlider(
                totalMinutes: progress.runtimeMinutes,
                minutesWatched: progress.minutesWatched,
                isWatched: progress.watched,
                onChanged: (_) {},
                onChangeEnd: (minutes) =>
                    controller.setMovieProgressMinutes(minutes),
              ),
              const SizedBox(height: ESizes.md),
              Row(
                children: [
                  _buildBtn(controller, 0, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildBtn(controller, 25, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildBtn(controller, 50, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildBtn(controller, 75, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildBtn(controller, 100, currentPercentage),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(
    ProgressController controller,
    int percentage,
    int currentPercentage,
  ) {
    final isSelected = currentPercentage == percentage;
    final isCompleted = percentage == 100;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setMovieProgress(percentage),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? (isCompleted ? EColors.success : EColors.primary)
                : EColors.surfaceLight,
            borderRadius: BorderRadius.circular(ESizes.radiusSm),
            border: Border.all(
              color: isSelected
                  ? (isCompleted ? EColors.success : EColors.primary)
                  : EColors.border,
            ),
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: ESizes.fontSm,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? EColors.textOnPrimary : EColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
