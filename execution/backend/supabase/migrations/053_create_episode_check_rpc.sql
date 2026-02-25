-- Migration: 053_create_episode_check_rpc.sql
-- Feature: New Episode Notifications + Episode Cache Refresh
-- Created: 2026-02-24
-- Note: notification_preferences.new_episodes already exists (DEFAULT true); no ALTER needed.

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
    WHERE cce.season_number > 0
      AND cce.air_date BETWEEN (NOW() - INTERVAL '90 days') AND (NOW() + INTERVAL '14 days')
    ORDER BY cce.tmdb_id, cce.season_number DESC
  ),
  last_detections AS (
    -- Most recent detection per show+season for dedup guard
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
  JOIN show_info si       ON si.tmdb_id = a.tmdb_id
  JOIN active_seasons ase ON ase.tmdb_id = a.tmdb_id
  LEFT JOIN last_detections ld
    ON ld.tmdb_id = a.tmdb_id AND ld.season_number = ase.season_number
  ORDER BY a.user_count DESC
  LIMIT limit_count;
$$;
