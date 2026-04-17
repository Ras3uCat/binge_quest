import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../models/playlist.dart';
import '../screens/playlist_detail_screen.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const PlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PlaylistDetailScreen(playlistId: playlist.id)),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(),
            Padding(
              padding: const EdgeInsets.all(ESizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          playlist.name,
                          style: const TextStyle(
                            fontSize: ESizes.fontSm,
                            fontWeight: FontWeight.bold,
                            color: EColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!playlist.isPublic)
                        const Icon(Icons.lock, size: 12, color: EColors.textTertiary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.itemCount} items',
                    style: const TextStyle(fontSize: ESizes.fontXs, color: EColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    final posterPath = playlist.coverPosterPath;
    if (posterPath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(ESizes.radiusMd)),
        child: CachedNetworkImage(
          imageUrl: 'https://image.tmdb.org/t/p/w185$posterPath',
          height: 90,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => _buildPlaceholder(),
          errorWidget: (ctx, url, err) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(ESizes.radiusMd)),
      child: Container(
        height: 90,
        width: double.infinity,
        color: EColors.surfaceLight,
        child: const Icon(Icons.playlist_play, size: 36, color: EColors.textTertiary),
      ),
    );
  }
}
