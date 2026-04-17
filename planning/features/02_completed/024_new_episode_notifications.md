# Feature: New Episode Notifications + Episode Cache Refresh

## Status
TODO

## Priority
High — active user-facing bug (Paradise S2 already aired)

## Overview
Two tightly coupled problems solved together:

1. **Stale episode cache** — `content_cache_episodes` is written once when a user first adds a show. Placeholder names ("Episode 1") set months before a season airs are never refreshed. TMDB fills in real names and overviews close to (or after) the air date.

2. **Missing episode notifications** — The `new_episode_events` + `user_episode_notifications` tables exist but nothing populates them. No Edge Function polls TMDB for newly aired episodes or sends "new episode" push notifications.

Both are fixed by a single `check-new-episodes` Edge Function running on a nightly cron, mirroring the pattern of `check-streaming-changes`.

---

## Related
- Extends existing `push_notifications.md` infrastructure
- Uses existing `new_episode_events` + `user_episode_notifications` tables (migration 022)
- Uses existing `content_cache_episodes` table (migration 013)
- Calls existing `send-notification` Edge Function

---

## User Stories
- As a user, I want to see real episode names and descriptions (not "Episode 1") once they are available on TMDB
- As a user, I want a push notification when a new season of a show on my watchlist premieres
- As a user, I want a push notification when a weekly episode drops for a show I'm watching
- As a user, I only want one notification per episode batch, not one per episode when a season drops all at once

---

## Acceptance Criteria
- [ ] Episode names and overviews refresh nightly for shows with recent or upcoming air dates
- [ ] Push notification sent when first episode(s) of a new season become available
- [ ] Push notification sent for subsequent weekly episode drops
- [ ] No duplicate notifications for the same episode batch
- [ ] Notification body describes whether it's a premiere or a single episode drop
- [ ] `new_episode_events` row inserted for each detected batch (dedup guard)
- [ ] `user_episode_notifications` row inserted per user per event
- [ ] Respects user notification preferences (`notification_preferences.new_episodes` category)

---

## Data Model

### Existing tables (no changes needed)

**`new_episode_events`** — one row per detected batch (tmdb_id + season_number + detected_at)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| tmdb_id | INTEGER | TV show TMDB ID |
| season_number | INTEGER | Season with new episodes |
| episode_count | INTEGER | Total aired count at time of detection |
| detected_at | TIMESTAMPTZ | When the run discovered this |

**`user_episode_notifications`** — per-user tracking
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK users |
| event_id | UUID | FK new_episode_events |
| notified_at | TIMESTAMPTZ | NULL = pending |
| read_at | TIMESTAMPTZ | NULL = unread |
| created_at | TIMESTAMPTZ | — |

**`notification_preferences`** — already has per-category toggles; add `new_episodes` category.

### New: Migration 053 — RPC helper

```sql
-- Returns TV shows actively in watchlists that have a season airing
-- within a relevant window (past 90 days or next 14 days).
-- Includes last detected aired_episode_count per season for dedup.
CREATE OR REPLACE FUNCTION get_tv_shows_for_episode_check(limit_count INT DEFAULT 50)
RETURNS TABLE (
  tmdb_id         INTEGER,
  title           TEXT,
  poster_path     TEXT,
  season_number   INTEGER,   -- season to check
  watchlist_user_count BIGINT,
  last_detected_count INTEGER  -- episode_count from most recent new_episode_events row (NULL if none)
) ...
```

The function joins:
- `watchlist_items` → `content_cache` (media_type = 'tv')
- `content_cache_episodes` grouped by (tmdb_id, season_number) to find the season whose episodes straddle today's date (air_date window: 90 days ago → 14 days ahead)
- `new_episode_events` (LEFT JOIN, most recent row per tmdb_id + season_number) for `last_detected_count`

Returns at most `limit_count` rows ordered by `watchlist_user_count DESC` (prioritize popular shows).

---

## Backend Changes

### Migration 053 — RPC + notification_preferences category

1. Add `get_tv_shows_for_episode_check(limit_count INT)` SECURITY DEFINER function (described above).
2. Ensure `notification_preferences` has a `new_episodes` boolean column (add if missing).

### Edge Function: `check-new-episodes`

**Trigger:** Nightly cron (same pg_cron schedule as `check-streaming-changes`). Also accepts HTTP POST from service_role for ad-hoc runs.

**Auth:** `verify_jwt: false` + in-function `getUser(token)` check (same pattern as other functions). Accepts both user JWT and service_role key.

**Rate limiting:** 250ms delay between TMDB API calls. Cap: 50 shows per run (via RPC `limit_count`).

**Algorithm:**

