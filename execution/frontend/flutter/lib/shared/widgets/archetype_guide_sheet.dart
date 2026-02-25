import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

class ArchetypeGuideSheet extends StatelessWidget {
  const ArchetypeGuideSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const ArchetypeGuideSheet(),
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
                'Viewer Archetypes',
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
                    'How your viewer personality is classified based on your watching behaviour.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: EColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('What It Is'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Data-Driven',
                    'Your archetype is computed from your real watching behaviour — no quiz needed.',
                    Icons.analytics_outlined,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    '12 Possible Types',
                    'There are 12 archetypes, each derived from a different signal — e.g. Weekend Warrior, Season Slayer, Deep Cut Explorer.',
                    Icons.grid_view_outlined,
                    EColors.secondary,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('How It\'s Calculated'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    '90-Day Window',
                    'Scores use a rolling 90-day activity window — old habits don\'t permanently define your archetype.',
                    Icons.history,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Minimum Threshold',
                    'You need at least 5 completed titles and 20 episodes watched before an archetype is assigned.',
                    Icons.lock_clock_outlined,
                    EColors.textSecondary,
                  ),
                  _buildScoreItem(
                    'Auto-Updates',
                    'Recalculated every 5th episode completion and nightly. Pin an archetype to lock it and prevent auto-updates.',
                    Icons.sync,
                    EColors.success,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Dual Archetypes'),
                  const SizedBox(height: 12),

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
                            'If two archetypes score within 5% of each other, both are shown — e.g. "Midnight Drifter + Completionist". Maximum two archetypes displayed.',
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

                  const SizedBox(height: 16),

                  _buildScoreItem(
                    'Still Exploring\u2026',
                    'If you haven\'t hit the activity threshold yet, you\'ll see "Still Exploring\u2026" — keep watching!',
                    Icons.explore_outlined,
                    EColors.warning,
                  ),

                  const SizedBox(height: 8),

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
                          Icons.touch_app_outlined,
                          color: EColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: ESizes.md),
                        Expanded(
                          child: Text(
                            'Tap your archetype badge to see a full score breakdown across all 12 types.',
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
