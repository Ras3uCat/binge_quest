# Feature: Notification Management (Delete & Clear)

## 📝 Summary
Notifications currently accumulate indefinitely in the notification center. Users need the ability to dismiss individual notifications and bulk-clear all of them. This is a UX hygiene feature — no new data or logic, just delete access.

## 🎯 Scope
- [x] **Included:** Swipe-to-dismiss on individual notification items
- [x] **Included:** "Clear all" button in the notification screen header
- [x] **Included:** RLS DELETE policy on `notifications` table (users delete their own)
- [ ] **NOT Included:** Undo / restore deleted notifications
- [ ] **NOT Included:** Delete by notification type/category
- [ ] **NOT Included:** Auto-expiry / TTL (separate feature if needed)

## 🎨 UX & Interaction

### Swipe-to-Dismiss (individual)
- Wrap each notification `ListTile` in a `Dismissible` widget (swipe left or right)
- Background shows a red trash icon (`Icons.delete_outline`, `EColors.error`)
- On dismiss: optimistically remove from list → call `NotificationRepository.deleteById(id)`
- On error: re-insert item and show `EToast.error('Failed to remove notification')`

### Clear All
- Header row of notification screen: `[Notifications]  [Clear All (TextButton)]`
- `Clear All` is only visible when the list is non-empty
- Tapping shows `EConfirmDialog` (per decisions.md standard):
  - Title: `"Clear all notifications?"`
  - Body: `"This will permanently remove all X notifications."`
  - Confirm: destructive style (`EColors.error`)
- On confirm: call `NotificationRepository.deleteAll(userId)` → clear local list
- On error: show `EToast.error('Failed to clear notifications')`

### Empty State
- Existing empty state widget is shown after all notifications are cleared (no change needed if it already exists; add one if missing)

## 💾 Backend / Data Layer

### RLS — New DELETE Policy on `notifications`
```sql
-- Migration: 036_notification_delete_policy.sql
CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  USING (auth.uid() = user_id);
```
No schema column changes needed — hard deletes are appropriate for ephemeral notification data.

### Repository Methods (NotificationRepository)
```
deleteById(String notificationId) → Future<void>
deleteAll(String userId) → Future<void>
```
Both execute Supabase `.delete()` queries filtered by `id` / `user_id`. No service_role needed — user JWT is sufficient with the new DELETE policy.

### Controller (NotificationController)
- `removeNotification(String id)` — calls repo, updates `RxList`
- `clearAllNotifications()` — calls repo, clears `RxList`
- Reactive list drives the UI; no full reload needed after delete

## 🏁 Acceptance Criteria
- [ ] User can swipe-dismiss a single notification; it disappears from the list immediately
- [ ] If the delete API call fails, the notification reappears and an error toast is shown
- [ ] "Clear All" button is visible only when at least one notification exists
- [ ] Tapping "Clear All" shows the `EConfirmDialog` before executing
- [ ] After confirming "Clear All", all notifications are removed and the empty state is shown
- [ ] Deleted notifications do not reappear on screen refresh / re-navigation
- [ ] RLS policy prevents users from deleting another user's notifications (verified via test query)
