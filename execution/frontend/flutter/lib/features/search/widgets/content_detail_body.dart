import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/tmdb_content.dart';
import '../controllers/search_controller.dart';
import 'trailer_player_dialog.dart';
import '../../../shared/models/tmdb_video.dart';

/// Renders metadata, overview, cast, seasons, and trailer button.
class ContentDetailBody extends StatelessWidget {
  final TmdbContent content;
  final void Function(int personId) onPersonTap;

  const ContentDetailBody({super.key, required this.content, required this.onPersonTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetadata(),
        const SizedBox(height: ESizes.lg),
        _buildTrailerButton(),
        _buildOverview(),
        if (content is TmdbMovie && (content as TmdbMovie).cast != null)
          _buildCast((content as TmdbMovie).cast!),
        if (content is TmdbTvShow && (content as TmdbTvShow).cast != null)
          _buildCast((content as TmdbTvShow).cast!),
        if (content is TmdbTvShow) _buildSeasons(content as TmdbTvShow),
      ],
    );
  }

  Widget _buildMetadata() {
    List<TmdbGenre> genres = [];
    String? status;
    if (content is TmdbMovie) {
      genres = (content as TmdbMovie).genres;
      status = (content as TmdbMovie).status;
    } else if (content is TmdbTvShow) {
      genres = (content as TmdbTvShow).genres;
      status = (content as TmdbTvShow).status;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genres.isNotEmpty)
          Wrap(
            spacing: ESizes.xs,
            runSpacing: ESizes.xs,
            children: genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.xs),
                decoration: BoxDecoration(
                  color: EColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ESizes.radiusRound),
                  border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  genre.name,
                  style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.primary),
                ),
              );
            }).toList(),
          ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: ESizes.sm),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: EColors.textTertiary),
                const SizedBox(width: ESizes.xs),
                Text(
                  'Status: $status',
                  style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOverview() {
    if (content.overview == null || content.overview!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          EText.overview,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Text(
          content.overview!,
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            color: EColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCast(List<TmdbCastMember> cast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ESizes.lg),
        const Text(
          EText.cast,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final member = cast[index];
              return GestureDetector(
                onTap: () => onPersonTap(member.id),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: ESizes.sm),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: EColors.surfaceLight,
                        backgroundImage: member.profilePath != null
                            ? CachedNetworkImageProvider(
                                EImages.tmdbPoster(member.profilePath, size: 'w92'),
                              )
                            : null,
                        child: member.profilePath == null
                            ? const Icon(Icons.person, color: EColors.textTertiary)
                            : null,
                      ),
                      const SizedBox(height: ESizes.xs),
                      Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: ESizes.fontXs, color: EColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeasons(TmdbTvShow tvShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ESizes.lg),
        Text(
          '${EText.seasons} (${tvShow.numberOfSeasons})',
          style: const TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        ...tvShow.seasons
            .take(5)
            .map(
              (season) => Padding(
                padding: const EdgeInsets.only(bottom: ESizes.xs),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 16, color: EColors.textSecondary),
                    const SizedBox(width: ESizes.sm),
                    Text(
                      season.name ?? 'Season ${season.seasonNumber}',
                      style: const TextStyle(fontSize: ESizes.fontMd, color: EColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${season.episodeCount} episodes',
                      style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
        if (tvShow.seasons.length > 5)
          Text(
            '+ ${tvShow.seasons.length - 5} more seasons',
            style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textTertiary),
          ),
      ],
    );
  }

  Widget _buildTrailerButton() {
    return Obx(() {
      final controller = ContentSearchController.to;
      if (controller.isLoadingVideos) {
        return const Padding(
          padding: EdgeInsets.only(bottom: ESizes.lg),
          child: SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }
      final trailer = controller.bestTrailer;
      if (trailer == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: ESizes.lg),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => TrailerPlayerDialog.show(Get.context!, trailer),
            icon: const Icon(Icons.play_circle_outline, color: EColors.accent),
            label: const Text(EText.watchTrailer, style: TextStyle(color: EColors.accent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: EColors.accent),
              padding: const EdgeInsets.symmetric(vertical: ESizes.md),
            ),
          ),
        ),
      );
    });
  }
}
