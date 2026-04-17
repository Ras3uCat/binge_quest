import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/friend_watching.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/widgets/friends_watching_row.dart';

class ContentDetailHeader extends StatelessWidget {
  final TmdbContent content;
  final double? bqRating;
  final int bqReviewCount;
  final int userCount;
  final List<FriendWatching> friendsWatching;
  final VoidCallback onShare;

  const ContentDetailHeader({
    super.key,
    required this.content,
    required this.bqRating,
    required this.bqReviewCount,
    required this.userCount,
    required this.friendsWatching,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          child: content.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: EImages.tmdbPoster(content.posterPath, size: 'w185'),
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 100,
                  height: 150,
                  color: EColors.surfaceLight,
                  child: const Icon(Icons.movie, size: 40),
                ),
        ),
        const SizedBox(width: ESizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: ESizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: EColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: EColors.textSecondary),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onShare,
                  ),
                ],
              ),
              const SizedBox(height: ESizes.xs),
              _buildInfoRow(),
              const SizedBox(height: ESizes.sm),
              Row(
                children: [
                  _buildRatingBadge(content.voteAverage),
                  if (bqRating != null) ...[
                    const SizedBox(width: ESizes.md),
                    _buildBqRatingBadge(),
                  ],
                ],
              ),
              if (userCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: EColors.textSecondary),
                      const SizedBox(width: ESizes.xs),
                      Text(
                        '${formatCompactNumber(userCount)} ${userCount == 1 ? 'user' : 'users'} watching',
                        style: const TextStyle(
                          fontSize: ESizes.fontSm,
                          color: EColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (friendsWatching.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.sm),
                  child: FriendsWatchingRow(friends: friendsWatching),
                ),
              if (content is TmdbMovie && (content as TmdbMovie).tagline != null)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.sm),
                  child: Text(
                    '"${(content as TmdbMovie).tagline}"',
                    style: const TextStyle(
                      fontSize: ESizes.fontSm,
                      fontStyle: FontStyle.italic,
                      color: EColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    final items = <String>[];
    if (content is TmdbMovie) {
      final m = content as TmdbMovie;
      if (m.year != null) items.add(m.year!);
      if (m.runtime != null) items.add(m.formattedRuntime);
    } else if (content is TmdbTvShow) {
      final t = content as TmdbTvShow;
      if (t.year != null) items.add(t.year!);
      items.add('${t.numberOfSeasons} Season${t.numberOfSeasons > 1 ? 's' : ''}');
      items.add('${t.numberOfEpisodes} Episodes');
    }
    return Wrap(spacing: ESizes.sm, children: items.map((item) => _buildInfoChip(item)).toList());
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.surfaceLight,
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: ESizes.fontXs, color: EColors.textSecondary),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    final color = _ratingColor(rating);
    return Row(
      children: [
        Icon(Icons.star, size: 18, color: color),
        const SizedBox(width: ESizes.xs),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: ESizes.fontMd, fontWeight: FontWeight.bold, color: color),
        ),
        const Text(
          ' / 10',
          style: TextStyle(fontSize: ESizes.fontSm, color: EColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildBqRatingBadge() {
    return Row(
      children: [
        const Icon(Icons.live_tv, size: 18, color: EColors.primary),
        const SizedBox(width: ESizes.xs),
        Text(
          bqRating!.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.bold,
            color: EColors.primary,
          ),
        ),
        Text(
          ' ($bqReviewCount)',
          style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textSecondary),
        ),
      ],
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 7.5) return Colors.green;
    if (rating >= 5.5) return Colors.orange;
    return Colors.red;
  }
}
