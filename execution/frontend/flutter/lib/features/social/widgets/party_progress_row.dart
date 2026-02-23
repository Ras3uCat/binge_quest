import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';

/// Displays a single party member's progress.
/// Two variants: TV (episode circles) and Movie (linear progress bar).
class PartyProgressRow extends StatelessWidget {
  final WatchPartyMemberProgress member;
  final _Variant _variant;

  /// Selected season number — used by TV variant to filter episodes.
  final int selectedSeason;

  const PartyProgressRow.tv({
    super.key,
    required this.member,
    required this.selectedSeason,
  }) : _variant = _Variant.tv;

  const PartyProgressRow.movie({
    super.key,
    required this.member,
    this.selectedSeason = 0,
  }) : _variant = _Variant.movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: ESizes.sm),
          _buildName(),
          const SizedBox(width: ESizes.sm),
          Expanded(child: _buildProgress()),
          if (member.isAllWatched) _buildCompletedBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = member.avatarUrl;
    return CircleAvatar(
      radius: 16,
      backgroundColor: EColors.surfaceLight,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? const Icon(Icons.person, size: 16, color: EColors.textSecondary)
          : null,
    );
  }

  Widget _buildName() {
    return SizedBox(
      width: 72,
      child: Text(
        member.displayName,
        style: const TextStyle(
          color: EColors.textPrimary,
          fontSize: ESizes.fontSm,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProgress() {
    return _variant == _Variant.tv ? _buildTvProgress() : _buildMovieProgress();
  }

  Widget _buildTvProgress() {
    final eps = member.episodes
        .where((e) => e.seasonNumber == selectedSeason)
        .toList()
      ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

    if (eps.isEmpty) {
      return const Text(
        'Not started',
        style: TextStyle(color: EColors.textTertiary, fontSize: ESizes.fontXs),
      );
    }

    // Find the current episode: first unwatched, or last if all watched.
    final current = eps.firstWhere(
      (e) => !e.isComplete,
      orElse: () => eps.last,
    );
    final watched = eps.where((e) => e.isComplete).length;
    final pct = (watched / eps.length * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'S$selectedSeason E${current.episodeNumber}',
              style: const TextStyle(
                color: EColors.textPrimary,
                fontSize: ESizes.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$watched/${eps.length} eps',
              style: const TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontXs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            backgroundColor: EColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct == 100 ? EColors.success : EColors.primary,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieProgress() {
    final ep = member.episodes.isNotEmpty ? member.episodes.first : null;
    final percent = ep?.progressPercent ?? 0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.radiusXs),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              backgroundColor: EColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(EColors.primary),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: ESizes.sm),
        Text(
          '$percent%',
          style: const TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontXs,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      margin: const EdgeInsets.only(left: ESizes.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: EColors.success.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ESizes.radiusXs),
        border: Border.all(color: EColors.success.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'Done',
        style: TextStyle(
          color: EColors.success,
          fontSize: ESizes.fontXs,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum _Variant { tv, movie }
