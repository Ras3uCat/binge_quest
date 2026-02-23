import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';

/// Displays a single party member's progress.
/// Two variants: TV (episode circles) and Movie (linear progress bar).
class PartyProgressRow extends StatelessWidget {
  final WatchPartyMemberProgress member;
  final _Variant _variant;

  // Saying fields
  final String? saying;
  final Color? sayingColor;
  final bool isSelf;

  // Nudge fields
  final bool canNudge;
  final VoidCallback? onNudge;

  const PartyProgressRow.tv({
    super.key,
    required this.member,
    this.saying,
    this.sayingColor,
    this.isSelf = false,
    this.canNudge = false,
    this.onNudge,
  }) : _variant = _Variant.tv;

  const PartyProgressRow.movie({
    super.key,
    required this.member,
    this.saying,
    this.sayingColor,
    this.isSelf = false,
    this.canNudge = false,
    this.onNudge,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: ESizes.sm),
              _buildName(),
              const SizedBox(width: ESizes.sm),
              Expanded(child: _buildProgress()),
              if (member.isAllWatched) _buildCompletedBadge(),
              if (!isSelf && canNudge && onNudge != null &&
                  !member.isAllWatched && member.hasStarted)
                _buildNudgeButton(),
            ],
          ),
          if (saying != null) _buildSaying(),
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
    if (member.episodes.isEmpty) {
      return const Text(
        'Not started',
        style: TextStyle(color: EColors.textTertiary, fontSize: ESizes.fontXs),
      );
    }

    // Sort all episodes across all seasons.
    final sorted = [...member.episodes]
      ..sort((a, b) {
        final s = a.seasonNumber.compareTo(b.seasonNumber);
        return s != 0 ? s : a.episodeNumber.compareTo(b.episodeNumber);
      });

    // Current = first partial in progress, then last completed, then first overall.
    final current = sorted.firstWhere(
      (e) => e.isPartial,
      orElse: () => sorted.lastWhere(
        (e) => e.isComplete,
        orElse: () => sorted.first,
      ),
    );

    final pct = current.displayPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'S${current.seasonNumber} E${current.episodeNumber}',
              style: const TextStyle(
                color: EColors.textPrimary,
                fontSize: ESizes.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
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
    final percent = ep?.displayPercent ?? 0;

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

  Widget _buildNudgeButton() {
    return IconButton(
      icon: const Icon(Icons.notifications_active_outlined, size: 16),
      color: EColors.textTertiary,
      onPressed: onNudge,
      tooltip: 'Nudge',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildSaying() {
    return Padding(
      padding: const EdgeInsets.only(top: ESizes.xs),
      child: Text(
        saying!,
        style: TextStyle(
          color: sayingColor ?? EColors.textSecondary,
          fontSize: ESizes.fontSm,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

enum _Variant { tv, movie }
