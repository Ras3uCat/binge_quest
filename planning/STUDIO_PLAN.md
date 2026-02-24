# User Archetypes (Viewer Personality Classification)

**Status:** IN PROGRESS
**Mode:** STUDIO
**Priority:** High
**Started:** 2026-02-23
**Specs:** `planning/features/user_archetypes.md`

---

## Problem Description

Users have no persistent identity signal on their profile beyond basic stats. Archetypes give each user a creative, data-driven label that reflects *how* they watch — not just *what* they watch. The feature drives profile engagement, friend conversation, and long-term retention via identity ownership ("I'm a Midnight Drifter").

---

## Architecture

Two new tables (`archetypes` reference, `user_archetypes` computed results) + three new columns on `users`.

`compute_user_archetype(p_user_id uuid)` is a SECURITY DEFINER SQL function that runs all 12 scoring queries as CTEs over a rolling 90-day window and writes the results. It is called by:
1. A BEFORE INSERT trigger on `watch_progress` on every 5th episode completion.
2. A nightly cron Edge Function (`compute-archetypes`) for batch refresh.

All signal data comes from existing columns — no new source data columns are needed.

**Dual archetype:** If the top two archetype scores are within 0.05 of each other, both are stored (rank 1 and rank 2) and displayed with a "+" connector.

**Pin:** A user may pin any archetype. When `is_pinned = true` on their highest-rank row, `compute_user_archetype` still writes new score rows but does NOT update `users.primary_archetype`.

---

## Track A: Backend

### A1 — Migration 050: `create_archetypes_tables`

#### `archetypes` (reference table)
```sql
CREATE TABLE public.archetypes (
  id          text PRIMARY KEY,
  display_name text NOT NULL,
  tagline     text NOT NULL,
  description text NOT NULL,
  icon_name   text NOT NULL,
  color_hex   text NOT NULL,
  sort_order  smallint NOT NULL
);

ALTER TABLE public.archetypes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "archetypes_select_auth"
  ON public.archetypes FOR SELECT
  TO authenticated USING (true);
```

Seeded with 12 rows:

| id | display_name | tagline |
|----|-------------|---------|
| `weekend_warrior` | Weekend Warrior | Vanishes Mon–Thu. Storms back Friday night. |
| `genre_loyalist` | Genre Loyalist | Found their lane. Never swerved. |
| `sampler_surfer` | Sampler Surfer | Starts everything. Finishes almost nothing. |
| `season_slayer` | Season Slayer | No show left unfinished. |
| `backlog_excavator` | Backlog Excavator | Digs into the vault. Long-ignored titles finally get their moment. |
| `midnight_drifter` | Midnight Drifter | 11PM to 3AM is sacred storytelling time. |
| `social_curator` | Social Curator | Watches so they can recommend. Their group chat depends on them. |
| `binge_sprinter` | Binge Sprinter | Doesn't watch shows — devours them. |
| `mood_surfer` | Mood Surfer | Doesn't pick shows — follows feelings. |
| `finish_first` | Finish-First Strategist | Efficiency is the game. Always knock out the nearest finish. |
| `trend_chaser` | Trend Chaser | Rides the algorithm's wave. Top 10 lists, viral clips. |
| `deep_cut` | Deep Cut Explorer | Digs where others don't. Foreign films, indie gems, forgotten series. |

#### `user_archetypes` (computed results)
```sql
CREATE TABLE public.user_archetypes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  archetype_id text NOT NULL REFERENCES public.archetypes(id),
  score        numeric(4,3) NOT NULL CHECK (score BETWEEN 0 AND 1),
  rank         smallint NOT NULL CHECK (rank IN (1, 2)),
  computed_at  timestamptz NOT NULL DEFAULT now(),
  is_pinned    boolean NOT NULL DEFAULT false,
  UNIQUE (user_id, archetype_id, computed_at)
);

CREATE INDEX idx_user_archetypes_user_computed
  ON public.user_archetypes (user_id, computed_at DESC);

ALTER TABLE public.user_archetypes ENABLE ROW LEVEL SECURITY;

-- Own rows always visible; friends' rows via are_friends()
CREATE POLICY "user_archetypes_select"
  ON public.user_archetypes FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR are_friends(auth.uid(), user_id));
-- No INSERT/UPDATE/DELETE from client — service_role only
```

