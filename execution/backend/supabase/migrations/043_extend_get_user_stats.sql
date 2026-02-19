-- Migration 043: Extend get_user_stats() with total_movies, total_shows, total_episodes
-- Must DROP and recreate because the return type (OUT columns) changes.

DROP FUNCTION IF EXISTS public.get_user_stats(uuid);

CREATE FUNCTION public.get_user_stats(p_user_id uuid)
RETURNS TABLE(
  items_completed    bigint,
  minutes_watched    bigint,
  movies_completed   bigint,
  shows_completed    bigint,
  episodes_watched   bigint,
  total_movies       bigint,
  total_shows        bigint,
  total_episodes     bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH user_watchlist_items AS (
    SELECT wi.id, wi.tmdb_id, wi.media_type
    FROM watchlist_items wi
    JOIN watchlists w ON w.id = wi.watchlist_id
    WHERE w.user_id = p_user_id
  ),
  movie_stats AS (
    SELECT
      COUNT(*)::BIGINT                                       AS completed_count,
      COALESCE(SUM(cc.total_runtime_minutes), 0)::BIGINT    AS total_minutes
    FROM user_watchlist_items uwi
    JOIN watch_progress wp ON wp.watchlist_item_id = uwi.id
    JOIN content_cache cc  ON cc.tmdb_id = uwi.tmdb_id AND cc.media_type = 'movie'
    WHERE uwi.media_type = 'movie'
      AND wp.episode_cache_id IS NULL
      AND wp.watched = true
  ),
  episode_stats AS (
    SELECT
      COUNT(*)::BIGINT                                    AS watched_count,
      COALESCE(SUM(cce.runtime_minutes), 0)::BIGINT      AS total_minutes
    FROM user_watchlist_items uwi
    JOIN watch_progress wp  ON wp.watchlist_item_id = uwi.id
    JOIN content_cache_episodes cce ON cce.id = wp.episode_cache_id
    WHERE wp.watched = true
  ),
  completed_shows AS (
    SELECT COUNT(DISTINCT uwi.id)::BIGINT AS count
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
  ),
  total_movies_cte AS (
    SELECT COUNT(*)::BIGINT AS count
    FROM user_watchlist_items
    WHERE media_type = 'movie'
  ),
  total_shows_cte AS (
    SELECT COUNT(*)::BIGINT AS count
    FROM user_watchlist_items
    WHERE media_type = 'tv'
  ),
  total_episodes_cte AS (
    -- Sum number_of_episodes from content_cache for all TV items in the user's watchlists.
    -- content_cache.number_of_episodes is the TMDB total episode count for a show.
    SELECT COALESCE(SUM(cc.number_of_episodes), 0)::BIGINT AS count
    FROM user_watchlist_items uwi
    JOIN content_cache cc ON cc.tmdb_id = uwi.tmdb_id AND cc.media_type = 'tv'
    WHERE uwi.media_type = 'tv'
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
