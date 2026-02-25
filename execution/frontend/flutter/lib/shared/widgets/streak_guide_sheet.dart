import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

class StreakGuideSheet extends StatelessWidget {
  const StreakGuideSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const StreakGuideSheet(),
      backgroundColor: EColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: EColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: EColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Streak Guide',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: EColors.textPrimary),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How your watching streak is tracked and what keeps it alive.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: EColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Building Your Streak'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Any Progress Counts',
                    'Any watch progress logged on a calendar day — even a single episode started — counts toward your streak.',
                    Icons.play_circle_outline,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Consecutive Days',
                    'Each day with progress logged extends your current streak by one.',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Breaking Your Streak'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Missing a Full Day',
                    'A full calendar day with no watch progress logged resets your streak to zero.',
                    Icons.warning_amber_rounded,
                    EColors.error,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Your Streak Stats'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Current Streak',
                    'Days in your active, unbroken run of watching.',
                    Icons.bolt,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Best Streak',
                    'Your all-time longest consecutive streak.',
                    Icons.emoji_events,
                    EColors.warning,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('7-Day Activity Dots'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Filled dot',
                    'Watch progress was logged on that day.',
                    Icons.circle,
                    EColors.success,
                  ),
                  _buildScoreItem(
                    'Empty dot',
                    'No activity was logged on that day.',
                    Icons.circle_outlined,
                    EColors.textSecondary,
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(ESizes.md),
                    decoration: BoxDecoration(
                      color: EColors.surface,
                      borderRadius: BorderRadius.circular(ESizes.radiusMd),
                      border: Border.all(color: EColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: EColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: ESizes.md),
                        Expanded(
                          child: Text(
                            'Even partial progress on an episode counts — you don\'t need to finish anything to keep your streak alive.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: EColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: EColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildScoreItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: EColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
