-- Migration: 023_content_cache_last_accessed.sql
-- Purpose: Add last_accessed_at column to content_cache for tracking when content
--          was last viewed, enabling efficient cleanup of stale cached data.
-- Created: 2026-02-02

-- Add last_accessed_at column
ALTER TABLE content_cache
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMPTZ DEFAULT NOW();

-- Backfill existing rows with updated_at
UPDATE content_cache
SET last_accessed_at = COALESCE(updated_at, created_at, NOW())
WHERE last_accessed_at IS NULL;

-- Index for cleanup queries
CREATE INDEX IF NOT EXISTS idx_content_cache_cleanup
ON content_cache(last_accessed_at);

-- Function to update last_accessed_at
CREATE OR REPLACE FUNCTION update_content_last_accessed(
  p_tmdb_id INTEGER,
  p_media_type TEXT
)
RETURNS VOID AS $$
BEGIN
  UPDATE content_cache
  SET last_accessed_at = NOW()
  WHERE tmdb_id = p_tmdb_id AND media_type = p_media_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION update_content_last_accessed TO authenticated;
