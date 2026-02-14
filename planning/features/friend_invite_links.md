# Feature: Friend Invite Links

## Status
TODO

## Overview
Allow users to share a link (e.g. `https://bingequest.app/add/username`) that opens the app to a friend request confirmation screen, or redirects to the app store if not installed. Builds on top of the existing username-based friend system.

## User Flow
1. User taps "Share my profile" (profile screen or friend list)
2. System generates `https://bingequest.app/add/{username}` and opens native share sheet
3. Recipient taps the link:
   - **App installed**: Universal link opens app → routes to Add Friend confirmation screen showing the sender's profile with Send Request / Cancel
   - **App not installed**: Web fallback page with app store redirect (smart banner or direct link)

## Acceptance Criteria
- [ ] "Share my profile" button on profile screen generates and shares a link
- [ ] Deep link `https://bingequest.app/add/{username}` opens app to Add Friend screen
- [ ] Add Friend screen shows user profile with Send Request / Cancel actions
- [ ] Graceful handling: user not found, self-link, already friends, blocked, pending request
- [ ] Fallback web page redirects to App Store / Play Store when app not installed
- [ ] Works on both iOS and Android

## Why Links Over Alternatives
- **QR codes** require being physically next to someone — users will mostly share the app with remote friends via text/social
- **Contacts sync** has heavy privacy implications (permission prompts, app store scrutiny, privacy policy updates) and only matches if the friend's Google login email is saved in the sender's phone contacts — overkill for v1
- **Links are the primary friend discovery method** alongside username search — someone discovers the app, tells a friend over text, shares a link in the same conversation

## Prerequisites (one-time setup)
- **Domain**: Need a domain (e.g. `bingequest.app`) or use Firebase Hosting (free, already have Firebase for FCM)
- **Firebase Hosting setup**: Deploy 2-3 static files — the verification files and a fallback redirect page
- This is the only blocker for this feature — once hosting is set up, the Flutter implementation is straightforward

## Backend Changes
- None required — uses existing `users` table username lookup and `friendships` table
- Web hosting for fallback page + `.well-known/assetlinks.json` (Android) + `apple-app-site-association` (iOS)

## Frontend Changes

### Dependencies
- `app_links` package for handling incoming universal/deep links

### New Files
- `lib/core/services/deep_link_service.dart` — Listens for incoming links, parses routes, navigates
- `lib/features/social/screens/add_friend_screen.dart` — Confirmation screen shown when opening an invite link (profile card + Send Request / Cancel)

### Modified Files
- `lib/main.dart` — Initialize `DeepLinkService` on app start
- `lib/features/profile/screens/profile_screen.dart` — Add "Share my profile" button
- `lib/features/social/screens/friend_list_screen.dart` — Add share/invite action in header

### Web Assets (hosting)
- `web/add/index.html` — Lightweight fallback page with smart app banner and store redirect
- `web/.well-known/assetlinks.json` — Android App Links verification
- `web/.well-known/apple-app-site-association` — iOS Universal Links verification

## Deep Link Routing

| Path | Action |
|------|--------|
| `/add/{username}` | Look up user → show Add Friend confirmation screen |

## Edge Cases
- **Username not found**: Show "User not found" message with option to search manually
- **Self-link**: Show "This is your own profile" message
- **Already friends**: Show "You're already friends with @username"
- **Pending request exists**: Show current request status with appropriate action (cancel / accept)
- **Blocked user**: Show generic "User not found" (don't reveal block)
- **Not logged in**: Store deep link intent, redirect to login, then resume after auth

## QA Checklist
- [ ] Share link from profile screen, verify correct URL format
- [ ] Open link with app installed — confirm navigation to Add Friend screen
- [ ] Open link with app not installed — confirm redirect to app store
- [ ] Send friend request via link, verify it appears in recipient's pending requests
- [ ] Test all edge cases (not found, self, already friends, blocked, pending)
- [ ] Test cold start deep link (app not running) vs warm start (app backgrounded)
- [ ] Test on both iOS and Android
