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

`compute_user_archetype(p_user_id uuid)` is a SECURITY DEFINER SQL function that runs 12 thin scoring sub-functions over a rolling 90-day window and writes all 12 scores. It is called by:
1. An AFTER INSERT OR UPDATE trigger on `watch_progress` on every 5th episode completion.
2. A nightly cron Edge Function (`compute-archetypes`) for batch refresh.

All signal data comes from existing columns — no new source data columns are needed.

**300-line rule:** The monolithic scoring function is split into 12 `SECURITY DEFINER` helper functions (`_score_*`) called by the thin orchestrator `compute_user_archetype`. Each helper is well under 50 lines.

**Dual archetype:** If the top two archetype scores are within 0.05 of each other, both are stored (rank 1 and rank 2) and displayed with a "+" connector.

**Notifications:** `compute_user_archetype` returns a `(new_archetype, prev_archetype)` pair. The Edge Function compares them and calls `send-notification` if changed — no pg_net dependency needed.

**Genre Loyalist dynamic name:** The dominant genre ID is stored in `user_archetypes.genre_override` (JSONB metadata column, nullable). The frontend reads it to compose the display label ("Horror Devotee", "Anime Purist"). Falls back to "Genre Loyalist" when absent.

---

## Track A: Backend

### A1 — Migration 050: `create_archetypes_tables`

#### `archetypes` (reference table)

```sql
CREATE TABLE public.archetypes (
  id           text PRIMARY KEY,
  display_name text NOT NULL,
  tagline      text NOT NULL,
  description  text NOT NULL,
  icon_name    text NOT NULL,   -- Material icon name string
  color_hex    text NOT NULL,   -- e.g. '#FF6B35'
  sort_order   smallint NOT NULL
);

ALTER TABLE public.archetypes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "archetypes_select_auth"
  ON public.archetypes FOR SELECT
  TO authenticated USING (true);
```

Seed 12 rows:

```sql
INSERT INTO public.archetypes
  (id, display_name, tagline, description, icon_name, color_hex, sort_order)
VALUES
  ('weekend_warrior',   'Weekend Warrior',          'Vanishes Mon–Thu. Storms back Friday night.',
   'They vanish Monday through Thursday, then return like a storm front. Entire seasons fall between Friday night and Sunday midnight.',
   'weekend_warrior', '#FF6B35', 1),

  ('genre_loyalist',    'Genre Loyalist',            'Found their lane. Never swerved.',
   'They found their lane and never swerved. Their watchlist is a cathedral dedicated to one flavor of story.',
   'local_movies', '#E63946', 2),

  ('sampler_surfer',    'Sampler Surfer',            'Starts everything. Finishes almost nothing.',
   'They start everything. Finish almost nothing. Their "Continue Watching" row is a museum of beginnings.',
   'shuffle', '#457B9D', 3),

  ('season_slayer',     'Season Slayer',             'No show left unfinished.',
   'No show left unfinished. If they start Episode 1, they will reach the final credits.',
   'military_tech', '#2A9D8F', 4),

  ('backlog_excavator', 'Backlog Excavator',         'Digs into the vault. Long-ignored titles finally get their moment.',
   'They dig into the vault. Long-ignored titles finally get their moment. Their queue gets shorter while everyone else''s grows.',
   'archive', '#8B5E3C', 5),

  ('midnight_drifter',  'Midnight Drifter',          '11 PM to 3 AM is sacred storytelling time.',
   'Their prime viewing hours begin when the world goes quiet. 11 PM to 3 AM is sacred storytelling time.',
   'nights_stay', '#6A0572', 6),

  ('social_curator',    'Social Curator',            'Watches so they can recommend.',
   'They watch so they can recommend. Their group chat depends on them. "Trust me, just watch episode 3" is their signature phrase.',
   'recommend', '#F4A261', 7),

  ('binge_sprinter',    'Binge Sprinter',            'Doesn''t watch shows — devours them.',
   'They don''t watch shows — they devour them. Three episodes? That''s a warm-up. An entire season in one sitting? Now we''re talking.',
   'bolt', '#E9C46A', 8),

  ('mood_surfer',       'Mood Surfer',               'Doesn''t pick shows — follows feelings.',
   'They don''t pick shows — they follow feelings. Their queue changes with the weather of their soul.',
   'waves', '#48CAE4', 9),

  ('finish_first',      'Finish-First Strategist',   'Efficiency is the game. Knock out the nearest finish.',
   'Efficiency is the game. They pick the show closest to done and knock it out. Their "in progress" list is always short and shrinking.',
   'checklist', '#52B788', 10),

  ('trend_chaser',      'Trend Chaser',              'Rides the algorithm''s wave.',
   'They ride the algorithm''s wave. Top 10 lists, viral clips, what everyone''s talking about right now.',
   'trending_up', '#F72585', 11),

  ('deep_cut',          'Deep Cut Explorer',         'Digs where others don''t.',
   'They dig where others don''t. Foreign films, indie gems, forgotten series from 2009.',
   'explore', '#7B2D8B', 12);
```

