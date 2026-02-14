import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';
import 'shimmer_widget.dart';

/// Skeleton loader for poster cards in recommendations/search.
class PosterCardSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final bool showTitle;

  const PosterCardSkeleton({
    super.key,
    this.width = 130,
    this.height = 200,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ShimmerBox(
                borderRadius: ESizes.radiusMd,
              ),
            ),
            if (showTitle) ...[
              const SizedBox(height: ESizes.xs),
              ShimmerText(width: width * 0.8),
              const SizedBox(height: 4),
              ShimmerText(width: width * 0.5, height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal list of poster card skeletons.
class PosterListSkeleton extends StatelessWidget {
  final int count;
  final double height;

  const PosterListSkeleton({
    super.key,
    this.count = 4,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < count - 1 ? ESizes.md : 0),
            child: PosterCardSkeleton(height: height),
          );
        },
      ),
    );
  }
}

/// Grid of poster card skeletons.
class PosterGridSkeleton extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const PosterGridSkeleton({
    super.key,
    this.crossAxisCount = 3,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65,
        crossAxisSpacing: ESizes.md,
        mainAxisSpacing: ESizes.md,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const PosterCardSkeleton(
        width: double.infinity,
        showTitle: true,
      ),
    );
  }
}

/// Skeleton loader for watchlist items.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
        child: Row(
          children: [
            // Poster thumbnail
            const ShimmerBox(
              width: 60,
              height: 90,
              borderRadius: ESizes.radiusSm,
            ),
            const SizedBox(width: ESizes.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerText(width: 180, height: 16),
                  const SizedBox(height: ESizes.sm),
                  const ShimmerText(width: 120, height: 12),
                  const SizedBox(height: ESizes.sm),
                  // Progress bar
                  ShimmerBox(
                    width: double.infinity,
                    height: 6,
                    borderRadius: ESizes.radiusSm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: ESizes.sm),
            // Trailing
            const ShimmerBox(width: 50, height: 24),
          ],
        ),
      ),
    );
  }
}

/// List of watchlist item skeletons.
class ListItemsSkeleton extends StatelessWidget {
  final int count;

  const ListItemsSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => const ListItemSkeleton(),
      ),
    );
  }
}

/// Skeleton loader for the queue health card.
class QueueHealthCardSkeleton extends StatelessWidget {
  const QueueHealthCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: BoxDecoration(
          gradient: EColors.primaryGradient,
          borderRadius: BorderRadius.circular(ESizes.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: 100,
                  height: 20,
                  borderRadius: ESizes.radiusSm,
                ),
                ShimmerBox(
                  width: 80,
                  height: 24,
                  borderRadius: ESizes.radiusRound,
                ),
              ],
            ),
            const SizedBox(height: ESizes.md),
            // Main content
            Row(
              children: [
                // Ring placeholder
                const ShimmerCircle(size: ESizes.progressRingMd),
                const SizedBox(width: ESizes.lg),
                // Stats
                Expanded(
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index < 2 ? ESizes.sm : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(width: 80, height: 14),
                            const ShimmerBox(width: 30, height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESizes.md),
            // Button placeholder
            ShimmerBox(
              width: double.infinity,
              height: 40,
              borderRadius: ESizes.radiusMd,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for badge grid.
class BadgeGridSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const BadgeGridSkeleton({
    super.key,
    this.count = 6,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.8,
          crossAxisSpacing: ESizes.md,
          mainAxisSpacing: ESizes.md,
        ),
        itemCount: count,
        itemBuilder: (context, index) => const _BadgeCardSkeleton(),
      ),
    );
  }
}

class _BadgeCardSkeleton extends StatelessWidget {
  const _BadgeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ShimmerCircle(size: 48),
          const SizedBox(height: ESizes.sm),
          ShimmerText(width: 60, height: 12),
          const SizedBox(height: 4),
          ShimmerText(width: 40, height: 10),
        ],
      ),
    );
  }
}

/// Skeleton for content detail bottom sheet.
class ContentDetailSheetSkeleton extends StatelessWidget {
  const ContentDetailSheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.all(ESizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(
                  width: 100,
                  height: 150,
                  borderRadius: ESizes.radiusMd,
                ),
                const SizedBox(width: ESizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerText(width: double.infinity, height: 20),
                      const SizedBox(height: ESizes.sm),
                      const ShimmerText(width: 120, height: 14),
                      const SizedBox(height: ESizes.xs),
                      const ShimmerText(width: 80, height: 14),
                      const SizedBox(height: ESizes.md),
                      Row(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: ESizes.xs),
                            child: ShimmerBox(
                              width: 60,
                              height: 24,
                              borderRadius: ESizes.radiusRound,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESizes.lg),
            // Overview
            const ShimmerTextLines(lines: 4, lastLineWidth: 200),
            const SizedBox(height: ESizes.lg),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ShimmerBox(
                    height: 48,
                    borderRadius: ESizes.radiusMd,
                  ),
                ),
                const SizedBox(width: ESizes.md),
                Expanded(
                  child: ShimmerBox(
                    height: 48,
                    borderRadius: ESizes.radiusMd,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for profile stats section.
class ProfileStatsSkeleton extends StatelessWidget {
  const ProfileStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (index) => Column(
            children: [
              const ShimmerBox(width: 40, height: 24),
              const SizedBox(height: ESizes.xs),
              ShimmerText(width: 50, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for person detail screen.
class PersonDetailSkeleton extends StatelessWidget {
  const PersonDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  const ShimmerCircle(size: 120),
                  const SizedBox(height: ESizes.md),
                  const ShimmerText(width: 150, height: 24),
                  const SizedBox(height: ESizes.xs),
                  const ShimmerText(width: 100, height: 14),
                ],
              ),
            ),
            const SizedBox(height: ESizes.xl),
            // Bio section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerText(width: 80, height: 18),
                  const SizedBox(height: ESizes.sm),
                  const ShimmerTextLines(lines: 4, lastLineWidth: 180),
                  const SizedBox(height: ESizes.xl),
                  // Known for section
                  const ShimmerText(width: 100, height: 18),
                  const SizedBox(height: ESizes.md),
                  const PosterListSkeleton(count: 3, height: 180),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
