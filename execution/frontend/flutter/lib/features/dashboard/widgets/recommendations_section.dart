import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/streaming_badge.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../../watchlist/screens/watchlist_screen.dart';
import '../../search/screens/search_screen.dart';
import 'filter_bar.dart';
import 'mood_filter_chips.dart';
import 'recommendation_mode_selector.dart';
import '../../../shared/widgets/mood_guide_sheet.dart';

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final mode = WatchlistController.to.recommendationMode;
          return Padding(
            padding: const EdgeInsets.only(left: ESizes.lg, right: ESizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mode.displayName,
                  style: const TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final controller = WatchlistController.to;
                    // Sync sort mode from current recommendation mode
                    controller.setSortMode(
                      controller.sortModeFromRecommendation(
                        controller.recommendationMode,
                      ),
                    );
                    // Moods already synced via shared controller
                    Get.to(() => const WatchlistScreen());
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: ESizes.sm),
        const RecommendationModeSelector(),
        const SizedBox(height: ESizes.md),
        // Mood filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mood',
                style: TextStyle(
                  fontSize: ESizes.fontSm,
                  color: EColors.textSecondary,
                ),
              ),
              InkWell(
                onTap: MoodGuideSheet.show,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: EColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ESizes.xs),
        const MoodFilterChips(),
        const SizedBox(height: ESizes.sm),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: FilterBar(),
        ),
        const SizedBox(height: ESizes.md),
        Obx(() {
          final controller = WatchlistController.to;

          if (controller.isLoadingItems) {
            return const PosterListSkeleton(count: 4, height: 200);
          }

          final items = controller.recommendedItems;

          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              child: _buildEmptyState(),
            );
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AnimatedListItem(
                  index: index,
                  slideDirection: Axis.horizontal,
                  child: _buildItemCard(items[index]),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = WatchlistController.to.hasActiveFilters;

    if (hasFilters) {
      return Container(
        width: double.infinity,
        height: 183,
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.border),
        ),
        child: EmptyStateWidget(
          icon: Icons.filter_list_off,
          title: 'No matches for current filters',
          actionLabel: 'Clear Filters',
          onAction: () => WatchlistController.to.clearFilters(),
          compact: true,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 183,
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: EmptyStateWidget(
        icon: Icons.lightbulb_outline_rounded,
        title: 'No recommendations yet',
        subtitle: 'Add some content to your watchlist to get started',
        actionLabel: 'Add Your First Title',
        onAction: () => Get.to(() => const SearchScreen()),
        compact: true,
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
                  Hero(
                    tag: 'poster-${item.id}',
                    child: ClipRRect(
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
                    child: StreamingBadge(
                      streamingProviders: item.streamingProviders,
                    ),
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
            // Title - constrained to prevent overflow
            SizedBox(
              height: 36, // Fixed height for 2 lines of text
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: ESizes.fontSm,
                  fontWeight: FontWeight.w500,
                  color: EColors.textPrimary,
                ),
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
