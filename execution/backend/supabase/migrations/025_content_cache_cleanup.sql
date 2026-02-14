-- Migration: 025_content_cache_cleanup.sql
-- Purpose: Create function for cleaning up stale content_cache entries that are
--          no longer in any watchlist and haven't been accessed recently.
--          Can be called by cron job or Supabase Edge Function.
-- Created: 2026-02-02

-- Function to cleanup stale content not in any watchlist
CREATE OR REPLACE FUNCTION cleanup_stale_content_cache(days_threshold INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM content_cache
  WHERE tmdb_id NOT IN (SELECT DISTINCT tmdb_id FROM watchlist_items)
    AND last_accessed_at < NOW() - (days_threshold || ' days')::INTERVAL;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to service role only (for scheduled jobs)
GRANT EXECUTE ON FUNCTION cleanup_stale_content_cache TO service_role;