#### `user_archetypes` (computed results)

```sql
CREATE TABLE public.user_archetypes (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  archetype_id   text NOT NULL REFERENCES public.archetypes(id),
  score          numeric(4,3) NOT NULL CHECK (score BETWEEN 0 AND 1),
  rank           smallint NOT NULL,          -- 1–12; 1 = highest score
  computed_at    timestamptz NOT NULL DEFAULT now(),
  is_pinned      boolean NOT NULL DEFAULT false,
  metadata       jsonb,                      -- e.g. {"dominant_genre_id": 28}
  UNIQUE (user_id, archetype_id, computed_at)
);

CREATE INDEX idx_user_archetypes_user_computed
  ON public.user_archetypes (user_id, computed_at DESC);

ALTER TABLE public.user_archetypes ENABLE ROW LEVEL SECURITY;

-- Read: own rows + friends' rows
CREATE POLICY "user_archetypes_select"
  ON public.user_archetypes FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR are_friends(auth.uid(), user_id));

-- No INSERT/UPDATE/DELETE from client — service_role only
```

#### Add columns to `users`

```sql
ALTER TABLE public.users
  ADD COLUMN primary_archetype    text REFERENCES public.archetypes(id),
  ADD COLUMN secondary_archetype  text REFERENCES public.archetypes(id),
  ADD COLUMN archetype_updated_at timestamptz;
```

---

### A2 — Migration 051: `create_archetype_scoring_functions`

#### Design: thin orchestrator + 12 helper functions

Each `_score_*` helper accepts `(p_user_id uuid, p_window timestamptz, p_tz text)` and returns `numeric(4,3)`. The orchestrator calls all 12, collects results, writes to `user_archetypes`, and returns `(new_archetype text, prev_archetype text)` as a composite type for the Edge Function to use.

```sql
-- Return type for Edge Function notification comparison
CREATE TYPE public.archetype_result AS (
  new_archetype  text,
  prev_archetype text
);
```

---

#### Helper 1 — `_score_weekend_warrior`

```sql
CREATE OR REPLACE FUNCTION public._score_weekend_warrior(
  p_user_id uuid, p_window timestamptz, p_tz text
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0, ROUND(
    COUNT(*) FILTER (
      WHERE EXTRACT(isodow FROM (wp.watched_at AT TIME ZONE p_tz)) IN (5,6,7)
        AND (
          EXTRACT(isodow FROM (wp.watched_at AT TIME ZONE p_tz)) IN (6,7)
          OR EXTRACT(hour  FROM (wp.watched_at AT TIME ZONE p_tz)) >= 18
        )
    )::numeric / NULLIF(COUNT(*), 0), 3))::numeric(4,3)
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w        ON w.id  = wi.watchlist_id
  WHERE w.user_id = p_user_id AND wp.watched_at >= p_window;
$$;
```

#### Helper 2 — `_score_genre_loyalist`

Returns the max single-genre share AND stores the dominant genre_id in `OUT p_genre_id int`.

