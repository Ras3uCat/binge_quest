import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/review.dart';

class RatedItemCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onTap;

  const RatedItemCard({super.key, required this.review, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ESizes.sm),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPoster(),
            const SizedBox(width: ESizes.md),
            Expanded(child: _buildInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ESizes.radiusSm),
      child: SizedBox(
        width: 60,
        height: 90,
        child: review.posterPath != null
            ? CachedNetworkImage(
                imageUrl: EImages.tmdbPoster(review.posterPath),
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _posterFallback(),
              )
            : _posterFallback(),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: EColors.surfaceLight,
      child: Icon(
        review.mediaType == 'movie' ? Icons.movie : Icons.tv,
        color: EColors.textTertiary,
        size: ESizes.iconMd,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          review.title ?? 'Unknown Title',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.xs),
        Row(children: [_buildMediaChip(), const Spacer(), _buildStars()]),
        const SizedBox(height: ESizes.xs),
        Text(
          _relativeDate(),
          style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMediaChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.xs, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Text(
        review.mediaType == 'movie' ? 'Movie' : 'TV',
        style: const TextStyle(
          fontSize: ESizes.fontSm,
          color: EColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          Icons.live_tv,
          size: 14,
          color: i < review.rating ? EColors.primary : EColors.textTertiary,
        ),
      ),
    );
  }

  String _relativeDate() {
    final diff = DateTime.now().difference(review.createdAt);
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Just now';
  }
}
