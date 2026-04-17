# Feature: Friends Watching Content Indicator

## Status
Planned

## Overview
Show which friends are also watching the same content on detail pages. Includes a privacy toggle so users can opt out of being visible to friends.

## Related
- Completes the missing acceptance criterion from `friend_system.md`
- Depends on existing friend system (friendships, user_blocks, FriendController)

## User Stories
- As a user, I want to see which friends are watching the same movie/show so I can discuss it
- As a user, I want to control whether friends can see what I'm watching

## Acceptance Criteria
- [ ] Content detail pages show friends who are also watching the same content
- [ ] Overlapping avatar stack (max 3) with descriptive label
- [ ] Indicator appears on both ContentDetailSheet (search) and ItemDetailScreen (watchlist)
- [ ] Privacy toggle in Settings: "Show My Activity to Friends"
- [ ] Privacy enforced server-side — opted-out users never returned regardless of client
- [ ] Graceful empty state when no friends are watching or user has no friends

## Data Model Changes

### `users` table (existing)
Add column:
```sql
ALTER TABLE public.users
  ADD COLUMN share_watching_activity BOOLEAN NOT NULL DEFAULT true;
```

### New RPC: `get_friends_watching_content`
```sql
CREATE OR REPLACE FUNCTION public.get_friends_watching_content(
  p_tmdb_id INTEGER,
  p_media_type TEXT,
  p_friend_ids UUID[]
)
RETURNS TABLE (user_id UUID, display_name TEXT, username TEXT, avatar_url TEXT)
AS $$
  SELECT DISTINCT u.id, u.display_name, u.username, u.avatar_url
  FROM watchlist_items wi
  JOIN watchlists w ON wi.watchlist_id = w.id
  JOIN users u ON w.user_id = u.id
  WHERE wi.tmdb_id = p_tmdb_id
    AND wi.media_type = p_media_type
    AND w.user_id = ANY(p_friend_ids)
    AND u.share_watching_activity = true
$$ LANGUAGE SQL STABLE SET search_path = public;
```

Design notes:
- Caller passes `p_friend_ids` from `FriendController.friendIds` — RPC doesn't re-derive friendships
- Privacy filter (`share_watching_activity = true`) is server-side, not bypassable by client
- No new RLS needed — existing `users` policies cover SELECT (public) and UPDATE (own row)

## Backend Changes
- Migration `035_friends_watching.sql`: privacy column + RPC function
- Run security advisors after migration

## Frontend Changes

### New files
| File | Description | ~Lines |
|------|-------------|--------|
| `lib/shared/models/friend_watching.dart` | Model with `userId`, `displayName`, `username`, `avatarUrl`, `displayLabel` getter, `fromJson` | 25 |
| `lib/shared/widgets/friends_watching_row.dart` | Overlapping avatar stack (max 3) + label. Returns `SizedBox.shrink()` when empty. Reused by both detail pages | 80 |

### Modified files
| File | Change | ~Lines added |
|------|--------|-------------|
| `WatchlistRepository` | Add `getFriendsWatching()` static method calling RPC | 20 |
| `FriendRepository` | Add `getShareWatchingActivity()` and `setShareWatchingActivity(bool)` | 20 |
| `FriendController` | Add `shareWatchingActivity` observable, load in `_loadInitialData`, `toggleShareWatchingActivity(bool)` with optimistic update | 15 |
| `ContentDetailSheet` | Add `_friendsWatching` state, `_loadFriendsWatching()` in `initState` (uses `setState`, no `Obx`), render `FriendsWatchingRow` below user count | 20 |
| `ItemDetailScreen` | Add `_buildFriendsWatchingRow()` via `FutureBuilder` with `ctrl.refresh()`, place below `_buildUserCountRow()` | 20 |
| `SettingsScreen` | Add `_buildPrivacySection()` with "Show My Activity to Friends" switch tile, placed before "Data" section | 20 |

### Widget behavior
- **Label variants:**
  - 1 friend: "Alex is also watching"
  - 2 friends: "Alex & Jordan are watching"
  - 3+ friends: "Alex & 2 more friends watching"
- **Avatar stack:** Overlapping circles, 20px diameter, 12px overlap offset

### Key patterns to follow
- `ContentDetailSheet` uses `setState` (not `Obx`) — safe in bottom sheets
- `ItemDetailScreen` uses `FutureBuilder` — matches existing `_buildUserCountRow()` pattern
- `FriendController` uses `Get.lazyPut(fenix: true)` — must `await ctrl.refresh()` before reading outside Friends tab
- Guard with `Get.isRegistered<FriendController>()` — graceful degradation if controller unavailable
- Settings toggle uses `_buildSwitchTile` + `_buildSection` existing helpers

## Implementation Order

| # | Scope | Task |
|---|-------|------|
| 1 | Backend | Apply migration (column + RPC) |
| 2 | Backend | Run security advisors |
| 3 | Frontend | Create `FriendWatching` model |
| 4 | Frontend | Create `FriendsWatchingRow` widget |
| 5 | Frontend | Add `getFriendsWatching` to `WatchlistRepository` |
| 6 | Frontend | Add privacy methods to `FriendRepository` |
| 7 | Frontend | Add `shareWatchingActivity` to `FriendController` |
| 8 | Frontend | Integrate into `ContentDetailSheet` |
| 9 | Frontend | Integrate into `ItemDetailScreen` |
| 10 | Frontend | Add Privacy section to `SettingsScreen` |

Steps 3-7 can be parallelized. Steps 8-10 depend on 3-7.

## QA Checklist
- [ ] Open content detail from search — friends watching indicator appears
- [ ] Open content detail from watchlist — friends watching indicator appears
- [ ] User with no friends sees no indicator (not an error state)
- [ ] Toggle privacy off in Settings — user no longer appears in friends' indicators
- [ ] Toggle privacy on — user reappears
- [ ] Privacy is server-enforced (test by querying RPC directly with opted-out user in friend list)
- [ ] Performance: indicator loads without blocking page render
