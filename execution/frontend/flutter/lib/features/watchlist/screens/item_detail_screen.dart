import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/models/watch_progress.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../core/services/share_service.dart';
import '../controllers/progress_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../search/widgets/content_detail_sheet.dart';
import '../../../shared/widgets/progress_slider.dart';
import '../../../shared/widgets/tv_rating_selector.dart';
import '../../search/widgets/review_form_sheet.dart';
import '../widgets/move_item_sheet.dart';
import '../../../shared/widgets/friends_watching_row.dart';

class ItemDetailScreen extends StatelessWidget {
  final WatchlistItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProgressController(item: item), tag: item.id);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [EColors.backgroundSecondary, EColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, controller),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: EColors.primary),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.loadProgress,
                    color: EColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(ESizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildItemInfo(controller),
                          const SizedBox(height: ESizes.lg),
                          _buildProgressCard(controller),
                          const SizedBox(height: ESizes.lg),
                          if (controller.isMovie)
                            _buildMovieProgress(controller)
                          else
                            _buildTvProgress(controller),
                          const SizedBox(height: ESizes.xl),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProgressController controller) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: ESizes.fontXl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: EColors.textSecondary),
            color: EColors.surface,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(
                      Icons.drive_file_move_outlined,
                      color: EColors.textPrimary,
                      size: 20,
                    ),
                    SizedBox(width: ESizes.sm),
                    Text(
                      EText.moveTo,
                      style: TextStyle(color: EColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: EColors.error, size: 20),
                    SizedBox(width: ESizes.sm),
                    Text(
                      'Remove from Watchlist',
                      style: TextStyle(color: EColors.error),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'move') {
                _showMoveSheet(context);
              } else if (value == 'remove') {
                _confirmRemove();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo(ProgressController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster - tappable to show TMDB info
        GestureDetector(
          onTap: _showTmdbInfo,
          child: Stack(
            children: [
              Hero(
                tag: 'poster-${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ESizes.radiusMd),
                  child: item.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: EImages.tmdbPoster(
                            item.posterPath,
                            size: 'w185',
                          ),
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          height: 150,
                          color: EColors.surfaceLight,
                          child: const Icon(Icons.movie, size: 40),
                        ),
                ),
              ),
              // Info icon overlay
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: EColors.background.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(ESizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: EColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: ESizes.md),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media type
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: EColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ESizes.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.mediaType == MediaType.movie
                          ? Icons.movie
                          : Icons.tv,
                      size: 14,
                      color: EColors.primary,
                    ),
                    const SizedBox(width: ESizes.xs),
                    Text(
                      item.mediaType == MediaType.movie ? 'Movie' : 'TV Show',
                      style: const TextStyle(
                        fontSize: ESizes.fontXs,
                        color: EColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.mediaType == MediaType.movie &&
                  item.releaseDate != null) ...[
                const SizedBox(height: ESizes.sm),
                Text(
                  'Released: ${DateFormat.yMMMd().format(item.releaseDate!)}',
                  style: const TextStyle(
                    fontSize: ESizes.fontXs,
                    color: EColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: ESizes.md),
              // Stats
              _buildStatRow(
                Icons.timer,
                'Total: ${_formatMinutes(controller.totalMinutes)}',
              ),
              const SizedBox(height: ESizes.xs),
              _buildStatRow(
                Icons.check_circle_outline,
                'Watched: ${_formatMinutes(controller.watchedMinutes)}',
              ),
              const SizedBox(height: ESizes.xs),
              _buildStatRow(
                Icons.schedule,
                'Remaining: ${_formatMinutes(controller.remainingMinutes)}',
              ),
              if (controller.isTvShow) ...[
                const SizedBox(height: ESizes.xs),
                _buildStatRow(
                  Icons.list,
                  '${controller.watchedEpisodes}/${controller.totalEpisodes} episodes',
                ),
              ],
              const SizedBox(height: ESizes.xs),
              _buildUserCountRow(),
              _buildFriendsWatchingRow(controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCountRow() {
    return FutureBuilder<int>(
      future: WatchlistRepository.getUserCount(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox.shrink();
        }
        return _buildStatRow(
          Icons.people,
          '${formatCompactNumber(snapshot.data!)} ${snapshot.data == 1 ? 'user' : 'users'} watching',
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: EColors.textSecondary),
        const SizedBox(width: ESizes.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsWatchingRow(ProgressController controller) {
    return Obx(() {
      final friends = controller.friendsWatching;
      if (friends.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: ESizes.sm),
        child: FriendsWatchingRow(friends: friends),
      );
    });
  }

  Widget _buildProgressCard(ProgressController controller) {
    if (controller.isComplete) {
      return _CompletedRatingCard(
        controller: controller,
        onEditThoughts: () => _openReviewForm(controller),
      );
    }

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
              // Progress ring
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
                        backgroundColor: EColors.textOnPrimary.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          EColors.textOnPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${progress.round()}%',
                      style: const TextStyle(
                        fontSize: ESizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: EColors.textOnPrimary,
                      ),
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
                        color: EColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: ESizes.xs),
                    Text(
                      controller.formattedRemaining,
                      style: TextStyle(
                        fontSize: ESizes.fontMd,
                        color: EColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
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
                      color: EColors.textOnPrimary.withValues(alpha: 0.5),
                    ),
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

  void _openReviewForm(ProgressController controller) async {
    final result = await Get.bottomSheet<bool>(
      ReviewFormSheet(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
        initialRating: controller.userRating,
        initialText: controller.userReviewText,
      ),
      isScrollControlled: true,
      backgroundColor: EColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );

    if (result == true) {
      controller.loadUserReview();
    }
  }

  // Progress UI Helpers
  Widget _buildMovieProgress(ProgressController controller) {
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
                          item.title,
                          style: const TextStyle(
                            fontSize: ESizes.fontMd,
                            fontWeight: FontWeight.w600,
                            color: EColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: ESizes.xs),
                        Text(
                          '${_formatMinutes(progress.minutesWatched)} of ${_formatMinutes(progress.runtimeMinutes)} watched',
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
                  _buildProgressButton(controller, 0, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildProgressButton(controller, 25, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildProgressButton(controller, 50, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildProgressButton(controller, 75, currentPercentage),
                  const SizedBox(width: ESizes.sm),
                  _buildProgressButton(controller, 100, currentPercentage),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressButton(
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
                color: isSelected
                    ? EColors.textOnPrimary
                    : EColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTvProgress(ProgressController controller) {
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
        ...seasons.map((season) => _buildSeasonCard(controller, season)),
      ],
    );
  }

  Widget _buildSeasonCard(
    ProgressController controller,
    SeasonProgress season,
  ) {
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
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: season.isComplete
                ? EColors.success.withValues(alpha: 0.2)
                : EColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(ESizes.radiusSm),
          ),
          child: Center(
            child: Text(
              '${season.seasonNumber}',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: season.isComplete ? EColors.success : EColors.primary,
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
        children: season.episodes.map((episode) {
          return _buildEpisodeTile(controller, episode);
        }).toList(),
      ),
    );
  }

  Widget _buildEpisodeTile(
    ProgressController controller,
    WatchProgress episode,
  ) {
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
          tilePadding: const EdgeInsets.only(left: ESizes.xl, right: ESizes.md),
          childrenPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: () => controller.toggleWatched(episode.id),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: episode.watched ? EColors.success : Colors.transparent,
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
                  decoration: episode.watched
                      ? TextDecoration.lineThrough
                      : null,
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
              padding: const EdgeInsets.only(
                left: ESizes.xl + 28 + ESizes.md,
                right: ESizes.md,
                bottom: ESizes.sm,
              ),
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
                padding: const EdgeInsets.only(
                  left: ESizes.xl + 28 + ESizes.md,
                  right: ESizes.md,
                  bottom: ESizes.md,
                ),
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

  void _showTmdbInfo() {
    final isMovie = item.mediaType == MediaType.movie;
    final result = TmdbSearchResult(
      id: item.tmdbId,
      mediaTypeString: item.mediaType.name,
      titleField: isMovie ? item.title : null,
      name: !isMovie ? item.title : null,
      posterPath: item.posterPath,
      overview: null,
      releaseDate: isMovie
          ? item.releaseDate?.toIso8601String().split('T').first
          : null,
      firstAirDate: !isMovie
          ? item.releaseDate?.toIso8601String().split('T').first
          : null,
      voteAverage: 0,
    );

    if (!Get.isRegistered<ContentSearchController>()) {
      Get.put(ContentSearchController());
    }

    Get.bottomSheet(
      ContentDetailSheet(result: result, showWatchlistAction: false),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showMoveSheet(BuildContext context) {
    final watchlistController = WatchlistController.to;
    final currentWatchlist = watchlistController.currentWatchlist;

    MoveItemSheet.show(
      context: context,
      item: item,
      currentWatchlistId: item.watchlistId,
      currentWatchlistName: currentWatchlist?.name ?? 'Watchlist',
    );
  }

  void _confirmRemove() {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          EText.removeFromWatchlist,
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: Text(
          'Remove "${item.title}" from your watchlist?',
          style: const TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(EText.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await WatchlistController.to.removeItem(item.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: EColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '${minutes}m';
  }
}

/// Simplified and specialized card for completed items.
class _CompletedRatingCard extends StatelessWidget {
  final ProgressController controller;
  final VoidCallback onEditThoughts;

  const _CompletedRatingCard({
    required this.controller,
    required this.onEditThoughts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EColors.success, Color(0xFF1B5E20)],
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
