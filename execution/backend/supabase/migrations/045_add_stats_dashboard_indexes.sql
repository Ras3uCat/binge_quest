-- Migration 045: Partial indexes for stats dashboard queries
-- Note: watch_progress has no user_id column; user scope is via watchlist_item_id → watchlists.
-- idx_watch_progress_item_watched_at: covers per-item time-series lookups.
-- idx_watch_progress_watched_at_partial: covers range scans where join provides user filter.
-- Both exclude backfill rows to keep index size small and match all analytics queries.

CREATE INDEX IF NOT EXISTS idx_watch_progress_item_watched_at
  ON watch_progress(watchlist_item_id, watched_at)
  WHERE is_backfill = false;

CREATE INDEX IF NOT EXISTS idx_watch_progress_watched_at_partial
  ON watch_progress(watched_at)
  WHERE is_backfill = false;
