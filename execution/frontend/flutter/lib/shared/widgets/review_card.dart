import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/e_colors.dart';
import '../models/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCurrentUser;
  final bool isFriend;

  const ReviewCard({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
    this.isCurrentUser = false,
    this.isFriend = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: EColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        color: EColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isFriend) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Friend',
                          style: TextStyle(
                            color: EColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  DateFormat.yMMMd().format(review.createdAt),
                  style: const TextStyle(color: EColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.live_tv,
                  size: 16,
                  color: index < review.rating ? EColors.primary : EColors.textTertiary,
                );
              }),
            ),
            if (review.hasText) ...[
              const SizedBox(height: 8),
              Text(review.reviewText!, style: const TextStyle(color: EColors.textPrimary)),
            ],
            if (isCurrentUser) ...[
              const Divider(color: EColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Edit', style: TextStyle(color: EColors.accent)),
                  ),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: EColors.error),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
