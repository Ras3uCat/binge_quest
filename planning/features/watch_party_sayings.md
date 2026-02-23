# Feature: Watch Party Progress Sayings

## Status
COMPLETE — implemented 2026-02-23

## Overview

Personalized fun sayings displayed on each member's progress row in the watch party screen. Applied to first place, last place, and a single "middle" position. Sayings are picked once per `openParty()` call and remain stable until the next refresh.

---

## Position Rules

**Rule:** `middleIndex = n ~/ 2` (integer division, 0-indexed). Always a single person.

| Members | First | Middle | Last |
|---------|-------|--------|------|
| 1 | — | — | — |
| 2 | index 0 | — | index 1 |
| 3 | index 0 | index 1 | index 2 |
| 4 | index 0 | index 2 | index 3 |
| 5 | index 0 | index 2 | index 4 |
| 6 | index 0 | index 3 | index 5 |
| 7 | index 0 | index 3 | index 6 |
| 8 | index 0 | index 4 (5th place) | index 7 |

Middle saying only applies when n >= 3.

---

## Sort Order

Members are sorted by progress score, **descending** (leader first, furthest behind last).

**TV:** `score = seasonNumber * 10000 + episodeNumber`, tiebreak on `progressPercent`
**Movie:** `score = progressPercent`
**No progress (empty episodes):** always last

---

## Saying Selection

- `WatchPartyController` stores three `int` fields: `firstPlaceSayingIndex`, `lastPlaceSayingIndex`, `middleSayingIndex`
- Each is assigned `Random().nextInt(10)` (first/last) or `Random().nextInt(20)` (middle) at the start of `openParty()`
- Only one member ever receives the middle saying (`n ~/ 2`, 0-indexed)
- `{name}` is replaced with `member.displayName` at render time

---

## Sayings

### First Place (10 sayings, index 0–9)

| # | Saying |
|---|--------|
| 0 | "No spoilers, {name}." |
| 1 | "Slow down, {name}." |
| 2 | "We see you, {name}." |
| 3 | "Pause and wait for us, {name}." |
| 4 | "{name} is not here to pace themselves." |
| 5 | "{name} came here to win." |
| 6 | "At this rate, {name} will finish before we hit episode three." |
| 7 | "Too fast, {name}." |
| 8 | "{name} is a force of nature." |
| 9 | "{name} clearly blocked off the whole weekend." |

### Last Place (10 sayings, index 0–9)

| # | Saying |
|---|--------|
| 0 | "Did {name} fall asleep?" |
| 1 | "Someone check on {name}." |
| 2 | "{name} is still on episode one." |
| 3 | "Is {name} even watching?" |
| 4 | "No pressure, {name}. But hurry up." |
| 5 | "{name} really committed to taking it slow." |
| 6 | "No rush, {name}. Really. No rush." |
| 7 | "{name} needs to catch up." |
| 8 | "{name} takes their time." |
| 9 | "{name} is officially the weak link." |

### Middle Place (20 sayings, index 0–19)

| # | Saying |
|---|--------|
| 0 | "Not first, not last. Classic {name}." |
| 1 | "{name} is right where they want to be." |
| 2 | "Comfortably in the middle, as is tradition for {name}." |
| 3 | "{name} is playing it safe." |
| 4 | "Dependable as ever, {name}." |
| 5 | "{name} refuses to commit to a side." |
| 6 | "Solidly mid. Respect, {name}." |
| 7 | "Neither fast nor slow. {name} found the sweet spot." |
| 8 | "{name} has seen enough to contribute to the conversation." |
| 9 | "{name} watched just enough to have opinions." |
| 10 | "Classic middle-child energy from {name}." |
| 11 | "Not winning, not losing. {name} is vibing." |
| 12 | "{name} is unbothered and perfectly on pace." |
| 13 | "Somewhere in the middle, {name} found peace." |
| 14 | "{name} is taking the scenic route." |
| 15 | "Right in the thick of it: {name}." |
| 16 | "{name} has a measured approach to all things." |
| 17 | "{name} is exactly where expected." |
| 18 | "Balanced, neutral, {name}." |
| 19 | "{name} is the true median of this group." |

### Not Started (6 sayings — members with zero progress, index 0–5)

Shown instead of last-place sayings when `member.episodes.isEmpty`. Takes priority over last-place assignment.

| # | Saying |
|---|--------|
| 0 | "{name} hasn't even pressed play yet." |
| 1 | "Still waiting on {name}." |
| 2 | "{name} has not started. Bold strategy." |
| 3 | "Whenever you're ready, {name}." |
| 4 | "{name} is saving it for a special occasion apparently." |
| 5 | "The journey has not yet begun for {name}." |

Random index: `Random().nextInt(6)`, assigned at `openParty()` as `notStartedSayingIndex`.

---

### Completed (6 sayings — members where all progress is watched, index 0–5)

Replaces the "Done" badge label. Shown when `member.isAllWatched == true`.

| # | Saying |
|---|--------|
| 0 | "{name} has seen everything. Tread carefully." |
| 1 | "{name} is waiting for the rest of you." |
| 2 | "{name} finished. No further questions." |
| 3 | "Say nothing around {name}." |
| 4 | "{name} knows how it ends." |
| 5 | "{name} has reached the other side." |

Random index: `Random().nextInt(6)`, assigned at `openParty()` as `completedSayingIndex`.

---

### Tied (10 sayings — two or more members on the exact same episode/percent, index 0–9)

