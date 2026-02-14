import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../controllers/search_controller.dart';
import '../widgets/search_results_grid.dart';
import '../widgets/person_results_grid.dart';
import '../widgets/provider_filter_panel.dart';
import '../widgets/search_suggestions.dart';
import '../widgets/content_detail_sheet.dart';
import '../../../shared/models/tmdb_content.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller if not already registered
    if (!Get.isRegistered<ContentSearchController>()) {
      Get.put(ContentSearchController());
    }

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
              _buildSearchBar(),
              _buildFilterChips(),
              const ProviderFilterPanel(),
              Obx(() => ContentSearchController.to.isProviderFilterActive
                  ? const SizedBox(height: ESizes.sm)
                  : const SizedBox.shrink()),
              Expanded(
                child: Obx(() {
                  final controller = ContentSearchController.to;

                  // Show suggestions when no search query and no provider filter
                  if (controller.showSuggestions && !controller.isPeopleSearch) {
                    return const SearchSuggestions();
                  }

                  if (controller.isPeopleSearch) {
                    return const PersonResultsGrid();
                  }
                  return const SearchResultsGrid();
                }),
              ),
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
          const Text(
            EText.search,
            style: TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final controller = ContentSearchController.to;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      child: TextField(
        controller: controller.textController,
        style: const TextStyle(color: EColors.textPrimary),
        decoration: InputDecoration(
          hintText: EText.searchHint,
          hintStyle: const TextStyle(color: EColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: EColors.textSecondary),
          suffixIcon: Obx(() {
            if (controller.searchQuery.isNotEmpty) {
              return IconButton(
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.clear),
                color: EColors.textSecondary,
              );
            }
            return const SizedBox.shrink();
          }),
          filled: true,
          fillColor: EColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            borderSide: const BorderSide(color: EColors.primary, width: 2),
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (query) => controller.search(query),
        onChanged: (query) {
          // Debounced search
          if (query.length >= 2) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (controller.textController.text == query) {
                controller.search(query);
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Obx(() {
        final controller = ContentSearchController.to;
        final currentFilter = controller.filter;

        return Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: EText.all,
                      isSelected: currentFilter == SearchFilter.all,
                      onTap: () => controller.setFilter(SearchFilter.all),
                    ),
                    const SizedBox(width: ESizes.sm),
                    _buildFilterChip(
                      label: EText.movies,
                      isSelected: currentFilter == SearchFilter.movies,
                      onTap: () => controller.setFilter(SearchFilter.movies),
                    ),
                    const SizedBox(width: ESizes.sm),
                    _buildFilterChip(
                      label: EText.tvShows,
                      isSelected: currentFilter == SearchFilter.tvShows,
                      onTap: () => controller.setFilter(SearchFilter.tvShows),
                    ),
                    const SizedBox(width: ESizes.sm),
                    _buildFilterChip(
                      label: EText.people,
                      isSelected: currentFilter == SearchFilter.people,
                      onTap: () => controller.setFilter(SearchFilter.people),
                    ),
                  ],
                ),
              ),
            ),
            // Provider filter button (hide for people search)
            if (currentFilter != SearchFilter.people) ...[
              const SizedBox(width: ESizes.sm),
              const ProviderFilterButton(),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md,
          vertical: ESizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? EColors.primary : EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
          border: Border.all(
            color: isSelected ? EColors.primary : EColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? EColors.textOnPrimary : EColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: ESizes.fontSm,
          ),
        ),
      ),
    );
  }
}

/// Shows content detail bottom sheet.
void showContentDetailSheet(TmdbSearchResult result) {
  Get.bottomSheet(
    ContentDetailSheet(result: result),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
