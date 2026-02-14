import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/tmdb_person.dart';
import '../../../shared/widgets/shimmer_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../controllers/search_controller.dart';
import '../screens/person_detail_screen.dart';

class PersonResultsGrid extends StatelessWidget {
  const PersonResultsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ContentSearchController.to;
      final results = controller.personResults;
      final isLoading = controller.isLoading;
      final error = controller.error;
      final query = controller.searchQuery;

      // Empty state - no search yet
      if (query.isEmpty && results.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.person_search_rounded,
          title: EText.searchPeopleHint,
          subtitle: 'Find actors, directors, and more',
        );
      }

      // Loading state
      if (isLoading && results.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(ESizes.lg),
          child: _PersonGridSkeleton(),
        );
      }

      // Error state
      if (error != null && results.isEmpty) {
        return ErrorStateWidget(
          title: error,
          onRetry: () {
            final controller = ContentSearchController.to;
            controller.search(controller.searchQuery);
          },
        );
      }

      // No results
      if (results.isEmpty) {
        return EmptyStateWidget.noResults(query: query);
      }

      // Results grid
      return GridView.builder(
        padding: const EdgeInsets.all(ESizes.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: ESizes.md,
          mainAxisSpacing: ESizes.md,
        ),
        itemCount: results.length + (controller.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more indicator
          if (index == results.length) {
            controller.loadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(ESizes.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return AnimatedListItem(
            index: index % 6,
            child: _PersonCard(person: results[index]),
          );
        },
      );
    });
  }
}

/// Person card skeleton for loading state.
class _PersonGridSkeleton extends StatelessWidget {
  const _PersonGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: ESizes.md,
        mainAxisSpacing: ESizes.md,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => const _PersonCardSkeleton(),
    );
  }
}

class _PersonCardSkeleton extends StatelessWidget {
  const _PersonCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: EColors.shimmerBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ESizes.radiusMd),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(ESizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 100, height: 14),
                    const SizedBox(height: ESizes.xs),
                    ShimmerText(width: 60, height: 10),
                    const Spacer(),
                    ShimmerText(width: 120, height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final TmdbPersonSearchResult person;

  const _PersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PersonDetailScreen(personId: person.id)),
      child: Container(
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ESizes.radiusMd),
                ),
                child: person.profilePath != null
                    ? CachedNetworkImage(
                        imageUrl: EImages.tmdbProfile(person.profilePath),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(ESizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: ESizes.fontMd,
                        fontWeight: FontWeight.w600,
                        color: EColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Department
                    if (person.knownForDepartment != null)
                      Text(
                        person.knownForDepartment!,
                        style: const TextStyle(
                          fontSize: ESizes.fontXs,
                          color: EColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    // Known for
                    if (person.knownFor.isNotEmpty)
                      Text(
                        person.knownFor.map((k) => k.displayTitle).take(2).join(', '),
                        style: const TextStyle(
                          fontSize: ESizes.fontXs,
                          color: EColors.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: EColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 48,
          color: EColors.textTertiary,
        ),
      ),
    );
  }
}
