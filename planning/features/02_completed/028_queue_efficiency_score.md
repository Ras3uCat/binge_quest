# Feature: Queue Efficiency Score

## Status
✅ Implemented

## Overview
Calculate and display a "Queue Efficiency Score" based on the user's completion rate and how quickly they finish items in their watchlist.

## Acceptance Criteria
- [x] Algorithm to calculate efficiency score (0-100)
- [x] Logic to identify "stale" content (items not touched in 30+ days)
- [x] Dashboard display for the score and efficiency stats

## Backend Changes
- Potentially a view or function to calculate stats across `watchlist_items` and `watch_progress`

## Frontend Changes
- `EfficiencyController` to calculate and provide score data
- UI: Efficiency card on Dashboard with score and "stale" count

## QA Checklist
- [x] Verify score updates as items are completed
- [x] Verify "stale" items are correctly identified
- [x] Verify score is 100 for a fresh/empty queue

## Implementation Notes
Implemented in:
- `lib/features/dashboard/controllers/queue_health_controller.dart`
- `lib/features/dashboard/widgets/queue_health_card.dart`
- `lib/features/dashboard/widgets/efficiency_detail_sheet.dart`
- `lib/shared/models/queue_efficiency.dart`

**Known Bug:** Queue Health does not update when switching watchlists. See `bugfix_queue_health_watchlist_switch.md`.