```sql
CREATE OR REPLACE FUNCTION public._score_genre_loyalist(
  p_user_id uuid, p_window timestamptz,
  OUT score numeric(4,3), OUT dominant_genre_id int
) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  WITH genre_counts AS (
    SELECT g.genre_id, COUNT(*) AS cnt
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    JOIN content_cache cc    ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    JOIN LATERAL unnest(cc.genre_ids) AS g(genre_id) ON true
    WHERE w.user_id = p_user_id AND wp.watched = true AND wp.watched_at >= p_window
    GROUP BY g.genre_id
  ),
  totals AS (SELECT SUM(cnt) AS t FROM genre_counts),
  top    AS (SELECT genre_id, cnt FROM genre_counts ORDER BY cnt DESC LIMIT 1)
  SELECT
    LEAST(1.0, ROUND(top.cnt::numeric / NULLIF(totals.t, 0), 3))::numeric(4,3),
    top.genre_id
  INTO score, dominant_genre_id
  FROM top, totals;

  score := COALESCE(score, 0.0);
END;
$$;
```

#### Helper 3 — `_score_sampler_surfer`

```sql
CREATE OR REPLACE FUNCTION public._score_sampler_surfer(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH started AS (
    SELECT wi.tmdb_id, COUNT(wp.id) AS ep_count
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id AND wi.media_type = 'tv' AND wp.watched_at >= p_window
    GROUP BY wi.tmdb_id
  )
  SELECT CASE
    WHEN COUNT(*) < 10 THEN 0.000
    ELSE LEAST(1.0, ROUND(
      COUNT(*) FILTER (WHERE ep_count <= 2)::numeric / NULLIF(COUNT(*), 0), 3
    ))
  END::numeric(4,3)
  FROM started;
$$;
```

#### Helper 4 — `_score_season_slayer`

Signal: ratio of watched episodes vs. started episodes per title (not vs. total series count — avoids penalising long-running shows mid-run).

```sql
CREATE OR REPLACE FUNCTION public._score_season_slayer(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH title_stats AS (
    SELECT
      wi.tmdb_id,
      COUNT(*) FILTER (WHERE wp.watched = true)::numeric AS watched_eps,
      COUNT(*)::numeric AS started_eps
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id AND wi.media_type = 'tv' AND wp.watched_at >= p_window
    GROUP BY wi.tmdb_id
  )
  SELECT LEAST(1.0, ROUND(
    COALESCE(AVG(watched_eps / NULLIF(started_eps, 0)), 0), 3
  ))::numeric(4,3)
  FROM title_stats;
$$;
```

#### Helper 5 — `_score_backlog_excavator`

```sql
CREATE OR REPLACE FUNCTION public._score_backlog_excavator(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH first_watch AS (
    SELECT wi.added_at, MIN(wp.watched_at) AS first_watched_at
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id AND wp.watched_at >= p_window
    GROUP BY wi.id, wi.added_at
  )
  -- 180-day average gap normalises to 1.0; capped via LEAST
  SELECT LEAST(1.0, ROUND(
    COALESCE(AVG(
      EXTRACT(epoch FROM (first_watched_at - added_at)) / 86400.0
    ) / 180.0, 0), 3
  ))::numeric(4,3)
  FROM first_watch;
$$;
```

#### Helper 6 — `_score_midnight_drifter`

```sql
CREATE OR REPLACE FUNCTION public._score_midnight_drifter(
  p_user_id uuid, p_window timestamptz, p_tz text
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  -- Hours 22–23 and 0–3 (NOT BETWEEN 4 AND 21 covers exactly this range)
  SELECT LEAST(1.0, ROUND(
    COUNT(*) FILTER (
      WHERE EXTRACT(hour FROM (wp.watched_at AT TIME ZONE p_tz))
            NOT BETWEEN 4 AND 21
    )::numeric / NULLIF(COUNT(*), 0), 3
  ))::numeric(4,3)
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w        ON w.id  = wi.watchlist_id
  WHERE w.user_id = p_user_id AND wp.watched_at >= p_window;
$$;
```

#### Helper 7 — `_score_social_curator`

```sql
CREATE OR REPLACE FUNCTION public._score_social_curator(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_count  numeric;
  v_platform_avg numeric;
BEGIN
  SELECT COUNT(*)::numeric INTO v_user_count
  FROM reviews WHERE user_id = p_user_id AND created_at >= p_window;

  SELECT COALESCE(AVG(cnt), 1) INTO v_platform_avg
  FROM (
    SELECT COUNT(*) AS cnt FROM reviews
    WHERE created_at >= p_window GROUP BY user_id
  ) sub;

  -- Score relative to 3× platform average (top performers approach 1.0)
  RETURN LEAST(1.0, ROUND(v_user_count / NULLIF(v_platform_avg * 3, 0), 3))::numeric(4,3);
END;
$$;
```

