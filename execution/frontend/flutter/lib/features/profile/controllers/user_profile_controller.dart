import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/review.dart';
import '../../../shared/models/user_badge.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/repositories/review_repository.dart';
import '../../social/controllers/friend_controller.dart';

class UserProfileController extends GetxController {
  final String? userId;
  final String? username;

  UserProfileController({this.userId, this.username})
    : assert(userId != null || username != null, 'userId or username required');

  static SupabaseClient get _client => Supabase.instance.client;

  final profile = Rxn<UserProfile>();
  final isLoading = true.obs;
  final loadFailed = false.obs;
  final isFriend = false.obs;
  final hasPendingRequest = false.obs;
  final isSendingRequest = false.obs;
  final stats = Rxn<Map<String, dynamic>>();
  final earnedBadges = <UserBadge>[].obs;
  final ratedItems = <Review>[].obs;
  final ratedItemsSort = ReviewSort.dateDesc.obs;
  final isLoadingRatings = false.obs;
  final ratingsError = Rxn<String>();

  final _allRatedItems = <Review>[];
  String? resolvedUserId;

  bool get isCurrentUser =>
      resolvedUserId != null && resolvedUserId == SupabaseService.currentUserId;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    loadFailed.value = false;
    try {
      String? uid = userId;
      if (uid == null && username != null) {
        final row = await _client
            .from('users')
            .select('id')
            .eq('username', username!)
            .maybeSingle();
        uid = row?['id'] as String?;
      }
      if (uid == null) {
        loadFailed.value = true;
        return;
      }
      resolvedUserId = uid;
      loadRatedItems();

      final row = await _client.from('users').select().eq('id', uid).maybeSingle();
      if (row != null) profile.value = UserProfile.fromJson(row);

      _syncFriendStatus(uid);
      _loadBadges(uid);
      if (profile.value?.shareWatchingActivity == true) {
        _loadStats(uid);
      }
    } catch (e) {
      debugPrint('UserProfileController load error: $e');
      loadFailed.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void _syncFriendStatus(String uid) {
    if (!Get.isRegistered<FriendController>()) return;
    final ctrl = FriendController.to;
    isFriend.value = ctrl.friendIds.contains(uid);
    hasPendingRequest.value = ctrl.pendingSent.any(
      (f) => f.addresseeId == uid || f.requesterId == uid,
    );
  }

  Future<void> _loadStats(String uid) async {
    try {
      final response = await _client.rpc('get_user_stats', params: {'p_user_id': uid});
      if (response != null && (response as List).isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        stats.value = {
          'items_completed': (data['items_completed'] as num?)?.toInt() ?? 0,
          'minutes_watched': (data['minutes_watched'] as num?)?.toInt() ?? 0,
          'movies_completed': (data['movies_completed'] as num?)?.toInt() ?? 0,
          'shows_completed': (data['shows_completed'] as num?)?.toInt() ?? 0,
          'episodes_watched': (data['episodes_watched'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (e) {
      debugPrint('UserProfileController stats error: $e');
    }
  }

  Future<void> _loadBadges(String uid) async {
    try {
      final response = await _client
          .from('user_badges')
          .select('*, badges(*)')
          .eq('user_id', uid)
          .order('earned_at', ascending: false);
      earnedBadges.value = (response as List).map((j) => UserBadge.fromJson(j)).toList();
    } catch (e) {
      debugPrint('UserProfileController badges error: $e');
    }
  }

  Future<void> loadRatedItems() async {
    final uid = resolvedUserId;
    if (uid == null) return;
    isLoadingRatings.value = true;
    ratingsError.value = null;
    try {
      final items = await ReviewRepository.getReviewsByUser(uid);
      _allRatedItems
        ..clear()
        ..addAll(items);
      _applySortAndUpdate();
    } catch (e) {
      ratingsError.value = 'Failed to load ratings';
    } finally {
      isLoadingRatings.value = false;
    }
  }

  void onSortRatingsDate() {
    final current = ratedItemsSort.value;
    if (current == ReviewSort.dateDesc) {
      ratedItemsSort.value = ReviewSort.dateAsc;
    } else if (current == ReviewSort.dateAsc) {
      ratedItemsSort.value = ReviewSort.dateDesc;
    } else {
      ratedItemsSort.value = ReviewSort.dateDesc;
    }
    _applySortAndUpdate();
  }

  void onSortRatingsRating() {
    final current = ratedItemsSort.value;
    if (current == ReviewSort.ratingDesc) {
      ratedItemsSort.value = ReviewSort.ratingAsc;
    } else if (current == ReviewSort.ratingAsc) {
      ratedItemsSort.value = ReviewSort.ratingDesc;
    } else {
      ratedItemsSort.value = ReviewSort.ratingDesc;
    }
    _applySortAndUpdate();
  }

  void _applySortAndUpdate() {
    final sorted = List<Review>.from(_allRatedItems);
    switch (ratedItemsSort.value) {
      case ReviewSort.dateDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReviewSort.dateAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ReviewSort.ratingDesc:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case ReviewSort.ratingAsc:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
    }
    ratedItems.assignAll(sorted);
  }

  Future<void> sendFriendRequest() async {
    final p = profile.value;
    if (p == null || isSendingRequest.value || isFriend.value) return;
    if (!Get.isRegistered<FriendController>()) return;

    isSendingRequest.value = true;
    final success = await FriendController.to.sendFriendRequest(p);
    if (success) {
      hasPendingRequest.value = true;
      Get.snackbar(
        'Request Sent',
        'Friend request sent to ${p.displayLabel}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.success,
        colorText: EColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
    }
    isSendingRequest.value = false;
  }
}
