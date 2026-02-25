import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

class WatchPartyGuideSheet extends StatelessWidget {
  const WatchPartyGuideSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const WatchPartyGuideSheet(),
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
                'Watch Party Guide',
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
                    'How watch parties work and what you can do in them.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: EColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('How It Works'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Async Watching',
                    'Watch parties are not live screen-shares — everyone watches on their own time, whenever it suits them.',
                    Icons.people_outline,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Progress Tracking',
                    'Each member\'s progress is tracked individually. The party view shows where everyone is up to.',
                    Icons.bar_chart,
                    EColors.success,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('TV Shows vs Movies'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'TV Shows',
                    'Progress is tracked per episode, per member, across all seasons.',
                    Icons.tv_outlined,
                    EColors.primary,
                  ),
                  _buildScoreItem(
                    'Movies',
                    'A progress bar per member shows how far along each person is.',
                    Icons.movie_outlined,
                    EColors.secondary,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Party Controls'),
                  const SizedBox(height: 12),
                  _buildScoreItem(
                    'Nudging',
                    'You can nudge a member who is behind you — but only if you\'ve watched more than them. If you\'re last in the party, everyone can nudge you but you can\'t nudge anyone.',
                    Icons.notifications_active_outlined,
                    Colors.orange,
                  ),
                  _buildScoreItem(
                    'Nudge Cooldown',
                    'Each member can only be nudged once every 24 hours.',
                    Icons.timer_outlined,
                    EColors.textSecondary,
                  ),
                  _buildScoreItem(
                    'Leaving',
                    'Any member can leave a party independently at any time.',
                    Icons.exit_to_app,
                    EColors.textSecondary,
                  ),
                  _buildScoreItem(
                    'Dissolving',
                    'The party creator can dissolve the party for all members.',
                    Icons.delete_outline,
                    EColors.error,
                  ),
                  _buildScoreItem(
                    'Finishing',
                    'Completing all episodes (or the full movie) marks you as done in the party.',
                    Icons.check_circle_outline,
                    EColors.success,
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
                            'Everyone watches at their own pace — there\'s no requirement to stay in sync.',
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
