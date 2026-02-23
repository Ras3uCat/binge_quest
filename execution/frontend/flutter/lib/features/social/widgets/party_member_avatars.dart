import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';

/// Compact horizontal row of member avatars with status overlays.
/// Active members show a green checkmark + progress label.
/// Pending members show an orange clock + "Pending" label.
class PartyMemberAvatars extends StatelessWidget {
  final List<WatchPartyMember> members;
  final List<WatchPartyMemberProgress> progress;
  final String mediaType; // 'tv' | 'movie'

  const PartyMemberAvatars({
    super.key,
    required this.members,
    required this.progress,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      child: Row(
        children: members.map((m) => _buildMember(m)).toList(),
      ),
    );
  }

  Widget _buildMember(WatchPartyMember member) {
    final isPending = member.status == WatchPartyMemberStatus.pending;
    final memberProgress = progress.firstWhere(
      (p) => p.userId == member.userId,
      orElse: () => WatchPartyMemberProgress(
        userId: member.userId,
        displayName: member.displayName ?? 'Member',
        episodes: const [],
      ),
    );

    final label = isPending
        ? 'Pending'
        : mediaType == 'tv'
            ? _tvLabel(memberProgress)
            : '${_moviePercent(memberProgress)}%';

    return Padding(
      padding: const EdgeInsets.only(right: ESizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: EColors.surface,
                backgroundImage: member.avatarUrl != null
                    ? NetworkImage(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? const Icon(Icons.person, color: EColors.textSecondary)
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isPending ? EColors.warning : EColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: EColors.background, width: 2),
                  ),
                  child: Icon(
                    isPending ? Icons.schedule : Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isPending ? EColors.warning : EColors.textSecondary,
              fontSize: ESizes.fontXs,
            ),
          ),
        ],
      ),
    );
  }

  /// For TV: show current episode position (e.g. "S1 E3") or "Not started".
  String _tvLabel(WatchPartyMemberProgress mp) {
    if (mp.episodes.isEmpty) return 'Not started';
    final sorted = [...mp.episodes]
      ..sort((a, b) {
        final s = a.seasonNumber.compareTo(b.seasonNumber);
        return s != 0 ? s : a.episodeNumber.compareTo(b.episodeNumber);
      });
    // Current episode = first unwatched, or last if all watched.
    final current = sorted.firstWhere(
      (e) => !e.isComplete,
      orElse: () => sorted.last,
    );
    return 'S${current.seasonNumber} E${current.episodeNumber}';
  }

  /// For movies: progress percentage from the single episode entry.
  int _moviePercent(WatchPartyMemberProgress mp) {
    if (mp.episodes.isEmpty) return 0;
    return mp.episodes.first.progressPercent;
  }
}
