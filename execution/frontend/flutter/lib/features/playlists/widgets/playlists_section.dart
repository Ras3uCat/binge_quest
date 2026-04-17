import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/playlist_controller.dart';
import 'create_edit_playlist_sheet.dart';
import 'playlist_card.dart';

class PlaylistsSection extends StatelessWidget {
  final String userId;
  final bool isOwnProfile;
  final bool showHeader;

  const PlaylistsSection({
    super.key,
    required this.userId,
    required this.isOwnProfile,
    this.showHeader = true,
  });

  PlaylistController _ensureController() {
    if (isOwnProfile) {
      if (!Get.isRegistered<PlaylistController>()) {
        return Get.put(PlaylistController())..init(userId);
      }
      return PlaylistController.to;
    } else {
      if (!Get.isRegistered<PlaylistController>(tag: userId)) {
        return Get.put(PlaylistController(), tag: userId)..init(userId);
      }
      return Get.find<PlaylistController>(tag: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ensureController();

    return Obx(() {
      if (ctrl.isLoading) {
        return _buildShimmer();
      }

      final playlists = isOwnProfile
          ? ctrl.playlists
          : ctrl.playlists.where((p) => p.isPublic).toList();

      if (!isOwnProfile && playlists.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                const Text(
                  'Playlists',
                  style: TextStyle(
                    fontSize: ESizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.add, color: EColors.primary),
                    onPressed: () => CreateEditPlaylistSheet.show(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: ESizes.sm),
          ],
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: playlists.length + (isOwnProfile ? 1 : 0),
              separatorBuilder: (_, i) => const SizedBox(width: ESizes.sm),
              itemBuilder: (context, index) {
                if (isOwnProfile && index == 0) {
                  return _buildNewPlaylistCard();
                }
                final playlist = isOwnProfile ? playlists[index - 1] : playlists[index];
                return PlaylistCard(playlist: playlist);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNewPlaylistCard() {
    return GestureDetector(
      onTap: () => CreateEditPlaylistSheet.show(),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.4)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 36, color: EColors.primary),
            SizedBox(height: ESizes.xs),
            Text(
              'New Playlist',
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: ESizes.fontLg,
          decoration: BoxDecoration(
            color: EColors.shimmerBase,
            borderRadius: BorderRadius.circular(ESizes.radiusXs),
          ),
        ),
        const SizedBox(height: ESizes.sm),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, i) => const SizedBox(width: ESizes.sm),
            itemBuilder: (_, i) => Container(
              width: 140,
              decoration: BoxDecoration(
                color: EColors.shimmerBase,
                borderRadius: BorderRadius.circular(ESizes.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
