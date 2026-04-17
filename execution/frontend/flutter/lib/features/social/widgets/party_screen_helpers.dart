import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';
import '../controllers/watch_party_controller.dart';
import '../utils/watch_party_sayings.dart';
import 'party_catch_up_indicator.dart';
import 'party_progress_row.dart';

// ---------------------------------------------------------------------------
// TV Body — member progress rows sorted by TV score
// ---------------------------------------------------------------------------
class PartyTvBody extends StatelessWidget {
  final WatchPartyController ctrl;
  final String partyId;
  final String partyName;

  const PartyTvBody({
    super.key,
    required this.ctrl,
    required this.partyId,
    required this.partyName,
  });

  /// TV score: max(season * 10000 + episode * 100 + pct ~/ 10) across
  /// episodes the user has actually watched or started (progress > 0).
  /// Fully-unstarted episodes are excluded so a user with no progress
  /// doesn't score the same as someone who finished a later episode.
  int _score(WatchPartyMemberProgress m) {
    if (m.episodes.isEmpty) return -1;
    final active = m.episodes.where((e) => e.watched || e.progressPercent > 0).toList();
    if (active.isEmpty) return -1;
    return active
        .map((e) => e.seasonNumber * 10000 + e.episodeNumber * 100 + e.displayPercent ~/ 10)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.isLoading.value;
      final raw = ctrl.progressByParty[partyId] ?? [];

      if (loading && raw.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: EColors.primary));
      }

      final members = [...raw]..sort((a, b) => _score(b).compareTo(_score(a)));
      final scores = members.map(_score).toList();
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';

      return RefreshIndicator(
        onRefresh: () => ctrl.openParty(partyId),
        color: EColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(ESizes.md),
          children: [
            ...List.generate(members.length, (i) {
              final m = members[i];
              final self = m.userId == uid;
              final tied = isTiedAt(i, scores);
              return PartyProgressRow.tv(
                key: ValueKey(m.userId),
                member: m,
                saying: _saying(i, members, ctrl, self, tied, scores),
                sayingColor: _color(i, members.length, m, tied),
                isSelf: self,
                canNudge: ctrl.canNudge(m.userId),
                nudgeTimeRemaining: ctrl.nudgeTimeRemaining(m.userId),
                onNudge: self
                    ? null
                    : () => ctrl.nudgeMember(
                        partyId: partyId,
                        partyName: partyName,
                        nudgedUserId: m.userId,
                        nudgedDisplayName: m.displayName,
                      ),
              );
            }),
            PartyCatchUpIndicator(members: members),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Movie Body — linear progress bars sorted by percent
// ---------------------------------------------------------------------------
class PartyMovieBody extends StatelessWidget {
  final WatchPartyController ctrl;
  final String partyId;
  final String partyName;

  const PartyMovieBody({
    super.key,
    required this.ctrl,
    required this.partyId,
    required this.partyName,
  });

  int _score(WatchPartyMemberProgress m) =>
      m.episodes.isNotEmpty ? m.episodes.first.displayPercent : -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.isLoading.value;
      final raw = ctrl.progressByParty[partyId] ?? [];

      if (loading && raw.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: EColors.primary));
      }

      if (!loading && raw.isEmpty) {
        return const Center(
          child: Text(
            'No members yet',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontMd),
          ),
        );
      }

      final members = [...raw]..sort((a, b) => _score(b).compareTo(_score(a)));
      final scores = members.map(_score).toList();
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';

      return RefreshIndicator(
        onRefresh: () => ctrl.openParty(partyId),
        color: EColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(ESizes.md),
          children: [
            ...List.generate(members.length, (i) {
              final m = members[i];
              final self = m.userId == uid;
              final tied = isTiedAt(i, scores);
              return PartyProgressRow.movie(
                key: ValueKey(m.userId),
                member: m,
                saying: _saying(i, members, ctrl, self, tied, scores),
                sayingColor: _color(i, members.length, m, tied),
                isSelf: self,
                canNudge: ctrl.canNudge(m.userId),
                nudgeTimeRemaining: ctrl.nudgeTimeRemaining(m.userId),
                onNudge: self
                    ? null
                    : () => ctrl.nudgeMember(
                        partyId: partyId,
                        partyName: partyName,
                        nudgedUserId: m.userId,
                        nudgedDisplayName: m.displayName,
                      ),
              );
            }),
            _furthestBehind(members),
          ],
        ),
      );
    });
  }

  Widget _furthestBehind(List<WatchPartyMemberProgress> members) {
    if (members.length < 2) return const SizedBox.shrink();
    WatchPartyMemberProgress? behind;
    int minPct = 101;
    for (final m in members) {
      final pct = m.episodes.isNotEmpty ? m.episodes.first.progressPercent : 0;
      if (pct < minPct) {
        minPct = pct;
        behind = m;
      }
    }
    if (behind == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: ESizes.sm),
      child: Text(
        '${behind.displayName} is furthest behind',
        style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared saying/colour helpers — thin wrappers around watch_party_sayings.dart
// ---------------------------------------------------------------------------

String? _saying(
  int index,
  List<WatchPartyMemberProgress> members,
  WatchPartyController ctrl,
  bool isSelf,
  bool tied,
  List<int> scores,
) {
  final m = members[index];
  return sayingFor(
    index: index,
    total: members.length,
    displayName: m.displayName,
    episodesEmpty: m.episodes.isEmpty,
    isAllWatched: m.isAllWatched,
    isTied: tied,
    isSelf: isSelf,
    firstPlaceIdx: ctrl.firstPlaceSayingIndex,
    lastPlaceIdx: ctrl.lastPlaceSayingIndex,
    middleIdx: ctrl.middleSayingIndex,
    notStartedIdx: ctrl.notStartedSayingIndex,
    completedIdx: ctrl.completedSayingIndex,
    tiedIdx: ctrl.tiedSayingIndex,
  );
}

Color? _color(int index, int total, WatchPartyMemberProgress m, bool isTied) {
  if (total < 2) return null;
  if (m.episodes.isEmpty) return EColors.textSecondary;
  if (m.isAllWatched) return EColors.success;
  if (isTied) return EColors.textSecondary;
  if (index == 0) return EColors.primary;
  if (index == total - 1) return EColors.textSecondary;
  if (total >= 3 && index == total ~/ 2) return EColors.textSecondary;
  return null;
}
