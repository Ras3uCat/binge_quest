# Feature: Profile Sharing via Text / Friend Invite Link

## Status
TODO

## Priority
Medium — lowers friction for friend acquisition

## Overview
Users should be able to share their profile with a link (via text, AirDrop, etc.). The recipient taps the link and is taken to the sender's profile page in the app, with an "Add Friend" prompt pre-surfaced. If the recipient does not have the app, the link falls back to a web page or the app store.

## Related
- Check `friend_invite_links.md` for any existing plan before implementing.

## User Stories
- As a user, I want to share my BingeQuest profile so my friends can easily find and add me.
- As a recipient, I want tapping a shared link to open the sender's profile directly.

## Acceptance Criteria
- [ ] A "Share Profile" option is accessible from the user's own profile screen.
- [ ] Tapping it opens the native share sheet with a link and message.
- [ ] The link format uses the user's `username` (e.g., `binge.quest/u/{username}`) or a token if username is not set.
- [ ] Recipients with the app installed are deep-linked to the sender's profile.
- [ ] Recipients without the app are directed to the App Store / Play Store (or a web fallback).
- [ ] On the sender's profile page, an "Add Friend" button is prominently shown to the recipient.

## Backend Changes
- Define a deep link scheme/URL pattern for user profiles (e.g., `binge.quest/u/{username}`).
- Ensure the profile lookup by username endpoint exists (likely already available via `users` table `username` column).
- No new table needed if using username-based URLs; add a token table if username is not guaranteed.

## Frontend Changes
- Add "Share Profile" button/action to the profile screen (own profile only).
- Configure deep link routing to handle `/u/{username}` → navigate to `UserProfileScreen(username: ...)`.
- On `UserProfileScreen` when viewed by a non-friend: show "Add Friend" prominently (not buried in a menu).
- Use `share_plus` to open the share sheet.

## Dependencies
- `share_plus` Flutter package.
- Deep link configuration (Firebase Dynamic Links or a custom scheme + App Links / Universal Links).
- `username` must be set for clean links; handle the no-username case (fallback to user ID or prompt to set username).

## QA Checklist
- [ ] Own profile: "Share Profile" button visible.
- [ ] Tapping it opens share sheet with a link containing the username.
- [ ] Recipient on iOS with app installed: link opens their profile.
- [ ] Recipient on Android with app installed: link opens their profile.
- [ ] Recipient without app: directed to appropriate store.
- [ ] "Add Friend" button visible on the shared profile for non-friends.
- [ ] User without username: link still works (uses ID or prompts to set username).
