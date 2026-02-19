-- Migration: 048_retroactive_backfill_detection
-- Purpose: Retroactively mark watch_progress rows as is_backfill = true
-- where multiple episodes of the same show were bulk-marked within 30 seconds
-- of each other (millisecond-apart timestamps = single bulk insert, not genuine tracking).

UPDATE watch_progress
SET is_backfill = true
WHERE id IN (
  SELECT wp.id
  FROM watch_progress wp
  JOIN watchlist_items wi ON wp.watchlist_item_id = wi.id
  WHERE wp.is_backfill = false
  AND (
    SELECT COUNT(*) FROM watch_progress wp2
    JOIN watchlist_items wi2 ON wp2.watchlist_item_id = wi2.id
    WHERE wi2.watchlist_id = wi.watchlist_id
      AND wi2.tmdb_id = wi.tmdb_id
      AND ABS(EXTRACT(EPOCH FROM (wp2.watched_at - wp.watched_at))) <= 30
      AND wp2.id != wp.id
  ) >= 2
);
