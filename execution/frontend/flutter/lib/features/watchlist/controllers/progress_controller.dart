import 'package:get/get.dart';
import '../../../shared/models/watch_progress.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import 'watchlist_controller.dart';
import '../../../shared/repositories/review_repository.dart';
import '../../social/controllers/friend_controller.dart';
import '../../../shared/models/friend_watching.dart';

/// Controller for managing watch progress of a single watchlist item.
class ProgressController extends GetxController {
  final WatchlistItem item;

  ProgressController({required this.item});

  // Observable state
  final _progressEntries = <WatchProgress>[].obs;
  final _seasonProgress = <SeasonProgress>[].obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();

  // Review state
  final _userRating = Rxn<int>();
  final _userReviewText = Rxn<String>();

  final _isLoadingReview = false.obs;

  // Social state
  final _friendsWatching = <FriendWatching>[].obs;

  // Getters
  List<WatchProgress> get progressEntries => _progressEntries;
  List<SeasonProgress> get seasonProgress => _seasonProgress;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  // Review Getters
  int? get userRating => _userRating.value;
  String? get userReviewText => _userReviewText.value;
  bool get isLoadingReview => _isLoadingReview.value;
  bool get hasReviewText =>
      _userReviewText.value != null && _userReviewText.value!.isNotEmpty;

  // Social Getters
  List<FriendWatching> get friendsWatching => _friendsWatching;

  // Computed properties
  bool get isMovie => item.mediaType == MediaType.movie;
  bool get isTvShow => item.mediaType == MediaType.tv;

  int get totalEpisodes => _progressEntries.length;
  int get watchedEpisodes => _progressEntries.where((e) => e.watched).length;

  int get totalMinutes =>
      _progressEntries.fold(0, (sum, e) => sum + e.runtimeMinutes);

  /// Watched minutes including partial progress for movies.
  int get watchedMinutes {
    int total = 0;
    for (final entry in _progressEntries) {
      if (entry.watched) {
        // Fully watched - count full runtime
        total += entry.runtimeMinutes;
      } else if (entry.minutesWatched > 0) {
        // Partially watched - count actual minutes
        total += entry.minutesWatched;
      }
    }
    return total;
  }

  int get remainingMinutes => totalMinutes - watchedMinutes;

  /// Progress percentage - time-based for movies, episode-based for TV shows.
  double get progressPercentage {
    if (isMovie) {
      // For movies, use time-based percentage
      if (totalMinutes == 0) return 0;
      return (watchedMinutes / totalMinutes) * 100;
    } else {
      // For TV shows, use episode count
      if (totalEpisodes == 0) return 0;
      return (watchedEpisodes / totalEpisodes) * 100;
    }
  }

  bool get isComplete => watchedEpisodes == totalEpisodes && totalEpisodes > 0;

  /// Check if started - accounts for partial movie progress.
  bool get isStarted => watchedEpisodes > 0 || watchedMinutes > 0;

  String get formattedRemaining {
    if (remainingMinutes >= 60) {
      final hours = remainingMinutes ~/ 60;
      final mins = remainingMinutes % 60;
      return '${hours}h ${mins}m left';
    }
    return '${remainingMinutes}m left';
  }

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
    if (ctrl.friends.isEmpty) {
      await ctrl.refresh();
    }

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

  /// Load all progress entries for this item.
  Future<void> loadProgress() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      final entries = await WatchlistRepository.getProgressEntries(item.id);

      // For movies, fetch runtime separately from content_cache
      int? movieRuntime;
      if (isMovie && entries.isNotEmpty) {
        movieRuntime = await WatchlistRepository.getMovieRuntime(item.id);
      }

      final progressList = entries
          .map((e) => WatchProgress.fromJson(e, movieRuntime: movieRuntime))
          .toList();

      _progressEntries.assignAll(progressList);

