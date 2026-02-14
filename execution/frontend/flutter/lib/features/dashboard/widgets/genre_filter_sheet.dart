import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/content_genre.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

class GenreFilterSheet extends StatelessWidget {
  const GenreFilterSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const GenreFilterSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    // Sectioned Obx Pattern: Each section has its own Obx
    // This prevents cascading rebuilds that cause semantics assertion errors
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const SizedBox(height: ESizes.md),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: ESizes.md),
              child: Obx(() => _buildGenreGrid()),
            ),
          ),
          Obx(() => _buildActions()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: ESizes.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: EColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.lg, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESizes.sm),
            decoration: BoxDecoration(
              color: EColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ESizes.radiusMd),
            ),
            child: const Icon(Icons.category, color: EColors.primary, size: 24),
          ),
          const SizedBox(width: ESizes.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Genre',
                  style: TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Select genres to show',
                  style: TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: EColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid() {
    final controller = WatchlistController.to;
    final selectedIds = controller.selectedGenreIds;

    // Get unique genres from user's watchlist items
    final userGenreIds = <int>{};
    for (final item in controller.items) {
      userGenreIds.addAll(item.genreIds);
    }

    // Filter to show only genres the user has
    final availableGenres = ContentGenre.allGenres
        .where((g) => userGenreIds.contains(g.id))
        .toList();

    if (availableGenres.isEmpty) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: ESizes.lg),
        padding: const EdgeInsets.all(ESizes.xl),
        decoration: BoxDecoration(
          color: EColors.surfaceLight,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.category_outlined,
                size: 40,
                color: EColors.textTertiary,
              ),
              const SizedBox(height: ESizes.md),
              const Text(
                'No genres available yet',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: ESizes.xs),
              const Text(
                'Genres will appear after your watchlist\nitems are synced',
                style: TextStyle(
                  color: EColors.textTertiary,
                  fontSize: ESizes.fontSm,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      child: Wrap(
        spacing: ESizes.sm,
        runSpacing: ESizes.sm,
        children: availableGenres.map((genre) {
          final isSelected = selectedIds.contains(genre.id);
          return _GenreChip(
            genre: genre,
            isSelected: isSelected,
            onTap: () => controller.toggleGenre(genre.id),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions() {
    final hasFilters = WatchlistController.to.hasActiveFilters;
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EColors.border)),
      ),
      child: Row(
        children: [
          if (hasFilters)
            TextButton(
              onPressed: WatchlistController.to.clearFilters,
              child: const Text('Clear All'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final ContentGenre genre;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.genre,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md,
            vertical: ESizes.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? EColors.primary : EColors.surfaceLight,
            borderRadius: BorderRadius.circular(ESizes.radiusRound),
            border: Border.all(
              color: isSelected ? EColors.primary : EColors.border,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: genre.icon != null ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        genre.icon ?? Icons.category,
                        size: 16,
                        color: isSelected
                            ? EColors.textOnPrimary
                            : EColors.textSecondary,
                      ),
                      const SizedBox(width: ESizes.xs),
                    ],
                  ),
                ),
                Text(
                  genre.name,
                  style: TextStyle(
                    fontSize: ESizes.fontSm,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? EColors.textOnPrimary
                        : EColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
