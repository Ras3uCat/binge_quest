import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/streaming_provider.dart';
import '../controllers/search_controller.dart';

/// Panel widget for selecting streaming providers to filter search results.
class ProviderFilterPanel extends StatelessWidget {
  const ProviderFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ContentSearchController.to;
      final isActive = controller.isProviderFilterActive;

      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: isActive
            ? AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: 1.0,
                child: ExcludeSemantics(
                  child: _buildContent(controller),
                ),
              )
            : const SizedBox.shrink(),
      );
    });
  }

  Widget _buildContent(ContentSearchController controller) {
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
        children: [
          _buildHeader(controller),
          const SizedBox(height: ESizes.md),
          _buildProviderGrid(controller),
        ],
      ),
    );
  }

  Widget _buildHeader(ContentSearchController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Streaming Services',
          style: TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        if (controller.hasSelectedProviders)
          GestureDetector(
            onTap: controller.clearProviders,
            child: const Text(
              'Clear',
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProviderGrid(ContentSearchController controller) {
    return Wrap(
      spacing: ESizes.sm,
      runSpacing: ESizes.sm,
      children: controller.availableProviders.map((provider) {
        return _ProviderChip(
          provider: provider,
          isSelected: controller.isProviderSelected(provider),
          onTap: () => controller.toggleProvider(provider),
        );
      }).toList(),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  final StreamingProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderChip({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.sm,
          vertical: ESizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? EColors.primary.withValues(alpha: 0.2) : EColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(
            color: isSelected ? EColors.primary : EColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: provider.logoUrl,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 24,
                    height: 24,
                    color: EColors.surfaceLight,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 24,
                    height: 24,
                    color: EColors.surfaceLight,
                    child: const Icon(Icons.tv, size: 16, color: EColors.textTertiary),
                  ),
                ),
              ),
              const SizedBox(width: ESizes.xs),
              Text(
                provider.name,
                style: TextStyle(
                  fontSize: ESizes.fontSm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? EColors.primary : EColors.textSecondary,
                ),
              ),
              Opacity(
                opacity: isSelected ? 1.0 : 0.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(width: ESizes.xs),
                    Icon(
                      Icons.check,
                      size: 14,
                      color: EColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact button to toggle the provider filter panel.
class ProviderFilterButton extends StatelessWidget {
  const ProviderFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ContentSearchController.to;
      final hasFilters = controller.hasSelectedProviders;
      final isActive = controller.isProviderFilterActive;

      return GestureDetector(
        onTap: controller.toggleProviderFilter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md,
            vertical: ESizes.sm,
          ),
          decoration: BoxDecoration(
            color: hasFilters || isActive ? EColors.primary : EColors.surface,
            borderRadius: BorderRadius.circular(ESizes.radiusRound),
            border: Border.all(
              color: hasFilters || isActive ? EColors.primary : EColors.border,
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: hasFilters || isActive ? EColors.textOnPrimary : EColors.textSecondary,
                ),
                Opacity(
                  opacity: hasFilters ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: ESizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EColors.textOnPrimary,
                          borderRadius: BorderRadius.circular(ESizes.radiusRound),
                        ),
                        child: Text(
                          '${controller.selectedProviders.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: EColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
