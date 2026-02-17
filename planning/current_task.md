# Current Task: Friends Watching Content Indicator

**Status**: QA
**Mode**: FLOW
**Priority**: Medium
**Started**: 2026-02-17
**Specs**: `friends_watching_content.md`

---

## Overview

Show which friends are also watching the same content on detail pages. Includes a privacy toggle so users can opt out of being visible to friends.

---

## Tasks

### Backend Tasks

| # | Task | Status | Owner |
|---|------|--------|-------|
| 1 | Apply migration: `share_watching_activity` column + `get_friends_watching_content` RPC | DONE | Backend |
| 2 | Run security advisors (no new warnings) | DONE | Backend |

### Frontend Tasks

| # | Task | Status | Owner |
|---|------|--------|-------|
| 3 | Create `FriendWatching` model | DONE | Frontend |
| 4 | Create `FriendsWatchingRow` widget (overlapping avatar stack + label) | DONE | Frontend |
| 5 | Add `getFriendsWatching()` to `WatchlistRepository` | DONE | Frontend |
| 6 | Add privacy methods to `FriendRepository` | DONE | Frontend |
| 7 | Add `shareWatchingActivity` observable to `FriendController` | DONE | Frontend |
| 8 | Integrate into `ContentDetailSheet` (search detail) | DONE | Frontend |
| 9 | Integrate into `ItemDetailScreen` (watchlist detail, via ProgressController) | DONE | Frontend |
| 10 | Add Privacy section to `SettingsScreen` | DONE | Frontend |

Tasks 3-7 can be parallelized. Tasks 8-10 depend on 3-7.

---

## Previous Tasks

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
