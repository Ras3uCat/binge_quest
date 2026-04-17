# Feature: BingeQuest Top 10 — Global / Friends Toggle

## Status
STUDIO — COMPLETE

## Priority
Low — engagement feature, no critical path dependency

## Overview
The BingeQuest Top 10 section currently shows a global leaderboard with two modes: Most Watched
and Top Rated. Add a **Friends** toggle that mirrors both modes, filtered to the current user's
friends only. Friends Most Watched = content on any friend's watchlist (regardless of status).
Friends Top Rated = reviews submitted by friends.

## Acceptance Criteria
- [ ] A "Friends" chip is added to the existing filter row alongside "Most Watched" and "Top Rated".
- [ ] Default mode remains **Most Watched** (global).
- [ ] Selecting "Friends" while "Most Watched" is active → friends most-watched list.
- [ ] Selecting "Friends" while "Top Rated" is active → friends top-rated list.
- [ ] Friends toggle is orthogonal to sort mode: both modes work in Global and Friends.
- [ ] If the user has no friends with activity, Friends mode shows an empty state message.
- [ ] Toggle persists for the session (resets to Global on app restart is acceptable).

## UI Layout
Four chip states in the filter row:

```
[ Most Watched ]  [ Top Rated ]  [ Friends ]
```

`Friends` chip acts as an overlay toggle — when active, it re-fetches using the
friends variant of whichever sort mode is currently selected.

## Backend Changes

Two new SECURITY DEFINER RPCs using `auth.uid()` internally (no user_id param).

### `get_friends_top10_by_users()`
Mirrors `get_top_10_by_users` — content on friends' watchlists, ranked by friend count.

```sql
CREATE OR REPLACE FUNCTION public.get_friends_top10_by_users()
  RETURNS TABLE (
    tmdb_id       integer,
    media_type    text,
    title         text,
    poster_path   text,
    user_count    bigint,
    streaming_providers jsonb
  )
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = 'public'
AS $$
  WITH friend_ids AS (
    SELECT addressee_id AS friend_id FROM friendships
      WHERE requester_id = auth.uid() AND status = 'accepted'
    UNION
    SELECT requester_id AS friend_id FROM friendships
      WHERE addressee_id = auth.uid() AND status = 'accepted'
  ),
  friend_watchlist_users AS (
    SELECT id AS watchlist_id, user_id FROM watchlists
      WHERE user_id IN (SELECT friend_id FROM friend_ids)
    UNION ALL
    SELECT watchlist_id, user_id FROM watchlist_members
      WHERE status = 'accepted'
      AND user_id IN (SELECT friend_id FROM friend_ids)
  )
  SELECT
    wi.tmdb_id,
    wi.media_type,
    cc.title,
    cc.poster_path,
    COUNT(DISTINCT fwu.user_id) AS user_count,
    cc.streaming_providers
  FROM watchlist_items wi
  JOIN friend_watchlist_users fwu ON wi.watchlist_id = fwu.watchlist_id
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
  GROUP BY wi.tmdb_id, wi.media_type, cc.title, cc.poster_path, cc.streaming_providers
  ORDER BY user_count DESC
  LIMIT 10;
$$;
```

### `get_friends_top10_by_rating()`
Mirrors `get_top_10_by_rating` — reviews from friends, ranked by average rating.
Note: `HAVING COUNT(*) >= 2` is dropped for friends mode (small friend groups would
always return empty).

```sql
CREATE OR REPLACE FUNCTION public.get_friends_top10_by_rating()
  RETURNS TABLE (
    tmdb_id          integer,
    media_type       text,
    title            text,
    poster_path      text,
    average_rating   numeric,
    review_count     bigint,
    streaming_providers jsonb
  )
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = 'public'
AS $$
  WITH friend_ids AS (
    SELECT addressee_id AS friend_id FROM friendships
      WHERE requester_id = auth.uid() AND status = 'accepted'
    UNION
    SELECT requester_id AS friend_id FROM friendships
      WHERE addressee_id = auth.uid() AND status = 'accepted'
  )
  SELECT
    r.tmdb_id,
    r.media_type,
    cc.title,
    cc.poster_path,
    ROUND(AVG(r.rating)::NUMERIC, 1) AS average_rating,
    COUNT(*) AS review_count,
    cc.streaming_providers
  FROM reviews r
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = r.tmdb_id AND cc.media_type = r.media_type
  WHERE r.user_id IN (SELECT friend_id FROM friend_ids)
  GROUP BY r.tmdb_id, r.media_type, cc.title, cc.poster_path, cc.streaming_providers
  ORDER BY average_rating DESC, review_count DESC
  LIMIT 10;
$$;
```

## Frontend Changes

`BingeQuestTop10Section` stays a `StatefulWidget` (no GetX migration needed).

Add `bool _isFriendsMode = false` to state alongside existing `_showMostWatched`.

Update `_loadData()`:
```dart
final items = _isFriendsMode
    ? (_showMostWatched
        ? await TopContentRepository.getFriendsTop10ByUsers()
        : await TopContentRepository.getFriendsTop10ByRating())
    : (_showMostWatched
        ? await TopContentRepository.getTop10ByUsers()
        : await TopContentRepository.getTop10ByRating());
```

Add two methods to `TopContentRepository`:
- `getFriendsTop10ByUsers()` → `rpc('get_friends_top10_by_users')` → `fromUserCountJson`
- `getFriendsTop10ByRating()` → `rpc('get_friends_top10_by_rating')` → `fromRatingJson`

Add a third `_FilterChip` labeled `'Friends'` to the chip row.

Empty state message for Friends mode:
> "None of your friends have added this type of content yet."

## QA Checklist
- [ ] "Friends" chip appears in filter row.
- [ ] Most Watched (Global): matches current behavior.
- [ ] Top Rated (Global): matches current behavior.
- [ ] Friends + Most Watched: shows content on friends' watchlists, ranked by friend count.
- [ ] Friends + Top Rated: shows content reviewed by friends, ranked by avg rating.
- [ ] Friends mode with zero friends activity: empty state shown.
- [ ] Toggling Friends off restores global list.
- [ ] No performance regression on global queries.
- [ ] User with no friends: Friends mode shows empty state (not an error).
