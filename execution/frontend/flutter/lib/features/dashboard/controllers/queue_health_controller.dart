import 'package:get/get.dart';
import '../../../shared/models/queue_efficiency.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

/// Controller for queue health and efficiency tracking.
class QueueHealthController extends GetxController {
  static QueueHealthController get to => Get.find();

  // Observable state
  final _efficiency = Rxn<QueueEfficiency>();
  final _staleItems = <WatchlistItem>[].obs;
  final _isLoading = false.obs;
  final _hasError = false.obs;

  // Getters
  QueueEfficiency? get efficiency => _efficiency.value;
  QueueEfficiency get efficiencyOrEmpty =>
      _efficiency.value ?? QueueEfficiency.empty();
  List<WatchlistItem> get staleItems => _staleItems;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  bool get hasData => _efficiency.value != null;

  // Efficiency score shortcuts
  int get efficiencyScore => efficiencyOrEmpty.efficiencyScore;
  EfficiencyRating get rating => efficiencyOrEmpty.rating;
  double get completionRate => efficiencyOrEmpty.completionRate;
  int get staleCount => efficiencyOrEmpty.staleItems;
  int get activeCount => efficiencyOrEmpty.activeItems;
  int get idleCount => efficiencyOrEmpty.idleItems;
  int get completedCount => efficiencyOrEmpty.completedItems;
  int get totalCount => efficiencyOrEmpty.totalItems;
  int get recentCompletions => efficiencyOrEmpty.recentCompletions;
  int get excludedCount => efficiencyOrEmpty.excludedItems;

  @override
  void onInit() {
    super.onInit();

    // Check if WatchlistController already has queue health data
    final existingData = WatchlistController.to.queueHealth;
    if (existingData != null && existingData is QueueEfficiency) {
      _efficiency.value = existingData;
      _isLoading.value = false;
      _loadStaleItemsIfNeeded(existingData.staleItems);
    }
    // Don't call loadEfficiency() on init - wait for RPC data via listener

    // Listen for watchlist changes
    ever(WatchlistController.to.rxCurrentWatchlist, (_) {
      // When watchlist changes, clear current data and wait for new RPC data
      _efficiency.value = null;
      _staleItems.clear();
    });

    // Listen for queue health data from dashboard RPC (primary data source)
    ever(WatchlistController.to.rxQueueHealth, (queueHealth) {
      _isLoading.value = false;
      if (queueHealth != null && queueHealth is QueueEfficiency) {
        _efficiency.value = queueHealth;
        _loadStaleItemsIfNeeded(queueHealth.staleItems);
      } else if (queueHealth == null) {
        // RPC failed, fallback to separate query
        _loadEfficiencyFallback();
      }
    });
  }

  /// Load stale items if there are any.
  Future<void> _loadStaleItemsIfNeeded(int staleCount) async {
    if (staleCount > 0) {
      final currentWatchlistId = WatchlistController.to.currentWatchlist?.id;
      _staleItems.value = await WatchlistRepository.getStaleItems(
        limit: 5,
        watchlistId: currentWatchlistId,
      );
    } else {
      _staleItems.clear();
    }
  }

  /// Fallback when RPC is not available.
  Future<void> _loadEfficiencyFallback() async {
    try {
      final currentWatchlistId = WatchlistController.to.currentWatchlist?.id;
      final efficiency = await WatchlistRepository.getQueueEfficiency(
        watchlistId: currentWatchlistId,
      );
      _efficiency.value = efficiency;
      _loadStaleItemsIfNeeded(efficiency.staleItems);
    } catch (e) {
      _hasError.value = true;
      _efficiency.value = QueueEfficiency.empty();
    }
  }

  /// Load queue efficiency data - uses shared RPC data when available.
  Future<void> loadEfficiency() async {
    // Check if WatchlistController already has the data
    final sharedQueueHealth = WatchlistController.to.queueHealth;
    if (sharedQueueHealth != null && sharedQueueHealth is QueueEfficiency) {
      _efficiency.value = sharedQueueHealth;
      _isLoading.value = false;
      _loadStaleItemsIfNeeded(sharedQueueHealth.staleItems);
      return;
    }

    // Otherwise wait for the listener or use fallback
    _isLoading.value = true;
    _hasError.value = false;
    await _loadEfficiencyFallback();
    _isLoading.value = false;
  }

  /// Refresh efficiency data - just waits for WatchlistController refresh.
  @override
  Future<void> refresh() async {
    // Data will come via the rxQueueHealth listener when WatchlistController refreshes
    // Only use fallback if no RPC data available
    final sharedQueueHealth = WatchlistController.to.queueHealth;
    if (sharedQueueHealth == null) {
      await loadEfficiency();
    }
  }

  /// Get status breakdown as percentages for visualization.
  Map<ItemStatus, double> get statusBreakdown {
    final total = efficiencyOrEmpty.inProgressItems;
    if (total == 0) {
      return {ItemStatus.active: 0, ItemStatus.idle: 0, ItemStatus.stale: 0};
    }

    return {
      ItemStatus.active: (activeCount / total) * 100,
      ItemStatus.idle: (idleCount / total) * 100,
      ItemStatus.stale: (staleCount / total) * 100,
    };
  }

  /// Get encouraging message based on efficiency.
  String get encouragementMessage {
    if (totalCount == 0) {
      return 'Add some titles to start tracking!';
    }
    return rating.message;
  }

  /// Check if user should be warned about stale items.
  bool get hasStaleWarning => staleCount >= 3;

  /// Get quick win suggestion (item closest to completion).
  WatchlistItem? get quickWinSuggestion {
    // If we have stale items, suggest the one with most progress
    if (_staleItems.isNotEmpty) {
      final sortedByProgress = List<WatchlistItem>.from(_staleItems)
        ..sort(
          (a, b) => (b.completionPercentage ?? 0).compareTo(
            a.completionPercentage ?? 0,
          ),
        );
      return sortedByProgress.first;
    }
    return null;
  }
}
