import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../stats/screens/stats_screen.dart';
import '../controllers/profile_controller.dart';

/// Stats summary card shown on the profile screen.
/// Tapping anywhere on the card — or the "View Full Stats" button — navigates
/// to [StatsScreen].
class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;

    return GestureDetector(
      onTap: () => Get.to(() => const StatsScreen()),
      child: Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(color: EColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.md),
            Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(ESizes.lg),
                    child: CircularProgressIndicator(color: EColors.primary),
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.schedule,
                          label: 'Time Watched',
                          value: controller.formattedWatchTime,
                          color: EColors.primary,
                        ),
                      ),
                      const SizedBox(width: ESizes.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.play_circle_outline,
                          label: 'Episodes',
                          value: '${controller.episodesWatched}',
                          color: EColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ESizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.movie,
                          label: 'Movies',
                          value: '${controller.moviesCompleted}',
                          color: EColors.accent,
                        ),
                      ),
                      const SizedBox(width: ESizes.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.tv,
                          label: 'TV Shows',
                          value: '${controller.showsCompleted}',
                          color: EColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ESizes.md),
                  TextButton.icon(
                    onPressed: () => Get.to(() => const StatsScreen()),
                    icon: const Icon(Icons.bar_chart, size: ESizes.iconSm),
                    label: const Text('View Full Stats'),
                    style: TextButton.styleFrom(
                      foregroundColor: EColors.primary,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: ESizes.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: ESizes.fontXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: ESizes.fontXs,
              color: EColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
