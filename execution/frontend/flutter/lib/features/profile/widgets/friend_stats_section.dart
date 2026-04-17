import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/user_profile_controller.dart';

class FriendStatsSection extends StatelessWidget {
  final UserProfileController ctrl;

  const FriendStatsSection({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = ctrl.stats.value;
      if (s == null) return const SizedBox.shrink();
      final hours = ((s['minutes_watched'] as int) / 60).round();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusLg),
          border: Border.all(color: EColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Watching Stats',
              style: TextStyle(
                fontSize: ESizes.fontMd,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.md),
            Row(
              children: [
                _statItem('Completed', '${s['items_completed']}'),
                _statItem('Movies', '${s['movies_completed']}'),
                _statItem('Shows', '${s['shows_completed']}'),
                _statItem('Hours', '$hours'),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
