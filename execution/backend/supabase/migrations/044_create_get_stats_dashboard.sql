-- Migration 044: Create get_stats_dashboard(p_user_id, p_time_window) RPC
-- Returns a single JSONB object with summary, watch_time_trend, genre_distribution,
-- peak_hours, streaks, and episode_pace sections.
-- All time-series queries exclude is_backfill = true rows.
-- Auth guard: raises exception if auth.uid() != p_user_id.

CREATE OR REPLACE FUNCTION public.get_stats_dashboard(
  p_user_id    uuid,
  p_time_window text  -- 'week' | 'month' | 'year' | 'all'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_interval        interval;
  v_cutoff          timestamptz;
  v_days_in_window  int;
  v_group_by        text;

  v_summary         jsonb;
  v_trend           jsonb;
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
  CASE p_time_window
    WHEN 'week'  THEN v_interval := interval '7 days';   v_days_in_window := 7;
    WHEN 'month' THEN v_interval := interval '30 days';  v_days_in_window := 30;
    WHEN 'year'  THEN v_interval := interval '365 days'; v_days_in_window := 365;
    ELSE              v_interval := NULL;                 v_days_in_window := NULL;
  END CASE;

  v_cutoff   := CASE WHEN v_interval IS NOT NULL THEN now() - v_interval ELSE NULL END;
  -- week/month → group by day; year/all → group by week
  v_group_by := CASE WHEN p_time_window IN ('week', 'month') THEN 'day' ELSE 'week' END;

  -- ── Summary ───────────────────────────────────────────────────────────────
  WITH uwi AS (
    SELECT wi.id, wi.media_type, wi.tmdb_id
    FROM watchlist_items wi
    JOIN watchlists wl ON wl.id = wi.watchlist_id
    WHERE wl.user_id = p_user_id
  ),
  completed_movies AS (
    SELECT COUNT(*)::int AS cnt
    FROM uwi
    JOIN watch_progress wp ON wp.watchlist_item_id = uwi.id
    WHERE uwi.media_type = 'movie'
      AND wp.watched = true
      AND wp.episode_cache_id IS NULL
      AND wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  ),
  completed_shows AS (
    SELECT COUNT(DISTINCT uwi.id)::int AS cnt
    FROM uwi
    WHERE uwi.media_type = 'tv'
      AND NOT EXISTS (
        SELECT 1 FROM watch_progress wp2
        WHERE wp2.watchlist_item_id = uwi.id AND wp2.watched = false
      )
      AND EXISTS (
        SELECT 1 FROM watch_progress wp3
        WHERE wp3.watchlist_item_id = uwi.id AND wp3.watched = true
          AND wp3.is_backfill = false
          AND (v_cutoff IS NULL OR wp3.watched_at >= v_cutoff)
      )
  ),
  eps_watched AS (
    SELECT COUNT(*)::int AS cnt
    FROM uwi
    JOIN watch_progress wp ON wp.watchlist_item_id = uwi.id
    WHERE wp.episode_cache_id IS NOT NULL
      AND wp.watched = true
      AND wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  ),
  mins AS (
    SELECT COALESCE(SUM(wp.minutes_watched), 0)::int AS total
    FROM uwi
    JOIN watch_progress wp ON wp.watchlist_item_id = uwi.id
    WHERE wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  ),
  total_items AS (
    SELECT COUNT(DISTINCT uwi.id)::int AS cnt FROM uwi
  )
  SELECT jsonb_build_object(
    'minutes_watched',  (SELECT total FROM mins),
    'items_completed',  (SELECT cnt FROM completed_movies) + (SELECT cnt FROM completed_shows),
    'total_items',      (SELECT cnt FROM total_items),
    'episodes_watched', (SELECT cnt FROM eps_watched),
    'movies_completed', (SELECT cnt FROM completed_movies),
    'shows_completed',  (SELECT cnt FROM completed_shows)
  )
  INTO v_summary;

  -- ── Watch time trend ──────────────────────────────────────────────────────
  SELECT jsonb_agg(
    jsonb_build_object(
      'date',    to_char(bucket, 'YYYY-MM-DD'),
      'minutes', total_minutes
    )
    ORDER BY bucket
  )
  INTO v_trend
  FROM (
    SELECT
      date_trunc(v_group_by, wp.watched_at) AS bucket,
      SUM(wp.minutes_watched)::int          AS total_minutes
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists wl      ON wl.id = wi.watchlist_id
    WHERE wl.user_id = p_user_id
      AND wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
    GROUP BY date_trunc(v_group_by, wp.watched_at)
  ) t;

  v_trend := COALESCE(v_trend, '[]'::jsonb);

  -- ── Genre distribution ────────────────────────────────────────────────────
  -- content_cache.genre_ids is integer[] — unnest to get per-genre rows.
  -- Genre names are resolved client-side from TMDB genre IDs.
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
      COUNT(DISTINCT wi.id)::int   AS item_count
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists wl      ON wl.id = wi.watchlist_id
    JOIN content_cache cc   ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    CROSS JOIN LATERAL unnest(cc.genre_ids) AS gid
    WHERE wl.user_id = p_user_id
      AND wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
    GROUP BY gid
  ) g;

  v_genres := COALESCE(v_genres, '[]'::jsonb);

  -- ── Peak hours (all 24, missing hours filled with 0) ──────────────────────
  WITH hours AS (
    SELECT generate_series(0, 23) AS hour
  ),
  activity AS (
    SELECT
      extract(hour FROM wp.watched_at)::int AS hour,
      SUM(wp.minutes_watched)::int          AS minutes
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists wl      ON wl.id = wi.watchlist_id
    WHERE wl.user_id = p_user_id
      AND wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
    GROUP BY extract(hour FROM wp.watched_at)::int
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'hour',    h.hour,
      'minutes', COALESCE(a.minutes, 0)
    )
    ORDER BY h.hour
  )
  INTO v_peak_hours
  FROM hours h
  LEFT JOIN activity a ON a.hour = h.hour;

  -- ── Streaks (uses all-time data, not window-filtered) ─────────────────────
  WITH watch_dates AS (
    SELECT DISTINCT date_trunc('day', wp.watched_at)::date AS watch_day
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists wl      ON wl.id = wi.watchlist_id
    WHERE wl.user_id = p_user_id
      AND wp.is_backfill = false
  ),
  numbered AS (
    SELECT
      watch_day,
      -- Subtract a sequential row number from each date; rows in the same
      -- consecutive run share the same group value.
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
    -- Current streak: the streak whose last day is today or yesterday
    SELECT COALESCE(
      (SELECT streak_len FROM streak_groups
       WHERE streak_end >= current_date - 1
       ORDER BY streak_end DESC
       LIMIT 1),
      0
    ) AS current_streak
  )
  SELECT jsonb_build_object(
    'current_streak', (SELECT current_streak FROM current_s),
    'longest_streak', (SELECT COALESCE(longest_streak, 0) FROM longest)
  )
  INTO v_streaks;

  -- ── Episode pace ──────────────────────────────────────────────────────────
  WITH pace_data AS (
    SELECT
      COUNT(*) FILTER (WHERE wp.episode_cache_id IS NOT NULL AND wp.watched = true)::numeric AS eps_watched,
      COUNT(DISTINCT date_trunc('day', wp.watched_at)::date)::numeric                        AS active_days
    FROM watch_progress wp
    JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
    JOIN watchlists wl      ON wl.id = wi.watchlist_id
    WHERE wl.user_id = p_user_id
      AND wp.is_backfill = false
      AND (v_cutoff IS NULL OR wp.watched_at >= v_cutoff)
  )
  SELECT jsonb_build_object(
    'episodes_per_day', ROUND(eps_watched / NULLIF(active_days, 0), 1),
    'days_in_window',   COALESCE(
      v_days_in_window,
      -- For 'all': span from first to last active watch day
      (SELECT (MAX(date_trunc('day', wp2.watched_at)::date)
             - MIN(date_trunc('day', wp2.watched_at)::date) + 1)
       FROM watch_progress wp2
       JOIN watchlist_items wi2 ON wi2.id = wp2.watchlist_item_id
       JOIN watchlists wl2      ON wl2.id = wi2.watchlist_id
       WHERE wl2.user_id = p_user_id AND wp2.is_backfill = false)
    )
  )
  INTO v_pace
  FROM pace_data;

  -- ── Assemble final result ─────────────────────────────────────────────────
  RETURN jsonb_build_object(
    'summary',            v_summary,
    'watch_time_trend',   v_trend,
    'genre_distribution', v_genres,
    'peak_hours',         v_peak_hours,
    'streaks',            v_streaks,
    'episode_pace',       v_pace
  );
END;
$$;