#### Helper 8 — `_score_binge_sprinter`

```sql
CREATE OR REPLACE FUNCTION public._score_binge_sprinter(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH ordered AS (
    SELECT wp.watched_at, wi.tmdb_id,
           LAG(wp.watched_at) OVER (PARTITION BY wi.tmdb_id ORDER BY wp.watched_at) AS prev_at
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id AND wp.watched_at >= p_window AND wi.media_type = 'tv'
  ),
  sessions AS (
    SELECT tmdb_id, watched_at,
           SUM(CASE WHEN prev_at IS NULL
                    OR EXTRACT(epoch FROM watched_at - prev_at) > 5400
                    THEN 1 ELSE 0 END)
             OVER (PARTITION BY tmdb_id ORDER BY watched_at) AS session_id
    FROM ordered
  ),
  cluster_sizes AS (
    SELECT COUNT(*) AS sz FROM sessions GROUP BY tmdb_id, session_id
  )
  -- Normalise: avg cluster of 5 episodes = score 1.0
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(sz) / 5.0, 0), 3))::numeric(4,3)
  FROM cluster_sizes;
$$;
```

#### Helper 9 — `_score_mood_surfer`

```sql
CREATE OR REPLACE FUNCTION public._score_mood_surfer(
  p_user_id uuid, p_window timestamptz, p_tz text
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH weekly_genres AS (
    SELECT
      DATE_TRUNC('week', wp.watched_at AT TIME ZONE p_tz) AS week,
      g.genre_id,
      COUNT(*) AS cnt
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    JOIN content_cache cc    ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    JOIN LATERAL unnest(cc.genre_ids) AS g(genre_id) ON true
    WHERE w.user_id = p_user_id AND wp.watched_at >= p_window
    GROUP BY week, g.genre_id
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
  -- LN(12) ≈ 2.485 is theoretical max (12 equal genres)
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(h) / LN(12.0), 0), 3))::numeric(4,3)
  FROM entropy;
$$;
```

#### Helper 10 — `_score_finish_first`

```sql
CREATE OR REPLACE FUNCTION public._score_finish_first(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  -- AVG(watched_eps_before_session / total_started_eps_for_title) at each session start
  WITH session_starts AS (
    SELECT
      wi.tmdb_id,
      wp.id AS progress_id,
      wp.watched_at,
      COUNT(wp2.id)::numeric AS prior_watched,
      COUNT(wp3.id)::numeric AS total_started
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    -- prior completed episodes for this title
    LEFT JOIN watch_progress wp2
      ON wp2.watchlist_item_id = wp.watchlist_item_id
     AND wp2.watched = true
     AND wp2.watched_at < wp.watched_at
    -- total episodes ever started for this title
    LEFT JOIN watch_progress wp3
      ON wp3.watchlist_item_id = wp.watchlist_item_id
    WHERE w.user_id = p_user_id AND wp.watched_at >= p_window
    GROUP BY wi.tmdb_id, wp.id, wp.watched_at
  )
  SELECT LEAST(1.0, ROUND(
    COALESCE(AVG(prior_watched / NULLIF(total_started, 0)), 0), 3
  ))::numeric(4,3)
  FROM session_starts;
$$;
```

#### Helper 11 — `_score_trend_chaser`

