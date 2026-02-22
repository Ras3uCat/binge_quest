import 'package:get/get.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/review_repository.dart';

/// Mixin for review/rating functionality in ProgressController.
mixin ProgressReviewMixin on GetxController {
  WatchlistItem get item;

  final _userRating = Rxn<int>();
  final _userReviewText = Rxn<String>();
  final _isLoadingReview = false.obs;

  int? get userRating => _userRating.value;
  String? get userReviewText => _userReviewText.value;
  bool get isLoadingReview => _isLoadingReview.value;
  bool get hasReviewText =>
      _userReviewText.value != null && _userReviewText.value!.isNotEmpty;

  Future<void> loadUserReview() async {
    _isLoadingReview.value = true;
    try {
      final review = await ReviewRepository.getUserReview(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
      );
      _userRating.value = review?.rating;
      _userReviewText.value = review?.reviewText;
    } catch (e) {
      // ignore
    } finally {
      _isLoadingReview.value = false;
    }
  }

  Future<void> submitRating(int rating) async {
    _userRating.value = rating;
    try {
      await ReviewRepository.upsertReview(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
        rating: rating,
        reviewText: _userReviewText.value,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save rating');
    }
  }
}