#### Add columns to `users`
```sql
ALTER TABLE public.users
  ADD COLUMN primary_archetype   text REFERENCES public.archetypes(id),
  ADD COLUMN secondary_archetype text REFERENCES public.archetypes(id),
  ADD COLUMN archetype_updated_at timestamptz;
```

---

### A2 — Migration 051: `create_archetype_scoring_function`

#### `compute_user_archetype(p_user_id uuid)` — SECURITY DEFINER

**Returns:** `text` (winning archetype_id, or `null` if below threshold)

**Logic outline:**
```sql
CREATE OR REPLACE FUNCTION public.compute_user_archetype(p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_window_start  timestamptz := now() - interval '90 days';
  v_timezone      text;
  v_completed_titles int;
  v_episodes_watched int;
  v_platform_avg_reviews numeric;
  -- 12 score variables
  v_score_weekend_warrior  numeric(4,3);
  v_score_genre_loyalist   numeric(4,3);
  v_score_sampler_surfer   numeric(4,3);
  v_score_season_slayer    numeric(4,3);
  v_score_backlog          numeric(4,3);
  v_score_midnight         numeric(4,3);
  v_score_social           numeric(4,3);
  v_score_binge            numeric(4,3);
  v_score_mood             numeric(4,3);
  v_score_finish_first     numeric(4,3);
  v_score_trend            numeric(4,3);
  v_score_deep_cut         numeric(4,3);
  -- result tracking
  v_scores        jsonb;
  v_top1_id       text;
  v_top1_score    numeric(4,3);
  v_top2_id       text;
  v_top2_score    numeric(4,3);
  v_prev_primary  text;
  v_now           timestamptz := now();
BEGIN
  -- Resolve user timezone (fallback UTC)
  SELECT COALESCE(timezone, 'UTC') INTO v_timezone
  FROM notification_preferences WHERE user_id = p_user_id;

  -- Minimum activity threshold
  SELECT
    COUNT(DISTINCT wi.tmdb_id) FILTER (WHERE wp.watched = true),
    COUNT(*) FILTER (WHERE wp.watched = true AND wi.media_type = 'tv')
  INTO v_completed_titles, v_episodes_watched
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE w.user_id = p_user_id
    AND wp.watched_at >= v_window_start;

  IF v_completed_titles < 5 OR v_episodes_watched < 20 THEN
    RETURN NULL;
  END IF;

  -- ── 1. Weekend Warrior ─────────────────────────────────────────────────────
  -- >= 70% of watched_at fall on Fri 18:00 – Sun 24:00 in user's timezone
  SELECT LEAST(1.0, ROUND(
    COUNT(*) FILTER (
      WHERE EXTRACT(isodow FROM (wp.watched_at AT TIME ZONE v_timezone)) IN (5,6,7)
        AND (
          EXTRACT(isodow FROM (wp.watched_at AT TIME ZONE v_timezone)) IN (6,7)
          OR EXTRACT(hour FROM (wp.watched_at AT TIME ZONE v_timezone)) >= 18
        )
    )::numeric / NULLIF(COUNT(*), 0), 3))
  INTO v_score_weekend_warrior
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE w.user_id = p_user_id AND wp.watched_at >= v_window_start;

  -- ── 2. Genre Loyalist ──────────────────────────────────────────────────────
  -- Max single-genre share across completed titles' genre_ids
  WITH genre_counts AS (
    SELECT g.genre_id, COUNT(*) AS cnt
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    JOIN LATERAL unnest(cc.genre_ids) AS g(genre_id) ON true
    WHERE w.user_id = p_user_id AND wp.watched = true AND wp.watched_at >= v_window_start
    GROUP BY g.genre_id
  ),
  total AS (SELECT SUM(cnt) AS t FROM genre_counts)
  SELECT LEAST(1.0, ROUND(MAX(cnt)::numeric / NULLIF(t, 0), 3))
  INTO v_score_genre_loyalist
  FROM genre_counts, total;

  -- ── 3. Sampler Surfer ──────────────────────────────────────────────────────
  -- >= 60% titles started with <= 2 episodes watched AND total started >= 10
  WITH started AS (
    SELECT wi.tmdb_id, COUNT(wp.id) AS ep_count
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    WHERE w.user_id = p_user_id
      AND wi.media_type = 'tv'
      AND wp.watched_at >= v_window_start
    GROUP BY wi.tmdb_id
  )
  SELECT CASE
    WHEN COUNT(*) < 10 THEN 0.0
    ELSE LEAST(1.0, ROUND(
      COUNT(*) FILTER (WHERE ep_count <= 2)::numeric / NULLIF(COUNT(*), 0), 3
    ))
  END
  INTO v_score_sampler_surfer FROM started;

  -- ── 4. Season Slayer (Completionist) ───────────────────────────────────────
  -- AVG completion rate across started TV titles (watched / total episodes)
  WITH title_completion AS (
    SELECT
      wi.tmdb_id,
      COUNT(wp.id) FILTER (WHERE wp.watched = true)::numeric
        / NULLIF(COALESCE(cc.number_of_episodes, 1), 0) AS completion_rate
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    LEFT JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = 'tv'
    WHERE w.user_id = p_user_id
      AND wi.media_type = 'tv'
      AND wp.watched_at >= v_window_start
    GROUP BY wi.tmdb_id, cc.number_of_episodes
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(LEAST(completion_rate, 1.0)), 0), 3))
  INTO v_score_season_slayer FROM title_completion;

  -- ── 5. Backlog Excavator ───────────────────────────────────────────────────
  -- AVG(first_watched_at - added_at) normalized; 60 days -> 0.5, 180+ days -> 1.0
  WITH first_watch AS (
    SELECT wi.id,
           wi.added_at,
           MIN(wp.watched_at) AS first_watched_at
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    WHERE w.user_id = p_user_id AND wp.watched_at >= v_window_start
    GROUP BY wi.id, wi.added_at
  )
  SELECT LEAST(1.0, ROUND(
    COALESCE(AVG(
      EXTRACT(epoch FROM (first_watched_at - added_at)) / 86400.0
    ) / 180.0, 0), 3))
  INTO v_score_backlog FROM first_watch;

  -- ── 6. Midnight Drifter ────────────────────────────────────────────────────
  -- >= 50% of watched_at between 22:00 and 04:00 (user timezone)
  SELECT LEAST(1.0, ROUND(
    COUNT(*) FILTER (
      WHERE EXTRACT(hour FROM (wp.watched_at AT TIME ZONE v_timezone))
            NOT BETWEEN 4 AND 21
    )::numeric / NULLIF(COUNT(*), 0), 3))
  INTO v_score_midnight
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE w.user_id = p_user_id AND wp.watched_at >= v_window_start;

  -- ── 7. Social Curator ──────────────────────────────────────────────────────
  -- COUNT(reviews) / platform_avg, capped at 1.0
  SELECT COALESCE(AVG(review_count), 1) INTO v_platform_avg_reviews
  FROM (
    SELECT user_id, COUNT(*) AS review_count
    FROM reviews
    WHERE created_at >= v_window_start
    GROUP BY user_id
  ) sub;

  SELECT LEAST(1.0, ROUND(
    COUNT(*)::numeric / NULLIF(v_platform_avg_reviews * 3, 0), 3))
  INTO v_score_social
  FROM reviews
  WHERE user_id = p_user_id AND created_at >= v_window_start;

  -- ── 8. Binge Sprinter ──────────────────────────────────────────────────────
  -- Average cluster size (consecutive episodes within 90min gap), normalized /5
  WITH ordered AS (
    SELECT wp.id, wp.watched_at,
           wi.tmdb_id,
           LAG(wp.watched_at) OVER (PARTITION BY wi.tmdb_id ORDER BY wp.watched_at) AS prev_at
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    WHERE w.user_id = p_user_id AND wp.watched_at >= v_window_start AND wi.media_type = 'tv'
  ),
  sessions AS (
    SELECT tmdb_id, watched_at,
           SUM(CASE WHEN prev_at IS NULL
                    OR EXTRACT(epoch FROM watched_at - prev_at) > 5400 THEN 1 ELSE 0 END)
             OVER (PARTITION BY tmdb_id ORDER BY watched_at) AS session_id
    FROM ordered
  ),
  cluster_sizes AS (
    SELECT COUNT(*) AS sz FROM sessions GROUP BY tmdb_id, session_id
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(sz) / 5.0, 0), 3))
  INTO v_score_binge FROM cluster_sizes;

  -- ── 9. Mood Surfer ─────────────────────────────────────────────────────────
  -- Shannon entropy of genre distribution per week, averaged across weeks, normalized
  WITH weekly_genres AS (
    SELECT
      DATE_TRUNC('week', wp.watched_at AT TIME ZONE v_timezone) AS week,
      unnest(cc.genre_ids) AS genre_id,
      COUNT(*) AS cnt
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE w.user_id = p_user_id AND wp.watched_at >= v_window_start
    GROUP BY week, genre_id
  ),
  week_totals AS (
    SELECT week, SUM(cnt) AS total FROM weekly_genres GROUP BY week
  ),
  entropy AS (
    SELECT wg.week,
           -SUM((wg.cnt::numeric / wt.total) * LN(wg.cnt::numeric / wt.total)) AS h
    FROM weekly_genres wg JOIN week_totals wt USING (week)
    GROUP BY wg.week
  )
  -- Normalize: LN(12) ≈ 2.485 is max entropy for 12 equal genres
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(h) / LN(12.0), 0), 3))
  INTO v_score_mood FROM entropy;

  -- ── 10. Finish-First Strategist ───────────────────────────────────────────
  -- AVG completion_pct of item at time of each session; penalize concurrent > 2
  WITH in_progress AS (
    SELECT wi.tmdb_id,
           wp.watched_at,
           COUNT(wp2.id) FILTER (WHERE wp2.watched = true)::numeric
             / NULLIF(COALESCE(cc.number_of_episodes, 1), 0) AS pct_at_session
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    LEFT JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    LEFT JOIN watch_progress wp2
      ON wp2.watchlist_item_id = wp.watchlist_item_id AND wp2.watched_at < wp.watched_at
    WHERE w.user_id = p_user_id
      AND wp.watched_at >= v_window_start
    GROUP BY wi.tmdb_id, wp.watched_at, cc.number_of_episodes
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(LEAST(pct_at_session, 1.0)), 0), 3))
  INTO v_score_finish_first FROM in_progress;

  -- ── 11. Trend Chaser ──────────────────────────────────────────────────────
  -- AVG popularity_percentile of titles at add time (top 10% = score approaches 1.0)
  WITH pop_data AS (
    SELECT
      cc.popularity_score,
      PERCENT_RANK() OVER (ORDER BY cc.popularity_score) AS percentile
    FROM content_cache cc
  ),
  user_titles AS (
    SELECT pd.percentile
    FROM watchlist_items wi
    JOIN watchlists w ON w.id = wi.watchlist_id
    JOIN pop_data pd ON pd.popularity_score = (
      SELECT popularity_score FROM content_cache
      WHERE tmdb_id = wi.tmdb_id AND media_type = wi.media_type
      LIMIT 1
    )
    WHERE w.user_id = p_user_id AND wi.added_at >= v_window_start
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(percentile), 0), 3))
  INTO v_score_trend FROM user_titles;

  -- ── 12. Deep Cut Explorer ─────────────────────────────────────────────────
  -- AVG(1 - popularity_percentile) + bonus for content older than 5 years
  WITH pop_data AS (
    SELECT cc.tmdb_id, cc.media_type, cc.popularity_score, cc.release_date,
           1.0 - PERCENT_RANK() OVER (ORDER BY cc.popularity_score) AS inv_percentile
    FROM content_cache cc
  ),
  user_deep AS (
    SELECT
      pd.inv_percentile
        + CASE WHEN pd.release_date < (now() - interval '5 years') THEN 0.2 ELSE 0 END AS signal
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w ON w.id = wi.watchlist_id
    JOIN pop_data pd ON pd.tmdb_id = wi.tmdb_id AND pd.media_type = wi.media_type
    WHERE w.user_id = p_user_id AND wp.watched_at >= v_window_start
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(signal), 0), 3))
  INTO v_score_deep_cut FROM user_deep;

  -- ── Rank and persist ──────────────────────────────────────────────────────
  v_scores := jsonb_build_object(
    'weekend_warrior', v_score_weekend_warrior,
    'genre_loyalist',  v_score_genre_loyalist,
    'sampler_surfer',  v_score_sampler_surfer,
    'season_slayer',   v_score_season_slayer,
    'backlog_excavator', v_score_backlog,
    'midnight_drifter',  v_score_midnight,
    'social_curator',  v_score_social,
    'binge_sprinter',  v_score_binge,
    'mood_surfer',     v_score_mood,
    'finish_first',    v_score_finish_first,
    'trend_chaser',    v_score_trend,
    'deep_cut',        v_score_deep_cut
  );

  -- Insert all 12 scores for this computation timestamp
  INSERT INTO public.user_archetypes (user_id, archetype_id, score, rank, computed_at)
  SELECT p_user_id, key, value::numeric(4,3),
    RANK() OVER (ORDER BY value::numeric DESC),
    v_now
  FROM jsonb_each_text(v_scores)
  WHERE RANK() OVER (ORDER BY value::numeric DESC) <= 2
     OR value::numeric = (SELECT MAX(v::numeric) FROM jsonb_each_text(v_scores) AS j(k,v));

  -- Determine top 1 and optional top 2 (within 0.05)
  SELECT archetype_id, score INTO v_top1_id, v_top1_score
  FROM public.user_archetypes
  WHERE user_id = p_user_id AND computed_at = v_now AND rank = 1
  LIMIT 1;

  SELECT archetype_id, score INTO v_top2_id, v_top2_score
  FROM public.user_archetypes
  WHERE user_id = p_user_id AND computed_at = v_now AND rank = 2
  LIMIT 1;

  -- Only show dual archetype if within 0.05 gap
  IF v_top1_score - v_top2_score > 0.05 THEN
    v_top2_id := NULL;
  END IF;

  -- Get current primary to detect change
  SELECT primary_archetype INTO v_prev_primary
  FROM public.users WHERE id = p_user_id;

  -- Update users table (skip if user has a pinned archetype)
  IF NOT EXISTS (
    SELECT 1 FROM public.user_archetypes
    WHERE user_id = p_user_id AND is_pinned = true
  ) THEN
    UPDATE public.users SET
      primary_archetype    = v_top1_id,
      secondary_archetype  = v_top2_id,
      archetype_updated_at = v_now
    WHERE id = p_user_id;

    -- Notify on change
    IF v_prev_primary IS DISTINCT FROM v_top1_id AND v_top1_id IS NOT NULL THEN
      PERFORM public.notify_archetype_change(p_user_id, v_top1_id);
    END IF;
  END IF;

  RETURN v_top1_id;
END;
$$;
```