Joins on `(tmdb_id, media_type)` instead of matching on the float `popularity_score` value (fix #2).

```sql
CREATE OR REPLACE FUNCTION public._score_trend_chaser(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH pop_ranked AS (
    SELECT tmdb_id, media_type,
           PERCENT_RANK() OVER (ORDER BY popularity_score) AS percentile
    FROM content_cache
  ),
  user_titles AS (
    SELECT pr.percentile
    FROM watchlist_items wi
    JOIN watchlists w  ON w.id = wi.watchlist_id
    JOIN pop_ranked pr ON pr.tmdb_id = wi.tmdb_id AND pr.media_type = wi.media_type
    WHERE w.user_id = p_user_id AND wi.added_at >= p_window
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(percentile), 0), 3))::numeric(4,3)
  FROM user_titles;
$$;
```

#### Helper 12 — `_score_deep_cut`

```sql
CREATE OR REPLACE FUNCTION public._score_deep_cut(
  p_user_id uuid, p_window timestamptz
) RETURNS numeric(4,3) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH pop_ranked AS (
    SELECT tmdb_id, media_type, release_date,
           1.0 - PERCENT_RANK() OVER (ORDER BY popularity_score) AS inv_percentile
    FROM content_cache
  ),
  user_deep AS (
    SELECT
      pr.inv_percentile
        + CASE WHEN pr.release_date < (now() - interval '5 years') THEN 0.2 ELSE 0 END AS signal
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists w        ON w.id  = wi.watchlist_id
    JOIN pop_ranked pr       ON pr.tmdb_id = wi.tmdb_id AND pr.media_type = wi.media_type
    WHERE w.user_id = p_user_id AND wp.watched_at >= p_window
  )
  SELECT LEAST(1.0, ROUND(COALESCE(AVG(signal), 0), 3))::numeric(4,3)
  FROM user_deep;
$$;
```

---

#### Orchestrator — `compute_user_archetype`

```sql
CREATE OR REPLACE FUNCTION public.compute_user_archetype(p_user_id uuid)
RETURNS public.archetype_result
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_window      timestamptz := now() - interval '90 days';
  v_tz          text;
  v_completed   int;
  v_eps_watched int;
  v_now         timestamptz := now();
  v_prev        text;
  v_top1_id     text;
  v_top1_score  numeric(4,3);
  v_top2_id     text;
  v_top2_score  numeric(4,3);
  v_gl_score    numeric(4,3);
  v_gl_genre    int;
  result        public.archetype_result;
BEGIN
  -- Resolve user timezone
  SELECT COALESCE(timezone, 'UTC') INTO v_tz
  FROM notification_preferences WHERE user_id = p_user_id;

  -- Minimum activity threshold: >= 5 completed titles AND >= 20 watched TV episodes
  SELECT
    COUNT(DISTINCT wi.tmdb_id) FILTER (WHERE wp.watched = true),
    COUNT(*)                   FILTER (WHERE wp.watched = true AND wi.media_type = 'tv')
  INTO v_completed, v_eps_watched
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w        ON w.id  = wi.watchlist_id
  WHERE w.user_id = p_user_id AND wp.watched_at >= v_window;

  IF v_completed < 5 OR v_eps_watched < 20 THEN
    result.new_archetype  := NULL;
    SELECT primary_archetype INTO result.prev_archetype FROM users WHERE id = p_user_id;
    RETURN result;
  END IF;

  -- Run Genre Loyalist helper (has OUT params for dominant genre)
  SELECT s.score, s.dominant_genre_id
  INTO v_gl_score, v_gl_genre
  FROM public._score_genre_loyalist(p_user_id, v_window) s;

  -- Insert all 12 scores using a CTE to rank first (fix #1: no window func in WHERE)
  WITH raw_scores (archetype_id, score) AS (
    VALUES
      ('weekend_warrior',   public._score_weekend_warrior(p_user_id, v_window, v_tz)),
      ('genre_loyalist',    v_gl_score),
      ('sampler_surfer',    public._score_sampler_surfer(p_user_id, v_window)),
      ('season_slayer',     public._score_season_slayer(p_user_id, v_window)),
      ('backlog_excavator', public._score_backlog_excavator(p_user_id, v_window)),
      ('midnight_drifter',  public._score_midnight_drifter(p_user_id, v_window, v_tz)),
      ('social_curator',    public._score_social_curator(p_user_id, v_window)),
      ('binge_sprinter',    public._score_binge_sprinter(p_user_id, v_window)),
      ('mood_surfer',       public._score_mood_surfer(p_user_id, v_window, v_tz)),
      ('finish_first',      public._score_finish_first(p_user_id, v_window)),
      ('trend_chaser',      public._score_trend_chaser(p_user_id, v_window)),
      ('deep_cut',          public._score_deep_cut(p_user_id, v_window))
  ),
  ranked AS (
    SELECT archetype_id, score,
           RANK() OVER (ORDER BY score DESC) AS rnk
    FROM raw_scores
  )
  -- Insert ALL 12 rows (radar chart needs full dataset) with ON CONFLICT safety (fix #10)
  INSERT INTO public.user_archetypes (user_id, archetype_id, score, rank, computed_at, metadata)
  SELECT
    p_user_id,
    r.archetype_id,
    r.score,
    r.rnk,
    v_now,
    CASE WHEN r.archetype_id = 'genre_loyalist' AND v_gl_genre IS NOT NULL
         THEN jsonb_build_object('dominant_genre_id', v_gl_genre)
         ELSE NULL
    END
  FROM ranked r
  ON CONFLICT (user_id, archetype_id, computed_at) DO NOTHING;

  -- Read back top 2
  SELECT archetype_id, score INTO v_top1_id, v_top1_score
  FROM user_archetypes
  WHERE user_id = p_user_id AND computed_at = v_now AND rank = 1 LIMIT 1;

  SELECT archetype_id, score INTO v_top2_id, v_top2_score
  FROM user_archetypes
  WHERE user_id = p_user_id AND computed_at = v_now AND rank = 2 LIMIT 1;

  -- Only surface dual archetype if gap <= 0.05
  IF v_top1_score - v_top2_score > 0.05 THEN
    v_top2_id := NULL;
  END IF;

  -- Capture previous primary before update
  SELECT primary_archetype INTO v_prev FROM users WHERE id = p_user_id;

  UPDATE users SET
    primary_archetype    = v_top1_id,
    secondary_archetype  = v_top2_id,
    archetype_updated_at = v_now
  WHERE id = p_user_id;

  result.new_archetype  := v_top1_id;
  result.prev_archetype := v_prev;
  RETURN result;
END;
$$;
```

---

### A3 — Migration 051 (cont): Episode Completion Trigger

Fixed OLD reference for INSERT operations (fix #3).

```sql
CREATE OR REPLACE FUNCTION public.on_watch_progress_archetype_check()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_user_id uuid;
  v_count   int;
BEGIN
  -- Only fire when an episode transitions to watched = true for the first time
  IF NEW.watched IS NOT TRUE THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND OLD.watched IS TRUE THEN RETURN NEW; END IF;

  SELECT w.user_id INTO v_user_id
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE wi.id = NEW.watchlist_item_id;

  -- Count completions since last archetype computation for this user
  SELECT COUNT(*) INTO v_count
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w        ON w.id  = wi.watchlist_id
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

Handles push notification after RPC call (no pg_net needed — fix #5). Uses a raw SQL RPC for the batch user list instead of nested PostgREST joins (fix: more reliable).

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

async function notifyIfChanged(
  userId: string, newArchetype: string | null, prevArchetype: string | null
) {
  if (!newArchetype || newArchetype === prevArchetype) return;
  // Reuse existing send-notification Edge Function pattern
  const { data: archetype } = await supabase
    .from("archetypes")
    .select("display_name")
    .eq("id", newArchetype)
    .single();
  await supabase.functions.invoke("send-notification", {
    body: {
      user_id: userId,
      title: "Your viewing style has evolved!",
      body: `You're now a ${archetype?.display_name ?? newArchetype}.`,
      data: { type: "archetype_change", archetype_id: newArchetype },
    },
  });
}

