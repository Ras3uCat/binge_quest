-- ============================================
-- Migration: Optimized User Stats RPC
-- Purpose: Single query for all profile stats (fixes N+1 pattern)
-- ============================================

CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE(
  items_completed BIGINT,
  minutes_watched BIGINT,
  movies_completed BIGINT,
  shows_completed BIGINT,
  episodes_watched BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH user_watchlist_items AS (
    -- Get all watchlist items for user
    SELECT wi.id, wi.tmdb_id, wi.media_type
    FROM watchlist_items wi
    JOIN watchlists w ON w.id = wi.watchlist_id
    WHERE w.user_id = p_user_id
  ),
  movie_stats AS (
    -- Movies: count watched and sum runtime from content_cache
    SELECT
      COUNT(*)::BIGINT as completed_count,
      COALESCE(SUM(cc.total_runtime_minutes), 0)::BIGINT as total_minutes
    FROM user_watchlist_items uwi
    JOIN watch_progress wp ON wp.watchlist_item_id = uwi.id
    JOIN content_cache cc ON cc.tmdb_id = uwi.tmdb_id AND cc.media_type = 'movie'
    WHERE uwi.media_type = 'movie'
      AND wp.episode_cache_id IS NULL
      AND wp.watched = true
  ),
  episode_stats AS (
    -- TV Episodes: count watched and sum runtime from content_cache_episodes
    SELECT
      COUNT(*)::BIGINT as watched_count,
      COALESCE(SUM(cce.runtime_minutes), 0)::BIGINT as total_minutes
    FROM user_watchlist_items uwi
    JOIN watch_progress wp ON wp.watchlist_item_id = uwi.id
    JOIN content_cache_episodes cce ON cce.id = wp.episode_cache_id
    WHERE wp.watched = true
  ),
  completed_shows AS (
    -- TV Shows fully completed (no unwatched episodes)
    SELECT COUNT(DISTINCT uwi.id)::BIGINT as count
    FROM user_watchlist_items uwi
    WHERE uwi.media_type = 'tv'
      AND NOT EXISTS (
        SELECT 1 FROM watch_progress wp
        WHERE wp.watchlist_item_id = uwi.id
          AND wp.watched = false
      )
      AND EXISTS (
        SELECT 1 FROM watch_progress wp
        WHERE wp.watchlist_item_id = uwi.id
      )
  )
  SELECT
    (SELECT completed_count FROM movie_stats) + (SELECT count FROM completed_shows),
    (SELECT total_minutes FROM movie_stats) + (SELECT total_minutes FROM episode_stats),
    (SELECT completed_count FROM movie_stats),
    (SELECT count FROM completed_shows),
    (SELECT watched_count FROM episode_stats);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION get_user_stats(UUID) TO authenticated;

-- Add index to speed up the query
CREATE INDEX IF NOT EXISTS idx_watch_progress_watched
ON watch_progress(watchlist_item_id, watched);
