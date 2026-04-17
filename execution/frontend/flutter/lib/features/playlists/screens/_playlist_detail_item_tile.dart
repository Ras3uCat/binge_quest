import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../models/playlist.dart';

class PlaylistItemTile extends StatelessWidget {
  final PlaylistItem item;
  final Widget? trailing;
  final VoidCallback? onDismiss;
  final int? rank;

  const PlaylistItemTile({super.key, required this.item, this.trailing, this.onDismiss, this.rank});

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
      leading: rank != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRankBadge(rank!),
                const SizedBox(width: ESizes.xs),
                _buildPoster(),
              ],
            )
          : _buildPoster(),
      title: Text(
        item.title,
        style: const TextStyle(
          color: EColors.textPrimary,
          fontSize: ESizes.fontMd,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildMediaTypeBadge(),
      trailing: trailing,
    );

    if (onDismiss != null) {
      return Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: ESizes.lg),
          color: EColors.error.withValues(alpha: 0.8),
          child: const Icon(Icons.delete, color: EColors.textOnPrimary),
        ),
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildRankBadge(int r) {
    return SizedBox(
      width: 28,
      child: Text(
        '#$r',
        style: const TextStyle(
          fontSize: ESizes.fontMd,
          fontWeight: FontWeight.bold,
          color: EColors.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPoster() {
    if (item.posterPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.radiusXs),
        child: CachedNetworkImage(
          imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
          width: 40,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => _placeholderBox(),
          errorWidget: (ctx, url, err) => _placeholderBox(),
        ),
      );
    }
    return _placeholderBox();
  }

  Widget _placeholderBox() {
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: EColors.surfaceLight,
        borderRadius: BorderRadius.circular(ESizes.radiusXs),
      ),
      child: const Icon(Icons.movie, size: ESizes.iconSm, color: EColors.textTertiary),
    );
  }

  Widget _buildMediaTypeBadge() {
    final label = item.mediaType == 'tv' ? 'TV Show' : 'Movie';
    return Container(
      margin: const EdgeInsets.only(top: ESizes.xs),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: ESizes.fontXs,
          color: EColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
