import 'package:get/get.dart';
import '../../../shared/models/watch_progress.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import 'watchlist_controller.dart';
import '../../social/controllers/friend_controller.dart';
import '../../social/controllers/watch_party_controller.dart';
import '../../../shared/models/friend_watching.dart';
import 'progress_review_mixin.dart';

/// Controller for managing watch progress of a single watchlist item.
class ProgressController extends GetxController with ProgressReviewMixin {
  @override
  final WatchlistItem item;

  ProgressController({required this.item});

  // Observable state
  final _progressEntries = <WatchProgress>[].obs;
  final _seasonProgress = <SeasonProgress>[].obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _friendsWatching = <FriendWatching>[].obs;

  // Getters
  List<WatchProgress> get progressEntries => _progressEntries;
  List<SeasonProgress> get seasonProgress => _seasonProgress;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<FriendWatching> get friendsWatching => _friendsWatching;

  // Computed
  bool get isMovie => item.mediaType == MediaType.movie;
  bool get isTvShow => item.mediaType == MediaType.tv;
  int get totalEpisodes => _progressEntries.length;
  int get watchedEpisodes => _progressEntries.where((e) => e.watched).length;
  int get totalMinutes =>
      _progressEntries.fold(0, (sum, e) => sum + e.runtimeMinutes);

  int get watchedMinutes {
    int total = 0;
    for (final entry in _progressEntries) {
      if (entry.watched) {
        total += entry.runtimeMinutes;
      } else if (entry.minutesWatched > 0) {
        total += entry.minutesWatched;
      }
    }
    return total;
  }

  int get remainingMinutes => totalMinutes - watchedMinutes;

  double get progressPercentage {
    if (isMovie) {
      if (totalMinutes == 0) return 0;
      return (watchedMinutes / totalMinutes) * 100;
    }
    if (totalEpisodes == 0) return 0;
    return (watchedEpisodes / totalEpisodes) * 100;
  }

  bool get isComplete => watchedEpisodes == totalEpisodes && totalEpisodes > 0;
  bool get isStarted => watchedEpisodes > 0 || watchedMinutes > 0;

  String get formattedRemaining {
    if (remainingMinutes >= 60) {
      return '${remainingMinutes ~/ 60}h ${remainingMinutes % 60}m left';
    }
    return '${remainingMinutes}m left';
  }

  WatchProgress? get movieProgress =>
      isMovie && _progressEntries.isNotEmpty ? _progressEntries.first : null;

  double get movieProgressPercentage => movieProgress?.progressPercentage ?? 0;

  @override
  void onInit() {
    super.onInit();
    loadProgress();
    loadUserReview();
    loadFriendsWatching();
  }

  Future<void> loadFriendsWatching() async {
    if (!Get.isRegistered<FriendController>()) return;
    final ctrl = FriendController.to;
    if (ctrl.friends.isEmpty) await ctrl.refresh();
    final friendIds = ctrl.friendIds.toList();
    if (friendIds.isEmpty) return;
    try {
      final friends = await WatchlistRepository.getFriendsWatching(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType,
        friendIds: friendIds,
      );
      _friendsWatching.assignAll(friends);
    } catch (e) {
      // ignore
    }
  }

