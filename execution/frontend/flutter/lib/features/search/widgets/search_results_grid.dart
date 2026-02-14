import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/streaming_badge.dart';
import '../controllers/search_controller.dart';
import '../screens/search_screen.dart';

class SearchResultsGrid extends StatelessWidget {
  const SearchResultsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ContentSearchController.to;
      final results = controller.filteredResults;
      final isLoading = controller.isLoading;
      final error = controller.error;
      final query = controller.searchQuery;

      // Initial state - no search yet
      if (query.isEmpty && results.isEmpty && !isLoading) {
        return _buildInitialState();
      }

      // Loading state
      if (isLoading && results.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: const PosterGridSkeleton(crossAxisCount: 3, itemCount: 9),
        );
      }

      // Error state
      if (error != null && results.isEmpty) {
        return _buildErrorState(error);
      }

      // Empty results
      if (results.isEmpty && query.isNotEmpty) {
        return _buildEmptyState();
      }

      // Results grid
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 200) {
              controller.loadMore();
            }
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.55,
            crossAxisSpacing: ESizes.sm,
            mainAxisSpacing: ESizes.md,
          ),
          itemCount: results.length + (controller.hasMorePages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= results.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(ESizes.md),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return AnimatedListItem(
              index:
                  index %
                  9, // Reset animation index every 9 items for smoother scroll
              child: _buildResultCard(results[index]),
            );
          },
        ),
      );
    });
  }

  Widget _buildInitialState() {
    return const EmptyStateWidget(
      icon: Icons.search_rounded,
      title: 'Search for movies & TV shows',
      subtitle: 'Add them to your watchlist',
    );
  }

  Widget _buildEmptyState() {
    final query = ContentSearchController.to.searchQuery;
    return EmptyStateWidget.noResults(query: query);
  }

  Widget _buildErrorState(String error) {
    return ErrorStateWidget(
      title: error,
      subtitle: 'Please try again',
      onRetry: () {
        final controller = ContentSearchController.to;
        controller.search(controller.searchQuery);
      },
    );
  }

  Widget _buildResultCard(TmdbSearchResult result) {
    final controller = ContentSearchController.to;
    final streamingProviders = controller.getStreamingProviders(result.id);

    return GestureDetector(
      onTap: () => showContentDetailSheet(result),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ESizes.radiusMd),
                  child: result.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: EImages.tmdbPoster(result.posterPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: EColors.surfaceLight,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholderPoster(),
                        )
                      : _buildPlaceholderPoster(),
                ),
                // Top left: Media type badge
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
                      result.mediaType == MediaType.movie
                          ? Icons.movie
                          : Icons.tv,
                      size: 14,
                      color: EColors.textSecondary,
                    ),
                  ),
                ),
                // Top right: Streaming badge
                if (streamingProviders != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: StreamingBadge(streamingProviders: streamingProviders),
                  ),
                // Bottom right: Rating badge
                if (result.voteAverage > 0)
                  Positioned(
                    bottom: ESizes.xs,
                    right: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(result.voteAverage),
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            result.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ESizes.xs),
          // Title
          Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              fontWeight: FontWeight.w500,
              color: EColors.textPrimary,
            ),
          ),
          // Year
          if (result.year != null)
            Text(
              result.year!,
              style: const TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: EColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.movie, size: 40, color: EColors.textTertiary),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return Colors.green;
    if (rating >= 5.5) return Colors.orange;
    return Colors.red;
  }
}
