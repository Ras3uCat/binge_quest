# Current Task: Pre-Launch Hardening

**Status**: COMPLETE
**Mode**: STUDIO
**Priority**: Critical
**Started**: 2026-02-19
**Specs**: `STUDIO_PLAN.md`

---

## Overview

Full pre-launch audit complete. Work is split into three tracks: database migrations, Flutter code fixes, and UI polish. All items must be resolved before store submission.

---

## Task Board

### Track A — Database (Migrations)

| # | Task | Status | Owner |
|---|------|--------|-------|
| A1 | Migration: fix `auth_rls_initplan` — wrap all `auth.uid()` calls in `(SELECT auth.uid())` across all affected RLS policies | **DONE** | Backend |
| A2 | Migration: merge multiple permissive SELECT policies on `users`, `watchlists`, `watchlist_items`, `watch_progress` into single combined `OR` policies | **DONE** | Backend |
| A3 | Migration: drop duplicate index `idx_watch_progress_item_watched` (identical to `idx_watch_progress_watched`) | **DONE** | Backend |
| A4 | ~~Leaked Password Protection~~ — N/A (OAuth-only: Google + Apple login, no passwords) | N/A | — |

### Track B — Flutter Code Fixes

| # | Task | Status | Owner |
|---|------|--------|-------|
| B1 | Remove 7 `print()` calls from `progress_controller.dart:128,405` and `notification_controller.dart:55,65,87,110,134` | **DONE** | Frontend |
| B2 | Convert `showDialog()` → `Get.dialog()` in `badge_controller.dart:132` only (controller has no BuildContext; widget files dropped — cosmetic only) | **DONE** | Frontend |
| B3 | Remove TODO comment at `bingequest_top10_section.dart:71` (dead "See All" navigation comment) | **DONE** | Frontend |

### Track C — UI Polish (EConfirmDialog Standardization)

| # | Task | Status | Owner |
|---|------|--------|-------|
| C1 | Refactor: Delete watchlist (simple) → `EConfirmDialog` (`watchlist_selector_widget.dart:317`) | **DONE** | Frontend |
| C2 | Refactor: Delete account warning → `EConfirmDialog` (`settings_screen.dart:259`) | **DONE** | Frontend |
| C3 | Refactor: Remove co-curator → `EConfirmDialog` (`manage_members_screen.dart:233`) | **DONE** | Frontend |
| C4 | Refactor: Leave watchlist → `EConfirmDialog` (`manage_members_screen.dart:259`) | **DONE** | Frontend |
| C5 | Refactor: Remove friend → `EConfirmDialog` (`friend_list_screen.dart:160`) | **DONE** | Frontend |
| C6 | Refactor: Delete review → `EConfirmDialog` + switch from `showDialog` to `Get.dialog` (`reviews_section.dart:87`) | **DONE** | Frontend |
| C7 | Refactor: Move item confirmation → `EConfirmDialog` (`move_item_sheet.dart:228`) | **DONE** | Frontend |
| C8 | Visual polish pass: uniform button sizes, padding, border radius across all dialogs | **DONE** | Frontend |

---

## Execution Order

```
A4 (dashboard, no migration needed) — immediate

A1 → A2 → A3 (sequential migrations, each depends on previous state)

B1, B2, B3 — parallel, no deps
C1–C7 — parallel after each other (no shared deps)
C8 — after C1–C7
```

---

## Known Non-Issues (Do Not Fix)

- `content_cache` / `content_cache_episodes` permissive RLS — intentional shared cache
- `function_search_path_mutable` on ~18 functions — pre-existing, low real-world risk
- 9 unused indexes — drop post-launch once traffic patterns confirm
- 3 unindexed FKs (`user_badges.badge_id`, `user_episode_notifications.event_id`, `watchlist_members.invited_by`) — low-traffic tables
- Hardcoded keys in `env.dart` — anon key is intentionally public; TMDB key obfuscation is a Flutter build-time limitation
- `kDevMode = false` — already correct

---

## Previous Tasks

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
