import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/e_colors.dart';
import '../../../../shared/widgets/tv_rating_selector.dart';
import '../../../../shared/repositories/review_repository.dart';

class ReviewFormSheet extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final int? initialRating;
  final String? initialText;

  const ReviewFormSheet({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    this.initialRating,
    this.initialText,
  });

  @override
  State<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<ReviewFormSheet> {
  late int _rating;
  late TextEditingController _textController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_rating == 0) {
      Get.snackbar(
        'Missing Rating',
        'Please select a rating',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.surface,
        colorText: EColors.textPrimary,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ReviewRepository.upsertReview(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
        rating: _rating,
        reviewText: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          '$e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: EColors.error,
          colorText: EColors.textOnPrimary,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Write a Review',
            style: TextStyle(
              color: EColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Rating',
            style: TextStyle(color: EColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TvRatingSelector(
            rating: _rating == 0 ? null : _rating,
            onRatingChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            maxLength: 500,
            maxLines: 4,
            style: const TextStyle(color: EColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Optional: Write your thoughts...',
              hintStyle: TextStyle(color: EColors.textTertiary),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: EColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: EColors.primary),
              ),
              counterStyle: TextStyle(color: EColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          SafeArea(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.primary,
                foregroundColor: EColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}
