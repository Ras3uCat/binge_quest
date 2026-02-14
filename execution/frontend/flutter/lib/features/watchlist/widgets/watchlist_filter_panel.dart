import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/mood_tag.dart';
import '../../../shared/models/watchlist_sort_mode.dart';
import '../controllers/watchlist_controller.dart';
import 'filter_chips.dart';

/// Inline collapsible panel for watchlist filters.
/// Uses AnimatedSize for smooth expand/collapse animations.
class WatchlistFilterPanel extends StatelessWidget {
  const WatchlistFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = WatchlistController.to;
      final isActive = controller.isFilterPanelActive;

      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: isActive
            ? AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: 1.0,
                child: ExcludeSemantics(child: _buildContent()),
              )
            : const SizedBox.shrink(),
      );
    });
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => _buildSortSection()),
          const SizedBox(height: ESizes.md),
          Obx(() => _buildStatusSection()),
          const SizedBox(height: ESizes.md),
          Obx(() => _buildStreamingSection()),
          const SizedBox(height: ESizes.md),
          Obx(() => _buildMoodSection()),
          Obx(() => _buildClearButton()),
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
        const _SectionLabel(label: 'Sort'),
        const SizedBox(height: ESizes.xs),
        Wrap(
          spacing: ESizes.xs,
          runSpacing: ESizes.xs,
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
      ],
    );
  }

  Widget _buildStatusSection() {
    final controller = WatchlistController.to;
    final currentStatus = controller.statusFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Status'),
        const SizedBox(height: ESizes.xs),
        Wrap(
          spacing: ESizes.xs,
          runSpacing: ESizes.xs,
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
      ],
    );
  }

  Widget _buildStreamingSection() {
    final controller = WatchlistController.to;
    final providers = controller.availableStreamingProviders;
    final selectedIds = controller.selectedStreamingProviderIds;

    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Streaming'),
        const SizedBox(height: ESizes.xs),
        Wrap(
          spacing: ESizes.xs,
          runSpacing: ESizes.xs,
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
      ],
    );
  }

  Widget _buildMoodSection() {
    final controller = WatchlistController.to;
    final selectedMoods = controller.selectedMoods;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Mood'),
        const SizedBox(height: ESizes.xs),
        Wrap(
          spacing: ESizes.xs,
          runSpacing: ESizes.xs,
          children: MoodTag.values.map((mood) {
            final isSelected = selectedMoods.contains(mood);
            return RepaintBoundary(
              child: _MoodChip(
                mood: mood,
                isSelected: isSelected,
                onTap: () => controller.toggleMood(mood),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildClearButton() {
    final controller = WatchlistController.to;
    final hasFilters = controller.hasActiveFilters;

    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: ESizes.md),
      child: GestureDetector(
        onTap: controller.clearAllFiltersAndSort,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md,
            vertical: ESizes.sm,
          ),
          decoration: BoxDecoration(
            color: EColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ESizes.radiusSm),
            border: Border.all(color: EColors.error.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear_all, size: 16, color: EColors.error),
              SizedBox(width: ESizes.xs),
              Text(
                'Clear All Filters',
                style: TextStyle(
                  fontSize: ESizes.fontSm,
                  fontWeight: FontWeight.w500,
                  color: EColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact section label for inline panel.
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: ESizes.fontSm,
        fontWeight: FontWeight.w600,
        color: EColors.textSecondary,
      ),
    );
  }
}

/// Mood chip widget for filter panel.
class _MoodChip extends StatelessWidget {
  final MoodTag mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.sm,
          vertical: ESizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? mood.color : EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
          border: Border.all(color: isSelected ? mood.color : EColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mood.icon,
              size: 14,
              color: isSelected ? EColors.textOnPrimary : EColors.textSecondary,
            ),
            const SizedBox(width: ESizes.xs),
            Text(
              mood.displayName,
              style: TextStyle(
                fontSize: ESizes.fontXs,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? EColors.textOnPrimary
                    : EColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
