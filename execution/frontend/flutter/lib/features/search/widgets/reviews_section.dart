import 'package:flutter/material.dart';
import '../../../../core/constants/e_colors.dart';
import '../../../../core/constants/e_sizes.dart';
import '../../../../shared/models/review.dart';
import '../../../../shared/repositories/review_repository.dart';
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
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReviewFormSheet(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
        initialRating: _userReview?.rating,
        initialText: _userReview?.reviewText,
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  Future<void> _deleteReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          'Delete Review?',
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete your review?',
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: EColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ReviewRepository.deleteReview(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
      );
      _loadReviews();
    }
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
