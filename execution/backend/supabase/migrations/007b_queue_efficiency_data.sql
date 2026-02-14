-- BingeQuest Queue Efficiency Data Migration
-- Run this MANUALLY in Supabase SQL Editor after 007_queue_efficiency_schema.sql

-- ============================================
-- BACKFILL LAST ACTIVITY DATA
-- ============================================

-- Initialize last_activity_at from existing watch_progress data
UPDATE public.watchlist_items wi
SET last_activity_at = (
    SELECT MAX(watched_at)
    FROM public.watch_progress wp
    WHERE wp.watchlist_item_id = wi.id
    AND wp.watched_at IS NOT NULL
);

-- For items with no activity, set to added_at
UPDATE public.watchlist_items
SET last_activity_at = added_at
WHERE last_activity_at IS NULL;

-- ============================================
-- CREATE TRIGGER (requires DROP first)
-- ============================================

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trigger_update_last_activity ON public.watch_progress;

-- Create trigger on watch_progress updates
CREATE TRIGGER trigger_update_last_activity
    AFTER UPDATE OF watched ON public.watch_progress
    FOR EACH ROW
    WHEN (NEW.watched IS DISTINCT FROM OLD.watched)
    EXECUTE FUNCTION update_item_last_activity();
