import 'package:get/get.dart';
import '../../../shared/models/streaming_breakdown.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../badges/controllers/badge_controller.dart';

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

  // Streaming breakdown state
  final _streamingBreakdown = <StreamingBreakdownItem>[].obs;
  final _isLoadingBreakdown = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  int get totalItemsWatched => _totalItemsWatched.value;
  int get totalMinutesWatched => _totalMinutesWatched.value;
  int get moviesCompleted => _moviesCompleted.value;
  int get showsCompleted => _showsCompleted.value;
  int get episodesWatched => _episodesWatched.value;

  // Streaming breakdown getters
  List<StreamingBreakdownItem> get streamingBreakdown => _streamingBreakdown;
  bool get isLoadingBreakdown => _isLoadingBreakdown.value;

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
        user?.email?.split('@').first ??
        'User';
  }

  String get email => AuthController.to.user?.email ?? '';

  String? get avatarUrl {
    final user = AuthController.to.user;
    return user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture'];
  }

  @override
  void onInit() {
    super.onInit();
    loadStats();
    loadStreamingBreakdown();
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

      // Check for new badges after stats load
      if (Get.isRegistered<BadgeController>()) {
        BadgeController.to.checkForNewBadges();
      }
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
}
