import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/e_colors.dart';
import '../../../../core/constants/e_sizes.dart';
import '../../../../shared/models/review.dart';
import '../../../../shared/repositories/review_repository.dart';
import '../../../../shared/widgets/e_confirm_dialog.dart';
import '../../../../shared/widgets/review_card.dart';
import 'review_form_sheet.dart';

class ReviewsSection extends StatefulWidget {
  final int tmdbId;
  final String mediaType;

  const ReviewsSection({
    super.key,
    required this.tmdbId,
    required this.mediaType,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  List<Review>? _reviews;
  Review? _userReview;
  double? _averageRating;
  int _reviewCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewRepository.getReviews(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
      );
      final userReview = await ReviewRepository.getUserReview(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
      );
      final stats = await ReviewRepository.getAverageRating(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _userReview = userReview;
          _averageRating = stats.average;
          _reviewCount = stats.count;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openReviewForm() async {
    final result = await Get.bottomSheet<bool>(
      Container(
        decoration: const BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ReviewFormSheet(
          tmdbId: widget.tmdbId,
          mediaType: widget.mediaType,
          initialRating: _userReview?.rating,
          initialText: _userReview?.reviewText,
        ),
      ),
      isScrollControlled: true,
    );

    if (result == true) {
      _loadReviews();
    }
  }

  Future<void> _deleteReview() async {
    EConfirmDialog.show(
      title: 'Delete Review?',
      message: 'Are you sure you want to delete your review?',
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () async {
        await ReviewRepository.deleteReview(
          tmdbId: widget.tmdbId,
          mediaType: widget.mediaType,
        );
        _loadReviews();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews${_isLoading ? " (loading...)" : " (${_reviews?.length ?? 0})"}',
                style: const TextStyle(
                  color: EColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _openReviewForm,
                child: Text(
                  _userReview == null ? 'Write Review' : 'Edit Review',
                  style: const TextStyle(color: EColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reviews == null || _reviews!.isEmpty)
            const Text(
              'No reviews yet. Be the first!',
              style: TextStyle(color: EColors.textSecondary),
            )
          else
            Column(
              children: _reviews!.map((review) {
                final isCurrentUser = review.userId == _userReview?.userId;
                return ReviewCard(
                  review: review,
                  isCurrentUser: isCurrentUser,
                  onEdit: isCurrentUser ? _openReviewForm : null,
                  onDelete: isCurrentUser ? _deleteReview : null,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
