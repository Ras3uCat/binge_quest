import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/friends_watching_row.dart';
import '../controllers/progress_controller.dart';

/// Info row at the top of ItemDetailScreen (poster + stats).
class ItemDetailInfoSection extends StatelessWidget {
  final WatchlistItem item;
  final ProgressController controller;
  final VoidCallback onPosterTap;

  const ItemDetailInfoSection({
    super.key,
    required this.item,
    required this.controller,
    required this.onPosterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPoster(),
        const SizedBox(width: ESizes.md),
        Expanded(child: _buildStats()),
      ],
    );
  }

  Widget _buildPoster() {
    return GestureDetector(
      onTap: onPosterTap,
      child: Stack(
        children: [
          Hero(
            tag: 'poster-${item.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.radiusMd),
              child: item.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: EImages.tmdbPoster(item.posterPath, size: 'w185'),
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 100,
                        height: 150,
                        color: EColors.surfaceLight,
                        child: const Icon(Icons.movie, size: 40),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 150,
                      color: EColors.surfaceLight,
                      child: const Icon(Icons.movie, size: 40),
                    ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: EColors.background.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: const Icon(Icons.info_outline,
                  size: 16, color: EColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mediaTypeBadge(),
        if (item.mediaType == MediaType.movie && item.releaseDate != null) ...[
          const SizedBox(height: ESizes.sm),
          Text(
            'Released: ${DateFormat.yMMMd().format(item.releaseDate!)}',
            style: const TextStyle(
                fontSize: ESizes.fontXs, color: EColors.textSecondary),
          ),
        ],
        const SizedBox(height: ESizes.md),
        _stat(Icons.timer, 'Total: ${_fmt(controller.totalMinutes)}'),
        const SizedBox(height: ESizes.xs),
        _stat(Icons.check_circle_outline,
            'Watched: ${_fmt(controller.watchedMinutes)}'),
        const SizedBox(height: ESizes.xs),
        _stat(Icons.schedule, 'Remaining: ${_fmt(controller.remainingMinutes)}'),
        if (controller.isTvShow) ...[
          const SizedBox(height: ESizes.xs),
          _stat(Icons.list,
              '${controller.watchedEpisodes}/${controller.totalEpisodes} episodes'),
        ],
        const SizedBox(height: ESizes.xs),
        _userCountRow(),
        _friendsWatchingRow(),
      ],
    );
  }

  Widget _mediaTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.mediaType == MediaType.movie ? Icons.movie : Icons.tv,
            size: 14,
            color: EColors.primary,
          ),
          const SizedBox(width: ESizes.xs),
          Text(
            item.mediaType == MediaType.movie ? 'Movie' : 'TV Show',
            style: const TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.primary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _userCountRow() {
    return FutureBuilder<int>(
      future: WatchlistRepository.getUserCount(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) return const SizedBox.shrink();
        return _stat(
          Icons.people,
          '${formatCompactNumber(snapshot.data!)} '
              '${snapshot.data == 1 ? 'user' : 'users'} watching',
        );
      },
    );
  }

  Widget _friendsWatchingRow() {
    return Obx(() {
      final friends = controller.friendsWatching;
      if (friends.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: ESizes.sm),
        child: FriendsWatchingRow(friends: friends),
      );
    });
  }

  Widget _stat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: EColors.textSecondary),
        const SizedBox(width: ESizes.xs),
        Text(text,
            style: const TextStyle(
                fontSize: ESizes.fontSm, color: EColors.textSecondary)),
      ],
    );
  }

  String _fmt(int minutes) {
    if (minutes >= 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '${minutes}m';
  }
}
