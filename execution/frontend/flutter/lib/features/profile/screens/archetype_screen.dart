import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/widgets/archetype_guide_sheet.dart';
import '../controllers/archetype_controller.dart';
import '../widgets/archetype_badge.dart';
import '../widgets/archetype_history_timeline.dart';
import '../widgets/archetype_radar_chart.dart';

/// Full-screen archetype detail — mirrors the Stats screen structure.
class ArchetypeScreen extends StatelessWidget {
  const ArchetypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [EColors.backgroundSecondary, EColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  final ctrl = ArchetypeController.to;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(ESizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ArchetypeBadge(
                          primary: ctrl.primary,
                          secondary: ctrl.secondary,
                          showTagline: true,
                        ),
                        if (ctrl.primary?.archetype?.description != null) ...[
                          const SizedBox(height: ESizes.md),
                          Text(
                            ctrl.primary!.archetype!.description,
                            style: const TextStyle(
                              color: EColors.textSecondary,
                              fontSize: ESizes.fontMd,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: ESizes.lg),
                        _buildSectionLabel('Score Breakdown'),
                        const SizedBox(height: ESizes.sm),
                        ArchetypeRadarChart(
                          scores: ctrl.allScores.toList(),
                          archetypes: ctrl.allArchetypes.toList(),
                        ),
                        const SizedBox(height: ESizes.lg),
                        _buildSectionLabel('Archetype History'),
                        const SizedBox(height: ESizes.sm),
                        ArchetypeHistoryTimeline(history: ctrl.history.toList()),
                        const SizedBox(height: ESizes.xxl),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          const Expanded(
            child: Text(
              'Archetypes',
              style: TextStyle(
                fontSize: ESizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: EColors.textSecondary),
            iconSize: 20,
            onPressed: ArchetypeGuideSheet.show,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: EColors.textSecondary,
          fontSize: ESizes.fontMd,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
