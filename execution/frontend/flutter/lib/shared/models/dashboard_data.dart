import 'watchlist_item.dart';
import 'queue_efficiency.dart';

/// Combined dashboard data from single RPC call.
/// Reduces 4 database round trips to 1 for dashboard load.
class DashboardData {
  final List<WatchlistItem> items;
  final Map<String, dynamic> stats;
  final QueueEfficiency queueHealth;

  const DashboardData({
    required this.items,
    required this.stats,
    required this.queueHealth,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Parse items from JSONB array
    final itemsJson = json['items'] as List? ?? [];
    final items = itemsJson.map((itemData) {
      final item = itemData as Map<String, dynamic>;
      return WatchlistItem.fromDashboardRpc(item);
    }).toList();

    // Calculate derived stats from items
    final totalRuntimeMinutes = (json['total_runtime_minutes'] as num?)?.toInt() ?? 0;
    final watchedRuntimeMinutes = (json['watched_runtime_minutes'] as num?)?.toInt() ?? 0;
    final totalMinutesRemaining = totalRuntimeMinutes - watchedRuntimeMinutes;

    // Count "almost done" items (< 60 minutes remaining, not completed)
    int almostDoneCount = 0;
    for (final item in items) {
      if (item.isAlmostDone) almostDoneCount++;
    }

    // Build stats map
    final stats = <String, dynamic>{
      'total_items': json['total_items'] ?? 0,
      'completed_items': json['completed_items'] ?? 0,
      'completed_count': json['completed_items'] ?? 0,
      'in_progress_items': json['in_progress_items'] ?? 0,
      'total_runtime_minutes': totalRuntimeMinutes,
      'watched_runtime_minutes': watchedRuntimeMinutes,
      'total_minutes_remaining': totalMinutesRemaining,
      'total_hours_remaining': (totalMinutesRemaining / 60).round(),
      'almost_done_count': almostDoneCount,
    };

    // Build queue efficiency
    final totalItems = (json['total_items'] as num?)?.toInt() ?? 0;
    final completedItems = (json['completed_items'] as num?)?.toInt() ?? 0;
    final activeItems = (json['active_count'] as num?)?.toInt() ?? 0;
    final idleItems = (json['idle_count'] as num?)?.toInt() ?? 0;
    final staleItems = (json['stale_count'] as num?)?.toInt() ?? 0;
    final recentCompletions = (json['recent_completions'] as num?)?.toInt() ?? 0;
    final efficiencyScore = (json['efficiency_score'] as num?)?.toInt() ?? 0;
    final excludedCount = (json['excluded_count'] as num?)?.toInt() ?? 0;

    // completionRate uses efficiency totals (active+idle+stale+completed)
    // which excludes unavailable items
    final effTotal = activeItems + idleItems + staleItems + completedItems;
    final queueHealth = QueueEfficiency(
      totalItems: effTotal,
      completedItems: completedItems,
      activeItems: activeItems,
      idleItems: idleItems,
      staleItems: staleItems,
      completionRate: effTotal > 0 ? (completedItems / effTotal) * 100 : 0.0,
      efficiencyScore: efficiencyScore,
      recentCompletions: recentCompletions,
      excludedItems: excludedCount,
    );

    return DashboardData(
      items: items,
      stats: stats,
      queueHealth: queueHealth,
    );
  }

  /// Empty data for when no watchlist is selected.
  factory DashboardData.empty() {
    return DashboardData(
      items: [],
      stats: {
        'total_items': 0,
        'completed_items': 0,
        'in_progress_items': 0,
        'total_runtime_minutes': 0,
        'watched_runtime_minutes': 0,
      },
      queueHealth: QueueEfficiency.empty(),
    );
  }
}
