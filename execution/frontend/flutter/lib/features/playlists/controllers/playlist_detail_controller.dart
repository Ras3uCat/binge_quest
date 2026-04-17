import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../models/playlist.dart';
import '../repositories/playlist_repository.dart';
import 'playlist_controller.dart';

class PlaylistDetailController extends GetxController {
  final String playlistId;
  PlaylistDetailController(this.playlistId);

  final _playlist = Rxn<Playlist>();
  final _isLoading = false.obs;
  final _isOwner = false.obs;

  Playlist? get playlist => _playlist.value;
  bool get isLoading => _isLoading.value;
  bool get isOwner => _isOwner.value;
  List<PlaylistItem> get items => _playlist.value?.items ?? [];

  @override
  void onInit() {
    super.onInit();
    loadPlaylist();
  }

  void updatePlaylistMeta(Playlist updated) {
    final current = _playlist.value;
    if (current != null) {
      _playlist.value = updated.copyWith(items: current.items);
    }
  }

  Future<void> loadPlaylist() async {
    _isLoading.value = true;
    try {
      final p = await PlaylistRepository.getPlaylistById(playlistId);
      _playlist.value = p;
      _isOwner.value = p.userId == SupabaseService.currentUserId;
    } catch (_) {
      // null playlist signals not found / private
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> addItem({
    required int tmdbId,
    required String mediaType,
    required String title,
    String? posterPath,
  }) async {
    if (items.length >= 25) {
      Get.snackbar(
        'Limit Reached',
        'Playlists can have at most 25 items',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.warning,
        colorText: EColors.textOnPrimary,
      );
      return false;
    }
    try {
      final newItem = await PlaylistRepository.addItem(
        playlistId: playlistId,
        tmdbId: tmdbId,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
      );
      final current = _playlist.value;
      if (current != null) {
        _playlist.value = current.copyWith(items: [...current.items, newItem]);
      }
      if (Get.isRegistered<PlaylistController>()) PlaylistController.to.loadPlaylists();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add item',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
      return false;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await PlaylistRepository.removeItem(itemId);
      final current = _playlist.value;
      if (current != null) {
        final updated = current.items.where((i) => i.id != itemId).toList();
        _playlist.value = current.copyWith(items: updated);
      }
      if (Get.isRegistered<PlaylistController>()) PlaylistController.to.loadPlaylists();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove item',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }

  Future<void> reorder(List<String> orderedIds) async {
    final current = _playlist.value;
    if (current == null) return;
    final reordered = orderedIds.map((id) => items.firstWhere((i) => i.id == id)).toList();
    _playlist.value = current.copyWith(items: reordered);
    try {
      await PlaylistRepository.reorderItems(playlistId: playlistId, orderedIds: orderedIds);
    } catch (e) {
      // Revert on failure
      _playlist.value = current;
      Get.snackbar(
        'Error',
        'Failed to reorder items',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }

  Future<void> addAllToWatchlist(String watchlistId) async {
    try {
      final count = await WatchlistRepository.bulkAddFromPlaylist(
        items: items,
        watchlistId: watchlistId,
      );
      Get.snackbar(
        'Done',
        '$count items added to watchlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.success,
        colorText: EColors.textOnPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add items to watchlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }
}
