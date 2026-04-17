-- Fix: watch_progress rows not created when check-new-episodes cron inserts new episodes.
-- Root cause: the nightly cron upserts content_cache_episodes but never creates
--   watch_progress rows — users with the show on their watchlist can't see or mark
--   newly added episodes until they manually open the item detail screen.
--
-- Part 1: One-time backfill for all existing gaps across all TV shows.
-- Part 2: Reusable function called by check-new-episodes after each episode upsert.

-- Part 1: Backfill all missing watch_progress rows globally.
-- Safe to run multiple times — NOT EXISTS prevents duplicates.
INSERT INTO watch_progress (watchlist_item_id, episode_cache_id, watched, minutes_watched, is_backfill)
SELECT
  wi.id      AS watchlist_item_id,
  cce.id     AS episode_cache_id,
  false      AS watched,
  0          AS minutes_watched,
  true       AS is_backfill
FROM content_cache_episodes cce
JOIN watchlist_items wi ON wi.tmdb_id = cce.tmdb_id AND wi.media_type = 'tv'
WHERE cce.season_number > 0  -- skip specials/season 0
  AND NOT EXISTS (
    SELECT 1 FROM watch_progress wp
    WHERE wp.watchlist_item_id = wi.id
      AND wp.episode_cache_id = cce.id
  );

-- Part 2: Function called by check-new-episodes after each season upsert.
-- Inserts missing watch_progress rows for one show+season, for all users who
-- have that show on any of their watchlists.
CREATE OR REPLACE FUNCTION public.ensure_episode_progress(
  p_tmdb_id      integer,
  p_season_number integer
)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  WITH inserted AS (
    INSERT INTO watch_progress (watchlist_item_id, episode_cache_id, watched, minutes_watched, is_backfill)
    SELECT
      wi.id  AS watchlist_item_id,
      cce.id AS episode_cache_id,
      false  AS watched,
      0      AS minutes_watched,
      true   AS is_backfill
    FROM content_cache_episodes cce
    JOIN watchlist_items wi ON wi.tmdb_id = cce.tmdb_id AND wi.media_type = 'tv'
    WHERE cce.tmdb_id = p_tmdb_id
      AND cce.season_number = p_season_number
      AND cce.season_number > 0
      AND NOT EXISTS (
        SELECT 1 FROM watch_progress wp
        WHERE wp.watchlist_item_id = wi.id
          AND wp.episode_cache_id = cce.id
      )
    RETURNING 1
  )
  SELECT COUNT(*)::integer FROM inserted;
$$;
