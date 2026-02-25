# New Episode Notifications + Episode Cache Refresh

**Status:** IN PROGRESS
**Mode:** STUDIO
**Priority:** High — active bug (Paradise S2 aired 2026-02-23)
**Started:** 2026-02-24
**Specs:** `planning/features/new_episode_notifications.md`

---

## Problem Description

Two bugs, one fix:

1. `content_cache_episodes` is written once when a user adds a show. TMDB uses "Episode 1 / Episode 2" placeholder names until close to air date. Nothing ever goes back to refresh them.
2. `new_episode_events` + `user_episode_notifications` tables exist but are empty — no Edge Function populates them or fires push notifications when episodes air.

The `check-new-episodes` Edge Function runs nightly on cron, mirrors the `check-streaming-changes` pattern, and solves both.

---

## Architecture

**Data flow:**
```
pg_cron → check-new-episodes Edge Function
  → RPC: get_tv_shows_for_episode_check(50)
  → For each show: TMDB GET /tv/{id}/season/{n}
  → Upsert content_cache_episodes (real names/overviews replace placeholders)
  → Count aired episodes; compare to last new_episode_events.episode_count
  → If new: INSERT new_episode_events
  → Query watchlist_items for affected users (filter by notification_preferences.new_episodes)
  → Call send-notification per user
  → INSERT user_episode_notifications per user
```

**Dedup guard:** `new_episode_events.episode_count` tracks how many episodes were aired at detection time. A show is only re-processed when `current_aired_count > last_detected_count`. Second nightly run = no-op.

---

## Track A: Backend

### M1 — Migration 053: `create_episode_check_rpc`

```sql
-- Migration: 053_create_episode_check_rpc.sql
-- Feature: New Episode Notifications + Episode Cache Refresh
-- Created: 2026-02-24

-- Ensure notification_preferences has new_episodes column
ALTER TABLE public.notification_preferences
  ADD COLUMN IF NOT EXISTS new_episodes BOOLEAN NOT NULL DEFAULT true;

-- ============================================================================
-- RPC: get_tv_shows_for_episode_check
-- Returns TV shows in active watchlists with a season airing within the
-- relevant window (90 days ago → 14 days ahead).
-- Includes last_detected_count from new_episode_events for dedup.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_tv_shows_for_episode_check(
  limit_count INT DEFAULT 50
)
RETURNS TABLE (
  tmdb_id              INTEGER,
  title                TEXT,
  poster_path          TEXT,
  season_number        INTEGER,
  watchlist_user_count BIGINT,
  last_detected_count  INTEGER
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH active_shows AS (
    -- TV shows in any user's watchlist
    SELECT wi.tmdb_id, COUNT(DISTINCT w.user_id) AS user_count
    FROM watchlist_items wi
    JOIN watchlists w ON w.id = wi.watchlist_id
    WHERE wi.media_type = 'tv'
    GROUP BY wi.tmdb_id
  ),
  show_info AS (
    SELECT cc.tmdb_id, cc.title, cc.poster_path
    FROM content_cache cc
    WHERE cc.media_type = 'tv'
  ),
  active_seasons AS (
    -- Most recent season with episodes in the detection window
    SELECT DISTINCT ON (cce.tmdb_id)
      cce.tmdb_id,
      cce.season_number
    FROM content_cache_episodes cce
    WHERE cce.season_number > 0  -- exclude specials
      AND cce.air_date BETWEEN (NOW() - INTERVAL '90 days') AND (NOW() + INTERVAL '14 days')
    ORDER BY cce.tmdb_id, cce.season_number DESC
  ),
  last_detections AS (
    -- Most recent detection per show+season (for dedup guard)
    SELECT DISTINCT ON (nee.tmdb_id, nee.season_number)
      nee.tmdb_id,
      nee.season_number,
      nee.episode_count
    FROM new_episode_events nee
    ORDER BY nee.tmdb_id, nee.season_number, nee.detected_at DESC
  )
  SELECT
    si.tmdb_id,
    si.title,
    si.poster_path,
    ase.season_number,
    a.user_count              AS watchlist_user_count,
    ld.episode_count          AS last_detected_count
  FROM active_shows a
  JOIN show_info si      ON si.tmdb_id = a.tmdb_id
  JOIN active_seasons ase ON ase.tmdb_id = a.tmdb_id
  LEFT JOIN last_detections ld
    ON ld.tmdb_id = a.tmdb_id AND ld.season_number = ase.season_number
  ORDER BY a.user_count DESC
  LIMIT limit_count;
$$;
```

---

### E1 — Edge Function: `check-new-episodes`

`verify_jwt: false` — in-function token validation accepts service_role key OR user JWT (same pattern as `check-streaming-changes`).

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p/w500';
const RATE_LIMIT_DELAY = 250;

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

interface ShowToCheck {
  tmdb_id: number;
  title: string;
  poster_path: string | null;
  season_number: number;
  watchlist_user_count: number;
  last_detected_count: number | null;
}

