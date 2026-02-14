import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/streaming_badge.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../../watchlist/screens/watchlist_screen.dart';

class FinishFastSection extends StatelessWidget {
  const FinishFastSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              EText.finishFast,
              style: TextStyle(
                fontSize: ESizes.fontXl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const WatchlistScreen()),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: ESizes.md),
        Obx(() {
          final controller = WatchlistController.to;

          if (controller.isLoadingItems) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final items = controller.finishFastItems;

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildItemCard(items[index]);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 48, color: EColors.textTertiary),
            SizedBox(height: ESizes.md),
            Text(
              EText.emptyWatchlist,
              style: TextStyle(
                fontSize: ESizes.fontLg,
                color: EColors.textSecondary,
              ),
            ),
            SizedBox(height: ESizes.xs),
            Text(
              EText.addSomething,
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(WatchlistItem item) {
    return GestureDetector(
      onTap: () => Get.to(() => ItemDetailScreen(item: item)),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ESizes.radiusMd),
                    child: item.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: EImages.tmdbPoster(item.posterPath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: EColors.surfaceLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholderPoster(),
                          )
                        : _buildPlaceholderPoster(),
                  ),
                  // Top left: Media type indicator
                  Positioned(
                    top: ESizes.xs,
                    left: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: EColors.background.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                      ),
                      child: Icon(
                        item.mediaType == MediaType.movie
                            ? Icons.movie
                            : Icons.tv,
                        size: 14,
                        color: EColors.textSecondary,
                      ),
                    ),
                  ),
                  // Top right: Streaming badge
                  Positioned(
                    top: 0,
                    right: 0,
                    child: StreamingBadge(streamingProviders: item.streamingProviders),
                  ),
                  // Bottom right: Runtime badge
                  Positioned(
                    bottom: ESizes.xs,
                    right: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EColors.accent,
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                      ),
                      child: Text(
                        item.formattedRuntime,
                        style: const TextStyle(
                          fontSize: ESizes.fontXs,
                          fontWeight: FontWeight.bold,
                          color: EColors.textOnAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESizes.xs),
            // Title
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                fontWeight: FontWeight.w500,
                color: EColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: double.infinity,
      color: EColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.movie, size: 40, color: EColors.textTertiary),
      ),
    );
  }
}