```
1. Call RPC get_tv_shows_for_episode_check(50)
   → list of {tmdb_id, title, season_number, watchlist_user_count, last_detected_count}

2. For each show:
   a. sleep(250ms)  // rate limit
   b. Fetch TMDB: GET /tv/{tmdb_id}/season/{season_number}
      → list of episodes with {name, overview, air_date, still_path, vote_average, runtime}

   c. UPSERT into content_cache_episodes:
      - For every episode in the TMDB response, upsert using
        onConflict: 'tmdb_id,season_number,episode_number'
        with DO UPDATE SET episode_name, episode_overview, still_path,
                           vote_average, runtime_minutes, updated_at
      → resolves stale "Episode N" placeholder names

   d. Count aired episodes (air_date <= TODAY)
      current_aired_count = episodes.filter(e => e.air_date <= today).length

   e. If current_aired_count == 0: skip (season hasn't started)
      If current_aired_count == last_detected_count: skip (nothing new)

   f. New episodes detected → determine notification copy:
      new_count = current_aired_count - (last_detected_count ?? 0)
      is_premiere = last_detected_count is NULL or last_detected_count == 0

      title_text:
        is_premiere → "🎬 {title} is back!"
        else        → "New episode of {title}"

      body_text:
        is_premiere && new_count > 1 → "Season {N} just dropped {new_count} episodes."
        is_premiere && new_count == 1 → "Season {N} Episode 1 is now available."
        !is_premiere → "Season {N} Episode {ep_number} is now available."

   g. INSERT into new_episode_events:
      {tmdb_id, season_number, episode_count: current_aired_count}

   h. Find users to notify via direct query:
      SELECT DISTINCT wi.user_id
      FROM watchlist_items wi
      JOIN watchlists w ON w.id = wi.watchlist_id
      JOIN notification_preferences np ON np.user_id = wi.user_id
      WHERE wi.tmdb_id = {tmdb_id}
        AND wi.media_type = 'tv'
        AND w.user_id = wi.user_id
        AND np.new_episodes = true

   i. For each user:
      - Call send-notification with category='new_episodes',
        data={type:'new_episode', tmdb_id, season_number, episode_count}
      - INSERT user_episode_notifications {user_id, event_id, notified_at: now()}
```

**Response shape** (same pattern as check-streaming-changes):
```json
{
  "success": true,
  "shows_checked": 42,
  "episodes_refreshed": 180,
  "new_events_created": 3,
  "notifications_sent": 17
}
```

---

## Frontend Changes

### Minimal — episode display refresh hint

When the episode list for a TV show is displayed and `episode_name` matches the pattern `/^Episode \d+$/`, the UI already shows the name from cache. No new code needed — the backend refresh will fix the data in `content_cache_episodes` and the next time the user opens the show detail, they'll see correct names (read from cache via existing `getSeasonEpisodes()`).

**Optional enhancement (non-blocking):** Add a `force` flag to the watchlist detail controller's episode load: if `updated_at` is older than 7 days AND air_date is in the past, call TMDB directly and re-upsert. This gives an immediate fix on first open without waiting for the nightly cron. Mark as optional — the backend cron alone solves the core bug.

### Notification deep link

Notification `data.type = 'new_episode'` should deep-link to the show's detail/progress screen (same as existing deep-link handling for `streaming_alert`). Verify the Flutter notification router handles this type or add a case.

---

## Detection Logic Summary

```
For each active TV show in watchlists:

  aired_now = episodes where air_date <= today
  last_known = most recent new_episode_events.episode_count for this season

  if aired_now.count > last_known:
    → refresh episode cache (upsert names/overviews)
    → insert new_episode_events
    → notify users
```

The `last_detected_count` guard prevents re-notifying on every cron run.

---

## Task Breakdown (for current_task.md)

| # | Task | Owner |
|---|------|-------|
| M1 | Migration 053: `get_tv_shows_for_episode_check` RPC + `new_episodes` column on `notification_preferences` | Backend |
| E1 | Edge Function `check-new-episodes`: fetch, upsert cache, detect new aired, insert events, notify | Backend |
| E2 | Register nightly pg_cron schedule for `check-new-episodes` (same as other cron functions) | Backend |
| F1 | Flutter: add `new_episode` case to notification deep-link router | Flutter |
| F2 | Flutter (optional): client-side stale-cache refresh — if `episode_name` matches `Episode \d+` and `updated_at > 7d`, re-fetch from TMDB on show open | Flutter |

---

## Dependencies
- Migration 022 (`new_episode_events`, `user_episode_notifications`) — already applied
- Migration 013 (`content_cache_episodes`) — already applied
- `send-notification` Edge Function v10 — already deployed
- TMDB_API_KEY secret — already configured

---

## QA Checklist
- [ ] Run edge function manually; verify `content_cache_episodes` updated_at changes for stale rows
- [ ] Verify "Episode 1" placeholder replaced with real name for Paradise S2 after manual run
- [ ] Verify `new_episode_events` row inserted for Paradise S2 season 2
- [ ] Verify push notification received on device for test user
- [ ] Run function a second time; verify no duplicate `new_episode_events` row and no duplicate notification
- [ ] Weekly episode scenario: manually insert a future episode into cache with air_date = today; verify detection
- [ ] User with `new_episodes = false` in `notification_preferences` does NOT receive notification
- [ ] Verify response JSON matches expected shape
