import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/content_genre.dart';
import '../../../shared/models/watchlist_sort_mode.dart';
import '../controllers/watchlist_controller.dart';
import 'filter_chips.dart';

class WatchlistFilterSheet extends StatelessWidget {
  const WatchlistFilterSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const WatchlistFilterSheet(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          _buildHeader(),
          const SizedBox(height: ESizes.md),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => _buildSortSection()),
                  const SizedBox(height: ESizes.lg),
                  Obx(() => _buildStatusSection()),
                  const SizedBox(height: ESizes.lg),
                  Obx(() => _buildStreamingSection()),
                  const SizedBox(height: ESizes.lg),
                  Obx(() => _buildGenreSection()),
                  const SizedBox(height: ESizes.md),
                ],
              ),
            ),
          ),
          Obx(() => _buildActions()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: ESizes.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: EColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
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
            child: const Icon(Icons.tune, color: EColors.primary, size: 24),
          ),
          const SizedBox(width: ESizes.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Customize your watchlist view',
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

  Widget _buildSortSection() {
    final controller = WatchlistController.to;
    final currentMode = controller.sortMode;
    final ascending = controller.sortAscending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Sort By', icon: Icons.sort),
        const SizedBox(height: ESizes.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: Wrap(
            spacing: ESizes.sm,
            runSpacing: ESizes.sm,
            children: WatchlistSortMode.values.map((mode) {
              final isSelected = currentMode == mode;
              return RepaintBoundary(
                child: SortModeChip(
                  mode: mode,
                  isSelected: isSelected,
                  ascending: ascending,
                  onTap: () {
                    if (isSelected) {
                      controller.toggleSortDirection();
                    } else {
                      controller.setSortMode(mode);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final controller = WatchlistController.to;
    final currentStatus = controller.statusFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(
          title: 'Status',
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: ESizes.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: Wrap(
            spacing: ESizes.sm,
            runSpacing: ESizes.sm,
            children: WatchlistStatusFilter.values.map((status) {
              final isSelected = currentStatus == status;
              return RepaintBoundary(
                child: StatusFilterChip(
                  status: status,
                  isSelected: isSelected,
                  onTap: () => controller.setStatusFilter(status),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingSection() {
    final controller = WatchlistController.to;
    final providers = controller.availableStreamingProviders;
    final selectedIds = controller.selectedStreamingProviderIds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Streaming Service', icon: Icons.tv),
        const SizedBox(height: ESizes.sm),
        if (providers.isEmpty)
          const FilterEmptyState(message: 'No streaming data available yet')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
            child: Wrap(
              spacing: ESizes.sm,
              runSpacing: ESizes.sm,
              children: providers.map((provider) {
                final isSelected = selectedIds.contains(provider.id);
                return RepaintBoundary(
                  child: StreamingProviderChip(
                    provider: provider,
                    isSelected: isSelected,
                    onTap: () => controller.toggleStreamingProvider(provider.id),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildGenreSection() {
    final controller = WatchlistController.to;
    final availableIds = controller.availableGenreIds;
    final selectedIds = controller.selectedGenreIds;
    final availableGenres = ContentGenre.allGenres
        .where((g) => availableIds.contains(g.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionHeader(title: 'Genre', icon: Icons.category),
        const SizedBox(height: ESizes.sm),
        if (availableGenres.isEmpty)
          const FilterEmptyState(message: 'No genre data available yet')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
            child: Wrap(
              spacing: ESizes.sm,
              runSpacing: ESizes.sm,
              children: availableGenres.map((genre) {
                final isSelected = selectedIds.contains(genre.id);
                return RepaintBoundary(
                  child: GenreFilterChip(
                    genre: genre,
                    isSelected: isSelected,
                    onTap: () => controller.toggleGenre(genre.id),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    final hasFilters = WatchlistController.to.hasActiveFilters;
    final count = WatchlistController.to.filteredAndSortedItems.length;
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EColors.border)),
      ),
      child: Row(
        children: [
          if (hasFilters)
            TextButton.icon(
              onPressed: WatchlistController.to.clearAllFiltersAndSort,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: EColors.error),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.textOnPrimary,
            ),
            child: Text('Show $count Items'),
          ),
        ],
      ),
    );
  }
}