      // Group by season for TV shows
      if (isTvShow) {
        _buildSeasonProgress();
      }
    } catch (e) {
      _error.value = 'Failed to load progress';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Build season progress summaries from episode entries.
  void _buildSeasonProgress() {
    final seasonMap = <int, List<WatchProgress>>{};

    for (final entry in _progressEntries) {
      if (entry.seasonNumber != null) {
        seasonMap.putIfAbsent(entry.seasonNumber!, () => []);
        seasonMap[entry.seasonNumber!]!.add(entry);
      }
    }

    final seasons = seasonMap.entries.map((e) {
      // Sort episodes within season
      e.value.sort(
        (a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0),
      );
      return SeasonProgress(seasonNumber: e.key, episodes: e.value);
    }).toList();

    // Sort seasons
    seasons.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

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

      // Update local state
      _progressEntries[index] = entry.copyWith(
        watched: newWatched,
        watchedAt: newWatched ? DateTime.now() : null,
      );

      // Rebuild season progress
      if (isTvShow) {
        _buildSeasonProgress();
      }

      // Refresh parent watchlist controller
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update progress';
    }
  }

  /// Mark all episodes in a season as watched.
  Future<void> markSeasonWatched(int seasonNumber, bool watched) async {
    final seasonEntries = _progressEntries
        .where((e) => e.seasonNumber == seasonNumber && e.watched != watched)
        .toList();

    try {
      for (final entry in seasonEntries) {
        await WatchlistRepository.updateWatchProgress(
          progressId: entry.id,
          watched: watched,
        );

        // Update local state in-place
        final idx = _progressEntries.indexWhere((e) => e.id == entry.id);
        if (idx != -1) {
          _progressEntries[idx] = _progressEntries[idx].copyWith(
            watched: watched,
            watchedAt: watched ? DateTime.now() : null,
          );
        }
      }

      // Rebuild season grouping from local state
      if (isTvShow) _buildSeasonProgress();

      // Refresh parent watchlist controller
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update season';
    }
  }

  /// Mark all episodes as watched.
  Future<void> markAllWatched(bool watched) async {
    final entriesToUpdate = _progressEntries
        .where((e) => e.watched != watched)
        .toList();

    try {
      for (final entry in entriesToUpdate) {
        await WatchlistRepository.updateWatchProgress(
          progressId: entry.id,
          watched: watched,
        );

        final idx = _progressEntries.indexWhere((e) => e.id == entry.id);
        if (idx != -1) {
          _progressEntries[idx] = _progressEntries[idx].copyWith(
            watched: watched,
            watchedAt: watched ? DateTime.now() : null,
          );
        }
      }

      if (isTvShow) _buildSeasonProgress();

      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update all';
    }
  }

  /// Set movie progress to a specific percentage (0, 25, 50, 75, 100).
  Future<void> setMovieProgress(int percentage) async {
    if (!isMovie || _progressEntries.isEmpty) return;

    final entry = _progressEntries.first;
    final minutesWatched = (entry.runtimeMinutes * percentage / 100).round();

    try {
      await WatchlistRepository.updateMovieProgress(
        progressId: entry.id,
        minutesWatched: minutesWatched,
        totalMinutes: entry.runtimeMinutes,
      );

      // Update local state
      _progressEntries[0] = entry.copyWith(
        minutesWatched: minutesWatched,
        watched: percentage >= 100,
        watchedAt: percentage >= 100 ? DateTime.now() : null,
      );

      // Refresh parent watchlist controller
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update progress';
    }
  }

  /// Set movie progress to a specific number of minutes.
  Future<void> setMovieProgressMinutes(int minutesWatched) async {
    if (!isMovie || _progressEntries.isEmpty) return;

    final entry = _progressEntries.first;
    final clampedMinutes = minutesWatched.clamp(0, entry.runtimeMinutes);

    try {
      await WatchlistRepository.updateMovieProgress(
        progressId: entry.id,
        minutesWatched: clampedMinutes,
        totalMinutes: entry.runtimeMinutes,
      );

      // Update local state
      _progressEntries[0] = entry.copyWith(
        minutesWatched: clampedMinutes,
        watched: clampedMinutes >= entry.runtimeMinutes,
        watchedAt: clampedMinutes >= entry.runtimeMinutes
            ? DateTime.now()
            : null,
      );

      // Refresh parent watchlist controller
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update progress';
    }
  }

  /// Set episode progress to a specific number of minutes.
  Future<void> setEpisodeProgress(String progressId, int minutesWatched) async {
    final index = _progressEntries.indexWhere((e) => e.id == progressId);
    if (index == -1) return;

    final entry = _progressEntries[index];
    final clampedMinutes = minutesWatched.clamp(0, entry.runtimeMinutes);
    final isComplete = clampedMinutes >= entry.runtimeMinutes;

    try {
      await WatchlistRepository.updateWatchProgress(
        progressId: progressId,
        watched: isComplete,
        minutesWatched: clampedMinutes,
      );

      // Update local state
      _progressEntries[index] = entry.copyWith(
        minutesWatched: clampedMinutes,
        watched: isComplete,
        watchedAt: isComplete ? DateTime.now() : entry.watchedAt,
      );

      // Rebuild season progress
      if (isTvShow) {
        _buildSeasonProgress();
      }

      // Refresh parent watchlist controller
      await WatchlistController.to.refresh();
    } catch (e) {
      _error.value = 'Failed to update episode progress';
    }
  }

  /// Get progress entry for a movie (single entry).
  WatchProgress? get movieProgress {
    if (!isMovie || _progressEntries.isEmpty) return null;
    return _progressEntries.first;
  }

  /// Current movie progress percentage.
  double get movieProgressPercentage {
    final progress = movieProgress;
    if (progress == null) return 0;
    return progress.progressPercentage;
  }

  /// Clear error.
  void clearError() {
    _error.value = null;
  }

  // Review Methods
  Future<void> loadUserReview() async {
    _isLoadingReview.value = true;
    try {
      final review = await ReviewRepository.getUserReview(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
      );
      _userRating.value = review?.rating;
      _userReviewText.value = review?.reviewText;
    } catch (e) {
      // ignore
    } finally {
      _isLoadingReview.value = false;
    }
  }

  Future<void> submitRating(int rating) async {
    _userRating.value = rating;
    try {
      await ReviewRepository.upsertReview(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
        rating: rating,
        reviewText: _userReviewText.value,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save rating');
    }
  }
}