interface TmdbEpisode {
  episode_number: number;
  name: string;
  overview: string;
  air_date: string | null;
  still_path: string | null;
  vote_average: number;
  runtime: number | null;
}

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  // Auth: accept service_role key OR valid user JWT
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 });
  }
  const token = authHeader.replace('Bearer ', '');
  if (token !== Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) {
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 401 });
    }
  }

  const tmdbApiKey = Deno.env.get('TMDB_API_KEY');
  if (!tmdbApiKey) {
    return new Response(JSON.stringify({ error: 'TMDB_API_KEY not configured' }), { status: 500 });
  }

  // 1. Get shows to check
  const { data: shows, error: rpcError } = await supabase
    .rpc('get_tv_shows_for_episode_check', { limit_count: 50 });

  if (rpcError) {
    console.error('RPC error:', rpcError);
    return new Response(JSON.stringify({ error: 'Failed to get shows' }), { status: 500 });
  }

  if (!shows || shows.length === 0) {
    return new Response(JSON.stringify({ message: 'No shows to check', checked: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  console.log(`Checking ${shows.length} shows for new episodes`);

  let episodesRefreshed = 0;
  let eventsCreated = 0;
  let notificationsSent = 0;
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

  for (const show of shows as ShowToCheck[]) {
    try {
      await sleep(RATE_LIMIT_DELAY);

      // 2. Fetch season data from TMDB
      const url = `${TMDB_BASE}/tv/${show.tmdb_id}/season/${show.season_number}?api_key=${tmdbApiKey}`;
      const resp = await fetch(url);
      if (!resp.ok) {
        console.warn(`TMDB ${resp.status} for ${show.title} S${show.season_number}`);
        continue;
      }

      const seasonData = await resp.json();
      const episodes: TmdbEpisode[] = seasonData.episodes ?? [];
      if (episodes.length === 0) continue;

      // 3. Upsert episode metadata — replaces stale "Episode N" placeholders
      const upsertRows = episodes.map(ep => ({
        tmdb_id: show.tmdb_id,
        season_number: show.season_number,
        episode_number: ep.episode_number,
        episode_name: ep.name || `Episode ${ep.episode_number}`,
        episode_overview: ep.overview || '',
        air_date: ep.air_date || null,
        still_path: ep.still_path || null,
        vote_average: ep.vote_average || null,
        runtime_minutes: ep.runtime || 0,
        updated_at: new Date().toISOString(),
      }));

      const { error: upsertError } = await supabase
        .from('content_cache_episodes')
        .upsert(upsertRows, {
          onConflict: 'tmdb_id,season_number,episode_number',
          ignoreDuplicates: false,
        });

      if (upsertError) {
        console.error(`Episode upsert error for ${show.title}:`, upsertError);
      } else {
        episodesRefreshed += upsertRows.length;
      }

      // 4. Count episodes that have aired (air_date <= today)
      const airedEpisodes = episodes.filter(ep => ep.air_date && ep.air_date <= today);
      const airedCount = airedEpisodes.length;
      if (airedCount === 0) continue;

      const lastCount = show.last_detected_count ?? 0;
      if (airedCount <= lastCount) continue; // nothing new since last detection

      // 5. Build notification copy
      const newCount = airedCount - lastCount;
      const isPremiere = lastCount === 0;
      const latestEp = airedEpisodes.sort((a, b) => b.episode_number - a.episode_number)[0];

      let notifTitle: string;
      let notifBody: string;
      if (isPremiere && newCount > 1) {
        notifTitle = `${show.title} is back!`;
        notifBody = `Season ${show.season_number} just dropped ${newCount} episodes.`;
      } else if (isPremiere) {
        notifTitle = `${show.title} is back!`;
        notifBody = `Season ${show.season_number} Episode 1 is now available.`;
      } else {
        notifTitle = `New episode of ${show.title}`;
        notifBody = `Season ${show.season_number} Episode ${latestEp.episode_number} is now available.`;
      }

      // 6. Insert new_episode_events
      const { data: eventRow, error: eventError } = await supabase
        .from('new_episode_events')
        .insert({
          tmdb_id: show.tmdb_id,
          season_number: show.season_number,
          episode_count: airedCount,
        })
        .select('id')
        .single();

      if (eventError || !eventRow) {
        console.error(`Event insert error for ${show.title}:`, eventError);
        continue;
      }
      eventsCreated++;

      // 7. Find users with this show in any watchlist
      const { data: watchlistRows, error: wlError } = await supabase
        .from('watchlist_items')
        .select('watchlists!inner(user_id)')
        .eq('tmdb_id', show.tmdb_id)
        .eq('media_type', 'tv');

      if (wlError || !watchlistRows) continue;

      const allUserIds = [
        ...new Set(watchlistRows.map((r: any) => r.watchlists?.user_id).filter(Boolean))
      ] as string[];

      if (allUserIds.length === 0) continue;

      // 8. Filter to users with new_episodes notifications enabled
      const { data: prefRows } = await supabase
        .from('notification_preferences')
        .select('user_id')
        .in('user_id', allUserIds)
        .eq('new_episodes', true);

      const notifiableIds = (prefRows ?? []).map((r: any) => r.user_id) as string[];

      // 9. Notify each user
      for (const userId of notifiableIds) {
        try {
          const { error: fnError } = await supabase.functions.invoke('send-notification', {
            body: {
              user_id: userId,
              category: 'new_episodes',
              title: notifTitle,
              body: notifBody,
              ...(show.poster_path
                ? { image_url: `${TMDB_IMAGE_BASE}${show.poster_path}` }
                : {}),
              data: {
                type: 'new_episode',
                tmdb_id: String(show.tmdb_id),
                season_number: String(show.season_number),
                episode_count: String(airedCount),
              },
            },
          });

          if (fnError) {
            console.error(`Notification error for user ${userId}:`, fnError);
          } else {
            notificationsSent++;
            await supabase.from('user_episode_notifications').insert({
              user_id: userId,
              event_id: eventRow.id,
              notified_at: new Date().toISOString(),
            });
          }
        } catch (notifErr) {
          console.error('Notification send error:', notifErr);
        }
      }

      console.log(`${show.title} S${show.season_number}: ${airedCount} aired, ${notifiableIds.length} users notified`);

    } catch (showErr) {
      console.error(`Error processing ${show.title}:`, showErr);
    }
  }

  return new Response(JSON.stringify({
    success: true,
    shows_checked: shows.length,
    episodes_refreshed: episodesRefreshed,
    new_events_created: eventsCreated,
    notifications_sent: notificationsSent,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
```

---

### E2 — pg_cron Schedule

Register via Supabase dashboard cron or MCP `execute_sql`:

```sql
-- Same nightly window as check-streaming-changes (3 AM UTC)
SELECT cron.schedule(
  'check-new-episodes-nightly',
  '0 3 * * *',
  $$
    SELECT net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/check-new-episodes',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := '{}'::jsonb
    );
  $$
);
```

---

## Track B: Frontend

### F1 — Notification Deep-Link Router

Find the Flutter notification handler (likely in `lib/core/services/` or the FCM message handler in `main.dart`). Add a `new_episode` case alongside existing `streaming_alert` and `talent_content` cases:

```dart
case 'new_episode':
  final tmdbId = int.tryParse(data['tmdb_id']?.toString() ?? '');
  if (tmdbId != null) {
    // Navigate to show detail / progress screen
    Get.toNamed(AppRoutes.watchlistDetail, arguments: {'tmdb_id': tmdbId});
  }
  break;
```

Exact route name and arguments should match the existing pattern for content navigation.

### F2 — Client-Side Stale Refresh (Optional)

In the watchlist detail controller, after loading episodes from `content_cache_episodes`, check if any have placeholder names and a stale `updated_at`:

```dart
// After loading episodes from cache
final hasStale = episodes.any((ep) =>
  RegExp(r'^Episode \d+$').hasMatch(ep.episodeName ?? '') &&
  ep.updatedAt.isBefore(DateTime.now().subtract(const Duration(days: 7)))
);

if (hasStale) {
  // Re-fetch from TMDB and batch upsert
  final fresh = await TmdbService.getSeasonDetails(tmdbId, seasonNumber);
  final rows = fresh.episodes.map((e) =>
    ContentCacheEpisodesRepository.fromTmdbEpisode(tmdbId, e)
  ).toList();
  await ContentCacheEpisodesRepository.batchInsert(rows);
  // Reload from cache
}
```

This gives an immediate fix on first open for any user — the nightly cron alone is sufficient, but F2 makes the refresh instant.

---

## Files to Touch

**Backend — new:**
- `execution/backend/supabase/migrations/053_create_episode_check_rpc.sql`
- `execution/backend/supabase/functions/check-new-episodes/index.ts`

**Frontend — modified:**
- Notification router (find FCM handler): add `new_episode` case
- Watchlist detail controller (F2, optional): stale-refresh guard

---

## Key Constraints

- **`ignoreDuplicates: false`** on `content_cache_episodes` upsert — always overwrite stale data
- **Dedup guard:** `airedCount > lastDetectedCount` before inserting `new_episode_events`
- **`new_episode_events` unique constraint:** `(tmdb_id, season_number, detected_at)` — each cron run gets its own timestamp; dedup is logical (count comparison), not DB-enforced
- **Rate limit:** 250ms between TMDB calls; 50-show cap
- **`verify_jwt: false`** on Edge Function; validate token manually
- **`notification_preferences.new_episodes` opt-out** respected before sending
- **Premiere copy vs. weekly copy:** different `notifTitle`/`notifBody` based on `isPremiere` flag
- **Season 0 excluded:** specials/extras filtered in RPC (`season_number > 0`)

---

## Previous Plan

**User Archetypes** — Paused (frontend + edge function complete; migrations 050/051 pending)
**Watch Party Sync** — Complete (2026-02-22)
**Advanced Stats Dashboard v1.1** — Complete (2026-02-19)
