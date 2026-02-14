import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../controllers/search_controller.dart';
import '../screens/search_screen.dart';

class SearchSuggestions extends StatefulWidget {
  const SearchSuggestions({super.key});

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  @override
  void initState() {
    super.initState();
    // Load suggestions when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ContentSearchController.to.loadSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ContentSearchController.to;
      final suggestions = controller.suggestions;
      final isLoading = controller.isLoadingSuggestions;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: EColors.accent,
                  size: 20,
                ),
                const SizedBox(width: ESizes.sm),
                const Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: ESizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (controller.suggestionsLoaded)
                  IconButton(
                    onPressed: controller.refreshSuggestions,
                    icon: const Icon(Icons.refresh, size: 20),
                    color: EColors.textSecondary,
                    tooltip: 'Refresh suggestions',
                  ),
              ],
            ),
          ),
          const SizedBox(height: ESizes.sm),
          // Content
          Expanded(
            child: isLoading && suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                    child: const PosterGridSkeleton(crossAxisCount: 3, itemCount: 9),
                  )
                : suggestions.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: ESizes.sm,
                          mainAxisSpacing: ESizes.md,
                        ),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          return AnimatedListItem(
                            index: index % 9,
                            child: _buildSuggestionCard(suggestions[index]),
                          );
                        },
                      ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter,
            size: 48,
            color: EColors.textTertiary,
          ),
          SizedBox(height: ESizes.md),
          Text(
            'No suggestions available',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(TmdbSearchResult result) {
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
                // Media type badge
                Positioned(
                  top: ESizes.xs,
                  right: ESizes.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ESizes.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: EColors.background.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(ESizes.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          result.mediaType == MediaType.movie
                              ? Icons.movie
                              : Icons.tv,
                          size: 12,
                          color: EColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          result.mediaType == MediaType.movie ? 'Movie' : 'TV',
                          style: const TextStyle(
                            fontSize: 10,
                            color: EColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Rating badge
                if (result.voteAverage > 0)
                  Positioned(
                    bottom: ESizes.xs,
                    left: ESizes.xs,
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
                          const Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.white,
                          ),
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
        child: Icon(
          Icons.movie,
          size: 40,
          color: EColors.textTertiary,
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return Colors.green;
    if (rating >= 5.5) return Colors.orange;
    return Colors.red;
  }
}
