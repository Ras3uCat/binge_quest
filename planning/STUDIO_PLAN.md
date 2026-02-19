# Advanced Stats Dashboard — v1.1 Bug Fixes & Iteration

**Status:** COMPLETE — All tracks done (2026-02-19)
**Mode:** STUDIO
**Priority:** High
**Started:** 2026-02-19
**Specs:** `planning/features/advanced_stats_dashboard.md`

---

## Problem Description

Post-implementation QA found 10 issues: RPC data scoping bugs, zero denominators on profile cards, empty all-time results, inflated episode pace, a chart crash on outside tap, a design change to watch time chart (dates → days of week), streak dot mismatch, formatting inconsistency, and completion section undercounting.

---

## Track A: Backend Fixes

### A1 — Audit Data Scope (All Watchlists)

Query `get_stats_dashboard` and `get_user_stats` source SQL. Confirm every subquery joins through the user's watchlists via `watchlists.user_id = p_user_id` and does NOT inadvertently filter to a single watchlist. Fix any missing join conditions.

Co-curator watch progress should be included — if a co-curator marked progress on a shared watchlist, it means they watched together. The scope is: all watchlist items on any watchlist the user owns OR is a co-curator of, with all associated watch progress rows regardless of who logged them.

### A2 — Fix `get_user_stats()` Totals Returning 0

