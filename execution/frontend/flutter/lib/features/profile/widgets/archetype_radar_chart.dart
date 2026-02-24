import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/archetype.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';

/// Spider/radar chart of all 12 archetype scores.
///
/// [scores] must be all 12 UserArchetype rows for a compute run.
/// [archetypes] is the ordered reference list for axis labels (sort_order).
class ArchetypeRadarChart extends StatelessWidget {
  final List<UserArchetype> scores;
  final List<Archetype> archetypes;

  const ArchetypeRadarChart({
    super.key,
    required this.scores,
    required this.archetypes,
  });

  @override
  Widget build(BuildContext context) {
    final orderedScores = _buildOrderedEntries();

    if (orderedScores.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSm,
            ),
          ),
        ),
      );
    }

    final primaryColor = EColors.primary;

    return SizedBox(
      height: 240,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            // Phantom dataset fixes the scale to 0–1.
            RadarDataSet(
              dataEntries: List.generate(
                orderedScores.length,
                (_) => const RadarEntry(value: 1),
              ),
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
            ),
            // Actual score dataset.
            RadarDataSet(
              dataEntries: orderedScores
                  .map((v) => RadarEntry(value: v))
                  .toList(),
              fillColor: primaryColor.withOpacity(0.2),
              borderColor: primaryColor,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(
            fontSize: 0,
            color: Colors.transparent,
          ),
          tickBorderData: BorderSide(
            color: EColors.border.withOpacity(0.4),
            width: 1,
          ),
          gridBorderData: BorderSide(
            color: EColors.border.withOpacity(0.4),
            width: 1,
          ),
          radarBorderData: BorderSide(color: EColors.border, width: 1),
          titleTextStyle: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontXs,
          ),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) {
            if (index >= archetypes.length) {
              return const RadarChartTitle(text: '');
            }
            final name = archetypes[index].displayName;
            final label = name.length > 10
                ? '${name.substring(0, 9)}…'
                : name;
            return RadarChartTitle(text: label, angle: 0);
          },
        ),
      ),
    );
  }

  /// Returns score values in archetypes sort_order, defaulting to 0 for gaps.
  List<double> _buildOrderedEntries() {
    if (archetypes.isEmpty) return [];
    final scoreMap = {for (final s in scores) s.archetypeId: s.score};
    return archetypes.map((a) => scoreMap[a.id] ?? 0.0).toList();
  }
}
