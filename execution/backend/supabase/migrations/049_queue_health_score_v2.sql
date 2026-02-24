-- ============================================
-- Migration 049: Queue Health Score v2
-- Purpose: Replace completion-rate base with ratio-based stale penalty.
--   OLD: score = completionRate - (stale × 2) + min(recent × 5, 25)
--        → tanks when user adds new content (lowers completionRate)
--   NEW: score = 100 - round(staleRatio × 60) + min(recent × 8, 30)
--        staleRatio = stale / max(started, 1)
--        started    = items with ANY watch_progress (not counting never-touched wishlist items)
--        never-started items → display as "active" (neutral, not penalized)
-- ============================================

DROP FUNCTION IF EXISTS calculate_queue_efficiency(UUID);
DROP FUNCTION IF EXISTS get_dashboard_data(UUID, UUID);

-- ============================================
-- calculate_queue_efficiency (fallback path)
-- ============================================
CREATE FUNCTION calculate_queue_efficiency(p_user_id UUID)
RETURNS TABLE (
    total_items INTEGER,
    completed_items INTEGER,
    active_items INTEGER,
    idle_items INTEGER,
    stale_items INTEGER,
    completion_rate NUMERIC,
    efficiency_score INTEGER,
    recent_completions INTEGER,
    excluded_items INTEGER
) AS $$
DECLARE
    v_total INTEGER := 0;
    v_completed INTEGER := 0;
    v_active INTEGER := 0;
    v_idle INTEGER := 0;
    v_stale INTEGER := 0;
    v_never_started INTEGER := 0;
    v_recent INTEGER := 0;
    v_excluded INTEGER := 0;
    v_started INTEGER := 0;
    v_stale_ratio NUMERIC := 0;
    v_completion_rate NUMERIC := 0;
    v_score INTEGER := 0;
BEGIN
    -- Count excluded (unavailable) items
    SELECT COUNT(*) INTO v_excluded
    FROM public.watchlist_items wi
    JOIN public.watchlists w ON w.id = wi.watchlist_id
    JOIN public.content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE w.user_id = p_user_id
      AND NOT is_content_available(cc.release_date, cc.status, cc.streaming_providers);

    -- Count items by status (available content only).
    -- never_started: available, not completed, has NO watch_progress rows.
    -- These show as "active" in the UI but are excluded from stale ratio.
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE get_item_status(wi.id) = 'completed'),
        COUNT(*) FILTER (WHERE get_item_status(wi.id) = 'active'),
        COUNT(*) FILTER (WHERE get_item_status(wi.id) = 'idle'),
        COUNT(*) FILTER (WHERE get_item_status(wi.id) = 'stale'),
        COUNT(*) FILTER (
            WHERE get_item_status(wi.id) != 'completed'
              AND NOT EXISTS (
                SELECT 1 FROM public.watch_progress wp WHERE wp.watchlist_item_id = wi.id
              )
        )
    INTO v_total, v_completed, v_active, v_idle, v_stale, v_never_started
    FROM public.watchlist_items wi
    JOIN public.watchlists w ON w.id = wi.watchlist_id
    JOIN public.content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE w.user_id = p_user_id
      AND is_content_available(cc.release_date, cc.status, cc.streaming_providers);

    -- Recent completions (last 7 days)
    SELECT COUNT(DISTINCT wi.id) INTO v_recent
    FROM public.watchlist_items wi
    JOIN public.watchlists w ON w.id = wi.watchlist_id
    JOIN public.watch_progress wp ON wp.watchlist_item_id = wi.id
    JOIN public.content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE w.user_id = p_user_id
      AND wp.watched_at >= NOW() - INTERVAL '7 days'
      AND get_completion_percentage(wi.id) >= 100
      AND is_content_available(cc.release_date, cc.status, cc.streaming_providers);

    -- Completion rate (display only — no longer used in score)
    IF v_total > 0 THEN
        v_completion_rate := ROUND((v_completed::NUMERIC / v_total::NUMERIC) * 100, 1);
    END IF;

    -- started = items with any watch activity (active + idle + stale minus never-started)
    -- Note: get_item_status uses COALESCE(last_activity, NOW()) so never-started appear in v_active
    v_started := v_total - v_completed - v_never_started;

    -- Stale ratio: only measures abandonment of items you actually started
    IF v_started > 0 THEN
        v_stale_ratio := v_stale::NUMERIC / v_started::NUMERIC;
    END IF;

    -- Score: 100 base, penalise abandonment, reward momentum
    v_score := GREATEST(0, LEAST(100,
        ROUND(100 - (v_stale_ratio * 60) + LEAST(v_recent * 8, 30))
    ))::INTEGER;

    RETURN QUERY SELECT
        v_total,
        v_completed,
        v_active,
        v_idle,
        v_stale,
        v_completion_rate,
        v_score,
        v_recent,
        v_excluded;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- get_dashboard_data (primary path)
