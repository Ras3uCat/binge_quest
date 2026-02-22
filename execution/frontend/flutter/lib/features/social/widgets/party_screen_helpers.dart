import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';
import '../controllers/watch_party_controller.dart';
import 'party_progress_row.dart';

// ---------------------------------------------------------------------------
// TV Body — season tabs + member progress rows
// ---------------------------------------------------------------------------
class PartyTvBody extends StatelessWidget {
  final WatchPartyController ctrl;
  final String partyId;

  const PartyTvBody({super.key, required this.ctrl, required this.partyId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: EColors.primary));
      }
      final members = ctrl.progressByParty[partyId] ?? [];
      final seasons = _seasons(members);
      if (seasons.isEmpty) {
        return _emptyState('No progress yet');
      }
      final selectedSeason =
          ctrl.selectedSeason.value.clamp(seasons.first, seasons.last);

      return RefreshIndicator(
        onRefresh: () => ctrl.openParty(partyId),
        color: EColors.primary,
        child: Column(
          children: [
            PartySeasonTabBar(
              seasons: seasons,
              selected: selectedSeason,
              onSelect: (s) => ctrl.selectedSeason.value = s,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(ESizes.md),
                children: [
                  ...members.map((m) => PartyProgressRow.tv(
                        member: m,
                        selectedSeason: selectedSeason,
                      )),
                  PartyCatchUpIndicator(
                      members: members, season: selectedSeason),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  List<int> _seasons(List<WatchPartyMemberProgress> members) {
    final set = <int>{};
    for (final m in members) {
      for (final e in m.episodes) {
        if (e.seasonNumber > 0) set.add(e.seasonNumber);
      }
    }
    return set.toList()..sort();
  }

  Widget _emptyState(String msg) => Center(
        child: Text(msg,
            style: const TextStyle(
                color: EColors.textSecondary, fontSize: ESizes.fontMd)),
      );
}

// ---------------------------------------------------------------------------
// Movie Body — linear progress bars
// ---------------------------------------------------------------------------
class PartyMovieBody extends StatelessWidget {
  final WatchPartyController ctrl;
  final String partyId;

  const PartyMovieBody({super.key, required this.ctrl, required this.partyId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: EColors.primary));
      }
      final members = ctrl.progressByParty[partyId] ?? [];

      return RefreshIndicator(
        onRefresh: () => ctrl.openParty(partyId),
        color: EColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(ESizes.md),
          children: [
            ...members.map((m) => PartyProgressRow.movie(member: m)),
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
        style: const TextStyle(
            color: EColors.textSecondary, fontSize: ESizes.fontSm),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Season Tab Bar
// ---------------------------------------------------------------------------
class PartySeasonTabBar extends StatelessWidget {
  final List<int> seasons;
  final int selected;
  final void Function(int) onSelect;

  const PartySeasonTabBar({
    super.key,
    required this.seasons,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      child: Row(
        children: seasons
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: ESizes.sm),
                child: ChoiceChip(
                  label: Text('Season $s'),
                  selected: s == selected,
                  selectedColor: EColors.primary,
                  labelStyle: TextStyle(
                    color: s == selected
                        ? EColors.textPrimary
                        : EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                  backgroundColor: EColors.surface,
                  onSelected: (_) => onSelect(s),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Catch-Up Indicator (TV only)
// ---------------------------------------------------------------------------
class PartyCatchUpIndicator extends StatelessWidget {
  final List<WatchPartyMemberProgress> members;
  final int season;

  const PartyCatchUpIndicator(
      {super.key, required this.members, required this.season});

  @override
  Widget build(BuildContext context) {
    if (members.length < 2) return const SizedBox.shrink();

    int? leaderEp;
    for (final m in members) {
      final eps = m.episodes.where((e) => e.seasonNumber == season);
      if (eps.isEmpty) continue;
      final maxEp =
          eps.map((e) => e.episodeNumber).reduce((a, b) => a > b ? a : b);
      if (leaderEp == null || maxEp > leaderEp) leaderEp = maxEp;
    }
    if (leaderEp == null) return const SizedBox.shrink();

    final behind = <String>[];
    for (final m in members) {
      final eps = m.episodes.where((e) => e.seasonNumber == season);
      if (eps.isEmpty) {
        behind.add('${m.displayName} has not started');
        continue;
      }
      final maxEp =
          eps.map((e) => e.episodeNumber).reduce((a, b) => a > b ? a : b);
      final diff = leaderEp - maxEp;
      if (diff > 0) {
        behind.add(
            '${m.displayName} is $diff ep${diff == 1 ? '' : 's'} behind');
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
