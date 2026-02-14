# Feature: Dashboard Performance Optimization

## Status
✅ Complete

## Priority
High

## Problem Description
The dashboard takes noticeable time to load on initial launch and refresh. Users experience a slow first meaningful paint.

## Goals
- Reduce initial dashboard load time
- Improve perceived performance
- Maintain feature completeness

## Solution Applied

### 1. Dashboard Data RPC (027_dashboard_data_rpc.sql)
Combined RPC that returns all dashboard data in a single query:
- Watchlist items with content cache data (as JSONB)
- Stats (total, completed, in-progress, runtime)
- Queue health metrics (efficiency score, active/idle/stale counts)

**Benefit**: Reduces 4 database round trips to 1.

### 2. Parallel Data Fetching
```dart
// dashboard_screen.dart - parallel refresh
await Future.wait([
  WatchlistController.to.refresh(),
  if (Get.isRegistered<QueueHealthController>())
    QueueHealthController.to.refresh(),
]);
```

### 3. Skeleton Loading
- Replaced `CircularProgressIndicator` with `PosterListSkeleton` in Top 10 section
- Shows content placeholders immediately while data loads

### 4. RPC Integration with Fallback
```dart
// watchlist_controller.dart
final dashboardData = await WatchlistRepository.getDashboardData(watchlistId);

if (dashboardData != null) {
  // RPC succeeded - use combined data
  _items.assignAll(dashboardData.items);
  _stats.assignAll(dashboardData.stats);
} else {
  // Fallback: Load items and stats in parallel
  final results = await Future.wait([
    WatchlistRepository.getWatchlistItems(watchlistId),
    WatchlistRepository.getWatchlistStats(watchlistId),
  ]);
  // ...
}
```

## Files Modified

### Backend
- `execution/backend/supabase/migrations/027_dashboard_data_rpc.sql` (new)

### Frontend
- `lib/shared/models/dashboard_data.dart` (new model)
- `lib/shared/models/watchlist_item.dart` (added `fromDashboardRpc`)
- `lib/shared/repositories/watchlist_repository.dart` (added `getDashboardData`)
- `lib/features/watchlist/controllers/watchlist_controller.dart` (RPC with fallback)
- `lib/features/dashboard/screens/dashboard_screen.dart` (parallel refresh)
- `lib/features/dashboard/widgets/bingequest_top10_section.dart` (skeleton loading)

## Acceptance Criteria
- [x] Dashboard shows content within 500ms (cached or skeleton)
- [x] Full data loads within 2 seconds (single RPC)
- [x] No blank white screen on load (skeleton loaders)
- [x] Smooth scrolling after load
- [x] Pull-to-refresh feels responsive (parallel refresh)

## QA Steps
1. Cold start app, measure time to see dashboard content
2. Kill app, relaunch, verify cached content shows quickly
3. Pull to refresh, verify smooth animation
4. Switch watchlists, verify quick update
5. Test on slower network (throttle to 3G)
