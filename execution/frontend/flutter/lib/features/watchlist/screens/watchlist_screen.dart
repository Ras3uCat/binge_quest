import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/watchlist_member_controller.dart';
import '../widgets/watchlist_selector_widget.dart';
import '../widgets/watchlist_filter_panel.dart';
import '../widgets/watchlist_filter_button.dart';
import '../widgets/watchlist_item_card.dart';
import '../screens/manage_members_screen.dart';
import '../../search/screens/search_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EColors.backgroundSecondary,
              EColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                child: const WatchlistSelectorWidget(),
              ),
              const SizedBox(height: ESizes.md),
              _buildFilterBar(),
              const WatchlistFilterPanel(),
              Obx(() => WatchlistController.to.isFilterPanelActive
                  ? const SizedBox(height: ESizes.sm)
                  : const SizedBox.shrink()),
              Expanded(child: _buildItemsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Expanded(
            child: Text(
              EText.watchlist,
              style: TextStyle(
                fontSize: ESizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
          Obx(() {
            final watchlist = WatchlistController.to.currentWatchlist;
            if (watchlist == null) return const SizedBox.shrink();
            return IconButton(
              onPressed: () => Get.to(() => ManageMembersScreen(
                    watchlistId: watchlist.id,
                    watchlistName: watchlist.name,
                    ownerId: watchlist.userId,
                  )),
              icon: Obx(() {
                final isShared = WatchlistMemberController.to
                    .isShared(watchlist.id);
                return Icon(
                  isShared ? Icons.group : Icons.group_add_outlined,
                  color: isShared
                      ? EColors.primary
                      : EColors.textSecondary,
                );
              }),
              tooltip: 'Members',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      child: Obx(() {
        final controller = WatchlistController.to;
        final filteredItems = controller.filteredAndSortedItems;
        final totalItems = controller.items.length;
        final hasFilters = controller.hasActiveFilters;

        return Row(
          children: [
            Text(
              hasFilters
                  ? '${filteredItems.length} of $totalItems items'
                  : '$totalItems items',
              style: const TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textSecondary,
              ),
            ),
            const Spacer(),
            // Sort indicator (compact display only)
            Obx(() {
              final sortMode = controller.sortMode;
              final isActive = controller.isFilterPanelActive;
              return GestureDetector(
                onTap: controller.toggleFilterPanel,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.sm,
                    vertical: ESizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? EColors.primary.withValues(alpha: 0.1) : EColors.surfaceLight,
                    borderRadius: BorderRadius.circular(ESizes.radiusSm),
                    border: Border.all(
                      color: isActive ? EColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sortMode.icon,
                        size: 14,
                        color: isActive ? EColors.primary : EColors.textSecondary,
                      ),
                      const SizedBox(width: ESizes.xs),
                      Text(
                        sortMode.displayName,
                        style: TextStyle(
                          fontSize: ESizes.fontXs,
                          color: isActive ? EColors.primary : EColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(width: ESizes.sm),
            // Filter toggle button (inline panel)
            const WatchlistFilterButton(),
          ],
        );
      }),
    );
  }

  Widget _buildItemsList() {
    return Obx(() {
      final controller = WatchlistController.to;
      final items = controller.filteredAndSortedItems;
      final isLoading = controller.isLoadingItems;
      final hasFilters = controller.hasActiveFilters;
      final totalItems = controller.items.length;

      if (isLoading && totalItems == 0) {
        return Padding(
          padding: const EdgeInsets.all(ESizes.lg),
          child: const ListItemsSkeleton(count: 6),
        );
      }

      if (totalItems == 0) {
        return _buildEmptyState();
      }

      if (items.isEmpty && hasFilters) {
        return _buildNoFilterResultsState();
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        color: EColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(ESizes.lg),
          itemCount: items.length,
          itemBuilder: (context, index) => AnimatedListItem(
            index: index,
            child: WatchlistItemCard(item: items[index]),
          ),
        ),
      );
    });
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ESizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: EColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: ESizes.lg),
            const Text(
              'No items match your filters',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.w600,
                color: EColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            const Text(
              'Try adjusting your filter settings',
              style: TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textTertiary,
              ),
            ),
            const SizedBox(height: ESizes.lg),
            TextButton.icon(
              onPressed: () => WatchlistController.to.clearFilters(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget.watchlist(
      onAction: () => Get.to(() => const SearchScreen()),
    );
  }
}
