import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/watch_progress.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../../../shared/widgets/progress_slider.dart';
import '../controllers/progress_controller.dart';

/// Thin inline progress bar, reused in ItemDetailScreen for partial episodes.
class ProgressBar extends StatelessWidget {
  final int totalMinutes;
  final int minutesWatched;
  final double height;

  const ProgressBar({
    super.key,
    required this.totalMinutes,
    required this.minutesWatched,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final value = totalMinutes > 0 ? minutesWatched / totalMinutes : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: EColors.surfaceLight,
        valueColor: const AlwaysStoppedAnimation<Color>(EColors.primary),
        minHeight: height,
      ),
    );
  }
}

/// Renders the full TV season/episode progress list for ItemDetailScreen.
class TvProgressSection extends StatelessWidget {
  final ProgressController controller;

  const TvProgressSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final seasons = controller.seasonProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${EText.seasons} (${seasons.length})',
              style: const TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.w600,
                color: EColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: ESizes.md),
        ...seasons.map((season) => _SeasonCard(
              controller: controller,
              season: season,
            )),
      ],
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final ProgressController controller;
  final SeasonProgress season;

  const _SeasonCard({required this.controller, required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(
          color: season.isComplete
              ? EColors.success.withValues(alpha: 0.3)
              : EColors.border,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: ESizes.md),
        childrenPadding: EdgeInsets.zero,
        leading: GestureDetector(
          onTap: () => _confirmSeasonToggle(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: season.isComplete
                  ? EColors.success.withValues(alpha: 0.2)
                  : EColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
            child: Center(
              child: season.isComplete
                  ? const Icon(Icons.check, color: EColors.success, size: 22)
                  : Text(
                      '${season.seasonNumber}',
                      style: const TextStyle(
                        fontSize: ESizes.fontLg,
                        fontWeight: FontWeight.bold,
                        color: EColors.primary,
                      ),
                    ),
            ),
          ),
        ),
        title: Text(
          'Season ${season.seasonNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
                child: LinearProgressIndicator(
                  value: season.progressPercentage / 100,
                  backgroundColor: EColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    season.isComplete ? EColors.success : EColors.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            Text(
              season.progressText,
              style: const TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.textTertiary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.expand_more, color: EColors.textTertiary),
        children: season.episodes.map((ep) {
          return _EpisodeTile(controller: controller, episode: ep);
        }).toList(),
      ),
    );
  }

  void _confirmSeasonToggle(BuildContext context) {
    final mc = !season.isComplete;
    EConfirmDialog.show(
      title: 'Mark Season ${season.seasonNumber} ${mc ? 'complete' : 'unwatched'}?',
      message: mc
          ? 'All ${season.totalEpisodes} episodes will be marked as watched.'
          : 'All ${season.watchedEpisodes} watched episodes will be unmarked.',
      confirmLabel: mc ? 'Mark Complete' : 'Unmark All',
      isDestructive: !mc,
      onConfirm: () => controller.markSeasonWatched(season.seasonNumber, mc),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final ProgressController controller;
  final WatchProgress episode;

  const _EpisodeTile({required this.controller, required this.episode});

  String _formatMinutes(int m) =>
      m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        episode.episodeOverview != null && episode.episodeOverview!.isNotEmpty;
    final hasPartialProgress = !episode.watched && episode.minutesWatched > 0;

    return Theme(
      data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: episode.hasAired
              ? null
              : EColors.surfaceLight.withValues(alpha: 0.5),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.only(left: ESizes.xl, right: ESizes.md),
          childrenPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: () => controller.toggleWatched(episode.id),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color:
                    episode.watched ? EColors.success : Colors.transparent,
                border: Border.all(
                  color: episode.watched
                      ? EColors.success
                      : EColors.textTertiary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: episode.watched
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                episode.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: ESizes.fontMd,
                  color: episode.watched
                      ? EColors.textSecondary
                      : EColors.textPrimary,
                  decoration:
                      episode.watched ? TextDecoration.lineThrough : null,
                ),
              ),
              if (hasPartialProgress) ...[
                const SizedBox(height: 4),
                ProgressBar(
                  totalMinutes: episode.runtimeMinutes,
                  minutesWatched: episode.minutesWatched,
                  height: 3,
                ),
              ],
            ],
          ),
          subtitle: Text(
            hasPartialProgress
                ? '${episode.episodeCode} • ${episode.airDateDisplay} • ${_formatMinutes(episode.minutesWatched)} of ${_formatMinutes(episode.runtimeMinutes)}'
                : '${episode.episodeCode} • ${episode.airDateDisplay} • ${_formatMinutes(episode.runtimeMinutes)}',
            style: TextStyle(
              fontSize: ESizes.fontXs,
              color: episode.hasAired
                  ? EColors.textTertiary
                  : EColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: ESizes.xl + 28 + ESizes.md, right: ESizes.md, bottom: ESizes.sm),
              child: ProgressSlider(
                totalMinutes: episode.runtimeMinutes,
                minutesWatched: episode.watched
                    ? episode.runtimeMinutes
                    : episode.minutesWatched,
                isWatched: episode.watched,
                compact: true,
                onChanged: (_) {},
                onChangeEnd: (minutes) =>
                    controller.setEpisodeProgress(episode.id, minutes),
              ),
            ),
            if (hasDescription)
              Padding(
                padding: const EdgeInsets.only(left: ESizes.xl + 28 + ESizes.md, right: ESizes.md, bottom: ESizes.md),
                child: Text(
                  episode.episodeOverview!,
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
