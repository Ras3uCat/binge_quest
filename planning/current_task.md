# Current Task: Pre-Launch Hardening

**Status**: TODO
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
| A1 | Migration: fix `auth_rls_initplan` — wrap all `auth.uid()` calls in `(SELECT auth.uid())` across all affected RLS policies | TODO | Backend |
| A2 | Migration: merge multiple permissive SELECT policies on `users`, `watchlists`, `watchlist_items`, `watch_progress` into single combined `OR` policies | TODO | Backend |
| A3 | Migration: drop duplicate index `idx_watch_progress_item_watched` (identical to `idx_watch_progress_watched`) | TODO | Backend |
| A4 | ~~Leaked Password Protection~~ — N/A (OAuth-only: Google + Apple login, no passwords) | N/A | — |

### Track B — Flutter Code Fixes

| # | Task | Status | Owner |
|---|------|--------|-------|
| B1 | Remove 7 `print()` calls from `progress_controller.dart:128,405` and `notification_controller.dart:55,65,87,110,134` | TODO | Frontend |
| B2 | Convert 3 `showDialog()` → `Get.dialog()`: `trailer_player_dialog.dart:21`, `badge_controller.dart:132`, `badges_screen.dart:196` | TODO | Frontend |
| B3 | Remove TODO comment at `bingequest_top10_section.dart:71` (dead "See All" navigation comment) | TODO | Frontend |

### Track C — UI Polish (EConfirmDialog Standardization)

| # | Task | Status | Owner |
|---|------|--------|-------|
| C1 | Refactor: Delete watchlist (simple) → `EConfirmDialog` (`watchlist_selector_widget.dart:317`) | TODO | Frontend |
| C2 | Refactor: Delete account warning → `EConfirmDialog` (`settings_screen.dart:259`) | TODO | Frontend |
| C3 | Refactor: Remove co-curator → `EConfirmDialog` (`manage_members_screen.dart:233`) | TODO | Frontend |
| C4 | Refactor: Leave watchlist → `EConfirmDialog` (`manage_members_screen.dart:259`) | TODO | Frontend |
| C5 | Refactor: Remove friend → `EConfirmDialog` (`friend_list_screen.dart:160`) | TODO | Frontend |
| C6 | Refactor: Delete review → `EConfirmDialog` + switch from `showDialog` to `Get.dialog` (`reviews_section.dart:87`) | TODO | Frontend |
| C7 | Refactor: Move item confirmation → `EConfirmDialog` (`move_item_sheet.dart:228`) | TODO | Frontend |
| C8 | Visual polish pass: uniform button sizes, padding, border radius across all dialogs | TODO | Frontend |

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

- Standardize Dialog Boxes (EConfirmDialog) - **Carried into Track C**
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
