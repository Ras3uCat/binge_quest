import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../shared/models/watch_party.dart';
import '../../../shared/repositories/watch_party_repository.dart';

/// Mixin that encapsulates Realtime progress update logic for WatchPartyController.
/// Handles INSERT/UPDATE/DELETE events from watch_party_progress table.
mixin WatchPartyRealtimeMixin on GetxController {
  WatchPartyRepository get repository;
  RxMap<String, List<WatchPartyMemberProgress>> get progressByParty;
  String? get openPartyId;

  /// Handle INSERT/UPDATE/DELETE from Realtime on watch_party_progress.
  void handleRealtimeUpdate(Map<String, dynamic> payload) {
    final partyId = openPartyId;
    if (partyId == null) return;

    final eventType = payload['type'] as String?;
    final record = (payload['new'] as Map<String, dynamic>?) ??
        (payload['old'] as Map<String, dynamic>?);
    if (record == null) return;

    final currentList = List<WatchPartyMemberProgress>.from(
      progressByParty[partyId] ?? [],
    );

    if (eventType == 'DELETE') {
      final oldRecord = payload['old'] as Map<String, dynamic>?;
      if (oldRecord == null) return;
      final userId = oldRecord['user_id'] as String;
      final season = oldRecord['season_number'] as int;
      final episode = oldRecord['episode_number'] as int;
      _removeEpisodeRow(currentList, userId, season, episode);
    } else {
      final ep = EpisodeProgress.fromJson(record);
      final userId = record['user_id'] as String;
      _upsertEpisodeRow(currentList, userId, ep);
    }

    progressByParty[partyId] = currentList;
    progressByParty.refresh();
  }

  void _upsertEpisodeRow(
    List<WatchPartyMemberProgress> members,
    String userId,
    EpisodeProgress ep,
  ) {
    final idx = members.indexWhere((m) => m.userId == userId);
    if (idx == -1) {
      refreshProgressSnapshot();
      return;
    }
    final member = members[idx];
    final epIdx = member.episodes.indexWhere(
      (e) =>
          e.seasonNumber == ep.seasonNumber &&
          e.episodeNumber == ep.episodeNumber,
    );
    final updatedEps = List<EpisodeProgress>.from(member.episodes);
    if (epIdx == -1) {
      updatedEps.add(ep);
    } else {
      updatedEps[epIdx] = ep;
    }
    members[idx] = member.copyWith(episodes: updatedEps);
  }

  void _removeEpisodeRow(
    List<WatchPartyMemberProgress> members,
    String userId,
    int season,
    int episode,
  ) {
    final idx = members.indexWhere((m) => m.userId == userId);
    if (idx == -1) return;
    final member = members[idx];
    final updatedEps = member.episodes
        .where(
          (e) => !(e.seasonNumber == season && e.episodeNumber == episode),
        )
        .toList();
    members[idx] = member.copyWith(episodes: updatedEps);
  }

  Future<void> refreshProgressSnapshot() async {
    final partyId = openPartyId;
    if (partyId == null) return;
    try {
      final progress = await repository.fetchProgress(partyId);
      progressByParty[partyId] = progress;
      progressByParty.refresh();
    } catch (e) {
      debugPrint('WatchPartyRealtimeMixin.refreshProgressSnapshot error: $e');
    }
  }
}
