# Pre-Launch Hardening

**Status:** COMPLETE — All tracks done (2026-02-19)
**Mode:** STUDIO
**Priority:** Critical
**Started:** 2026-02-19
**Specs:** Full audit results from pre-launch review

---

## Problem Description

Full pre-launch audit surfaced database performance issues (RLS initplan re-evaluation, duplicate indexes, merged policies), Flutter code quality issues (print() in production, showDialog() inconsistency), one Auth security gap (leaked password protection disabled), and incomplete dialog standardization.

---

## Design Decisions (ADR)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| RLS `auth.uid()` fix | Wrap in `(SELECT auth.uid())` | Standard Supabase optimization — evaluates once per query instead of per row |
| Merge permissive SELECT policies | Combine into single policy with OR condition | Postgres evaluates all permissive policies; merging eliminates redundant evaluation |
| `print()` removal | Delete outright | They're in error catch blocks with no user-facing value; release builds still emit them |
| `showDialog()` → `Get.dialog()` | Replace with Get.dialog() | Consistency with rest of app; GetX context management |
| Leaked password protection | Enable in dashboard | Zero-code security uplift via HaveIBeenPwned API |
| Duplicate index drop | Drop `idx_watch_progress_item_watched` | `idx_watch_progress_watched` is identical; duplicate wastes write overhead |

---

## Track A: Database Migrations ✅ COMPLETE

### A1 — Fix `auth_rls_initplan` (All Tables)

Replace `auth.uid()` with `(SELECT auth.uid())` in RLS USING/WITH CHECK clauses across all affected tables. This prevents per-row re-evaluation and is the highest-impact performance fix.

**Affected tables:** `users`, `watchlists`, `watchlist_items`, `watch_progress`, `reviews`, `user_episode_notifications`, `user_device_tokens`, `notification_preferences`, `notifications`, `user_streaming_preferences`, `followed_talent`, `user_blocks`, `friendships`, `watchlist_members`, `user_badges`

**Pattern:**
```sql
-- Before
USING (auth.uid() = user_id)
-- After
USING ((SELECT auth.uid()) = user_id)
```

### A2 — Merge Multiple Permissive Policies

**`users` table — SELECT:**
Merge `Users can view their own profile` + `Authenticated users can view all profiles` into one policy.
Result: `USING (true)` (since all authenticated users can view all profiles already).

**`watchlists` table — SELECT:**
Merge `Users can view their own watchlists` + `Co-owners can view shared watchlists`.
Result: single policy with `OR` covering both conditions.

**`watchlist_items` table — SELECT/INSERT/UPDATE/DELETE:**
Merge owner + co-owner variants for each operation into combined policies.

**`watch_progress` table — SELECT/INSERT/UPDATE/DELETE:**
Merge owner + co-owner variants for each operation into combined policies.

### A3 — Drop Duplicate Index

```sql
DROP INDEX IF EXISTS public.idx_watch_progress_item_watched;
-- Keep: idx_watch_progress_watched
```

### A4 — Leaked Password Protection (Dashboard Only)

Supabase Dashboard → Authentication → Security → enable "Leaked Password Protection".
No SQL migration needed.

---

## Track B: Flutter Code Fixes ✅ COMPLETE

### B1 — Remove `print()` Calls

| File | Lines |
|------|-------|
| `features/watchlist/controllers/progress_controller.dart` | 128, 405 |
| `features/notifications/controllers/notification_controller.dart` | 55, 65, 87, 110, 134 |

Delete the print statements. These are in catch blocks — silent failure is acceptable; the state simply stays at default.

### B2 — Convert `showDialog()` → `Get.dialog()`

Only the controller instance is worth fixing — widget files with valid BuildContext are fine with `showDialog()`.

| File | Line | Reason |
|------|------|--------|
| `features/badges/controllers/badge_controller.dart` | 132 | Controller has no BuildContext; was using `Get.context!` (fragile) |

### B3 — Remove Dead TODO

`features/dashboard/widgets/bingequest_top10_section.dart:71` — delete the TODO comment about "See All" navigation. Not shipping this screen; comment adds noise.

---

## Track C: EConfirmDialog Standardization ✅ COMPLETE

`EConfirmDialog` widget already exists and is used in `profile_screen.dart`. Convert the remaining 7 raw dialog patterns:

| Task | File | Current Pattern |
|------|------|----------------|
| C1 | `watchlist/widgets/watchlist_selector_widget.dart:317` | `Get.dialog` + `AlertDialog` |
| C2 | `settings/screens/settings_screen.dart:259` | `Get.dialog` + `AlertDialog` |
| C3 | `social/screens/manage_members_screen.dart:233` | `Get.dialog` + `AlertDialog` |
| C4 | `social/screens/manage_members_screen.dart:259` | `Get.dialog` + `AlertDialog` |
| C5 | `social/screens/friend_list_screen.dart:160` | `Get.dialog` + `AlertDialog` |
| C6 | `features/reviews/widgets/reviews_section.dart:87` | `showDialog` + `AlertDialog` |
| C7 | `features/watchlist/widgets/move_item_sheet.dart:228` | `Get.dialog` + `AlertDialog` |

**Custom dialogs to leave as-is:** Create watchlist, transfer ownership, delete account final confirmation, backfill progress, badge unlock animation, trailer player.

**C8 — Visual polish:** After C1–C7, verify all dialogs (including custom ones) use `border-radius: 16`, `ESizes.lg` padding, and consistent button sizing.

---

## Files Modified

**Migrations (new files in `supabase/migrations/`):**
- `038_fix_rls_initplan.sql`
- `039_merge_permissive_policies.sql`
- `040_drop_duplicate_index.sql`

**Flutter:**
- `features/watchlist/controllers/progress_controller.dart` (remove prints)
- `features/notifications/controllers/notification_controller.dart` (remove prints)
- `features/search/widgets/trailer_player_dialog.dart` (showDialog → Get.dialog)
- `features/badges/controllers/badge_controller.dart` (showDialog → Get.dialog)
- `features/badges/screens/badges_screen.dart` (showDialog → Get.dialog)
- `features/dashboard/widgets/bingequest_top10_section.dart` (remove TODO)
- `features/watchlist/widgets/watchlist_selector_widget.dart` (EConfirmDialog)
- `features/settings/screens/settings_screen.dart` (EConfirmDialog)
- `features/social/screens/manage_members_screen.dart` (EConfirmDialog x2)
- `features/social/screens/friend_list_screen.dart` (EConfirmDialog)
- `features/reviews/widgets/reviews_section.dart` (EConfirmDialog)
- `features/watchlist/widgets/move_item_sheet.dart` (EConfirmDialog)

---

## Risk Assessment

| Item | Risk | Notes |
|------|------|-------|
| A1 RLS rewrite | Medium | Test all RLS-protected operations after migration |
| A2 Policy merge | Medium | Verify co-owner access still works end-to-end |
| A3 Drop index | Low | Duplicate index — zero functional impact |
| B1–B3 | Low | Cosmetic/consistency changes |
| C1–C8 | Low | UI-only, no logic changes |

---

## Previous Plan

**Mood Guide** — Complete
**Social Features Suite** — Friend System (done), Watchlist Co-Curators (done), Watch Party Sync (todo), Shareable Playlists (todo)
