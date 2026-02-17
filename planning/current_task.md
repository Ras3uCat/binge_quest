# Current Task: Standardize Dialog Boxes

**Status**: TODO
**Mode**: FLOW
**Priority**: Medium
**Started**: 2026-02-17
**Specs**: N/A (UI polish)

---

## Overview

Standardize all confirmation/action dialogs across the app for consistent look and feel. Create a shared `EDialog` helper to eliminate duplicated dialog code and ensure uniform styling.

---

## Audit Summary (12 dialog instances found)

| # | Location | Dialog | Pattern | Issue |
|---|----------|--------|---------|-------|
| 1 | `watchlist_selector_widget.dart:317` | Delete watchlist (simple) | `Get.dialog` + `AlertDialog` | Duplicated pattern |
| 2 | `watchlist_selector_widget.dart:347` | Transfer/Delete watchlist (co-curators) | `Get.dialog` + `Obx` + `AlertDialog` | Custom — keep as-is |
| 3 | `create_watchlist_dialog.dart` | Create/Edit watchlist | Custom `AlertDialog` widget | Good — keep as-is |
| 4 | `settings_screen.dart:259` | Delete account warning | `Get.dialog` + `AlertDialog` | Duplicated pattern |
| 5 | `settings_screen.dart:289` | Delete account confirmation | `Get.dialog` + `Obx` + `AlertDialog` | Custom — keep as-is |
| 6 | `settings_screen.dart:340` | Episode backfill progress | `Get.dialog` + `Obx` + `AlertDialog` | Custom — keep as-is |
| 7 | `manage_members_screen.dart:233` | Remove co-curator | `Get.dialog` + `AlertDialog` | Duplicated pattern |
| 8 | `manage_members_screen.dart:259` | Leave watchlist | `Get.dialog` + `AlertDialog` | Duplicated pattern |
| 9 | `friend_list_screen.dart:160` | Remove friend | `Get.dialog` + `AlertDialog` | Duplicated pattern |
| 10 | `profile_screen.dart:365` | Sign out | `Get.dialog` + `AlertDialog` | Duplicated pattern |
| 11 | `reviews_section.dart:87` | Delete review | `showDialog` + `AlertDialog` | Uses `showDialog` not `Get.dialog` |
| 12 | `move_item_sheet.dart:228` | Move item confirmation | `Get.dialog` + `AlertDialog` | Duplicated pattern |

**Custom dialogs (keep as-is):** Create watchlist, transfer ownership, delete account final, backfill progress, badge detail, badge unlock, trailer player. These have unique UI needs (forms, animations, reactive state).

**Standardizable (7 dialogs):** #1, #4, #7, #8, #9, #10, #11, #12 — all follow the same "title + message + cancel/confirm" pattern.

---

## Tasks

### Frontend Tasks

| # | Task | Status | Owner |
|---|------|--------|-------|
| 1 | Create shared `EConfirmDialog` widget in `lib/shared/widgets/` — title, message, confirmLabel, cancelLabel, isDestructive flag, onConfirm callback. Uses `Get.dialog()`, `EColors` consistently | TODO | Frontend |
| 2 | Create `EConfirmDialog.show()` static helper for one-liner usage | TODO | Frontend |
| 3 | Refactor: Delete watchlist (simple) → `EConfirmDialog` | TODO | Frontend |
| 4 | Refactor: Delete account warning → `EConfirmDialog` | TODO | Frontend |
| 5 | Refactor: Remove co-curator → `EConfirmDialog` | TODO | Frontend |
| 6 | Refactor: Leave watchlist → `EConfirmDialog` | TODO | Frontend |
| 7 | Refactor: Remove friend → `EConfirmDialog` | TODO | Frontend |
| 8 | Refactor: Sign out → `EConfirmDialog` | TODO | Frontend |
| 9 | Refactor: Delete review → `EConfirmDialog` (also switch from `showDialog` to `Get.dialog`) | TODO | Frontend |
| 10 | Refactor: Move item confirmation → `EConfirmDialog` | TODO | Frontend |
| 11 | Visual polish pass: ensure button sizes, padding, border radius are uniform across ALL dialogs (including custom ones) | TODO | Frontend |

Tasks 1-2 first. Tasks 3-10 can be parallelized after. Task 11 last.

---

## Design Spec: `EConfirmDialog`

```
┌─────────────────────────────────────┐
│                                     │
│  Title                              │  ← EColors.textPrimary, fontMd, bold
│                                     │
│  Description text that explains     │  ← EColors.textSecondary, fontSm
│  what will happen.                  │
│                                     │
│              [Cancel]  [Confirm]    │  ← Cancel: TextButton
│                                     │     Confirm: ElevatedButton
│                                     │     Destructive: EColors.error bg
│                                     │     Normal: EColors.primary bg
└─────────────────────────────────────┘

Background: EColors.surface
Border radius: 16
Content padding: ESizes.lg
```

### API

```dart
EConfirmDialog.show(
  title: 'Delete Watchlist',
  message: 'Are you sure? This cannot be undone.',
  confirmLabel: 'Delete',        // default: 'Confirm'
  cancelLabel: 'Cancel',         // default: 'Cancel'
  isDestructive: true,           // default: false — colors confirm button red
  onConfirm: () => ctrl.delete(),
);
```

---

## Previous Tasks

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