-- ============================================
CREATE FUNCTION get_dashboard_data(
  p_user_id UUID,
  p_watchlist_id UUID
)
RETURNS TABLE(
  items JSONB,
  total_items BIGINT,
  completed_items BIGINT,
  in_progress_items BIGINT,
  total_runtime_minutes BIGINT,
  watched_runtime_minutes BIGINT,
  efficiency_score INT,
  active_count BIGINT,
  idle_count BIGINT,
  stale_count BIGINT,
  completed_count BIGINT,
  recent_completions BIGINT,
  excluded_count BIGINT
) AS $$
DECLARE
  v_items JSONB;
  v_total BIGINT := 0;
  v_completed BIGINT := 0;
  v_in_progress BIGINT := 0;
  v_total_runtime BIGINT := 0;
  v_watched_runtime BIGINT := 0;
  v_active BIGINT := 0;
  v_idle BIGINT := 0;
  v_stale BIGINT := 0;
  v_recent BIGINT := 0;
  v_excluded BIGINT := 0;
  v_score INT := 0;
  v_eff_total BIGINT := 0;
  v_eff_completed BIGINT := 0;
  v_never_started BIGINT := 0;
  v_started BIGINT := 0;
  v_stale_ratio FLOAT := 0;
BEGIN
  -- Items JSON (unchanged — shows everything in UI)
  SELECT COALESCE(jsonb_agg(item_data), '[]'::jsonb)
  INTO v_items
  FROM (
    SELECT jsonb_build_object(
      'id', wi.id,
      'watchlist_id', wi.watchlist_id,
      'tmdb_id', wi.tmdb_id,
      'media_type', wi.media_type,
      'added_at', wi.added_at,
      'content', jsonb_build_object(
        'title', cc.title,
        'poster_path', cc.poster_path,
        'backdrop_path', cc.backdrop_path,
        'overview', cc.overview,
        'vote_average', cc.vote_average,
        'popularity_score', cc.popularity_score,
        'genre_ids', cc.genre_ids,
        'status', cc.status,
        'release_date', cc.release_date,
        'total_runtime_minutes', cc.total_runtime_minutes,
        'episode_runtime', cc.episode_runtime,
        'number_of_seasons', cc.number_of_seasons,
        'number_of_episodes', cc.number_of_episodes,
        'streaming_providers', cc.streaming_providers,
        'cast_members', cc.cast_members
      ),
      'progress', (
        SELECT jsonb_build_object(
          'total_entries', COUNT(*),
          'watched_entries', COUNT(*) FILTER (WHERE wp.watched = true),
          'minutes_watched', COALESCE(SUM(
            CASE
              WHEN wp.watched = true THEN
                CASE WHEN wp.episode_cache_id IS NOT NULL THEN cce.runtime_minutes
                ELSE cc.total_runtime_minutes END
              ELSE wp.minutes_watched
            END
          ), 0),
          'last_activity_at', MAX(wp.watched_at),
          'next_episode_runtime', (
            SELECT cce2.runtime_minutes
            FROM watch_progress wp2
            JOIN content_cache_episodes cce2 ON cce2.id = wp2.episode_cache_id
            WHERE wp2.watchlist_item_id = wi.id AND wp2.watched = false
            ORDER BY cce2.season_number, cce2.episode_number
            LIMIT 1
          ),
          'next_episode_remaining', (
            SELECT cce2.runtime_minutes - COALESCE(wp2.minutes_watched, 0)
            FROM watch_progress wp2
            JOIN content_cache_episodes cce2 ON cce2.id = wp2.episode_cache_id
            WHERE wp2.watchlist_item_id = wi.id AND wp2.watched = false
            ORDER BY cce2.season_number, cce2.episode_number
            LIMIT 1
          ),
          'has_partial_progress', EXISTS(
            SELECT 1 FROM watch_progress wp2
            WHERE wp2.watchlist_item_id = wi.id
            AND wp2.watched = false AND wp2.minutes_watched > 0
          )
        )
        FROM watch_progress wp
        LEFT JOIN content_cache_episodes cce ON cce.id = wp.episode_cache_id
        WHERE wp.watchlist_item_id = wi.id
      )
    ) as item_data
    FROM watchlist_items wi
    JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE wi.watchlist_id = p_watchlist_id
    ORDER BY wi.added_at DESC
  ) subq;

  -- Overall display stats (ALL items)
  SELECT
    COUNT(*),
    COUNT(*) FILTER (WHERE is_completed),
    COUNT(*) FILTER (WHERE NOT is_completed),
    COALESCE(SUM(total_runtime), 0),
    COALESCE(SUM(watched_runtime), 0)
  INTO v_total, v_completed, v_in_progress, v_total_runtime, v_watched_runtime
  FROM (
    SELECT
      wi.id,
      cc.total_runtime_minutes as total_runtime,
      COALESCE((
        SELECT SUM(
          CASE
            WHEN wp.watched = true THEN
              CASE WHEN wp.episode_cache_id IS NOT NULL THEN cce.runtime_minutes
              ELSE cc.total_runtime_minutes END
            ELSE wp.minutes_watched
          END
        )
        FROM watch_progress wp
        LEFT JOIN content_cache_episodes cce ON cce.id = wp.episode_cache_id
        WHERE wp.watchlist_item_id = wi.id
      ), 0) as watched_runtime,
      NOT EXISTS (
        SELECT 1 FROM watch_progress wp
        WHERE wp.watchlist_item_id = wi.id AND wp.watched = false
      ) AND EXISTS (
        SELECT 1 FROM watch_progress wp WHERE wp.watchlist_item_id = wi.id
      ) as is_completed
    FROM watchlist_items wi
    JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE wi.watchlist_id = p_watchlist_id
  ) stats;

  -- Efficiency stats (available items only).
  -- KEY CHANGE: days_since_activity = NULL means never started (no watch_progress).
  -- Never-started items are shown as "active" in the UI (neutral, aspirational)
  -- but excluded from the stale ratio so adding content never lowers your score.
  SELECT
    -- active: recently watched OR never started (wishlist items — shown as active, not penalised)
    COUNT(*) FILTER (WHERE NOT is_completed AND (never_started OR days_since_activity < 7)),
    -- idle: started, not touched in 7–30 days
    COUNT(*) FILTER (WHERE NOT is_completed AND NOT never_started AND days_since_activity >= 7 AND days_since_activity < 30),
    -- stale: started but abandoned 30+ days ago
    COUNT(*) FILTER (WHERE NOT is_completed AND NOT never_started AND days_since_activity >= 30),
    -- recent completions: finished within last 7 days
    COUNT(*) FILTER (WHERE is_completed AND days_since_activity < 7),
    COUNT(*),
    COUNT(*) FILTER (WHERE is_completed),
    -- never started count (for internal score calc — not returned)
    COUNT(*) FILTER (WHERE NOT is_completed AND never_started)
  INTO v_active, v_idle, v_stale, v_recent, v_eff_total, v_eff_completed, v_never_started
  FROM (
    SELECT
      wi.id,
      NOT EXISTS (
        SELECT 1 FROM watch_progress wp
        WHERE wp.watchlist_item_id = wi.id AND wp.watched = false
      ) AND EXISTS (
        SELECT 1 FROM watch_progress wp WHERE wp.watchlist_item_id = wi.id
      ) as is_completed,
      -- NULL = never started; INT = days since last watch activity
      EXTRACT(DAY FROM NOW() - (
        SELECT MAX(wp.watched_at) FROM watch_progress wp WHERE wp.watchlist_item_id = wi.id
      ))::INT as days_since_activity,
      NOT EXISTS (
        SELECT 1 FROM watch_progress wp WHERE wp.watchlist_item_id = wi.id
      ) as never_started
    FROM watchlist_items wi
    JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE wi.watchlist_id = p_watchlist_id
      AND is_content_available(cc.release_date, cc.status, cc.streaming_providers)
  ) eff_stats;

  -- Count excluded items
  SELECT COUNT(*) INTO v_excluded
  FROM watchlist_items wi
  JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
  WHERE wi.watchlist_id = p_watchlist_id
    AND NOT is_content_available(cc.release_date, cc.status, cc.streaming_providers);

  -- Score: ratio-based, ignores wishlist size
  -- started = eff items with any watch_progress (active + idle + stale − never_started)
  v_started := v_eff_total - v_eff_completed - v_never_started;

  IF v_started > 0 THEN
    v_stale_ratio := v_stale::FLOAT / v_started;
  END IF;

  v_score := GREATEST(0, LEAST(100,
    ROUND(100 - (v_stale_ratio * 60) + LEAST(v_recent * 8, 30))
  ));

  RETURN QUERY SELECT
    v_items,
    v_total,
    v_completed,
    v_in_progress,
    v_total_runtime,
    v_watched_runtime,
    v_score,
    v_active,
    v_idle,
    v_stale,
    v_eff_completed,
    v_recent,
    v_excluded;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Restore grants
GRANT EXECUTE ON FUNCTION get_dashboard_data(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_queue_efficiency(UUID) TO authenticated;
