# Current Task: New Episode Notifications + Episode Cache Refresh

**Status**: IN PROGRESS
**Mode**: STUDIO
**Priority**: High (active bug — Paradise S2 aired 2026-02-23, stale cache + no notifications)
**Started**: 2026-02-24
**Specs**: `STUDIO_PLAN.md`, `planning/features/new_episode_notifications.md`

---

## Overview

Two tightly coupled bugs fixed together:

1. **Stale episode cache** — `content_cache_episodes` written once when a show is added; season placeholder names ("Episode 1") never refreshed when TMDB populates real data close to air date.
2. **Missing episode notifications** — `new_episode_events` + `user_episode_notifications` tables exist but nothing populates them. No Edge Function polls TMDB for newly aired episodes.

Fix: `check-new-episodes` Edge Function (nightly cron) that (a) re-upserts episode metadata from TMDB and (b) detects + notifies new aired episodes.

---

## Task Board

### Track A — Backend

| # | Task | Status | Owner |
|---|------|--------|-------|
| M1 | Migration 053: `get_tv_shows_for_episode_check` RPC + ensure `notification_preferences.new_episodes` column | **DONE** | Backend |
| E1 | Edge Function `check-new-episodes`: TMDB fetch, episode cache upsert, new-aired detection, insert `new_episode_events`, notify users via `send-notification`, insert `user_episode_notifications` | **DONE** | Backend |
| E2 | Register nightly pg_cron for `check-new-episodes` (same schedule as `check-streaming-changes`) | **DONE** | Backend |

### Track B — Frontend

| # | Task | Status | Owner |
|---|------|--------|-------|
| F1 | Add `new_episode` case to notification deep-link router (route to show detail/progress screen) | **DONE** | Flutter |
| F2 | (Optional) Client-side stale refresh: if `episode_name` matches `/^Episode \d+$/` and `updated_at > 7d`, re-fetch from TMDB on show open | **TODO** | Flutter |

---

## Execution Order

```
M1 → E1 → E2   (sequential: RPC must exist before Edge Function is deployed)
F1              (independent, can run in parallel with backend track)
F2              (optional, after F1)
```

---

## Key Decisions

- **Dedup guard:** `new_episode_events` is only inserted when `airedCount > lastDetectedCount`. Second cron run produces no duplicate events.
- **Notification copy:** Premiere with multi-episode drop → "Season N just dropped X episodes."; single weekly drop → "Season N Episode X is now available."
- **Cache refresh:** Every TMDB season fetch is upserted with `ignoreDuplicates: false` — real names/overviews always overwrite stale placeholders.
- **Show selection:** `get_tv_shows_for_episode_check` joins `watchlist_items` → `content_cache_episodes` to find seasons with air_date in [-90d, +14d] window; ordered by `watchlist_user_count DESC`; cap 50.
- **Rate limit:** 250ms delay between TMDB calls (same as existing edge functions).
- **Auth pattern:** `verify_jwt: false` + in-function token check (service_role key OR user JWT) — same pattern as `check-streaming-changes`.
- **Opt-out:** Respects `notification_preferences.new_episodes = false`.

---

## Previous Tasks

- User Archetypes — **Complete**
- Watch Party Sync — **Complete**
- Advanced Stats Dashboard v1.1 Bug Fixes & Backfill Integrity — **Complete**
- Advanced Stats Dashboard v1.0 — **Complete**
- Pre-Launch Hardening (Tracks A, B, C) — **Complete**
- Standardize Dialog Boxes (EConfirmDialog) — **Complete**
- Search + Provider Filter Integration — **Complete**
- Friends Watching Content Indicator — **Complete**
- Mood Guide — **Complete**
- Social Features Suite (Friend System, Watchlist Co-Curators) — **In Progress** (Shareable Playlists remaining)
- Follow Talent (Actors & Directors) — **Complete**
- Streaming Availability Alerts — **Complete**
- Push Notifications Infrastructure — **Complete**
- Move Item Between Watchlists — **Complete**
- Release & Air Dates Display — **Complete**
- Partial Episode Progress Display Fix — **Complete**
- External Sharing — **Complete**
- Dashboard Performance Optimization — **Complete**
- Profile Stats Performance & Minutes Watched Accuracy — **Complete**
- Queue Health Watchlist Switch Bug — **Complete**
- Badge Placement Consistency — **Complete**
