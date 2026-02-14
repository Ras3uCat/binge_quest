-- ============================================
-- Migration: Dashboard Data RPC
-- Purpose: Single query for all dashboard data (reduces 4 round trips to 1)
-- ============================================

CREATE OR REPLACE FUNCTION get_dashboard_data(
  p_user_id UUID,
  p_watchlist_id UUID
)
RETURNS TABLE(
  -- Watchlist items as JSONB array
  items JSONB,
  -- Stats
  total_items BIGINT,
  completed_items BIGINT,
  in_progress_items BIGINT,
  total_runtime_minutes BIGINT,
  watched_runtime_minutes BIGINT,
  -- Queue health
  efficiency_score INT,
  active_count BIGINT,
  idle_count BIGINT,
  stale_count BIGINT,
  completed_count BIGINT,
  recent_completions BIGINT
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
  v_score INT := 0;
BEGIN
  -- Get watchlist items with content cache data
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
              WHEN wp.episode_cache_id IS NOT NULL THEN cce.runtime_minutes
              ELSE cc.total_runtime_minutes
            END
          ) FILTER (WHERE wp.watched = true), 0),
          'last_activity_at', MAX(wp.watched_at)
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

  -- Calculate stats
  SELECT
    COUNT(*),
    COUNT(*) FILTER (WHERE is_completed),
    COUNT(*) FILTER (WHERE NOT is_completed),
    COALESCE(SUM(total_runtime), 0),
    COALESCE(SUM(watched_runtime), 0),
    COUNT(*) FILTER (WHERE NOT is_completed AND days_since_activity < 7),
    COUNT(*) FILTER (WHERE NOT is_completed AND days_since_activity >= 7 AND days_since_activity < 30),
    COUNT(*) FILTER (WHERE NOT is_completed AND days_since_activity >= 30),
    COUNT(*) FILTER (WHERE is_completed AND days_since_activity < 7)
  INTO v_total, v_completed, v_in_progress, v_total_runtime, v_watched_runtime,
       v_active, v_idle, v_stale, v_recent
  FROM (
    SELECT
      wi.id,
      cc.total_runtime_minutes as total_runtime,
      COALESCE((
        SELECT SUM(
          CASE
            WHEN wp.episode_cache_id IS NOT NULL THEN cce.runtime_minutes
            ELSE cc.total_runtime_minutes
          END
        )
        FROM watch_progress wp
        LEFT JOIN content_cache_episodes cce ON cce.id = wp.episode_cache_id
        WHERE wp.watchlist_item_id = wi.id AND wp.watched = true
      ), 0) as watched_runtime,
      NOT EXISTS (
        SELECT 1 FROM watch_progress wp
        WHERE wp.watchlist_item_id = wi.id AND wp.watched = false
      ) AND EXISTS (
        SELECT 1 FROM watch_progress wp WHERE wp.watchlist_item_id = wi.id
      ) as is_completed,
      COALESCE(
        EXTRACT(DAY FROM NOW() - (
          SELECT MAX(wp.watched_at) FROM watch_progress wp WHERE wp.watchlist_item_id = wi.id
        ))::INT,
        999
      ) as days_since_activity
    FROM watchlist_items wi
    JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    WHERE wi.watchlist_id = p_watchlist_id
  ) stats;

  -- Calculate efficiency score
  -- Base: completion rate, Penalty: -2 per stale, Bonus: +5 per recent (max 25)
  IF v_total > 0 THEN
    v_score := GREATEST(0, LEAST(100,
      ((v_completed::FLOAT / v_total) * 100)::INT
      - (v_stale * 2)::INT
      + LEAST(v_recent * 5, 25)::INT
    ));
  END IF;

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
    v_completed,
    v_recent;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant access
GRANT EXECUTE ON FUNCTION get_dashboard_data(UUID, UUID) TO authenticated;

-- Add index to speed up the query
CREATE INDEX IF NOT EXISTS idx_watchlist_items_watchlist_id
ON watchlist_items(watchlist_id);

CREATE INDEX IF NOT EXISTS idx_watch_progress_item_watched
ON watch_progress(watchlist_item_id, watched);
