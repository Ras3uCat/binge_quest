-- ============================================================
-- Migration 046: fix_stats_dashboard_v1
--
-- Fixes applied:
--   A1  Scope: include co-curator watchlists via watchlist_members (status='accepted')
--   A2  get_user_stats totals: add COALESCE on number_of_episodes; apply scope fix
--   A3  'all' time window: was structurally OK but absorbed into full rewrite
--   A4  Episode pace: divide by calendar days in window, not active days
--   A5  Completion count: proxy completed_at via MAX(watched_at) within window
--   A6  Replace watch_time_trend with watch_time_by_weekday (Sun–Sat, 7 rows)
--       + current_week_activity (7 booleans, current calendar week, always)
--
-- Because the return shape of get_stats_dashboard changes (trend → weekday),
-- both functions are DROPped and re-CREATEd in one transaction.
-- ============================================================

-- ── Drop old versions ─────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_stats_dashboard(uuid, text);
DROP FUNCTION IF EXISTS public.get_user_stats(uuid);


-- ══════════════════════════════════════════════════════════════════════════
-- get_user_stats(p_user_id uuid)
--
-- Returns lifetime aggregate stats for a user.
-- Scope: watchlists owned by user OR where user is an accepted co-curator.
-- ══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_user_stats(p_user_id uuid)
RETURNS TABLE(
  items_completed   bigint,
  minutes_watched   bigint,
  movies_completed  bigint,
  shows_completed   bigint,
  episodes_watched  bigint,
  total_movies      bigint,
  total_shows       bigint,
  total_episodes    bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH

  -- A1 fix: owned watchlists UNION co-curator watchlists (accepted)
  user_watchlists AS (
    SELECT id AS watchlist_id
    FROM   watchlists
    WHERE  user_id = p_user_id

    UNION

    SELECT watchlist_id
    FROM   watchlist_members
    WHERE  user_id = p_user_id
      AND  status  = 'accepted'
  ),

  user_watchlist_items AS (
    SELECT wi.id, wi.tmdb_id, wi.media_type
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),

  movie_stats AS (
    SELECT
      COUNT(*)::BIGINT                                     AS completed_count,
      COALESCE(SUM(cc.total_runtime_minutes), 0)::BIGINT  AS total_minutes
    FROM   user_watchlist_items uwi
    JOIN   watch_progress wp
           ON wp.watchlist_item_id = uwi.id
    JOIN   content_cache cc
           ON cc.tmdb_id    = uwi.tmdb_id
          AND cc.media_type = 'movie'
    WHERE  uwi.media_type         = 'movie'
      AND  wp.episode_cache_id    IS NULL
      AND  wp.watched              = true
  ),

  episode_stats AS (
    SELECT
      COUNT(*)::BIGINT                                     AS watched_count,
      COALESCE(SUM(cce.runtime_minutes), 0)::BIGINT       AS total_minutes
    FROM   user_watchlist_items uwi
    JOIN   watch_progress wp
           ON wp.watchlist_item_id = uwi.id
    JOIN   content_cache_episodes cce
           ON cce.id = wp.episode_cache_id
    WHERE  wp.watched = true
  ),

  completed_shows AS (
    SELECT COUNT(DISTINCT uwi.id)::BIGINT AS count
    FROM   user_watchlist_items uwi
    WHERE  uwi.media_type = 'tv'
      AND  NOT EXISTS (
             SELECT 1
             FROM   watch_progress wp
             WHERE  wp.watchlist_item_id = uwi.id
               AND  wp.watched = false
           )
      AND  EXISTS (
             SELECT 1
             FROM   watch_progress wp
             WHERE  wp.watchlist_item_id = uwi.id
           )
  ),

  total_movies_cte AS (
    SELECT COUNT(*)::BIGINT AS count
    FROM   user_watchlist_items
    WHERE  media_type = 'movie'
  ),

  total_shows_cte AS (
    SELECT COUNT(*)::BIGINT AS count
    FROM   user_watchlist_items
    WHERE  media_type = 'tv'
  ),

  -- A2 fix: COALESCE(number_of_episodes, 0) to handle NULL rows in content_cache
  total_episodes_cte AS (
    SELECT COALESCE(SUM(COALESCE(cc.number_of_episodes, 0)), 0)::BIGINT AS count
    FROM   user_watchlist_items uwi
    JOIN   content_cache cc
           ON cc.tmdb_id    = uwi.tmdb_id
          AND cc.media_type = 'tv'
    WHERE  uwi.media_type = 'tv'
  )

  SELECT
    (SELECT completed_count FROM movie_stats) + (SELECT count FROM completed_shows),
    (SELECT total_minutes   FROM movie_stats) + (SELECT total_minutes FROM episode_stats),
    (SELECT completed_count FROM movie_stats),
    (SELECT count           FROM completed_shows),
    (SELECT watched_count   FROM episode_stats),
    (SELECT count           FROM total_movies_cte),
    (SELECT count           FROM total_shows_cte),
    (SELECT count           FROM total_episodes_cte);
END;
$$;


-- ══════════════════════════════════════════════════════════════════════════
-- get_stats_dashboard(p_user_id uuid, p_time_window text)
--
-- Returns a rich JSONB stats object.
-- p_time_window: 'week' | 'month' | 'year' | 'all'
--
-- Scope:  watchlists owned by user OR where user is accepted co-curator.
-- Progress: ALL watch_progress rows for items on those watchlists,
--           regardless of who logged them.
-- ══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_stats_dashboard(p_user_id uuid, p_time_window text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_cutoff          timestamptz;
  v_days_in_window  int;

  v_summary         jsonb;
  v_weekday         jsonb;
  v_current_week    jsonb;
  v_genres          jsonb;
  v_peak_hours      jsonb;
  v_streaks         jsonb;
  v_pace            jsonb;
BEGIN
  -- ── Auth guard ────────────────────────────────────────────────────────────
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- ── Resolve time window ───────────────────────────────────────────────────
  -- A3 fix: 'all' → no cutoff (NULL). Use explicit CASE, no ELSE that sets
  --         a restrictive interval.
  CASE p_time_window
    WHEN 'week'  THEN v_cutoff := now() - interval '7 days';   v_days_in_window := 7;
    WHEN 'month' THEN v_cutoff := now() - interval '30 days';  v_days_in_window := 30;
    WHEN 'year'  THEN v_cutoff := now() - interval '365 days'; v_days_in_window := 365;
    ELSE              v_cutoff := NULL;                         v_days_in_window := NULL;  -- 'all'
  END CASE;

  -- ── Scoped watchlist items (owned + co-curator) ───────────────────────────
  -- Materialised as a CTE inside each query block (PL/pgSQL can't share CTEs
  -- across statements, so we inline the union pattern per-query).

  -- ── Summary ───────────────────────────────────────────────────────────────
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id, wi.media_type, wi.tmdb_id
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),
  -- A5 fix: completed_at proxy — item is "completed in window" when its
  --         last non-backfill progress entry falls within the window.
  completed_movies AS (
    SELECT COUNT(DISTINCT uwi.id)::int AS cnt
    FROM   uwi
    JOIN   watch_progress wp ON wp.watchlist_item_id = uwi.id
    WHERE  uwi.media_type      = 'movie'
      AND  wp.watched           = true
      AND  wp.episode_cache_id IS NULL
      AND  wp.is_backfill       = false
      AND  (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  ),
  completed_shows AS (
    -- A show is completed-in-window if: no unwatched episodes AND
    -- the most recent watched_at entry is within the window.
    SELECT COUNT(DISTINCT uwi.id)::int AS cnt
    FROM   uwi
    WHERE  uwi.media_type = 'tv'
      AND  NOT EXISTS (
             SELECT 1 FROM watch_progress wp2
             WHERE  wp2.watchlist_item_id = uwi.id AND wp2.watched = false
           )
      AND  EXISTS (
             SELECT 1 FROM watch_progress wp3
             WHERE  wp3.watchlist_item_id = uwi.id
               AND  wp3.watched            = true
               AND  wp3.is_backfill        = false
               AND  (v_cutoff IS NULL OR wp3.watched_at >= v_cutoff)
           )
  ),
  base_agg AS (
    SELECT
      COALESCE(SUM(wp.minutes_watched), 0)::int                                    AS minutes_watched,
      COUNT(DISTINCT wi.id)::int                                                   AS total_items,
      COUNT(*) FILTER (WHERE wp.episode_cache_id IS NOT NULL AND wp.watched = true)::int
                                                                                   AS episodes_watched
    FROM   uwi wi
    JOIN   watch_progress wp ON wp.watchlist_item_id = wi.id
    WHERE  wp.is_backfill = false
      AND  (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  )
  SELECT jsonb_build_object(
    'minutes_watched',  (SELECT minutes_watched  FROM base_agg),
    'total_items',      (SELECT total_items      FROM base_agg),
    'episodes_watched', (SELECT episodes_watched FROM base_agg),
    'movies_completed', (SELECT cnt              FROM completed_movies),
    'shows_completed',  (SELECT cnt              FROM completed_shows),
    'items_completed',  (SELECT cnt FROM completed_movies) + (SELECT cnt FROM completed_shows)
  )
  INTO v_summary;

  -- ── Watch time by weekday (A6) ────────────────────────────────────────────
  -- 7 rows Sun–Sat (DOW 0–6), 0 for inactive days.
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),
  activity AS (
    SELECT
      EXTRACT(DOW FROM wp.watched_at)::int AS dow,
      SUM(wp.minutes_watched)::int         AS minutes
    FROM   watch_progress wp
    JOIN   uwi ON uwi.id = wp.watchlist_item_id
    WHERE  wp.is_backfill = false
      AND  (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
    GROUP BY EXTRACT(DOW FROM wp.watched_at)::int
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'weekday',  d.dow,
      'day_name', CASE d.dow
                    WHEN 0 THEN 'Sun'
                    WHEN 1 THEN 'Mon'
                    WHEN 2 THEN 'Tue'
                    WHEN 3 THEN 'Wed'
                    WHEN 4 THEN 'Thu'
                    WHEN 5 THEN 'Fri'
                    WHEN 6 THEN 'Sat'
                  END,
      'minutes',  COALESCE(a.minutes, 0)
    )
    ORDER BY d.dow
  )
  INTO v_weekday
  FROM   generate_series(0, 6) AS d(dow)
  LEFT JOIN activity a ON a.dow = d.dow;

  v_weekday := COALESCE(v_weekday, '[]'::jsonb);

  -- ── Current week activity (A6) ────────────────────────────────────────────
  -- 7 booleans (Sun–Sat) for the CURRENT calendar week, regardless of
  -- p_time_window. Drives streak dot visualisation.
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),
  week_start AS (
    -- Sunday of the current calendar week
    SELECT date_trunc('week', now() AT TIME ZONE 'UTC')::date - interval '1 day' AS sun
  ),
  active_dows AS (
    SELECT DISTINCT EXTRACT(DOW FROM wp.watched_at)::int AS dow
    FROM   watch_progress wp
    JOIN   uwi ON uwi.id = wp.watchlist_item_id
    WHERE  wp.is_backfill = false
      AND  wp.watched_at  >= (SELECT sun FROM week_start)
      AND  wp.watched_at  <  (SELECT sun FROM week_start) + interval '7 days'
  )
  SELECT jsonb_agg(
    (d.dow IN (SELECT dow FROM active_dows))
    ORDER BY d.dow
  )
  INTO v_current_week
  FROM generate_series(0, 6) AS d(dow);

  v_current_week := COALESCE(v_current_week, '[false,false,false,false,false,false,false]'::jsonb);

  -- ── Genre distribution ────────────────────────────────────────────────────
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id, wi.tmdb_id, wi.media_type
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'genre_id', gid,
      'minutes',  genre_minutes,
      'count',    item_count
    )
    ORDER BY genre_minutes DESC
  )
  INTO v_genres
  FROM (
    SELECT
      gid,
      SUM(wp.minutes_watched)::int AS genre_minutes,
      COUNT(DISTINCT uwi.id)::int  AS item_count
    FROM   watch_progress wp
    JOIN   uwi            ON uwi.id = wp.watchlist_item_id
    JOIN   content_cache  cc
           ON cc.tmdb_id    = uwi.tmdb_id
          AND cc.media_type = uwi.media_type
    CROSS JOIN LATERAL unnest(cc.genre_ids) AS gid
    WHERE  wp.is_backfill = false
      AND  (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
    GROUP BY gid
  ) g;

  v_genres := COALESCE(v_genres, '[]'::jsonb);

  -- ── Peak hours ────────────────────────────────────────────────────────────
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),
  hours AS (
    SELECT generate_series(0, 23) AS hour
  ),
  activity AS (
    SELECT
      EXTRACT(HOUR FROM wp.watched_at)::int AS hour,
      SUM(wp.minutes_watched)::int          AS minutes
    FROM   watch_progress wp
    JOIN   uwi ON uwi.id = wp.watchlist_item_id
    WHERE  wp.is_backfill = false
      AND  (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
    GROUP BY EXTRACT(HOUR FROM wp.watched_at)::int
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'hour',    h.hour,
      'minutes', COALESCE(a.minutes, 0)
    )
    ORDER BY h.hour
  )
  INTO v_peak_hours
  FROM   hours h
  LEFT JOIN activity a ON a.hour = h.hour;

  -- ── Streaks ───────────────────────────────────────────────────────────────
  -- Streak is lifetime (not time-windowed) — reflects actual viewing habit.
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),
  watch_dates AS (
    SELECT DISTINCT date_trunc('day', wp.watched_at)::date AS watch_day
    FROM   watch_progress wp
    JOIN   uwi ON uwi.id = wp.watchlist_item_id
    WHERE  wp.is_backfill = false
  ),
  numbered AS (
    SELECT
      watch_day,
      watch_day - (row_number() OVER (ORDER BY watch_day))::int AS grp
    FROM watch_dates
  ),
  streak_groups AS (
    SELECT
      grp,
      MIN(watch_day) AS streak_start,
      MAX(watch_day) AS streak_end,
      COUNT(*)::int  AS streak_len
    FROM numbered
    GROUP BY grp
  ),
  longest AS (
    SELECT MAX(streak_len) AS longest_streak FROM streak_groups
  ),
  current_s AS (
    SELECT COALESCE(
      (SELECT streak_len FROM streak_groups
       WHERE  streak_end >= current_date - 1
       ORDER BY streak_end DESC
       LIMIT 1),
      0
    ) AS current_streak
  )
  SELECT jsonb_build_object(
    'current_streak', (SELECT current_streak  FROM current_s),
    'longest_streak', (SELECT COALESCE(longest_streak, 0) FROM longest)
  )
  INTO v_streaks;

  -- ── Episode pace (A4 fix) ─────────────────────────────────────────────────
  -- Denominator = calendar days in the window (not active days).
  -- For 'all': use span from first to last watched entry (min 1 day).
  WITH user_watchlists AS (
    SELECT id AS watchlist_id FROM watchlists WHERE user_id = p_user_id
    UNION
    SELECT watchlist_id FROM watchlist_members WHERE user_id = p_user_id AND status = 'accepted'
  ),
  uwi AS (
    SELECT wi.id
    FROM   watchlist_items wi
    JOIN   user_watchlists uw ON uw.watchlist_id = wi.watchlist_id
  ),
  pace_data AS (
    SELECT
      COUNT(*) FILTER (WHERE wp.episode_cache_id IS NOT NULL AND wp.watched = true)::numeric AS eps_watched,
      GREATEST(1,
        EXTRACT(DAY FROM now() - MIN(wp.watched_at))::int
      )::numeric AS span_days
    FROM   watch_progress wp
    JOIN   uwi ON uwi.id = wp.watchlist_item_id
    WHERE  wp.is_backfill = false
      AND  (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  )
  SELECT jsonb_build_object(
    'episodes_per_day', ROUND(
      eps_watched / NULLIF(
        CASE p_time_window
          WHEN 'week'  THEN 7
          WHEN 'month' THEN 30
          WHEN 'year'  THEN 365
          ELSE span_days
        END,
        0
      )::numeric,
      1
    ),
    'days_in_window', CASE p_time_window
                        WHEN 'week'  THEN 7
                        WHEN 'month' THEN 30
                        WHEN 'year'  THEN 365
                        ELSE (SELECT span_days::int FROM pace_data)
                      END
  )
  INTO v_pace
  FROM pace_data;

  -- ── Assemble and return ───────────────────────────────────────────────────
  RETURN jsonb_build_object(
    'summary',                v_summary,
    'watch_time_by_weekday',  v_weekday,
    'current_week_activity',  v_current_week,
    'genre_distribution',     v_genres,
    'peak_hours',             v_peak_hours,
    'streaks',                v_streaks,
    'episode_pace',           v_pace
  );
END;
$$;


-- ── Grants ────────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.get_stats_dashboard(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_stats(uuid)            TO authenticated;