Applied when two adjacent members in the sorted list have identical scores. Both members share the same saying. Use `{name}` for the tied member's name; the saying does not reference the other person.

| # | Saying |
|---|--------|
| 0 | "{name} is locked in step." |
| 1 | "Exactly on pace: {name}." |
| 2 | "Right there with the pack, {name}." |
| 3 | "{name} refuses to pull ahead." |
| 4 | "Neck and neck. Eyes forward, {name}." |
| 5 | "{name} is keeping it close." |
| 6 | "Nobody blinked yet. Not even {name}." |
| 7 | "{name} is holding steady." |
| 8 | "Matched. {name} knows what they are doing." |
| 9 | "{name} is right in the mix." |

Random index: `Random().nextInt(10)`, assigned at `openParty()` as `tiedSayingIndex`. All tied members at the same score share the same index.

---

### Self-Aware Variants (first and last only)

When the saying applies to the **current user's own row**, substitute an alternate version. These are positional mirrors of the standard sayings — same index maps to the self-aware variant.

**First place — self (10 sayings, same index as `firstPlaceSayingIndex`):**

| # | Saying |
|---|--------|
| 0 | "You are ahead. No spoilers." |
| 1 | "Slow down. Wait for them." |
| 2 | "They see you." |
| 3 | "Pause. Let them catch up." |
| 4 | "You are not here to pace yourself, are you." |
| 5 | "You came here to win." |
| 6 | "At this rate you will finish alone." |
| 7 | "Too fast. Even for you." |
| 8 | "You are a force of nature apparently." |
| 9 | "You blocked off the whole weekend for this." |

**Last place — self (10 sayings, same index as `lastPlaceSayingIndex`):**

| # | Saying |
|---|--------|
| 0 | "Did you fall asleep?" |
| 1 | "We are checking on you." |
| 2 | "You are still on episode one." |
| 3 | "Are you even watching?" |
| 4 | "No pressure. But maybe some pressure." |
| 5 | "You really committed to taking it slow." |
| 6 | "No rush. Really. No rush." |
| 7 | "You need to catch up." |
| 8 | "Taking your time, as usual." |
| 9 | "You are officially the weak link." |

The self-aware variants use second-person ("you") instead of third-person ("{name}"). No `{name}` substitution needed. Determined by comparing `member.userId == currentUserId` at render time.

---

## UI Placement

Saying renders as a small italic text line **beneath the progress bar** inside the member's row card.

- First place: `EColors.primary` at reduced opacity
- Last place: `EColors.textTertiary`
- Middle place: `EColors.textTertiary`

---

---

## Nudge Feature

### Overview

A single-tap button on any member's row that sends them a push notification prompting them to catch up. Rate-limited to once per 24 hours per sender per recipient per party. Not shown on your own row or on completed members.

### UI Placement

Small `TextButton` or icon button (`Icons.notifications_active`) at the trailing edge of the row — only visible when the member is not the current user and is not completed. Tapping immediately disables the button for the session and sends the notification.

### Rate Limiting

Client-side only (MVP). `WatchPartyController` stores:
```dart
final Map<String, DateTime> _lastNudgeSent = {};
// key: nudgedUserId
```
Button is shown only if `_lastNudgeSent[userId]` is null or more than 24 hours ago. Resets when the app is restarted (acceptable for MVP).

### Notification

```
category: 'watch_party_nudge'
title: '{partyName}'
body: random nudge saying (see below)
data: { 'party_id': partyId }
recipient: nudged member's userId
```

### Nudge Sayings (10, index 0–9)

Randomized per tap (not per session — fresh random each nudge so the recipient gets variety).

| # | Saying |
|---|--------|
| 0 | "The group is waiting on you." |
| 1 | "Time to press play." |
| 2 | "They need you to catch up." |
| 3 | "The watch party misses you." |
| 4 | "Consider this your formal notice to catch up." |
| 5 | "Someone from the group wants you to hurry up." |
| 6 | "You have been nudged." |
| 7 | "The group sent a search party." |
| 8 | "Your presence has been requested." |
| 9 | "Catch up. Please." |

### Files to Touch (Nudge)

| File | Change |
|------|--------|
| `watch_party_sayings.dart` | Add `nudgeSayings` list |
| `watch_party_controller.dart` | Add `nudgeMember(partyId, userId)` + `_lastNudgeSent` map + `canNudge(userId)` helper |
| `party_progress_row.dart` | Add nudge button to trailing; visible when `!isSelf && !member.isAllWatched && canNudge` |
| `app_notification.dart` | Add `watchPartyNudge` to `NotificationType` enum |

---

## Files to Touch

| File | Change |
|------|--------|
| `lib/features/social/utils/watch_party_sayings.dart` | New — six `List<String>` constants (first, last, middle, notStarted, completed, tied) + self-aware variants + `resolveSaying(template, name)` helper |
| `lib/features/social/controllers/watch_party_controller.dart` | Add `firstPlaceSayingIndex`, `lastPlaceSayingIndex`, `middleSayingIndex`, `notStartedSayingIndex`, `completedSayingIndex`, `tiedSayingIndex`; all assigned randomly in `openParty()` |
| `lib/features/social/widgets/party_progress_row.dart` | Add optional `saying`, `sayingColor`, `isSelf` params; render saying beneath progress bar; use second-person variant when `isSelf = true` |
| `lib/features/social/widgets/party_screen_helpers.dart` | Sort members by score; resolve saying for each position (not started check first, then completed, then tied, then first/middle/last); pass `isSelf` based on current user ID |
