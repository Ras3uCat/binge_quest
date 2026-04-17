# Bug: Apple Sign-In — Username Display Priority

## Status
TODO

## Priority
Medium — affects all Apple users who haven't set a real display name

## Overview
Apple's "Hide My Email" sign-in generates a relay email address (e.g., `abc123@privaterelay.appleid.com`) that surfaces as the user's display name in some parts of the app. 

`UserProfile` already has a `displayLabel` getter that prioritizes `username` over `displayName`. The relay email problem occurs in places that bypass `displayLabel` and read `user.email` or `auth.currentUser.email` directly, or in places where `displayName` itself was populated with the relay email at sign-in time.

## Existing Code (do not duplicate)
`UserProfile.displayLabel` at `lib/shared/models/user_profile.dart:27`:
```dart
String get displayLabel =>
    username != null ? '@$username' : (displayName ?? 'User');
```
This already handles username priority for anything using `UserProfile`. Do not create a new `resolveDisplayName()` utility — extend the existing getter instead.

Note: `displayLabel` prefixes usernames with `@` — verify this is appropriate in all display contexts (notifications, review bylines, leaderboard entries). Some contexts may want the username without `@`.

## Acceptance Criteria
- [ ] `UserProfile.displayLabel` detects and suppresses `@privaterelay.appleid.com` addresses as a fallback, returning `'Apple User'` instead.
- [ ] All UI locations that render a user's name use `displayLabel` (or a context-appropriate variant) — not raw `.email` or `.displayName`.
- [ ] Apple user with `username` set: username shown everywhere, relay email never visible.
- [ ] Apple user without `username`: shows `'Apple User'` (not the relay string).
- [ ] Non-Apple users: unaffected.

## Backend Changes
None — `username` already exists on the `users` table.

## Frontend Changes

### 1. Update `UserProfile.displayLabel`
```dart
String get displayLabel {
  if (username != null) return '@$username';
  if (displayName != null && !displayName!.contains('@privaterelay.appleid.com')) {
    return displayName!;
  }
  return 'Apple User';
}
```

### 2. Audit — find all direct `.email` / `.displayName` reads rendered as labels
Search for these patterns in `lib/`:
- `user.email` rendered in a Text widget
- `user.displayName` rendered directly (not via `displayLabel`)
- `currentUser?.email` shown in UI
- Any string that might show the relay email pattern

Replace with `.displayLabel` or a context-appropriate variant (without `@` prefix if needed).

### 3. Check sign-in flow
Confirm that when Apple sign-in completes, the relay email is not being written into `display_name` in the `users` table — if it is, that needs to be suppressed at the auth callback level too.

## QA Checklist
- [ ] Apple user with username: username shown in profile, friends list, reviews, leaderboard.
- [ ] Apple user without username: shows `'Apple User'` — not relay email string.
- [ ] Non-Apple user: no change in display behavior.
- [ ] Search `lib/` for any remaining `.email` or `.displayName` renders — none shown as user-facing labels.
