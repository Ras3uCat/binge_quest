import 'package:flutter/material.dart';
import '../../../shared/models/archetype.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import 'archetype_badge.dart';
import 'archetype_history_timeline.dart';
import 'archetype_radar_chart.dart';

/// Bottom sheet showing full archetype details for a user's profile.
///
/// All data is passed as constructor params — no Obx/reactive widgets inside
/// to comply with bottom-sheet animation constraints.
///
/// Show via:
/// ```dart
/// Get.bottomSheet(ArchetypeDetailSheet(...));
/// ```
class ArchetypeDetailSheet extends StatelessWidget {
  final UserArchetype? primary;
  final UserArchetype? secondary;
  final List<UserArchetype> allScores;
  final List<UserArchetype> history;
  final List<Archetype> allArchetypes;

  const ArchetypeDetailSheet({
    super.key,
    required this.primary,
    required this.secondary,
    required this.allScores,
    required this.history,
    required this.allArchetypes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ESizes.md,
                ESizes.sm,
                ESizes.md,
                ESizes.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  SizedBox(height: ESizes.md),
                  if (primary != null) _buildDescription(),
                  SizedBox(height: ESizes.lg),
                  _buildSectionLabel('Score Breakdown'),
                  SizedBox(height: ESizes.sm),
                  ArchetypeRadarChart(
                    scores: allScores,
                    archetypes: allArchetypes,
                  ),
                  SizedBox(height: ESizes.lg),
                  _buildSectionLabel('Archetype History'),
                  SizedBox(height: ESizes.sm),
                  ArchetypeHistoryTimeline(history: history),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: EdgeInsets.only(top: ESizes.sm, bottom: ESizes.xs),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: EColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ArchetypeBadge(
          primary: primary,
          secondary: secondary,
          showTagline: true,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final desc = primary!.archetype?.description;
    if (desc == null) return const SizedBox.shrink();
    return Text(
      desc,
      style: TextStyle(
        color: EColors.textSecondary,
        fontSize: ESizes.fontMd,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: EColors.textSecondary,
          fontSize: ESizes.fontMd,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
