import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../shared/models/followed_talent.dart';
import '../../../shared/repositories/followed_talent_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Controller for managing followed talent state.
class FollowedTalentController extends GetxController {
  static FollowedTalentController get to => Get.find();

  final FollowedTalentRepository _repository = FollowedTalentRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<FollowedTalent> followedTalent = <FollowedTalent>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadFollowedTalent();
  }

  String? get _userId => _authController.user?.id;

  /// Set of TMDB person IDs being followed for quick lookups.
  Set<int> get followedPersonIds =>
      followedTalent.map((t) => t.tmdbPersonId).toSet();

  /// Check if a person is currently followed.
  bool isFollowing(int tmdbPersonId) =>
      followedPersonIds.contains(tmdbPersonId);

  /// Load all followed talent for the current user.
  Future<void> loadFollowedTalent() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      isLoading.value = true;
      final talent = await _repository.getFollowedTalent(userId);
      followedTalent.assignAll(talent);
    } catch (e) {
      debugPrint('Error loading followed talent: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle follow state for a person with optimistic UI update.
  Future<void> toggleFollow({
    required int tmdbPersonId,
    required String personName,
    required String personType,
    String? profilePath,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final currentlyFollowing = isFollowing(tmdbPersonId);

    if (currentlyFollowing) {
      await _unfollow(userId, tmdbPersonId);
    } else {
      await _follow(
        userId: userId,
        tmdbPersonId: tmdbPersonId,
        personName: personName,
        personType: personType,
        profilePath: profilePath,
      );
    }
  }

  Future<void> _follow({
    required String userId,
    required int tmdbPersonId,
    required String personName,
    required String personType,
    String? profilePath,
  }) async {
    // Optimistic: add to local list
    final optimistic = FollowedTalent(
      id: 'temp_$tmdbPersonId',
      userId: userId,
      tmdbPersonId: tmdbPersonId,
      personName: personName,
      personType: personType,
      profilePath: profilePath,
      createdAt: DateTime.now(),
    );
    followedTalent.insert(0, optimistic);

    try {
      await _repository.followTalent(
        userId: userId,
        tmdbPersonId: tmdbPersonId,
        personName: personName,
        personType: personType,
        profilePath: profilePath,
      );
      // Reload to get the real ID from the server
      await loadFollowedTalent();
    } catch (e) {
      // Revert optimistic update
      followedTalent.removeWhere((t) => t.tmdbPersonId == tmdbPersonId);
      debugPrint('Error following talent: $e');
      Get.snackbar('Error', 'Failed to follow $personName');
    }
  }

  Future<void> _unfollow(String userId, int tmdbPersonId) async {
    // Optimistic: remember item and remove from local list
    final index = followedTalent.indexWhere(
      (t) => t.tmdbPersonId == tmdbPersonId,
    );
    if (index == -1) return;

    final removed = followedTalent.removeAt(index);

    try {
      await _repository.unfollowTalent(
        userId: userId,
        tmdbPersonId: tmdbPersonId,
      );
    } catch (e) {
      // Revert optimistic update
      followedTalent.insert(index.clamp(0, followedTalent.length), removed);
      debugPrint('Error unfollowing talent: $e');
      Get.snackbar('Error', 'Failed to unfollow ${removed.personName}');
    }
  }
}
