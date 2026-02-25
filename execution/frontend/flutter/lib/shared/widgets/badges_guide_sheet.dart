import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

class BadgesGuideSheet extends StatelessWidget {
  const BadgesGuideSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const BadgesGuideSheet(),
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
                'Badges Guide',
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
                    'How badges are earned and what each category covers.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: EColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Badge Categories'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Completion',
                    'Awarded for finishing shows and movies — the more you complete, the more you unlock.',
                    Icons.check_circle_outline,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Milestone',
                    'Hit watch time and quantity targets — e.g. 10 hours total, 5 shows completed.',
                    Icons.emoji_events_outlined,
                    EColors.warning,
                  ),
                  _buildScoreItem(
                    'Genre',
                    'Watch enough content in specific genres to earn that genre\'s badge.',
                    Icons.movie_outlined,
                    EColors.secondary,
                  ),
                  _buildScoreItem(
                    'Activity & Streak',
                    'Tied to consistent watching habits and maintaining streaks — e.g. a 7-day streak.',
                    Icons.local_fire_department_outlined,
                    Colors.orange,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('How They\'re Awarded'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Automatic',
                    'Badges unlock on your next app open after criteria are met — no manual claiming needed.',
                    Icons.auto_awesome_outlined,
                    EColors.success,
                  ),
                  _buildScoreItem(
                    'Always Visible',
                    'Locked badges are shown as motivation — you can always see what you\'re working toward.',
                    Icons.lock_outline,
                    EColors.textSecondary,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Activity Badge Thresholds'),
                  const SizedBox(height: 12),
                  _buildStatusItem('Queue Manager', '50+ Queue Health score', EColors.warning),
                  _buildStatusItem('Efficiency Expert', '75+ Queue Health score', EColors.primary),
                  _buildStatusItem('Queue Master', '90+ Queue Health score', EColors.success),

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

  Widget _buildStatusItem(String label, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: EColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: EColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
