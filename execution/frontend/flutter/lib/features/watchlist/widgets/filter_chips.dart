import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/content_cache.dart';
import '../../../shared/models/content_genre.dart';
import '../../../shared/models/watchlist_sort_mode.dart';

/// Base chip decoration for consistent styling
BoxDecoration _chipDecoration(bool isSelected, {double borderWidth = 1}) =>
    BoxDecoration(
      color: isSelected ? EColors.primary : EColors.surfaceLight,
      borderRadius: BorderRadius.circular(ESizes.radiusRound),
      border: Border.all(
        color: isSelected ? EColors.primary : EColors.border,
        width: borderWidth,
      ),
    );

TextStyle _chipTextStyle(bool isSelected) => TextStyle(
  fontSize: ESizes.fontSm,
  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  color: isSelected ? EColors.textOnPrimary : EColors.textPrimary,
);

Color _chipIconColor(bool isSelected) =>
    isSelected ? EColors.textOnPrimary : EColors.textSecondary;

/// Reusable filter chip for sort modes
class SortModeChip extends StatelessWidget {
  final WatchlistSortMode mode;
  final bool isSelected;
  final bool ascending;
  final VoidCallback onTap;

  const SortModeChip({super.key, required this.mode, required this.isSelected, required this.ascending, required this.onTap});

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
          decoration: _chipDecoration(isSelected),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon, size: 16, color: _chipIconColor(isSelected)),
                const SizedBox(width: ESizes.xs),
                Text(mode.displayName, style: _chipTextStyle(isSelected)),
                Opacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: ESizes.xs),
                      Icon(
                        ascending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: EColors.textOnPrimary,
                      ),
                    ],
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

/// Reusable filter chip for status filters
class StatusFilterChip extends StatelessWidget {
  final WatchlistStatusFilter status;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusFilterChip({super.key, required this.status, required this.isSelected, required this.onTap});

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
          decoration: _chipDecoration(isSelected),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon, size: 16, color: _chipIconColor(isSelected)),
                const SizedBox(width: ESizes.xs),
                Text(status.displayName, style: _chipTextStyle(isSelected)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable filter chip for streaming providers
class StreamingProviderChip extends StatelessWidget {
  final StreamingProviderInfo provider;
  final bool isSelected;
  final VoidCallback onTap;

  const StreamingProviderChip({super.key, required this.provider, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.sm,
            vertical: ESizes.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? EColors.primary : EColors.surfaceLight,
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
                _buildProviderLogo(),
                const SizedBox(width: ESizes.xs),
                Text(provider.name, style: _chipTextStyle(isSelected)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderLogo() {
    if (provider.logoPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: EImages.tmdbLogo(provider.logoPath),
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.tv, size: 16, color: EColors.textTertiary),
    );
  }
}

/// Reusable filter chip for genres
class GenreFilterChip extends StatelessWidget {
  final ContentGenre genre;
  final bool isSelected;
  final VoidCallback onTap;

  const GenreFilterChip({super.key, required this.genre, required this.isSelected, required this.onTap});

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
          decoration: _chipDecoration(isSelected),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: genre.icon != null ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(genre.icon ?? Icons.category, size: 16, color: _chipIconColor(isSelected)),
                      const SizedBox(width: ESizes.xs),
                    ],
                  ),
                ),
                Text(genre.name, style: _chipTextStyle(isSelected)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state placeholder for filter sections
class FilterEmptyState extends StatelessWidget {
  final String message;

  const FilterEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      child: Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surfaceLight,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              size: 18,
              color: EColors.textTertiary,
            ),
            const SizedBox(width: ESizes.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header for filter sections
class FilterSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const FilterSectionHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      child: Row(
        children: [
          Icon(icon, size: 18, color: EColors.textSecondary),
          const SizedBox(width: ESizes.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: ESizes.fontMd,
              fontWeight: FontWeight.w600,
              color: EColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
