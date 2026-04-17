import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../models/playlist.dart';
import '../repositories/playlist_repository.dart';
import 'playlist_detail_controller.dart';

class PlaylistController extends GetxController {
  static PlaylistController get to => Get.find();

  final _playlists = <Playlist>[].obs;
  final _isLoading = false.obs;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading.value;

  String? _userId;

  void init(String userId) {
    _userId = userId;
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    if (_userId == null) return;
    _isLoading.value = true;
    try {
      final result = await PlaylistRepository.getUserPlaylists(_userId!);
      _playlists.assignAll(result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load playlists',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    bool isPublic = true,
    bool isRanked = false,
  }) async {
    try {
      final created = await PlaylistRepository.createPlaylist(
        name: name,
        description: description,
        isPublic: isPublic,
        isRanked: isRanked,
      );
      _playlists.insert(0, created);
      return created;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
      return null;
    }
  }

  Future<void> updatePlaylist({
    required String id,
    String? name,
    String? description,
    bool? isPublic,
    bool? isRanked,
  }) async {
    try {
      final updated = await PlaylistRepository.updatePlaylist(
        id: id,
        name: name,
        description: description,
        isPublic: isPublic,
        isRanked: isRanked,
      );
      final index = _playlists.indexWhere((p) => p.id == id);
      if (index != -1) {
        // Preserve existing items — updatePlaylist only returns metadata columns
        _playlists[index] = updated.copyWith(items: _playlists[index].items);
      }
      if (Get.isRegistered<PlaylistDetailController>(tag: id)) {
        Get.find<PlaylistDetailController>(tag: id).updatePlaylistMeta(updated);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await PlaylistRepository.deletePlaylist(id);
      _playlists.removeWhere((p) => p.id == id);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }
}
