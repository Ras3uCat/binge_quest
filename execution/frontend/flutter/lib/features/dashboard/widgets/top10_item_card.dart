import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/models/top_content.dart';
import '../../../../shared/models/tmdb_content.dart';
import '../../../../core/constants/e_colors.dart';
import '../../../../core/constants/e_sizes.dart';
import '../../../../shared/widgets/streaming_badge.dart';
import '../../search/controllers/search_controller.dart';
import '../../search/widgets/content_detail_sheet.dart';

class Top10ItemCard extends StatelessWidget {
  final TopContent item;
  final int rank;
  final bool showUserCount;

  const Top10ItemCard({
    super.key,
    required this.item,
    required this.rank,
    this.showUserCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: SizedBox(
        width: 130, // Matching RecommendationSection width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with rank badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ESizes.radiusMd),
                    child: item.hasPoster
                        ? Image.network(
                            item.posterUrl,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: EColors.surface,
                            child: const Icon(
                              Icons.movie,
                              color: EColors.textTertiary,
                            ),
                          ),
                  ),
                  // Top left: Media type indicator
                  Positioned(
                    top: ESizes.xs,
                    left: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: EColors.background.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                      ),
                      child: Icon(
                        item.mediaType == 'movie' ? Icons.movie : Icons.tv,
                        size: 14,
                        color: EColors.textSecondary,
                      ),
                    ),
                  ),
                  // Top right: Streaming badge
                  if (item.streamingProviders.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: StreamingBadge(
                        streamingProviders: item.streamingProviders,
                      ),
                    ),
                  // Bottom right: Rank badge
                  Positioned(
                    bottom: ESizes.xs,
                    right: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EColors.primary,
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: EColors.textOnPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: ESizes.fontSm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESizes.xs),
            // Title - constrained for 2 lines
            SizedBox(
              height: 36,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: ESizes.fontSm,
                ),
              ),
            ),
            // const SizedBox(height: 2),
            // Metric
            if (showUserCount)
              Text(
                '${item.userCount} ${item.userCount == 1 ? 'user' : 'users'}',
                style: const TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontXs,
                ),
              )
            else if (item.averageRating != null)
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      Icons.live_tv,
                      size: 10,
                      color: i < item.averageRating!.round()
                          ? EColors.primary
                          : EColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.averageRating}',
                    style: const TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontXs,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    // Ensure controller is registered to avoid GetX error
    if (!Get.isRegistered<ContentSearchController>()) {
      Get.put(ContentSearchController());
    }

    final result = TmdbSearchResult(
      id: item.tmdbId,
      titleField: item.mediaType == 'movie' ? item.title : null,
      name: item.mediaType == 'tv' ? item.title : null,
      posterPath: item.posterPath,
      mediaTypeString: item.mediaType,
      voteAverage: 0.0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContentDetailSheet(result: result),
    );
  }
}
