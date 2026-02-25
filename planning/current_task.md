# Current Task: Notification Management (Delete & Clear)

**Status**: IN PROGRESS
**Mode**: STUDIO
**Priority**: High
**Started**: 2026-02-24
**Specs**: `planning/features/notification_management.md`, `STUDIO_PLAN.md`

---

## Overview

Notifications accumulate indefinitely. Add swipe-to-dismiss on individual items and a "Clear All" bulk action. Requires one new RLS DELETE policy migration plus repository/controller/UI changes.

---

## Task Board

### Track A — Backend

| # | Task | Status |
|---|------|--------|
| A1 | Apply migration `036_notification_delete_policy` (DELETE RLS on `notifications`) | ✅ Done |

### Track B — Data Layer

| # | Task | Status |
|---|------|--------|
| B1 | `NotificationRepository`: add `deleteById` + `deleteAll` | ✅ Done |
| B2 | `NotificationController`: add `removeNotification` + `clearAllNotifications` | ✅ Done |

### Track C — UI

| # | Task | Status |
|---|------|--------|
| C1 | Wrap notification items in `Dismissible` (swipe-to-delete) | ✅ Done |
| C2 | Add "Clear All" button to notification screen header | ✅ Done |
| C3 | Verify / add empty state widget | ✅ Done |

---

## Execution Order

```
A1 (migration — unblocks B1)
  → B1 (repo methods)
    → B2 (controller methods — depends on B1)
      → C1, C2, C3 (UI — parallel, depend on B2)
```

---

## Previous Tasks

- Contextual Info Guides — **Complete**

- New Episode Notifications + Episode Cache Refresh — **Complete**
- Push Notifications Hardening (FCM token lifecycle, Realtime channel cleanup, Android/iOS audit, watch party categories, preference mapping) — **Complete**
- User Archetypes — **Complete**
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
