import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/review.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/repositories/review_repository.dart';
import '../../search/widgets/content_detail_sheet.dart';
import 'rated_item_card.dart';

class RatedItemsSection extends StatelessWidget {
  final List<Review> items;
  final bool isLoading;
  final String? error;
  final ReviewSort sort;
  final VoidCallback onSortDate;
  final VoidCallback onSortRating;
  final bool isOwnProfile;

  const RatedItemsSection({
    super.key,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.sort,
    required this.onSortDate,
    required this.onSortRating,
    this.isOwnProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: ESizes.md),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDateActive = sort == ReviewSort.dateDesc || sort == ReviewSort.dateAsc;
    final isRatingActive = sort == ReviewSort.ratingDesc || sort == ReviewSort.ratingAsc;

    return Row(
      children: [
        const Icon(Icons.star_rate_rounded, color: EColors.accent, size: ESizes.iconMd),
        const SizedBox(width: ESizes.sm),
        const Expanded(
          child: Text(
            'Ratings',
            style: TextStyle(
              fontSize: ESizes.fontLg,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
        ),
        _SortButton(
          label: 'Date',
          isActive: isDateActive,
          isAsc: sort == ReviewSort.dateAsc,
          onTap: onSortDate,
        ),
        const SizedBox(width: ESizes.xs),
        _SortButton(
          label: 'Rating',
          isActive: isRatingActive,
          isAsc: sort == ReviewSort.ratingAsc,
          onTap: onSortRating,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2)),
      );
    }

    if (error != null) {
      return _buildError();
    }

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: ESizes.xs),
      itemBuilder: (_, i) => RatedItemCard(review: items[i], onTap: () => _openSheet(items[i])),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EColors.textSecondary),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              error!,
              style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
        border: Border.all(color: EColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EColors.surface,
              border: Border.all(color: EColors.border),
            ),
            child: const Center(
              child: Icon(Icons.star_border, color: EColors.textTertiary, size: 24),
            ),
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Text(
              isOwnProfile ? 'No ratings yet. Rate content to see it here.' : 'No ratings yet.',
              style: const TextStyle(fontSize: ESizes.fontMd, color: EColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(Review review) {
    final result = TmdbSearchResult(
      id: review.tmdbId,
      titleField: review.mediaType == 'movie' ? review.title : null,
      name: review.mediaType == 'tv' ? review.title : null,
      posterPath: review.posterPath,
      mediaTypeString: review.mediaType,
      voteAverage: 0.0,
    );
    Get.bottomSheet(ContentDetailSheet(result: result));
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isAsc;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.isActive,
    required this.isAsc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? EColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
          border: Border.all(
            color: isActive ? EColors.primary.withValues(alpha: 0.4) : EColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: isActive ? EColors.primary : EColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: EColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
