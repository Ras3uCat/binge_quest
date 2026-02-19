-- Migration 041: Drop duplicate index on watch_progress
-- Both idx_watch_progress_item_watched and idx_watch_progress_watched are
-- identical: CREATE INDEX ... USING btree (watchlist_item_id, watched)
-- Keeping idx_watch_progress_watched; dropping the duplicate.

DROP INDEX IF EXISTS public.idx_watch_progress_item_watched;
