# Current Task: User Archetypes

**Status**: IN PROGRESS
**Mode**: STUDIO
**Priority**: High
**Started**: 2026-02-23
**Specs**: `STUDIO_PLAN.md`, `planning/features/user_archetypes.md`

---

## Overview

Classify each user into one of 12 viewer archetypes based on their real watching behavior. The active archetype lives on the user's profile as a badge-like identity label, computed periodically from a rolling 90-day activity window. Supports dual archetypes (tie within 0.05), user-pinned archetypes, archetype history, and push notification on archetype change.

All 12 archetypes are derived exclusively from existing columns — no new source data columns required.

---

## Task Board

### Track A — Backend (Migrations 050–051 + Edge Function)

| # | Task | Status | Owner |
|---|------|--------|-------|
| A1 | Migration 050: `archetypes` reference table + 12 seed rows + `user_archetypes` table + `users` columns (`primary_archetype`, `secondary_archetype`, `archetype_updated_at`) + RLS + indexes | **TODO** | Backend |
| A2 | Migration 051: `compute_user_archetype(p_user_id uuid)` SECURITY DEFINER function (all 12 scoring CTEs, 90-day window, dual archetype logic, min activity threshold) | **TODO** | Backend |
| A3 | Migration 051 (cont): `on_watch_progress_archetype_check()` trigger — AFTER INSERT on `watch_progress`, counts completions since last computation, calls `compute_user_archetype` on every 5th | **TODO** | Backend |
| A4 | Edge Function `compute-archetypes`: nightly cron batch + single-user HTTP entrypoint (service_role only) | **DONE** | Backend |
| A5 | Archetype change notification: Edge Function calls `send-notification` when `new_archetype != prev_archetype` (both non-null) | **DONE** | Backend |

### Track B — Frontend (New Files)

| # | Task | Status | Owner |
|---|------|--------|-------|
| B1 | `lib/shared/models/archetype.dart` — `Archetype`, `UserArchetype` models with `fromJson` | **DONE** | Flutter |
| B2 | `lib/shared/repositories/archetype_repository.dart` — `fetchAllArchetypes`, `fetchUserCurrentScores`, `fetchArchetypeHistory` | **DONE** | Flutter |
| B3 | `lib/features/profile/controllers/archetype_controller.dart` — GetX `lazyPut(fenix: true)`: `allScores`, `history`, `allArchetypes`, `primary`/`secondary` getters, `archetypeById()` | **DONE** | Flutter |
| B4 | `lib/features/profile/widgets/archetype_badge.dart` — compact badge (icon + name + tagline); dual "+" display; "Still Exploring..." placeholder | **DONE** | Flutter |
| B5 | `lib/features/profile/widgets/archetype_detail_sheet.dart` — bottom sheet: description + radar chart + history timeline | **DONE** | Flutter |
| B6 | `lib/features/profile/widgets/archetype_radar_chart.dart` — fl_chart RadarChart with phantom scale dataset | **DONE** | Flutter |
| B7 | `lib/features/profile/widgets/archetype_history_timeline.dart` — scrollable list of past archetype rows | **DONE** | Flutter |

### Track C — Integration (Modified Files)

| # | Task | Status | Owner |
|---|------|--------|-------|
| C1 | Profile screen: add `ArchetypeBadge` below display name; tap → `ArchetypeDetailSheet` (own profile + friend profile views) | **DONE** | Flutter |
| C2 | Friend list items + friend profile cards: compact `ArchetypeBadge` (icon + name only, no tagline) | **DONE** | Flutter |

---

## Execution Order

```
A1 → A2 → A3 (trigger depends on function)
A4, A5 — after A2 (edge function calls DB function)

B1 → B2 → B3 → B4, B5, B6, B7 (sequential model → repo → controller → widgets)

C1, C2 — after B3 controller available
```

---

## Key Decisions

- **Scoring window:** Rolling 90-day `watched_at` lookback — stale history doesn't dominate
- **Minimum threshold:** >= 5 completed titles AND >= 20 episodes watched; below = `null` archetype ("Still Exploring...")
- **Dual archetype:** If top two scores within 0.05 of each other → show both with "+" connector (max 2)
- **Tie-breaking connector:** "+" (not "&" or "x")
- **Recompute trigger:** Every 5th episode completion per user (counted from `watch_progress` INSERT where `watched = true`)
- **Fallback:** Nightly cron via `compute-archetypes` Edge Function covers inactive users
- **Push notification:** Sent when `primary_archetype` column on `users` actually changes value (not on every recompute)
- **`user_archetypes` is write-only for service_role** — no INSERT/UPDATE/DELETE from client
- **Archetype visibility:** Friends only (via existing `users` SELECT policy + `are_friends()` for `user_archetypes`)
- **Quiz (Viewing Style Quiz):** SKIPPED for v1 — all archetypes are fully data-driven
- **Social visibility:** Compact badge on friend profiles (icon + name); full detail only on own profile

---

## Previous Tasks

- Watch Party Sync — **Complete**
- Advanced Stats Dashboard v1.1 Bug Fixes & Backfill Integrity — **Complete**
- Advanced Stats Dashboard v1.0 — **Complete**
- Pre-Launch Hardening (Tracks A, B, C) — **Complete**
- Standardize Dialog Boxes (EConfirmDialog) — **Complete**
- Search + Provider Filter Integration — **Complete**
- Friends Watching Content Indicator — **Complete**
- Mood Guide — **Complete**
- Social Features Suite (Friend System, Watchlist Co-Curators) — **In Progress** (Shareable Playlists remaining)
- Follow Talent (Actors & Directors) — **Complete**
- Streaming Availability Alerts — **Complete**
- Push Notifications Infrastructure — **Complete**
- Move Item Between Watchlists — **Complete**
- Release & Air Dates Display — **Complete**
- Partial Episode Progress Display Fix — **Complete**
- External Sharing — **Complete**
- Dashboard Performance Optimization — **Complete**
- Profile Stats Performance & Minutes Watched Accuracy — **Complete**
- Queue Health Watchlist Switch Bug — **Complete**
- Badge Placement Consistency — **Complete**
