-- ============================================================
-- Migration 051: create_archetype_scoring_functions
--
-- Structure:
--   1. archetype_result composite type (return type for orchestrator)
--   2. 12 _score_* SECURITY DEFINER helper functions
--   3. compute_user_archetype orchestrator
--   4. get_active_user_ids_90d  (batch helper for Edge Function)
--   5. on_watch_progress_archetype_check trigger function
--   6. Trigger on watch_progress
-- ============================================================


-- ── 0. Composite return type ────────────────────────────────────────────────
CREATE TYPE public.archetype_result AS (
  new_archetype  text,
  prev_archetype text
);


-- ── 1. Weekend Warrior ──────────────────────────────────────────────────────
-- Signal: >= 70% of watched_at fall on Fri 18:00 – Sun midnight (user's tz)
CREATE OR REPLACE FUNCTION public._score_weekend_warrior(
  p_user_id uuid,
  p_window  timestamptz,
  p_tz      text
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    LEAST(1.0, ROUND(
      COUNT(*) FILTER (
        WHERE
          -- isodow: 5=Fri 6=Sat 7=Sun
          EXTRACT(isodow FROM (wp.watched_at AT TIME ZONE p_tz)) IN (5,6,7)
          AND (
            EXTRACT(isodow FROM (wp.watched_at AT TIME ZONE p_tz)) IN (6,7)
            OR EXTRACT(hour  FROM (wp.watched_at AT TIME ZONE p_tz)) >= 18
          )
      )::numeric / NULLIF(COUNT(*), 0),
    3))::numeric(4,3),
  0.000);
$$;


-- ── 2. Genre Loyalist ───────────────────────────────────────────────────────
-- Signal: max single-genre share of completed titles.
-- Returns both score AND dominant_genre_id (stored in metadata for frontend).
CREATE OR REPLACE FUNCTION public._score_genre_loyalist(
  p_user_id uuid,
  p_window  timestamptz,
  OUT score            numeric(4,3),
  OUT dominant_genre_id integer
) RETURNS RECORD
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  WITH genre_counts AS (
    SELECT g.genre_id, COUNT(*) AS cnt
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    JOIN content_cache    cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    JOIN LATERAL unnest(cc.genre_ids) AS g(genre_id) ON true
    WHERE w.user_id = p_user_id
      AND wp.watched = true
      AND wp.watched_at >= p_window
    GROUP BY g.genre_id
  ),
  totals AS (SELECT SUM(cnt) AS t FROM genre_counts),
  top    AS (SELECT genre_id, cnt FROM genre_counts ORDER BY cnt DESC LIMIT 1)
  SELECT
    COALESCE(LEAST(1.0, ROUND(top.cnt::numeric / NULLIF(totals.t, 0), 3))::numeric(4,3), 0.000),
    top.genre_id
  INTO score, dominant_genre_id
  FROM top, totals;

  score := COALESCE(score, 0.000);
END;
$$;


-- ── 3. Sampler Surfer ───────────────────────────────────────────────────────
-- Signal: >= 60% of started TV titles have <= 2 episodes watched (min 10 started).
CREATE OR REPLACE FUNCTION public._score_sampler_surfer(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH started AS (
    SELECT wi.tmdb_id, COUNT(wp.id) AS ep_count
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id
      AND wi.media_type = 'tv'
      AND wp.watched_at >= p_window
    GROUP BY wi.tmdb_id
  )
  SELECT CASE
    WHEN COUNT(*) < 10 THEN 0.000
    ELSE COALESCE(
      LEAST(1.0, ROUND(
        COUNT(*) FILTER (WHERE ep_count <= 2)::numeric / NULLIF(COUNT(*), 0),
      3))::numeric(4,3),
      0.000)
  END
  FROM started;
$$;


-- ── 4. Season Slayer ────────────────────────────────────────────────────────
-- Signal: avg(watched_eps / started_eps) per title. Measures how often
-- they finish what they start — not vs. total series length.
CREATE OR REPLACE FUNCTION public._score_season_slayer(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH title_stats AS (
    SELECT
      wi.tmdb_id,
      COUNT(*) FILTER (WHERE wp.watched = true)::numeric AS watched_eps,
      COUNT(*)::numeric                                  AS started_eps
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id
      AND wi.media_type = 'tv'
      AND wp.watched_at >= p_window
    GROUP BY wi.tmdb_id
  )
  SELECT COALESCE(
    LEAST(1.0, ROUND(
      AVG(watched_eps / NULLIF(started_eps, 0)),
    3))::numeric(4,3),
  0.000)
  FROM title_stats;
$$;


-- ── 5. Backlog Excavator ────────────────────────────────────────────────────
-- Signal: avg days between added_at and first watch. 180-day avg → score 1.0.
CREATE OR REPLACE FUNCTION public._score_backlog_excavator(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH first_watch AS (
    SELECT wi.added_at, MIN(wp.watched_at) AS first_watched_at
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id
      AND wp.watched_at >= p_window
    GROUP BY wi.id, wi.added_at
  )
  -- EXTRACT(epoch) returns double precision — cast to numeric before ROUND
  SELECT COALESCE(
    GREATEST(0.0,
      LEAST(1.0, ROUND(
        (AVG(EXTRACT(epoch FROM (first_watched_at - added_at)) / 86400.0) / 180.0)::numeric,
      3)))::numeric(4,3),
  0.000)
  FROM first_watch;
$$;


-- ── 6. Midnight Drifter ─────────────────────────────────────────────────────
-- Signal: >= 50% of watched_at between 22:00 and 04:00 (user's tz).
CREATE OR REPLACE FUNCTION public._score_midnight_drifter(
  p_user_id uuid,
  p_window  timestamptz,
  p_tz      text
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  -- NOT BETWEEN 4 AND 21 covers hours 0,1,2,3 and 22,23 → 10pm–4am
  SELECT COALESCE(
    LEAST(1.0, ROUND(
      COUNT(*) FILTER (
        WHERE EXTRACT(hour FROM (wp.watched_at AT TIME ZONE p_tz))
              NOT BETWEEN 4 AND 21
      )::numeric / NULLIF(COUNT(*), 0),
    3))::numeric(4,3),
  0.000)
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists       w  ON w.id  = wi.watchlist_id
  WHERE w.user_id = p_user_id
    AND wp.watched_at >= p_window;
$$;


-- ── 7. Social Curator ───────────────────────────────────────────────────────
-- Signal: review count vs. 3× platform average. Top reviewers approach 1.0.
CREATE OR REPLACE FUNCTION public._score_social_curator(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_count    numeric;
  v_platform_avg  numeric;
BEGIN
  SELECT COUNT(*)::numeric INTO v_user_count
  FROM reviews
  WHERE user_id = p_user_id AND created_at >= p_window;

  SELECT COALESCE(AVG(cnt), 1) INTO v_platform_avg
  FROM (
    SELECT COUNT(*) AS cnt
    FROM reviews
    WHERE created_at >= p_window
    GROUP BY user_id
  ) sub;

  RETURN COALESCE(
    LEAST(1.0, ROUND(v_user_count / NULLIF(v_platform_avg * 3, 0), 3))::numeric(4,3),
  0.000);
END;
$$;


-- ── 8. Binge Sprinter ───────────────────────────────────────────────────────
-- Signal: avg session cluster size (consecutive eps within 90 min). /5 → 1.0.
CREATE OR REPLACE FUNCTION public._score_binge_sprinter(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH ordered AS (
    SELECT
      wp.watched_at,
      wi.tmdb_id,
      LAG(wp.watched_at) OVER (PARTITION BY wi.tmdb_id ORDER BY wp.watched_at) AS prev_at
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    WHERE w.user_id = p_user_id
      AND wp.watched_at >= p_window
      AND wi.media_type = 'tv'
  ),
  sessions AS (
    SELECT
      tmdb_id,
      watched_at,
      SUM(CASE
        WHEN prev_at IS NULL
          OR EXTRACT(epoch FROM (watched_at - prev_at)) > 5400   -- 90 min gap
        THEN 1 ELSE 0
      END) OVER (PARTITION BY tmdb_id ORDER BY watched_at) AS session_id
    FROM ordered
  ),
  cluster_sizes AS (
    SELECT COUNT(*) AS sz FROM sessions GROUP BY tmdb_id, session_id
  )
  -- avg cluster of 5 episodes normalises to 1.0
  SELECT COALESCE(
    LEAST(1.0, ROUND(AVG(sz) / 5.0, 3))::numeric(4,3),
  0.000)
  FROM cluster_sizes;
$$;


-- ── 9. Mood Surfer ──────────────────────────────────────────────────────────
-- Signal: Shannon entropy of genre distribution per week, avg across weeks.
-- LN(12) ≈ 2.485 is theoretical max (12 equal genres across all watches).
CREATE OR REPLACE FUNCTION public._score_mood_surfer(
  p_user_id uuid,
  p_window  timestamptz,
  p_tz      text
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH weekly_genres AS (
    SELECT
      DATE_TRUNC('week', wp.watched_at AT TIME ZONE p_tz) AS week,
      g.genre_id,
      COUNT(*) AS cnt
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    JOIN content_cache    cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    JOIN LATERAL unnest(cc.genre_ids) AS g(genre_id) ON true
    WHERE w.user_id = p_user_id
      AND wp.watched_at >= p_window
    GROUP BY week, g.genre_id
  ),
  week_totals AS (
    SELECT week, SUM(cnt) AS total FROM weekly_genres GROUP BY week
  ),
  entropy AS (
    SELECT
      wg.week,
      -SUM((wg.cnt::numeric / wt.total) * LN(wg.cnt::numeric / wt.total)) AS h
    FROM weekly_genres wg
    JOIN week_totals   wt USING (week)
    GROUP BY wg.week
  )
  SELECT COALESCE(
    LEAST(1.0, ROUND(AVG(h) / LN(12.0), 3))::numeric(4,3),
  0.000)
  FROM entropy;
$$;


-- ── 10. Finish-First Strategist ─────────────────────────────────────────────
-- Signal: for each session in the window, what fraction of that show was
-- already done? High avg means they pick up nearly-complete shows.
-- Uses LATERAL to avoid GROUP BY complexity with two counting joins.
CREATE OR REPLACE FUNCTION public._score_finish_first(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH sessions AS (
    SELECT
      counts.prior_watched,
      counts.total_started
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists       w  ON w.id  = wi.watchlist_id
    CROSS JOIN LATERAL (
      SELECT
        COUNT(*) FILTER (
          WHERE wpp.watched = true AND wpp.watched_at < wp.watched_at
        )::numeric AS prior_watched,
        COUNT(*)::numeric AS total_started
      FROM watch_progress wpp
      WHERE wpp.watchlist_item_id = wp.watchlist_item_id
    ) counts
    WHERE w.user_id = p_user_id
      AND wp.watched_at >= p_window
  )
  SELECT COALESCE(
    LEAST(1.0, ROUND(
      AVG(prior_watched / NULLIF(total_started, 0)),
    3))::numeric(4,3),
  0.000)
  FROM sessions;
$$;


-- ── 11. Trend Chaser ────────────────────────────────────────────────────────
-- Signal: avg popularity_percentile of titles added in the window.
-- Join on (tmdb_id, media_type) — never on float equality (fix #2).
CREATE OR REPLACE FUNCTION public._score_trend_chaser(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH pop_ranked AS (
    SELECT
      tmdb_id,
      media_type,
      PERCENT_RANK() OVER (ORDER BY popularity_score) AS percentile
    FROM content_cache
  )
  -- PERCENT_RANK() returns double precision — cast to numeric before ROUND
  SELECT COALESCE(
    LEAST(1.0, ROUND(AVG(pr.percentile)::numeric, 3))::numeric(4,3),
  0.000)
  FROM watchlist_items wi
  JOIN watchlists  w  ON w.id  = wi.watchlist_id
  JOIN pop_ranked  pr ON pr.tmdb_id = wi.tmdb_id AND pr.media_type = wi.media_type
  WHERE w.user_id = p_user_id
    AND wi.added_at >= p_window;
$$;


-- ── 12. Deep Cut Explorer ───────────────────────────────────────────────────
-- Signal: avg(1 - popularity_percentile) + 0.2 bonus for titles > 5 years old.
CREATE OR REPLACE FUNCTION public._score_deep_cut(
  p_user_id uuid,
  p_window  timestamptz
) RETURNS numeric(4,3)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH pop_ranked AS (
    SELECT
      tmdb_id,
      media_type,
      release_date,
      1.0 - PERCENT_RANK() OVER (ORDER BY popularity_score) AS inv_percentile
    FROM content_cache
  )
  -- PERCENT_RANK() returns double precision — cast to numeric before ROUND
  SELECT COALESCE(
    LEAST(1.0, ROUND(
      AVG(pr.inv_percentile
          + CASE WHEN pr.release_date < (now() - interval '5 years') THEN 0.2 ELSE 0 END
      )::numeric,
    3))::numeric(4,3),
  0.000)
  FROM watch_progress wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists       w  ON w.id  = wi.watchlist_id
  JOIN pop_ranked       pr ON pr.tmdb_id = wi.tmdb_id AND pr.media_type = wi.media_type
  WHERE w.user_id = p_user_id
    AND wp.watched_at >= p_window;
$$;


-- ── Orchestrator ────────────────────────────────────────────────────────────
-- Calls all 12 helpers, writes all 12 scores to user_archetypes,
-- updates users.primary_archetype (unless pinned), returns
-- (new_archetype, prev_archetype) for Edge Function notification diff.
CREATE OR REPLACE FUNCTION public.compute_user_archetype(p_user_id uuid)
RETURNS public.archetype_result
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_window       timestamptz := now() - interval '90 days';
  v_tz           text;
  v_completed    int;
  v_eps_watched  int;
  v_now          timestamptz := now();
  v_prev         text;
  v_top1_id      text;
  v_top1_score   numeric(4,3);
  v_top2_id      text;
  v_top2_score   numeric(4,3);
  v_gl_score     numeric(4,3);
  v_gl_genre     integer;
  result         public.archetype_result;
BEGIN
  -- Resolve user timezone (fallback UTC)
  SELECT COALESCE(np.timezone, 'UTC') INTO v_tz
  FROM notification_preferences np
  WHERE np.user_id = p_user_id;
  v_tz := COALESCE(v_tz, 'UTC');

  -- Minimum activity threshold
  SELECT
    COUNT(DISTINCT wi.tmdb_id) FILTER (WHERE wp.watched = true),
    COUNT(*)                   FILTER (WHERE wp.watched = true AND wi.media_type = 'tv')
  INTO v_completed, v_eps_watched
  FROM watch_progress  wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists      w  ON w.id  = wi.watchlist_id
  WHERE w.user_id = p_user_id
    AND wp.watched_at >= v_window;

  IF v_completed < 5 OR v_eps_watched < 20 THEN
    result.new_archetype  := NULL;
    SELECT primary_archetype INTO result.prev_archetype FROM users WHERE id = p_user_id;
    RETURN result;
  END IF;

  -- Run genre loyalist separately to capture dominant_genre_id for metadata
  SELECT s.score, s.dominant_genre_id
  INTO v_gl_score, v_gl_genre
  FROM public._score_genre_loyalist(p_user_id, v_window) s;

  -- Insert all 12 scores. CTE ranks first so window func is never in WHERE (fix #1).
  WITH raw_scores (archetype_id, score) AS (
    VALUES
      ('weekend_warrior'::text,   public._score_weekend_warrior(p_user_id, v_window, v_tz)),
      ('genre_loyalist'::text,    v_gl_score),
      ('sampler_surfer'::text,    public._score_sampler_surfer(p_user_id, v_window)),
      ('season_slayer'::text,     public._score_season_slayer(p_user_id, v_window)),
      ('backlog_excavator'::text, public._score_backlog_excavator(p_user_id, v_window)),
      ('midnight_drifter'::text,  public._score_midnight_drifter(p_user_id, v_window, v_tz)),
      ('social_curator'::text,    public._score_social_curator(p_user_id, v_window)),
      ('binge_sprinter'::text,    public._score_binge_sprinter(p_user_id, v_window)),
      ('mood_surfer'::text,       public._score_mood_surfer(p_user_id, v_window, v_tz)),
      ('finish_first'::text,      public._score_finish_first(p_user_id, v_window)),
      ('trend_chaser'::text,      public._score_trend_chaser(p_user_id, v_window)),
      ('deep_cut'::text,          public._score_deep_cut(p_user_id, v_window))
  ),
  ranked AS (
    SELECT
      archetype_id,
      score,
      RANK() OVER (ORDER BY score DESC)::smallint AS rnk
    FROM raw_scores
  )
  INSERT INTO public.user_archetypes
    (user_id, archetype_id, score, rank, computed_at, metadata)
  SELECT
    p_user_id,
    r.archetype_id,
    r.score,
    r.rnk,
    v_now,
    CASE
      WHEN r.archetype_id = 'genre_loyalist' AND v_gl_genre IS NOT NULL
      THEN jsonb_build_object('dominant_genre_id', v_gl_genre)
      ELSE NULL
    END
  FROM ranked r
  ON CONFLICT (user_id, archetype_id, computed_at) DO NOTHING;

  -- Read back top two scores for this computation
  SELECT archetype_id, score INTO v_top1_id, v_top1_score
  FROM user_archetypes
  WHERE user_id = p_user_id AND computed_at = v_now AND rank = 1
  LIMIT 1;

  SELECT archetype_id, score INTO v_top2_id, v_top2_score
  FROM user_archetypes
  WHERE user_id = p_user_id AND computed_at = v_now AND rank = 2
  LIMIT 1;

  -- Only surface a secondary archetype when the gap is <= 0.05
  IF (v_top1_score - v_top2_score) > 0.05 THEN
    v_top2_id := NULL;
  END IF;

  -- Capture previous primary before overwriting
  SELECT primary_archetype INTO v_prev FROM users WHERE id = p_user_id;

  -- Update denormalized columns unless user has pinned an archetype
  IF NOT EXISTS (
    SELECT 1 FROM user_archetypes
    WHERE user_id = p_user_id AND is_pinned = true
  ) THEN
    UPDATE users SET
      primary_archetype    = v_top1_id,
      secondary_archetype  = v_top2_id,
      archetype_updated_at = v_now
    WHERE id = p_user_id;
  END IF;

  result.new_archetype  := v_top1_id;
  result.prev_archetype := v_prev;
  RETURN result;
END;
$$;


-- ── Batch helper (used by compute-archetypes Edge Function) ─────────────────
CREATE OR REPLACE FUNCTION public.get_active_user_ids_90d()
RETURNS TABLE (user_id uuid)
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT DISTINCT w.user_id
  FROM watch_progress  wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists      w  ON w.id  = wi.watchlist_id
  WHERE wp.watched_at >= now() - interval '90 days';
$$;


-- ── Trigger function ────────────────────────────────────────────────────────
-- Fires after every watch_progress INSERT or UPDATE.
-- Calls compute_user_archetype on every 5th episode completion since last compute.
CREATE OR REPLACE FUNCTION public.on_watch_progress_archetype_check()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id uuid;
  v_count   int;
BEGIN
  -- Only act when an episode transitions to watched = true for the first time
  IF NEW.watched IS NOT TRUE THEN RETURN NEW; END IF;
  -- Guard against UPDATE where it was already true (fix #3: safe for INSERT too)
  IF TG_OP = 'UPDATE' AND OLD.watched IS TRUE THEN RETURN NEW; END IF;

  SELECT w.user_id INTO v_user_id
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE wi.id = NEW.watchlist_item_id;

  IF v_user_id IS NULL THEN RETURN NEW; END IF;

  -- Count completions since last archetype computation
  SELECT COUNT(*) INTO v_count
  FROM watch_progress  wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists      w  ON w.id  = wi.watchlist_id
  WHERE w.user_id = v_user_id
    AND wp.watched = true
    AND wp.watched_at > COALESCE(
      (SELECT MAX(computed_at) FROM user_archetypes WHERE user_id = v_user_id),
      '-infinity'::timestamptz
    );

  -- Recompute on every 5th completion (v_count > 0 guards the 0 % 5 = 0 edge case)
  IF v_count > 0 AND v_count % 5 = 0 THEN
    PERFORM public.compute_user_archetype(v_user_id);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_watch_progress_archetype
  AFTER INSERT OR UPDATE ON public.watch_progress
  FOR EACH ROW EXECUTE FUNCTION public.on_watch_progress_archetype_check();
