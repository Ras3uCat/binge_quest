# Bug Fix: Queue Health Not Updating on Watchlist Switch

## Status
✅ Complete

## Priority
Medium

## Problem Description
When user switches to a different watchlist on the dashboard, the Queue Health card does not completely update to reflect the selected watchlist's data. Some metrics may show stale data from the previously selected watchlist.

## Expected Behavior
Queue Health card should fully refresh and display accurate metrics for the newly selected watchlist immediately after switching.

## Current Behavior
Queue Health card shows partial or stale data after watchlist switch.

## Investigation Completed
- [x] Identify which specific metrics are not updating - ALL metrics were stale
- [x] Check if `QueueHealthController` is listening to watchlist changes - Added by Gemini
- [x] Verify reactive bindings between `WatchlistController.selectedWatchlist` and queue health - Fixed
- [x] Check if data fetch is triggered on watchlist change - Now triggers refresh

## Likely Affected Files
- `lib/features/dashboard/widgets/queue_health_card.dart`
- `lib/features/dashboard/controllers/queue_health_controller.dart`
- `lib/features/watchlist/controllers/watchlist_controller.dart`

## Potential Fixes
1. Ensure `QueueHealthController` has `ever()` listener on selected watchlist
2. Call `refresh()` on queue health when watchlist changes
3. Verify Obx widgets are properly wrapping reactive state

## Acceptance Criteria
- [x] Switch watchlist → Queue Health updates immediately
- [x] All metrics reflect new watchlist data
- [x] No stale data visible during transition
- [x] Loading indicator shown during refresh (if needed)

## Root Cause Analysis
Two issues were found:
1. Controller had no listener for watchlist changes (fixed by Gemini)
2. `getQueueEfficiency()` calculated across ALL watchlists instead of the selected one

## Fix Applied
- Added `watchlistId` parameter to `WatchlistRepository.getQueueEfficiency()`
- Added `_calculateEfficiencyForWatchlist()` method
- Updated `QueueHealthController.loadEfficiency()` to pass current watchlist ID

## QA Steps
1. Add items to Watchlist A and Watchlist B with different completion states
2. View dashboard with Watchlist A selected
3. Note Queue Health metrics
4. Switch to Watchlist B
5. Verify Queue Health shows Watchlist B's metrics
6. Switch back to Watchlist A
7. Verify metrics return to Watchlist A values