Deno.serve(async (req: Request) => {
  // Manual service_role validation (verify_jwt: false)
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  if (token !== Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")) {
    return new Response("Unauthorized", { status: 401 });
  }

  const body = await req.json().catch(() => ({}));

  // Single user mode
  if (body.user_id) {
    const { data, error } = await supabase.rpc("compute_user_archetype", {
      p_user_id: body.user_id,
    });
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    await notifyIfChanged(body.user_id, data?.new_archetype, data?.prev_archetype);
    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json" },
    });
  }

  // Batch mode: all users active in last 90 days
  if (body.batch) {
    const { data: rows } = await supabase.rpc("get_active_user_ids_90d");
    const userIds: string[] = (rows ?? []).map((r: { user_id: string }) => r.user_id);
    let processed = 0;
    for (const uid of userIds) {
      const { data } = await supabase.rpc("compute_user_archetype", { p_user_id: uid });
      await notifyIfChanged(uid, data?.new_archetype, data?.prev_archetype);
      processed++;
    }
    return new Response(JSON.stringify({ processed }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response("Bad Request", { status: 400 });
});
```

Add helper RPC for batch query (goes in Migration 051):

```sql
CREATE OR REPLACE FUNCTION public.get_active_user_ids_90d()
RETURNS TABLE (user_id uuid) LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT DISTINCT w.user_id
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists w        ON w.id  = wi.watchlist_id
  WHERE wp.watched_at >= now() - interval '90 days';
$$;
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

  // Genre Loyalist dynamic label — falls back to displayName (fix #8)
  String resolvedDisplayName(Map<String, dynamic>? metadata) {
    if (id != 'genre_loyalist' || metadata == null) return displayName;
    final genreId = metadata['dominant_genre_id'] as int?;
    return _genreLabel(genreId) ?? displayName;
  }

  static String? _genreLabel(int? genreId) => const {
    28: 'Action Junkie',    12: 'Adventure Seeker', 16: 'Animation Lover',
    35: 'Comedy Addict',    80: 'Crime Obsessive',  99: 'Documentary Buff',
    18: 'Drama Devotee',    10751: 'Family Viewer', 14: 'Fantasy Fan',
    36: 'History Nerd',     27: 'Horror Devotee',   10402: 'Music Head',
    9648: 'Mystery Hunter', 10749: 'Romance Watcher',878: 'Sci-Fi Purist',
    53: 'Thriller Junkie',  10752: 'War Watcher',   37: 'Western Rider',
  }[genreId];
}

