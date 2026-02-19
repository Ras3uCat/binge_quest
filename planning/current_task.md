# Current Task: Advanced Stats Dashboard — Bug Fixes & Iteration (v1.1)

**Status**: COMPLETE
**Mode**: STUDIO
**Priority**: High
**Started**: 2026-02-19
**Specs**: `STUDIO_PLAN.md`

---

## Overview

Post-implementation QA surfaced 10 issues spanning backend RPC bugs, frontend rendering bugs, a calculation error, and one design change (watch time chart). Split into backend fixes (Track A) and frontend fixes (Track B).

---

## Issue Log

| # | Description | Track |
|---|---|---|
| 1 | Stats should aggregate across ALL user's watchlists combined | A |
| 2 | Profile card denominators show 0 — `total_episodes`, `total_movies`, `total_shows` from `get_user_stats()` returning 0 | A |
| 3 | All-time filter returns empty stats on the stats screen | A |
| 4 | Completion ring shows all-time completed/total — should show completed within selected time window | A + B |
| 5 | Episode pace too high — 9.4/day (week), 43.6/day (month), 46.5/day (year) — calculation bug | A |
| 6 | Tapping outside mood donut chart throws `RangeError: not in range 0..5: -1` | B |
| 7 | Watch time chart: redesign from date-based to day-of-week (Sun–Sat) aggregated across the selected window | A + B |
| 8 | Streak "Best" number formatting doesn't match "Current streak" style (color difference is fine, keep it) | B |
| 9 | Streak dots (7-day row) don't match the actual streak — derivation logic is wrong | B |
| 10 | Completion section missing items — not counting everything across all watchlists | A |

---

## Task Board

### Track A — Backend Fixes

| # | Task | Status | Owner |
|---|------|--------|-------|
| A1 | Audit `get_stats_dashboard` and `get_user_stats` — confirm all queries scope to ALL watchlists the user owns OR is a co-curator of, including co-curator watch progress (watching together counts). Fix any missing joins. | **DONE** | Backend |
| A2 | Fix `get_user_stats()` `total_episodes`, `total_movies`, `total_shows` returning 0 — debug join logic against `watchlist_items` + `content_cache` | **DONE** | Backend |
| A3 | Fix `get_stats_dashboard('all')` returning empty — the `'all'` time window branch likely has a bad or missing filter condition | **DONE** | Backend |
| A4 | Fix episode pace calculation — should be `total_episodes_in_window / days_in_window` (full calendar days), not `/ days_with_activity` | **DONE** | Backend |
| A5 | Fix completion count — `summary.items_completed` should count items marked complete within the selected time window, not all-time | **DONE** | Backend |
| A6 | Add day-of-week aggregation to `get_stats_dashboard` — replace `watch_time_trend` (date-based) with `watch_time_by_weekday`: 7 rows, one per weekday (0=Sun … 6=Sat), summed across the selected window | **DONE** | Backend |
| A7 | Fix `longest_streak` — must be computed within the selected time window (not all-time). `current_streak` stays as today's active consecutive streak. | **DONE** | Backend |

### Track B — Frontend Fixes

| # | Task | Status | Owner |
|---|------|--------|-------|
| B1 | Fix mood donut `RangeError` — guard `fl_chart` touch callback against index `-1` | **DONE** | Gemini |
| B2 | Redesign watch time chart — 7 fixed day-of-week bars (Sun–Sat), `watch_time_by_weekday` field | **DONE** | Gemini |
| B3 | Fix completion ring — time-window-aware label | **DONE** | Gemini |
| B4 | Fix streak "Best" label — match `'day streak'` pattern → now reads `'best streak'` | **DONE** | Frontend |
| B5 | Fix streak dots — use `current_week_activity` from RPC | **DONE** | Gemini |
| B6 | Fix inactive streak dots — were `EColors.surface` (invisible); changed to `EColors.border` | **DONE** | Frontend |

### Track C — Backfill Data Integrity

| # | Task | Status | Owner |
|---|------|--------|-------|
| C1 | Dry-run: detect bulk-marked rows via 30-second timestamp clustering — 1,177 of 2,939 rows identified | **DONE** | Backend |
| C2 | Migration `048`: retroactively set `is_backfill = true` on 1,177 bulk-marked rows | **DONE** | Backend |
| C3 | Update bulk-mark write paths — `markSeasonWatched`, `markAllWatched`, `_createTvShowProgress`, `_syncNewEpisodesForShow` now pass `is_backfill: true` | **DONE** | Frontend |

---

## Execution Order

```
A1 first — establishes correct data scope for all other fixes
A2, A3, A4, A5, A6 — after A1, can parallelize

B1 — immediate, no backend dep
B2 — after A6 (needs new weekday response shape)
B3 — after A5 (needs fixed completion count)
B4, B5 — no backend dep, can parallelize
```

---

## Previous Tasks

- Advanced Stats Dashboard v1.1 Bug Fixes & Backfill Integrity - **Complete**
- Advanced Stats Dashboard v1.0 - **Complete**
- Pre-Launch Hardening (Tracks A, B, C) - **Complete**
- Standardize Dialog Boxes (EConfirmDialog) - **Complete**
- Search + Provider Filter Integration - **Complete**
- Friends Watching Content Indicator - **Complete**
- Mood Guide - **Complete**
- Social Features Suite (Friend System, Watchlist Co-Curators) - **In Progress** (Watch Party + Shareable Playlists remaining)
- Follow Talent (Actors & Directors) - **Complete**
- Streaming Availability Alerts - **Complete**
- Push Notifications Infrastructure - **Complete**
- Move Item Between Watchlists - **Complete**
- Release & Air Dates Display - **Complete**
- Partial Episode Progress Display Fix - **Complete**
- External Sharing - **Complete**
- Dashboard Performance Optimization - **Complete**
- Profile Stats Performance & Minutes Watched Accuracy - **Complete**
- Queue Health Watchlist Switch Bug - **Complete**
- Badge Placement Consistency - **Complete**
