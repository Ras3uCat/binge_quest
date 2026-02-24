import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

class QueueEfficiencyGuideSheet extends StatelessWidget {
  const QueueEfficiencyGuideSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const QueueEfficiencyGuideSheet(),
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
                'Queue Efficiency Guide',
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
                    'Understanding your score helps you optimize your binge watching.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: EColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('How Scoring Works'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Start at 100',
                    'Everyone starts perfect. Your score only changes based on what you\'ve started watching.',
                    Icons.star,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Abandonment Penalty',
                    'Up to -80 points based on how many of your started items have gone stale. The more you abandon, the bigger the hit.',
                    Icons.arrow_downward,
                    EColors.error,
                  ),
                  _buildScoreItem(
                    'Momentum Bonus',
                    '+8 points for each item finished this week (max +30). Finishing things fast brings your score right back up.',
                    Icons.arrow_upward,
                    EColors.success,
                  ),
                  _buildScoreItem(
                    'Wishlist is free',
                    'Adding titles you haven\'t started yet never lowers your score. Build your list freely.',
                    Icons.playlist_add,
                    EColors.textSecondary,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Status Legend'),
                  const SizedBox(height: 12),
                  _buildStatusItem(
                    'Active',
                    'Watched recently (last 7 days) or not yet started',
                    EColors.success,
                  ),
                  _buildStatusItem(
                    'Idle',
                    'Started but no activity in 7–30 days',
                    EColors.warning,
                  ),
                  _buildStatusItem(
                    'Stale',
                    'Started but abandoned for 30+ days',
                    EColors.error,
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
                            'Items that are not released or not available on streaming are excluded from the score calculation.',
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

  Widget _buildStatusItem(String status, String description, Color color) {
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
            status,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: EColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: EColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
