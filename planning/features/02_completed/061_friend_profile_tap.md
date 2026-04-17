# Feature: Tap Friend to View Profile

## Status
DONE

## Overview
From the friends list, tapping a friend's tile navigates to their profile via `UserProfileScreen`. The screen already exists and supports viewing any user's profile by `userId`.

## Scope
FLOW — up to 2 files depending on whether Requests/Blocked tabs also get the tap.

## Acceptance Criteria
- [ ] Tapping a friend tile in the Friends tab navigates to `UserProfileScreen(userId: friend.id)`
- [ ] Tile tap is null-safe: only navigate if `friendship.friend != null`
- [ ] Back navigation returns to the friends list
- [ ] Tapping tiles in Requests and Blocked tabs also navigates to that user's profile (consistent UX)

## Backend Changes
None.

## Frontend Changes
- `lib/features/social/screens/friend_list_screen.dart`
  - Add import for `UserProfileScreen`
  - Wrap `_FriendTile` Container with `InkWell`; `onTap`: `if (friend != null) Get.to(() => UserProfileScreen(userId: friend.id))`
- `lib/features/social/widgets/friend_tab_sections.dart` (if Requests/Blocked tabs render tappable user tiles)
  - Same pattern: add `InkWell` + `UserProfileScreen` navigation on any user tile widgets there

## Notes
- `UserProfileScreen` (`lib/features/profile/screens/user_profile_screen.dart`) uses tag-based `Get.put(tag: userId)` — safe for multiple concurrent instances and back/forward navigation.
- `UserProfileScreen` already handles own-profile detection and friend-add button display — no changes needed there.
- No new routes required; use `Get.to()` consistent with existing deep-link navigation pattern.

## QA Checklist
- [ ] Tap a confirmed friend → correct profile loads with their stats, archetype, badges
- [ ] Back button returns to friends list without state reset or scroll position loss
- [ ] Rapid back/forward navigation (push → back → push) doesn't cause controller tag collision or stale data
- [ ] Tap on a pending request user tile → profile loads (no friend-add button since request is pending)
- [ ] Tap on a blocked user tile → profile loads correctly
