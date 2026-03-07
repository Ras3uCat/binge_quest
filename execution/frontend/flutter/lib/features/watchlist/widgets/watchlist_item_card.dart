import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/streaming_badge.dart';
import '../screens/item_detail_screen.dart';

/// Card widget for displaying a watchlist item in the list.
class WatchlistItemCard extends StatelessWidget {
  final WatchlistItem item;

  const WatchlistItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final progress = item.completionPercentage ?? 0;
    final isCompleted = item.isCompleted;

    return GestureDetector(
      onTap: () => Get.to(() => ItemDetailScreen(item: item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(
            color: isCompleted
                ? EColors.success.withValues(alpha: 0.3)
                : EColors.border,
          ),
        ),
        child: Row(
          children: [
            _buildPoster(isCompleted),
            _buildInfo(progress, isCompleted),
            const Padding(
              padding: EdgeInsets.all(ESizes.md),
              child: Icon(Icons.chevron_right, color: EColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(bool isCompleted) {
    return Hero(
      tag: 'poster-${item.id}',
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(ESizes.radiusMd),
        ),
        child: Stack(
          children: [
            item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: EImages.tmdbPoster(item.posterPath),
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 120,
                    color: EColors.surfaceLight,
                    child: const Icon(Icons.movie, size: 32),
                  ),
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  color: EColors.success.withValues(alpha: 0.7),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
              ),
            // Streaming badge
            Positioned(
              top: 0,
              left: 0,
              child: StreamingBadge(streamingProviders: item.streamingProviders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(double progress, bool isCompleted) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: ESizes.fontMd,
                fontWeight: FontWeight.w600,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.xs),
            _buildMediaTypeBadge(),
            const SizedBox(height: ESizes.sm),
            _buildProgressBar(progress, isCompleted),
            const SizedBox(height: ESizes.xs),
            _buildProgressText(progress, isCompleted),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTypeBadge() {
    return Row(
      children: [
        Icon(
          item.mediaType == MediaType.movie ? Icons.movie : Icons.tv,
          size: 14,
          color: EColors.textTertiary,
        ),
        const SizedBox(width: ESizes.xs),
        Text(
          item.mediaType == MediaType.movie ? 'Movie' : 'TV Show',
          style: const TextStyle(
            fontSize: ESizes.fontXs,
            color: EColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, bool isCompleted) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ESizes.radiusSm),
      child: LinearProgressIndicator(
        value: progress / 100,
        backgroundColor: EColors.surfaceLight,
        valueColor: AlwaysStoppedAnimation<Color>(
          isCompleted ? EColors.success : EColors.primary,
        ),
        minHeight: 6,
      ),
    );
  }

  Widget _buildProgressText(double progress, bool isCompleted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${progress.round()}% complete',
          style: TextStyle(
            fontSize: ESizes.fontXs,
            color: isCompleted ? EColors.success : EColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (!isCompleted)
          Text(
            item.formattedRuntime,
            style: const TextStyle(
              fontSize: ESizes.fontXs,
              color: EColors.textTertiary,
            ),
          ),
      ],
    );
  }
}
