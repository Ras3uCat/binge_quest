import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/review.dart';
import '../../../shared/models/streaming_breakdown.dart';
import '../../../shared/repositories/review_repository.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Controller for user profile and stats.
class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  // Observable state
  final _isLoading = false.obs;
  final _totalItemsWatched = 0.obs;
  final _totalMinutesWatched = 0.obs;
  final _moviesCompleted = 0.obs;
  final _showsCompleted = 0.obs;
  final _episodesWatched = 0.obs;
  final _totalEpisodes = 0.obs;
  final _totalMovies = 0.obs;
  final _totalShows = 0.obs;

  // Streaming breakdown state
  final _streamingBreakdown = <StreamingBreakdownItem>[].obs;
  final _isLoadingBreakdown = false.obs;

  // Rated items state
  final _allRatedItems = <Review>[];
  final _ratedItems = <Review>[].obs;
  final _ratedItemsSort = ReviewSort.dateDesc.obs;
  final _isLoadingRatings = false.obs;
  final _ratingsError = Rxn<String>();

  // Realtime
  RealtimeChannel? _statsChannel;

  // Getters
  bool get isLoading => _isLoading.value;
  int get totalItemsWatched => _totalItemsWatched.value;
  int get totalMinutesWatched => _totalMinutesWatched.value;
  int get moviesCompleted => _moviesCompleted.value;
  int get showsCompleted => _showsCompleted.value;
  int get episodesWatched => _episodesWatched.value;
  int get totalEpisodes => _totalEpisodes.value;
  int get totalMovies => _totalMovies.value;
  int get totalShows => _totalShows.value;

  // Streaming breakdown getters
  List<StreamingBreakdownItem> get streamingBreakdown => _streamingBreakdown;
  bool get isLoadingBreakdown => _isLoadingBreakdown.value;

  // Rated items getters
  List<Review> get ratedItems => _ratedItems;
  ReviewSort get ratedItemsSort => _ratedItemsSort.value;
  bool get isLoadingRatings => _isLoadingRatings.value;
  String? get ratingsError => _ratingsError.value;

  String get formattedWatchTime {
    final hours = totalMinutesWatched ~/ 60;
    final mins = totalMinutesWatched % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  // User info from auth
  String get displayName {
    final user = AuthController.to.user;
    return user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        (user?.email?.contains('@privaterelay.appleid.com') == true
            ? 'Apple User'
            : user?.email?.split('@').first) ??
        'User';
  }

  String get email => AuthController.to.user?.email ?? '';

  String? get avatarUrl {
    final user = AuthController.to.user;
    return user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
  }

  @override
  void onInit() {
    super.onInit();
    loadStats();
    loadStreamingBreakdown();
    loadRatedItems();
    _subscribeToStats();
  }

  @override
  void onClose() {
    _statsChannel?.unsubscribe();
    super.onClose();
  }

  void _subscribeToStats() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _statsChannel = Supabase.instance.client
        .channel('profile_stats:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'watchlist_items',
          callback: (_) => _onStatsChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'watch_progress',
          callback: (_) => _onStatsChange(),
        )
        .subscribe();
  }

  void _onStatsChange() {
    if (!_isLoading.value) loadStats();
    if (!_isLoadingBreakdown.value) loadStreamingBreakdown();
  }

  /// Load user watching statistics.
  Future<void> loadStats() async {
    _isLoading.value = true;

    try {
      final stats = await WatchlistRepository.getUserStats();

      _totalItemsWatched.value = stats['items_completed'] ?? 0;
      _totalMinutesWatched.value = stats['minutes_watched'] ?? 0;
      _moviesCompleted.value = stats['movies_completed'] ?? 0;
      _showsCompleted.value = stats['shows_completed'] ?? 0;
      _episodesWatched.value = stats['episodes_watched'] ?? 0;
      _totalEpisodes.value = stats['total_episodes'] ?? 0;
      _totalMovies.value = stats['total_movies'] ?? 0;
      _totalShows.value = stats['total_shows'] ?? 0;
    } catch (e) {
      // Stats failed to load, use defaults
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign out the user.
  Future<void> signOut() async {
    await AuthController.to.signOut();
  }

  /// Load streaming provider breakdown.
  Future<void> loadStreamingBreakdown() async {
    _isLoadingBreakdown.value = true;
    try {
      final breakdown = await WatchlistRepository.getStreamingBreakdown();
      _streamingBreakdown.assignAll(breakdown);
    } catch (e) {
      _streamingBreakdown.clear();
    } finally {
      _isLoadingBreakdown.value = false;
    }
  }

  Future<void> loadRatedItems() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    _isLoadingRatings.value = true;
    _ratingsError.value = null;
    try {
      final items = await ReviewRepository.getReviewsByUser(userId);
      _allRatedItems
        ..clear()
        ..addAll(items);
      _applySortAndUpdate();
    } catch (e) {
      _ratingsError.value = 'Failed to load ratings';
    } finally {
      _isLoadingRatings.value = false;
    }
  }

  void onSortRatingsDate() {
    final current = _ratedItemsSort.value;
    if (current == ReviewSort.dateDesc) {
      _ratedItemsSort.value = ReviewSort.dateAsc;
    } else if (current == ReviewSort.dateAsc) {
      _ratedItemsSort.value = ReviewSort.dateDesc;
    } else {
      _ratedItemsSort.value = ReviewSort.dateDesc;
    }
    _applySortAndUpdate();
  }

  void onSortRatingsRating() {
    final current = _ratedItemsSort.value;
    if (current == ReviewSort.ratingDesc) {
      _ratedItemsSort.value = ReviewSort.ratingAsc;
    } else if (current == ReviewSort.ratingAsc) {
      _ratedItemsSort.value = ReviewSort.ratingDesc;
    } else {
      _ratedItemsSort.value = ReviewSort.ratingDesc;
    }
    _applySortAndUpdate();
  }

  void _applySortAndUpdate() {
    final sorted = List<Review>.from(_allRatedItems);
    switch (_ratedItemsSort.value) {
      case ReviewSort.dateDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReviewSort.dateAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ReviewSort.ratingDesc:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case ReviewSort.ratingAsc:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
    }
    _ratedItems.assignAll(sorted);
  }
}