class UserArchetype {
  final String id;
  final String userId;
  final String archetypeId;
  final double score;       // 0.000 – 1.000
  final int rank;           // 1–12; 1 = highest
  final DateTime computedAt;
  final Map<String, dynamic>? metadata;  // dominant_genre_id for genre_loyalist

  factory UserArchetype.fromJson(Map<String, dynamic> json) { ... }
}
```

### B2 — Repository (`lib/shared/repositories/archetype_repository.dart`)

```
fetchAllArchetypes()          → List<Archetype>       (cache in memory after first fetch)
fetchUserArchetype(userId)    → (UserArchetype? primary, UserArchetype? secondary)
fetchArchetypeScores(userId)  → List<UserArchetype>   (all 12 rows for most recent computed_at)
fetchArchetypeHistory(userId) → List<UserArchetype>   (rank=1 rows, DESC by computed_at, limit 20)
```

### B3 — Controller (`lib/features/profile/controllers/archetype_controller.dart`)

GetX, `Get.lazyPut(fenix: true)`:
- `Rx<Archetype?> currentArchetype`, `Rx<Archetype?> secondaryArchetype`
- `RxList<UserArchetype> allScores` — all 12, latest `computed_at` (used by radar chart)
- `RxList<UserArchetype> history`
- `RxBool isLoading`
- `loadForUser(String userId)` — fetches reference data + user archetypes, populates observables

**Registration (fix #11):** Add `Get.lazyPut<ArchetypeController>(() => ArchetypeController(), fenix: true)` to `AppBinding` (or equivalent binding file used by other profile controllers).

### B4 — ArchetypeBadge (`lib/features/profile/widgets/archetype_badge.dart`)

Two modes controlled by `compact` bool parameter:
- **Full** (own profile, `compact: false`): `Icon` + `displayName` (bold) + `tagline` (subtitle); dual archetype = two `ArchetypeBadge` chips with "+" `Text` between them
- **Compact** (friend list/cards, `compact: true`): `Icon` + `displayName` only, single line
- **Placeholder** (archetype is null): "Still Exploring..." italic label

Tappable in full mode → `Get.bottomSheet(ArchetypeDetailSheet(...))`. Compact mode is display-only.

Use `Archetype.resolvedDisplayName(userArchetype?.metadata)` for the label text to handle Genre Loyalist dynamic names.

### B5 — ArchetypeDetailSheet (`lib/features/profile/widgets/archetype_detail_sheet.dart`)

Bottom sheet — use `Get.bottomSheet(Container(decoration: BoxDecoration(...)))` pattern (no `isScrollControlled`, no `backgroundColor: transparent`).

- Header: archetype icon (large) + resolved name + color accent chip
- Body: full description text
- `ArchetypeRadarChart(scores: controller.allScores, archetypes: controller.allArchetypes)`
- `ArchetypeHistoryTimeline(history: controller.history)`

**No `Obx` wrapping the entire sheet** — pass data as constructor params to avoid sheet dismissal during animation.

### B6 — ArchetypeRadarChart (`lib/features/profile/widgets/archetype_radar_chart.dart`)

Use `fl_chart`'s `RadarChart` widget (already in pubspec: `fl_chart: ^0.69.0` — fix #12, no custom painter needed):

```dart
RadarChart(
  RadarChartData(
    dataSets: [
      RadarDataSet(
        dataEntries: scores.map((s) => RadarEntry(value: s.score)).toList(),
        fillColor: archetypeColor.withOpacity(0.3),
        borderColor: archetypeColor,
      ),
    ],
    radarShape: RadarShape.polygon,
    titleTextStyle: TextStyle(fontSize: 9),
    getTitle: (index, angle) => RadarChartTitle(text: shortLabels[index]),
    tickCount: 4,
    ticksTextStyle: TextStyle(fontSize: 0, color: Colors.transparent),
  ),
)
```

`shortLabels` is a 12-element list of abbreviated archetype names ordered to match the `allScores` list sorted by `archetypes.sort_order`.

### B7 — ArchetypeHistoryTimeline (`lib/features/profile/widgets/archetype_history_timeline.dart`)

Scrollable `ListView` of past `user_archetypes` rows (rank = 1 only, most recent first, max 10 entries):
- Each row: date chip + archetype icon + resolved name
- Latest row highlighted with archetype color accent

---

## Track C: Integration

### C1 — Profile Screen

- Add `ArchetypeBadge(compact: false)` below display name in profile header.
- On `initState` / `onInit`: call `ArchetypeController.loadForUser(userId)`.
- Works for own profile AND friend profile views.
- On friend profile: pass `showPinToggle: false` to `ArchetypeDetailSheet`.

### C2 — Friend List Items & Friend Profile Cards

- Add `ArchetypeBadge(compact: true)` as subtitle widget on existing friend list tiles.
- Source: join `users.primary_archetype` + `archetypes.display_name` + `archetypes.icon_name` in the existing friend query — **single extra join, no extra round-trip**.
- `FriendController` friend model needs `primaryArchetypeId` field added; `Archetype` reference data loaded once via `ArchetypeController.fetchAllArchetypes()`.

---

## Files to Touch

**Backend — new:**
- `050_create_archetypes_tables.sql` — tables, seed, RLS, user columns
- `051_create_archetype_scoring_functions.sql` — 12 helpers + orchestrator + trigger + `get_active_user_ids_90d`
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
- Profile screen: `ArchetypeBadge` in header
- Friend list screen + friend profile card: compact `ArchetypeBadge`
- `FriendController` / friend model: add `primaryArchetypeId`
- App binding: register `ArchetypeController`

---

## Key Constraints

- **All 12 scores inserted per computation** — radar chart requires the full dataset
- **`user_archetypes` INSERT/UPDATE/DELETE: service_role only** — no client writes
- **`compute_user_archetype` returns `archetype_result`** — Edge Function handles notification, no pg_net
- **Minimum threshold:** >= 5 completed titles AND >= 20 TV episodes watched (rolling 90 days)
- **Dual archetype:** top two within 0.05 gap; "+" connector; max 2 displayed
- **Pin:** prevents `users.primary_archetype` update; scoring still runs and writes new rows
- **Season Slayer:** uses watched/started ratio per title, not watched/total-series-episodes
- **Genre Loyalist display:** dynamic label composed on frontend from `metadata.dominant_genre_id`
- **Radar chart:** `fl_chart` `RadarChart` widget (already in pubspec)
- **No file > 300 lines** — scoring split into 12 helper functions; orchestrator ~80 lines
- **`ON CONFLICT DO NOTHING`** on `user_archetypes` INSERT
- **Trigger OLD guard:** `TG_OP = 'UPDATE' AND OLD.watched IS TRUE` before skipping
- **Batch user query:** dedicated `get_active_user_ids_90d()` RPC, not nested PostgREST join
- **Quiz (Viewing Style Quiz):** SKIPPED for v1
- **`verify_jwt: false`** on `compute-archetypes` Edge Function; validate service_role key manually

---

## Previous Plan

**Watch Party Sync** — Complete (2026-02-22)
**Advanced Stats Dashboard v1.1** — Complete (2026-02-19)
**Advanced Stats Dashboard v1.0** — Complete (2026-02-19)
**Pre-Launch Hardening** — Complete (2026-02-19)
