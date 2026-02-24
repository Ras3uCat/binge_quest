import 'package:flutter/material.dart';
import '../../../shared/models/archetype.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import 'archetype_badge.dart';

/// Scrollable list of past rank-1 archetype snapshots.
///
/// [history] is ordered newest-first (as returned by the repository).
class ArchetypeHistoryTimeline extends StatelessWidget {
  final List<UserArchetype> history;

  const ArchetypeHistoryTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: ESizes.lg),
        child: Center(
          child: Text(
            'No archetype history yet.',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSm,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => Divider(
        color: EColors.border.withOpacity(0.4),
        height: 1,
      ),
      itemBuilder: (_, index) => _HistoryRow(entry: history[index]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final UserArchetype entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final arch = entry.archetype;
    final color = arch != null
        ? Color(int.parse(arch.colorHex.replaceAll('#', '0xFF')))
        : EColors.textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ESizes.sm),
          Expanded(
            child: ArchetypeBadge(primary: entry),
          ),
          Text(
            _formatDate(entry.computedAt),
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSm,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}
