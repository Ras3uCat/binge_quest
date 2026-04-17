# Bug: Content Cache — New Season Discovery Gap

## Status
TODO

## Priority
Medium — specific reported bugs are resolved; remaining work is systemic prevention

## Overview
The three originally reported issues (For All Mankind S5 missing, SNL new episodes not surfacing, Daredevil: Born Again missing descriptions) are **resolved as of 2026-04-03**:

- **For All Mankind S5**: all 10 episodes seeded with correct titles/air dates (March 26 – May 28, 2026). `content_cache.updated_at = 2026-04-03`.
- **SNL S51**: 20 episodes tracked through May 16, 2026.
- **Daredevil**: self-resolved (descriptions populated by TMDB).

The remaining work is **systemic prevention**: ensuring new seasons are discovered automatically without manual intervention or a user opening the show.

## Root Cause (Corrected)

### How the pipeline actually works
`get_tv_shows_for_episode_check` is smarter than originally described. Its `active_seasons` CTE dynamically selects the **most recent season with at least one episode air date in `[now - 90d, now + 14d]`** — it is not tied to a hardcoded season number. This means it correctly auto-advances to new seasons **as long as episodes for that season are already seeded in `content_cache_episodes`**.

### The real gap
**New seasons are invisible until episodes are seeded.** The pipeline has no mechanism to discover a brand-new season that has zero rows in `content_cache_episodes`:

1. `content_cache.number_of_seasons` is only updated when a user opens that show in-app. The nightly cron never re-fetches top-level show metadata.
2. If TMDB announces Season 6 of For All Mankind, `content_cache.number_of_seasons` will remain `5` and no new season rows will be inserted until a user opens the show detail screen.
3. Once a user does open it, the season is seeded and the nightly `check-new-episodes` cron picks it up — but there is no guarantee this happens before the premiere.

### Secondary gap
`content_cache.updated_at` is inconsistent across shows:
- For All Mankind: refreshed today (app-triggered)
- SNL: last refreshed 2026-03-03 (no user opened it recently)

Shows with low recent traffic can have stale `number_of_seasons` indefinitely.

## Remaining Work

### Fix 1 — Weekly show-level metadata refresh for Returning Series
Add a cron (or extend `cleanup-stale-content-cache`) that runs weekly and re-fetches top-level TMDB show data for all `content_cache` entries where `status = 'Returning Series'`:
- `GET /tv/{tmdb_id}` from TMDB
- If `tmdb.number_of_seasons > content_cache.number_of_seasons`:
  - Update `content_cache.number_of_seasons` and `updated_at`
  - For each new season number: insert placeholder rows into `content_cache_episodes` (episode_number = 0, or fetch the full season) so `active_seasons` CTE picks them up

Target: runs Sunday alongside `cleanup-stale-content-cache` (currently `0 4 * * 0`). Cap at 100 shows per run to stay within TMDB rate limits.

### Fix 2 — Reduce TTL for Returning Series
In the app-level cache fetch logic (wherever show data is written to `content_cache`), treat `Returning Series` shows as stale after 7 days instead of the default 30 days. This ensures active shows get their `number_of_seasons` refreshed more frequently via organic user traffic.

## Acceptance Criteria
- [ ] When TMDB increments `number_of_seasons` for a `Returning Series` show, `content_cache` reflects the new count within 7 days without any manual intervention.
- [ ] New season episodes are seeded into `content_cache_episodes` automatically, enabling `check-new-episodes` to detect them.
- [ ] `Returning Series` shows have `content_cache.updated_at` no older than 7 days.
- [ ] Ended/Canceled shows are not re-fetched by the weekly refresh.
- [ ] No regression: the nightly episode check continues to work for all currently-tracked seasons.

## Frontend Changes
None — data pipeline only.

## QA Checklist
- [ ] Simulate new season: manually set `content_cache.number_of_seasons = N-1` for a returning show, trigger the weekly refresh, confirm it resets to `N` and new season rows appear in `content_cache_episodes`.
- [ ] Confirm ended shows are skipped by the weekly refresh.
- [ ] Confirm `check-new-episodes` nightly cron picks up the newly seeded season within 24h.
