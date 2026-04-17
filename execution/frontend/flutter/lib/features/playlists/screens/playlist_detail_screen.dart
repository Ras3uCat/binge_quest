import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../notifications/helpers/quick_add_helper.dart';
import '../controllers/playlist_detail_controller.dart';
import '../models/playlist.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/create_edit_playlist_sheet.dart';
import '../widgets/playlist_watchlist_sheet.dart';
import '_playlist_detail_item_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  PlaylistDetailController _initController() {
    if (!Get.isRegistered<PlaylistDetailController>(tag: playlistId)) {
      return Get.put(PlaylistDetailController(playlistId), tag: playlistId);
    }
    return Get.find<PlaylistDetailController>(tag: playlistId);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _initController();

    return Scaffold(
      backgroundColor: EColors.background,
      body: Obx(() {
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator(color: EColors.primary));
        }
        final playlist = ctrl.playlist;
        if (playlist == null) {
          return _buildNotFound();
        }
        return ctrl.isOwner
            ? _PlaylistOwnerView(ctrl: ctrl, playlist: playlist)
            : _PlaylistViewerView(ctrl: ctrl, playlist: playlist);
      }),
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        backgroundColor: EColors.background,
        leading: const BackButton(color: EColors.textPrimary),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove, size: 64, color: EColors.textTertiary),
            SizedBox(height: ESizes.md),
            Text(
              'Playlist not found',
              style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontMd),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistOwnerView extends StatelessWidget {
  final PlaylistDetailController ctrl;
  final Playlist playlist;

  const _PlaylistOwnerView({required this.ctrl, required this.playlist});

  void _share() {
    final link = 'https://raspucat.com/bingequest/playlist?id=${playlist.id}';
    Share.share('Check out my playlist "${playlist.name}" on BingeQuest!\n$link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        backgroundColor: EColors.background,
        leading: const BackButton(color: EColors.textPrimary),
        title: Obx(
          () => Text(ctrl.playlist?.name ?? '', style: const TextStyle(color: EColors.textPrimary)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: EColors.textPrimary),
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: EColors.textPrimary),
            onPressed: () => CreateEditPlaylistSheet.show(existing: playlist),
          ),
        ],
      ),
      body: Obx(() {
        final items = ctrl.items;
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No items yet. Tap + to add content.',
              style: TextStyle(color: EColors.textSecondary),
            ),
          );
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
          itemCount: items.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final reordered = List.of(items);
            final moved = reordered.removeAt(oldIndex);
            reordered.insert(newIndex, moved);
            ctrl.reorder(reordered.map((i) => i.id).toList());
          },
          itemBuilder: (_, index) {
            final item = items[index];
            return PlaylistItemTile(
              key: ValueKey(item.id),
              item: item,
              rank: playlist.isRanked ? index + 1 : null,
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: EColors.textTertiary),
              ),
              onDismiss: () => ctrl.removeItem(item.id),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddToPlaylistSheet.show(playlistId: playlist.id),
        backgroundColor: EColors.primary,
        child: const Icon(Icons.add, color: EColors.textOnPrimary),
      ),
    );
  }
}

class _PlaylistViewerView extends StatelessWidget {
  final PlaylistDetailController ctrl;
  final Playlist playlist;

  const _PlaylistViewerView({required this.ctrl, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        backgroundColor: EColors.background,
        leading: const BackButton(color: EColors.textPrimary),
        title: Text(playlist.name, style: const TextStyle(color: EColors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final items = ctrl.items;
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'This playlist is empty.',
                    style: TextStyle(color: EColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return PlaylistItemTile(
                    key: ValueKey(item.id),
                    item: item,
                    rank: playlist.isRanked ? index + 1 : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: EColors.primary),
                      onPressed: () => QuickAddHelper.quickAddToWatchlist(
                        tmdbId: item.tmdbId,
                        mediaType: item.mediaType,
                        contentTitle: item.title,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          _buildAddAllBar(context),
        ],
      ),
    );
  }

  Widget _buildAddAllBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: const BoxDecoration(
        color: EColors.surface,
        border: Border(top: BorderSide(color: EColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: ESizes.buttonHeightMd,
        child: FilledButton(
          onPressed: () =>
              PlaylistWatchlistSheet.show(context: context, onConfirm: ctrl.addAllToWatchlist),
          child: const Text('Add All to Watchlist'),
        ),
      ),
    );
  }
}
