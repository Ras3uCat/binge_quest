# Notification Management (Delete & Clear)

**Status:** IN PROGRESS
**Mode:** STUDIO
**Priority:** High
**Started:** 2026-02-24
**Specs:** `planning/features/notification_management.md`

---

## Problem Description

Notifications accumulate indefinitely. Users have no way to dismiss individual notifications or clear them in bulk, making the notification center increasingly noisy over time.

---

## Architecture

**Minimal change — one migration + two repo methods + UI wrappers.**

No new tables or schema columns. Notifications are ephemeral; hard deletes are appropriate.

The existing `notifications` table is missing a `DELETE` RLS policy — users can read their own but cannot delete them. Adding that policy unlocks all client-side delete calls.

---

## Track A: Backend

### A1 — Migration `036_notification_delete_policy.sql`

```sql
CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  USING (auth.uid() = user_id);
```

Apply via Supabase MCP (`apply_migration`). No data changes, no column changes.

---

## Track B: Data Layer

### B1 — `NotificationRepository`

Add two methods:

```dart
Future<void> deleteById(String notificationId)
Future<void> deleteAll(String userId)
```

Both use the Supabase client `.delete()` filtered by `id` / `user_id`. User JWT is sufficient — no service_role needed.

### B2 — `NotificationController`

Add two methods that call the repo and update the reactive `RxList`:

```dart
void removeNotification(String id)      // optimistic remove → repo call → rollback on error
Future<void> clearAllNotifications()    // confirm dialog → repo call → clear list
```

No full reload needed after delete — mutate the local `RxList` directly.

---

## Track C: UI

### C1 — Swipe-to-Dismiss (individual)

Wrap each notification `ListTile` in `Dismissible`:
- Direction: `DismissDirection.endToStart` (swipe left)
- Background: red container with `Icons.delete_outline` right-aligned (`EColors.error`)
- `onDismissed`: call `controller.removeNotification(id)`
- On error: re-insert item at original index + `EToast.error('Failed to remove notification')`

### C2 — Clear All (header)

Add a trailing `TextButton('Clear All')` to the notification screen's header row:
- Only visible when list is non-empty (reactive `Obx`)
- Tap → `EConfirmDialog`:
  - Title: `"Clear all notifications?"`
  - Body: `"This will permanently remove all X notifications."`
  - Confirm: destructive style (`EColors.error`)
- On confirm: `controller.clearAllNotifications()`

### C3 — Empty State

Verify an empty state widget exists; add one if missing (icon + "No notifications" label).

---

## Files to Touch

**New:**
- Supabase migration `036_notification_delete_policy` (via MCP)

**Modified:**
- `notification_repository.dart` — add `deleteById`, `deleteAll`
- `notification_controller.dart` — add `removeNotification`, `clearAllNotifications`
- Notification screen — `Dismissible` on items (C1), Clear All header button (C2), empty state check (C3)

---

## Key Constraints

- Optimistic UI: remove from list first, rollback on API error
- `EConfirmDialog` required for destructive bulk action (per decisions.md)
- No `Obx` inside bottom sheets (not applicable here, but noted)
- Repository pattern must be respected — no direct Supabase calls from controller

---

## Previous Plans

**Contextual Info Guides** — Complete (2026-02-24)
**New Episode Notifications + Episode Cache Refresh** — Complete (2026-02-25)
