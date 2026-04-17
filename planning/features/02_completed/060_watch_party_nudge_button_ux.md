# Bug/Feature: Watch Party Nudge Button UX Fix

## Status
TODO

## Priority
Medium — confusing UX confirmed by multiple users; notification sends but no feedback given

## Overview
The watch party nudge (bell) button has two problems:

1. **No feedback on tap** — the push notification sends successfully (friends confirm receipt), but there is zero UI response. The user cannot tell if anything happened.
2. **Silent disappearance** — once the 24-hour cooldown activates, the button completely vanishes instead of showing a disabled/sent state. Users see a missing button and assume it's broken.

Additionally, the 24-hour cooldown is tracked in-memory only (`_lastNudgeSent` map in `WatchPartyController`) and resets on every app restart, allowing duplicate nudges within the same day after relaunching the app.

## Root Cause
- **Button**: Always rendered with `EColors.textTertiary` (tertiary grey), giving no "active" vs "inactive" visual distinction.
- **Cooldown**: `canNudge()` returning `false` causes the button to be hidden entirely, not disabled with a visual explanation.
- **No feedback**: `nudgeMember()` sends the notification but does not call `Get.snackbar` or show any confirmation.
- **No persistence**: `_lastNudgeSent` is an in-memory `Map<String, DateTime>` that resets on app restart.

## Key Files
- `lib/features/social/widgets/party_progress_row.dart` — button UI (`_buildNudgeButton`, visibility condition)
- `lib/features/social/controllers/watch_party_controller.dart` — `nudgeMember()`, `canNudge()`, `_lastNudgeSent`

## Acceptance Criteria
- [ ] When the nudge is ready to send, the bell icon is colored (e.g., `EColors.primary`) and clearly tappable.
- [ ] After a nudge is sent, a snackbar confirms: `"Nudge sent to {name}!"`.
- [ ] During the 24-hour cooldown, the button remains visible but is greyed out and disabled (not hidden).
- [ ] The disabled button shows a tooltip or subtitle indicating when the nudge will be available again (e.g., "Available again in 18h").
- [ ] The cooldown persists across app restarts (surviving controller disposal and relaunch).
- [ ] No regression: nudge still only fires once per 24 hours per member.

## Implementation Notes

### Dependency
- Confirm `shared_preferences` is in `pubspec.yaml` before implementing. Add it if missing.

### `canNudge()` needs a companion helper
- The disabled tooltip requires knowing the time remaining, not just a bool.
- Add `Duration? nudgeTimeRemaining(String userId)` to the controller: returns `null` if
  nudge is available, or the `Duration` until the cooldown expires if not.
- Keep `canNudge()` as-is for the visibility/enabled check; use `nudgeTimeRemaining()` for
  the tooltip label (e.g., `"Available again in 18h"`).

### Fix `nudgeMember()` write ordering
- Currently `_lastNudgeSent` is updated **before** the network call (optimistic). This means
  a failed send locks the user out of nudging for 24h. Fix: only write to `_lastNudgeSent`
  and `SharedPreferences` **after** the repository call returns successfully.

### Tap target
- The nudge `IconButton` is currently `size: 16` — below Material's 48px minimum.
- Wrap with `SizedBox` or use `IconButton` constraints to ensure at least a 48px hit area,
  especially important when the button is in disabled state.

## Frontend Changes

### `party_progress_row.dart`
- Change visibility condition: show the button when `!isSelf && !member.isAllWatched && member.hasStarted` (always, not gated on `canNudge`).
- Pass `canNudge` as a bool and `timeRemaining` as a `Duration?` to the button builder.
- In `_buildNudgeButton()`:
  - If `canNudge == true`: render `Icons.notifications_active` in `EColors.primary`, `onPressed: onNudge`. Ensure 48px tap target.
  - If `canNudge == false`: render `Icons.notifications_outlined` in `EColors.textTertiary`, `onPressed: null` (disabled).
  - Wrap disabled button in a `Tooltip` using `timeRemaining` to show e.g. `"Available again in 18h"`.

### `watch_party_controller.dart`
- Add `nudgeTimeRemaining(String userId) → Duration?` helper.
- In `nudgeMember()`: write to `_lastNudgeSent` and persist **only after** the repository call succeeds. Then call `Get.snackbar('Nudge Sent', 'Notified ${member.displayName}!')`.
- Persist cooldown: `prefs.setInt('nudge_${partyId}_${userId}', DateTime.now().millisecondsSinceEpoch)`.
- On `onInit()`: read persisted nudge timestamps and pre-populate `_lastNudgeSent`.

## Backend Changes
None — the notification send path is correct and working.

## QA Checklist
- [ ] Tap nudge button: snackbar appears confirming send.
- [ ] After sending: button turns grey/disabled with tooltip showing time remaining.
- [ ] Close and reopen app within 24h: button still shows as disabled (cooldown persisted).
- [ ] After 24h: button returns to active/colored state.
- [ ] Failed network call: button remains active (no cooldown written on failure).
- [ ] Recipient's device: notification received as before.
- [ ] Self-nudge: button not shown (existing behavior preserved).
- [ ] Member who finished all episodes: button not shown (existing behavior preserved).
- [ ] Disabled button has at least 48px tap target (no accidental taps).