> **Note:** `notify_archetype_change()` is a lightweight wrapper that calls `send-notification` via `net.http_post` (pg_net) to avoid blocking the trigger. Alternatively, the Edge Function can handle the notification on its own after calling `compute_user_archetype`.

---

### A3 — Migration 051 (cont): Episode Completion Trigger

```sql
CREATE OR REPLACE FUNCTION public.on_watch_progress_archetype_check()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_user_id uuid;
  v_count   int;
BEGIN
  -- Only fire on episode-marked-watched
  IF NEW.watched IS NOT TRUE OR (OLD.watched IS TRUE) THEN
    RETURN NEW;
  END IF;

  SELECT w.user_id INTO v_user_id
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE wi.id = NEW.watchlist_item_id;

  -- Count completions since last archetype computation
  SELECT COUNT(*) INTO v_count
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE w.user_id = v_user_id
    AND wp.watched = true
    AND wp.watched_at > COALESCE(
      (SELECT MAX(computed_at) FROM user_archetypes WHERE user_id = v_user_id),
      '-infinity'::timestamptz
    );

  IF v_count % 5 = 0 THEN
    PERFORM public.compute_user_archetype(v_user_id);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_watch_progress_archetype
  AFTER INSERT OR UPDATE ON public.watch_progress
  FOR EACH ROW EXECUTE FUNCTION public.on_watch_progress_archetype_check();
```

