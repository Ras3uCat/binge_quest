-- BingeQuest Migration: Remove redundant columns from watch_progress
-- Episode metadata now comes from content_cache_episodes join
-- Movie runtime comes from content_cache join via watchlist_items
--
-- IMPORTANT: Run the episode backfill BEFORE this migration!
-- All watch_progress entries for TV episodes must have episode_cache_id set.

-- Drop redundant columns from watch_progress
ALTER TABLE public.watch_progress
DROP COLUMN IF EXISTS season_number,
DROP COLUMN IF EXISTS episode_number,
DROP COLUMN IF EXISTS runtime_minutes;

-- The watch_progress table now only contains:
-- - id (PK)
-- - watchlist_item_id (FK to watchlist_items)
-- - episode_cache_id (FK to content_cache_episodes, NULL for movies)
-- - minutes_watched (for partial progress tracking)
-- - watched (boolean)
-- - watched_at (timestamp)
--
-- All other data comes from joins:
-- - Episode metadata: content_cache_episodes (via episode_cache_id)
-- - Movie runtime: content_cache (via watchlist_items)