  Future<void> loadProgress() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final entries = await WatchlistRepository.getProgressEntries(item.id);
      int? movieRuntime;
      if (isMovie && entries.isNotEmpty) {
        movieRuntime = await WatchlistRepository.getMovieRuntime(item.id);
      }
      final progressList = entries
          .map((e) => WatchProgress.fromJson(e, movieRuntime: movieRuntime))
          .toList();
      _progressEntries.assignAll(progressList);
      if (isTvShow) _buildSeasonProgress();
    } catch (e) {
      _error.value = 'Failed to load progress';
    } finally {
      _isLoading.value = false;
    }
  }

  void _buildSeasonProgress() {
    final seasonMap = <int, List<WatchProgress>>{};
    for (final entry in _progressEntries) {
      if (entry.seasonNumber != null) {
        seasonMap.putIfAbsent(entry.seasonNumber!, () => []);
        seasonMap[entry.seasonNumber!]!.add(entry);
      }
    }
    final seasons = seasonMap.entries.map((e) {
      e.value.sort(
        (a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0),
      );
      return SeasonProgress(seasonNumber: e.key, episodes: e.value);
    }).toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    _seasonProgress.assignAll(seasons);
  }

  /// Toggle watched status for a single progress entry.
  Future<void> toggleWatched(String progressId) async {
    final index = _progressEntries.indexWhere((e) => e.id == progressId);
    if (index == -1) return;
    final entry = _progressEntries[index];
    final newWatched = !entry.watched;
    try {
      await WatchlistRepository.updateWatchProgress(
        progressId: progressId,
        watched: newWatched,
      );
      _progressEntries[index] = entry.copyWith(
        watched: newWatched,
        watchedAt: newWatched ? DateTime.now() : null,
      );
      if (isTvShow) _buildSeasonProgress();
      await WatchlistController.to.refresh();
      // C4c: fire party progress notification when marking watched
      if (newWatched) _notifyPartyProgress(entry);
    } catch (e) {
      _error.value = 'Failed to update progress';
    }
  }

  void _notifyPartyProgress(WatchProgress entry) {
    if (!Get.isRegistered<WatchPartyController>()) return;
    final partyCtrl = WatchPartyController.to;
    final mediaTypeStr = item.mediaType.name;
    final matching = partyCtrl.activeParties.where(
      (p) => p.tmdbId == item.tmdbId && p.mediaType == mediaTypeStr,
    );
    final label =
        entry.episodeCode.isNotEmpty ? entry.episodeCode : item.title;
    for (final party in matching) {
      partyCtrl.notifyPartyProgress(
        partyId: party.id,
        partyName: party.name,
        episodeLabel: label,
      );
    }
  }

  Future<void> markSeasonWatched(int seasonNumber, bool watched) async {
    await _bulkUpdateWatched(
      _progressEntries
          .where((e) => e.seasonNumber == seasonNumber && e.watched != watched)
          .toList(),
      watched,
      'Failed to update season',
    );
  }

  Future<void> markAllWatched(bool watched) async {
    await _bulkUpdateWatched(
      _progressEntries.where((e) => e.watched != watched).toList(),
      watched,
      'Failed to update all',
    );
  }

  Future<void> _bulkUpdateWatched(
    List<WatchProgress> entries,
    bool watched,
    String errorMsg,
  ) async {
    try {
      for (final entry in entries) {
        await WatchlistRepository.updateWatchProgress(
          progressId: entry.id, watched: watched, isBackfill: true,
        );
        final idx = _progressEntries.indexWhere((e) => e.id == entry.id);
        if (idx != -1) {
          _progressEntries[idx] = _progressEntries[idx].copyWith(
            watched: watched, watchedAt: watched ? DateTime.now() : null,
          );
        }
      }
      if (isTvShow) _buildSeasonProgress();
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = errorMsg;
    }
  }

  Future<void> setMovieProgress(int percentage) async {
    if (!isMovie || _progressEntries.isEmpty) return;
    final entry = _progressEntries.first;
    final minutes = (entry.runtimeMinutes * percentage / 100).round();
    try {
      await WatchlistRepository.updateMovieProgress(
        progressId: entry.id,
        minutesWatched: minutes,
        totalMinutes: entry.runtimeMinutes,
      );
      _progressEntries[0] = entry.copyWith(
        minutesWatched: minutes,
        watched: percentage >= 100,
        watchedAt: percentage >= 100 ? DateTime.now() : null,
      );
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update progress';
    }
  }

  Future<void> setMovieProgressMinutes(int minutesWatched) async {
    if (!isMovie || _progressEntries.isEmpty) return;
    final entry = _progressEntries.first;
    final clamped = minutesWatched.clamp(0, entry.runtimeMinutes);
    try {
      await WatchlistRepository.updateMovieProgress(
        progressId: entry.id,
        minutesWatched: clamped,
        totalMinutes: entry.runtimeMinutes,
      );
      _progressEntries[0] = entry.copyWith(
        minutesWatched: clamped,
        watched: clamped >= entry.runtimeMinutes,
        watchedAt: clamped >= entry.runtimeMinutes ? DateTime.now() : null,
      );
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update progress';
    }
  }

  Future<void> setEpisodeProgress(String progressId, int minutesWatched) async {
    final index = _progressEntries.indexWhere((e) => e.id == progressId);
    if (index == -1) return;
    final entry = _progressEntries[index];
    final clamped = minutesWatched.clamp(0, entry.runtimeMinutes);
    final isComplete = clamped >= entry.runtimeMinutes;
    try {
      await WatchlistRepository.updateWatchProgress(
        progressId: progressId,
        watched: isComplete,
        minutesWatched: clamped,
      );
      _progressEntries[index] = entry.copyWith(
        minutesWatched: clamped,
        watched: isComplete,
        watchedAt: isComplete ? DateTime.now() : entry.watchedAt,
      );
      if (isTvShow) _buildSeasonProgress();
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update episode progress';
    }
  }

  void clearError() => _error.value = null;
}