---

### A4 — Edge Function: `compute-archetypes`

**File:** `supabase/functions/compute-archetypes/index.ts`

- Accepts service_role bearer token only (`verify_jwt: false` + manual check).
- **Single user mode:** POST body `{ user_id: string }` → calls `compute_user_archetype(user_id)`.
- **Batch mode:** POST body `{ batch: true }` → queries all users active in last 90 days, calls function for each with a small delay to avoid lock contention.
- **Cron:** Scheduled nightly via Supabase cron or external scheduler.

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const body = await req.json().catch(() => ({}));

  if (body.user_id) {
    const { data, error } = await supabase.rpc("compute_user_archetype", {
      p_user_id: body.user_id,
    });
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    return new Response(JSON.stringify({ archetype: data }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  if (body.batch) {
    // Fetch all users active in last 90 days
    const { data: users } = await supabase
      .from("watch_progress")
      .select("watchlist_items!inner(watchlists!inner(user_id))")
      .gte("watched_at", new Date(Date.now() - 90 * 86400000).toISOString());

    const userIds = [...new Set(
      (users ?? []).map((r: any) => r.watchlist_items?.watchlists?.user_id).filter(Boolean)
    )];

    let processed = 0;
    for (const uid of userIds) {
      await supabase.rpc("compute_user_archetype", { p_user_id: uid });
      processed++;
    }
    return new Response(JSON.stringify({ processed }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response("Bad Request", { status: 400 });
});
```

---

## Track B: Frontend

### B1 — Models (`lib/shared/models/archetype.dart`)

```dart
class Archetype {
  final String id;
  final String displayName;
  final String tagline;
  final String description;
  final String iconName;
  final String colorHex;
  final int sortOrder;

  factory Archetype.fromJson(Map<String, dynamic> json) { ... }
}

class UserArchetype {
  final String id;
  final String userId;
  final String archetypeId;
  final double score;          // 0.000 – 1.000
  final int rank;              // 1 = primary, 2 = secondary
  final DateTime computedAt;
  final bool isPinned;

  factory UserArchetype.fromJson(Map<String, dynamic> json) { ... }
}
```

### B2 — Repository (`lib/shared/repositories/archetype_repository.dart`)

```
fetchAllArchetypes()          → List<Archetype>   (cache in memory)
fetchUserArchetype(userId)    → (UserArchetype? primary, UserArchetype? secondary)
fetchArchetypeScores(userId)  → List<UserArchetype>  (all 12 for most recent computed_at)
fetchArchetypeHistory(userId) → List<UserArchetype>  (rank=1 rows, ordered by computed_at DESC)
pinArchetype(archetypeId)     → void  (UPDATE user_archetypes SET is_pinned = true WHERE ...)
unpinArchetype()              → void  (UPDATE is_pinned = false for current user)
```

### B3 — Controller (`lib/features/profile/controllers/archetype_controller.dart`)

GetX, `Get.lazyPut(fenix: true)`:
- `Rx<Archetype?> currentArchetype`, `Rx<Archetype?> secondaryArchetype`
- `RxList<UserArchetype> allScores` (all 12, latest compute)
- `RxList<UserArchetype> history`
- `RxBool isPinned`
- `RxBool isLoading`
- `loadForUser(String userId)` — fetches reference + user data, populates observables
- `togglePin(String archetypeId)` — calls repo, updates `isPinned`

### B4 — ArchetypeBadge (`lib/features/profile/widgets/archetype_badge.dart`)

Two modes:
- **Full** (own profile): `Icon` + `displayName` (bold) + `tagline` (subtitle); dual archetype = two badges with "+" between them
- **Compact** (friend list/cards): `Icon` + `displayName` only, single line
- **Placeholder:** "Still Exploring..." italic label with progress hint

Tappable in full mode → opens `ArchetypeDetailSheet`.

### B5 — ArchetypeDetailSheet (`lib/features/profile/widgets/archetype_detail_sheet.dart`)

Bottom sheet (use `Get.bottomSheet(Container(decoration: BoxDecoration(...)))` pattern):
- Header: archetype icon (large) + name + color chip
- Body: full description text
- Radar chart: `ArchetypeRadarChart(scores: controller.allScores)`
- History section: `ArchetypeHistoryTimeline`
- Footer: "Pin this archetype" `Switch` tile (own profile only)

### B6 — ArchetypeRadarChart (`lib/features/profile/widgets/archetype_radar_chart.dart`)

`CustomPainter`-based spider chart:
- 12 axes, one per archetype
- Polygon filled with archetype color at 30% opacity
- Axis labels at tips (abbreviated names, ~8 chars)
- Current axis highlighted
- `Size` ~240×240 dp

### B7 — ArchetypeHistoryTimeline (`lib/features/profile/widgets/archetype_history_timeline.dart`)

Scrollable vertical list of past `user_archetypes` rows (rank = 1 only):
- Each row: date chip + archetype icon + name
- Latest row highlighted
- Limit to 10 most recent entries

---

## Track C: Integration

### C1 — Profile Screen

- Add `ArchetypeBadge` (full mode) below display name in profile header.
- Connect to `ArchetypeController.loadForUser(userId)` on screen init.
- Works for own profile AND friend profile view (compact mode on friend profile).

### C2 — Friend List Items & Friend Profile Cards

- Add compact `ArchetypeBadge` to existing friend list tile subtitle area.
- `FriendController` already loads friend user data; archetype comes from `users.primary_archetype` join.
- Option: eager-load from `users` join (single extra column, no extra query).

---

## Files to Touch

**Backend — new:**
- `050_create_archetypes_tables.sql`
- `051_create_archetype_scoring_function.sql`
- `supabase/functions/compute-archetypes/index.ts`

**Frontend — new:**
- `lib/shared/models/archetype.dart`
- `lib/shared/repositories/archetype_repository.dart`
- `lib/features/profile/controllers/archetype_controller.dart`
- `lib/features/profile/widgets/archetype_badge.dart`
- `lib/features/profile/widgets/archetype_detail_sheet.dart`
- `lib/features/profile/widgets/archetype_radar_chart.dart`
- `lib/features/profile/widgets/archetype_history_timeline.dart`

**Frontend — modified:**
- Profile screen: add `ArchetypeBadge`
- Friend list screen + friend profile card: add compact `ArchetypeBadge`

---

## Key Constraints

- **`user_archetypes` is write-only for service_role** — no client INSERT/UPDATE/DELETE
- **`compute_user_archetype` is SECURITY DEFINER** — must SET search_path = public
- **Minimum threshold:** >= 5 completed titles AND >= 20 episodes watched; return `null` otherwise
- **Dual archetype:** only when top two scores within 0.05; max 2 displayed
- **Pin:** prevents `users.primary_archetype` update, but does NOT stop scoring from running
- **Push notification:** only when `primary_archetype` value actually changes (not every recompute)
- **Archetype visibility:** own profile = full; friend profiles = compact; non-friends = not shown
- **Quiz:** SKIPPED for v1
- **`verify_jwt: false`** on `compute-archetypes` Edge Function; validate service_role key manually
- **File size limit:** no file > 300 lines; split scorer into helper functions if needed
- **All scoring CTEs use 90-day rolling window:** `WHERE watched_at >= now() - interval '90 days'`

---

## Previous Plan

**Watch Party Sync** — Complete (2026-02-22)
**Advanced Stats Dashboard v1.1** — Complete (2026-02-19)
**Advanced Stats Dashboard v1.0** — Complete (2026-02-19)
**Pre-Launch Hardening** — Complete (2026-02-19)
