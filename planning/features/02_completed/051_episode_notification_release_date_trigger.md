# Feature: Episode Notification — Release Date Trigger

## Status
COMPLETE

## Mode
STUDIO

## Priority
High — notifications arriving a day late are a poor experience

## Overview
New-episode push notifications should fire on the episode's `air_date`, not when a polling
cycle happens to detect a count change. The `check-new-episodes` edge function already uses
`air_date` for comparison, but the triggering logic is count-based (`airedCount > lastCount`)
rather than date-based. This feature tightens the trigger so notifications fire on the release
day itself.

The cron runs at 03:30 UTC, which is 10:30pm EST / 7:30pm PST — naturally landing in the
evening for US users. No per-user timezone logic is required.

## Current State (as of 2026-04-14)
- `check-new-episodes` edge function exists and runs nightly at **03:30 UTC** (migration 054)
- `air_date` is already upserted to `content_cache_episodes` from TMDB (date only, no time)
- Deduplication exists via `user_episode_notifications` (per-user, per-event)
- `notification_preferences.new_episodes` filter already in place
- `today` is computed as a **single UTC date string** and applied globally — this is acceptable

## Investigation Resolved
- TMDB provides `air_date` as **date only** (no time component)
- Edge function owner: `check-new-episodes`
- `air_date` stored in: `content_cache_episodes`

## What Needs to Change
The current trigger fires when `airedCount > lastCount` (episode count delta). This means:
- If the episode count was already correct from a prior run, no notification fires even if
  the episode just became available today.
- A new episode with `air_date = today` that was pre-cached won't trigger a notification
  unless the count increased.

The fix: add a secondary trigger path that fires a notification when an episode's
`air_date = today` and no notification has been sent yet for that user + episode.

## Acceptance Criteria
- [ ] When an episode's `air_date` matches today (UTC), a notification fires on that day.
- [ ] No duplicate notifications — `user_episode_notifications` is checked before sending.
- [ ] Existing count-delta path is preserved (does not regress).
- [ ] Notification arrives in the evening for US users (03:30 UTC cron — no change needed).

## Backend Changes
1. In `check-new-episodes`, after upserting episodes, scan for rows where `air_date = today`
   for each show.
2. For each such episode, check `user_episode_notifications` to see if a notification was
   already sent for that user + show/season/episode combination.
3. If not sent, invoke `send-notification` and insert a `user_episode_notifications` record.
4. Deduplication key: `(user_id, tmdb_id, season_number, episode_number)` — may require a
   schema update to `user_episode_notifications` if it only tracks by `event_id`.

## Migration Required
- **065_create_user_notified_episodes.sql** — new table `user_notified_episodes` with unique
  constraint on `(user_id, tmdb_id, season_number, episode_number)`. Keeps the existing
  `user_episode_notifications` (event/count-delta path) untouched.

## Frontend Changes
None — notification payload format unchanged.

## QA Checklist
- [ ] Episode with `air_date = today`: notification sent at next cron run.
- [ ] Episode with `air_date = yesterday` already notified: no duplicate.
- [ ] Episode with `air_date = tomorrow`: no premature notification.
- [ ] Running the cron twice in one day: only one notification sent per user per episode.
- [ ] Count-delta path still works for batch drops (multiple episodes at once).