Debug `total_episodes`, `total_movies`, `total_shows` subqueries. Likely causes:
- Join on wrong column (`tmdb_id` type mismatch between `watchlist_items` and `content_cache`)
- `media_type` value mismatch (`'tv'` vs `'TV'` vs integer)
- `number_of_episodes` is NULL for many `content_cache` rows (TMDB doesn't always populate this)

Fix: use `COALESCE(cc.number_of_episodes, 0)` and verify the exact `media_type` values stored.

### A3 — Fix `get_stats_dashboard('all')` Returning Empty

The `'all'` time window branch should apply NO date filter (return all rows). Check for:
- An `ELSE` branch that accidentally applies a filter
- A `NULL` interval that causes `watched_at >= now() - NULL` to evaluate unexpectedly
- Missing `CASE` branch for `'all'`

Fix: ensure `p_time_window = 'all'` results in no `WHERE watched_at >=` clause at all.

### A4 — Fix Episode Pace Calculation

Current formula divides by `days_with_activity` (days where at least one episode was watched). This inflates the number — a user who watched 10 episodes on 1 day out of 30 gets "10 eps/day" instead of "0.3 eps/day".

Fix: divide by `days_in_window` (full calendar days in the selected window: 7, 30, 365, or days since first watch for 'all').

```sql
-- days_in_window
CASE p_time_window
  WHEN 'week'  THEN 7
  WHEN 'month' THEN 30
  WHEN 'year'  THEN 365
  ELSE EXTRACT(DAY FROM now() - MIN(watched_at))::int
END
```

### A5 — Fix Completion Count for Time Window

`summary.items_completed` should count items where the completion event (status changed to 'completed') falls within the selected time window — not all-time completions.

Check `watchlist_items` for a `completed_at` or `updated_at` timestamp to filter on. If none exists, use the latest `watch_progress.watched_at` for the item as a proxy for completion date.

### A6 — Replace `watch_time_trend` with `watch_time_by_weekday`

Remove the date-based trend array. Add a 7-element weekday aggregation:

```sql
SELECT
  EXTRACT(DOW FROM watched_at)::int AS weekday,  -- 0=Sun, 1=Mon ... 6=Sat
  SUM(wp.duration_minutes) AS minutes
FROM watch_progress wp
-- [time window filter + user scope]
GROUP BY weekday
```

Return all 7 weekdays, filling missing days with 0 minutes:

```json
"watch_time_by_weekday": [
  { "weekday": 0, "day_name": "Sun", "minutes": 45 },
  { "weekday": 1, "day_name": "Mon", "minutes": 120 },
  ...
  { "weekday": 6, "day_name": "Sat", "minutes": 0 }
]
```

Always return all 7 rows regardless of activity.

---

## Track B: Frontend Fixes

### B1 — Fix Mood Donut `RangeError`

`fl_chart` PieChart touch callbacks return `touchedIndex = -1` when the user taps outside any segment. The current handler accesses `moodList[-1]` which throws.

Fix in `mood_donut_chart.dart`:
```dart
onChartTouchCallback: (event, response) {
  final index = response?.touchedSection?.touchedSectionIndex ?? -1;
  if (index < 0) {
    // clear selection
    return;
  }
  // existing highlight logic
}
```

### B2 — Redesign Watch Time Chart (Dates → Days of Week)

Replace `WatchTimeBarChart` with 7 fixed bars: Sun / Mon / Tue / Wed / Thu / Fri / Sat.

- X axis: 3-letter day abbreviations
- Y axis: minutes (auto-scaled)
- Bars use `EColors.primary`
- Tap tooltip showing exact minutes for that weekday
- Update `WatchTimeTrend` model → `WatchTimeWeekday(weekday: int, dayName: String, minutes: int)`
- Update `StatsData` model field: `watchTimeTrend` → `watchTimeByWeekday`
- Update `StatsRepository` parsing
- Update `StatsController` references

### B3 — Fix Completion Ring

- Numerator: items completed within the selected time window (from fixed `summary.items_completed`)
- Denominator: total items in the user's watchlists (all-time, from `summary.total_items`)
- Label: "X completed this [week/month/year]" (or "all time" for the all window)

### B4 — Fix Streak "Best" Formatting

In `streak_indicator.dart`, the "Best" streak number should match the visual weight and size of the "Current streak" number. Only the color should differ (keep existing color distinction).

### B5 — Fix Streak Dots (7-Day Row)

The 7-dot row represents the current calendar week (Sun–Sat), not the selected time window. A dot is filled if the user watched anything on that calendar day this week.

Fix: derive dot states from a current-week slice of data. Options:
- Add a `current_week_activity` field to the RPC response (7 booleans, always all-time/this-week regardless of window)
- Or filter `watch_time_by_weekday` when window is 'week' to use as proxy

Simplest approach: always pass `current_week_days_active: [true, false, true, ...]` (7 booleans, Sun–Sat) from the RPC regardless of selected window. Add this field to `get_stats_dashboard` response.

---

## Files to Touch

**Backend (migration or RPC update):**
- `get_user_stats` function — fix totals
- `get_stats_dashboard` function — fix scope, all-time, pace, completion, replace trend with weekday

**Frontend:**
- `lib/shared/models/stats_data.dart` — rename/replace `WatchTimeTrend` → `WatchTimeWeekday`, add `currentWeekActivity`
- `lib/shared/repositories/stats_repository.dart` — update parsing
- `lib/features/stats/controllers/stats_controller.dart` — update references
- `lib/features/stats/widgets/mood_donut_chart.dart` — B1 fix
- `lib/features/stats/widgets/watch_time_bar_chart.dart` — B2 redesign
- `lib/features/stats/widgets/completion_ring.dart` — B3 label fix
- `lib/features/stats/widgets/streak_indicator.dart` — B4 + B5 fixes

---

## Track C: Backfill Data Integrity ✅ COMPLETE

- Dry-run detected 1,177 of 2,939 rows as bulk-marked (40%) via 30-second timestamp clustering
- Migration `048_retroactive_backfill_detection.sql` applied — rows retroactively flagged
- Bulk write paths (`markSeasonWatched`, `markAllWatched`, `_createTvShowProgress`, `_syncNewEpisodesForShow`) updated to pass `is_backfill: true` going forward
- Single-episode paths and Settings backfill tool left untouched

---

## Previous Plan

**Advanced Stats Dashboard v1.0** — Complete (2026-02-19)
**Pre-Launch Hardening** — Complete (2026-02-19)
