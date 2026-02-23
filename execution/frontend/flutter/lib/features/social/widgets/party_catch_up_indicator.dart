import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';

/// Catch-Up Indicator (TV only) — lists members who are behind the leader.
class PartyCatchUpIndicator extends StatelessWidget {
  final List<WatchPartyMemberProgress> members;

  const PartyCatchUpIndicator({super.key, required this.members});

  /// Returns a sortable integer score for a member's furthest position.
  /// season * 10000 + episode — higher = further ahead.
  int _score(WatchPartyMemberProgress m) {
    if (m.episodes.isEmpty) return -1;
    return m.episodes
        .map((e) => e.seasonNumber * 10000 + e.episodeNumber)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (members.length < 2) return const SizedBox.shrink();

    final leaderScore = members.map(_score).reduce((a, b) => a > b ? a : b);
    if (leaderScore < 0) return const SizedBox.shrink();

    final behind = <String>[];
    for (final m in members) {
      final score = _score(m);
      if (score < 0) {
        behind.add('${m.displayName} has not started');
      } else if (score < leaderScore) {
        final leaderSeason = leaderScore ~/ 10000;
        final mSeason = score ~/ 10000;
        final mEp = score % 10000;
        final leaderEp = leaderScore % 10000;
        if (mSeason < leaderSeason) {
          behind.add('${m.displayName} is on S${mSeason}E$mEp');
        } else {
          final diff = leaderEp - mEp;
          behind.add(
              '${m.displayName} is $diff ep${diff == 1 ? '' : 's'} behind');
        }
      }
    }
    if (behind.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: ESizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: behind
            .map((t) => Text(t,
                style: const TextStyle(
                    color: EColors.textSecondary, fontSize: ESizes.fontSm)))
            .toList(),
      ),
    );
  }
}
