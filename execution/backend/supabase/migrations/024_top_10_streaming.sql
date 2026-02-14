-- Migration: 024_top_10_streaming.sql
-- Purpose: Update Top 10 RPC functions to include streaming_providers data
--          by joining with the content_cache table.
-- Created: 2026-02-02

-- Must drop existing functions first since return type is changing
DROP FUNCTION IF EXISTS get_top_10_by_users();
DROP FUNCTION IF EXISTS get_top_10_by_rating();

-- Recreate get_top_10_by_users with streaming_providers
-- Join watchlists to get user_id, content_cache for title/poster/streaming
CREATE OR REPLACE FUNCTION get_top_10_by_users()
RETURNS TABLE(
  tmdb_id INTEGER,
  media_type TEXT,
  title TEXT,
  poster_path TEXT,
  user_count BIGINT,
  streaming_providers JSONB
) AS $$
  SELECT
    wi.tmdb_id,
    wi.media_type,
    cc.title,
    cc.poster_path,
    COUNT(DISTINCT w.user_id) as user_count,
    cc.streaming_providers
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = wi.tmdb_id
    AND cc.media_type = wi.media_type
  GROUP BY wi.tmdb_id, wi.media_type, cc.title, cc.poster_path, cc.streaming_providers
  ORDER BY user_count DESC
  LIMIT 10;
$$ LANGUAGE SQL STABLE;

-- Recreate get_top_10_by_rating with streaming_providers
-- All metadata comes from content_cache
CREATE OR REPLACE FUNCTION get_top_10_by_rating()
RETURNS TABLE(
  tmdb_id INTEGER,
  media_type TEXT,
  title TEXT,
  poster_path TEXT,
  average_rating NUMERIC,
  review_count BIGINT,
  streaming_providers JSONB
) AS $$
  SELECT
    r.tmdb_id,
    r.media_type,
    cc.title,
    cc.poster_path,
    ROUND(AVG(r.rating)::NUMERIC, 1) as average_rating,
    COUNT(*) as review_count,
    cc.streaming_providers
  FROM reviews r
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = r.tmdb_id
    AND cc.media_type = r.media_type
  GROUP BY r.tmdb_id, r.media_type, cc.title, cc.poster_path, cc.streaming_providers
  HAVING COUNT(*) >= 2
  ORDER BY average_rating DESC, review_count DESC
  LIMIT 10;
$$ LANGUAGE SQL STABLE;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_top_10_by_users() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_top_10_by_rating() TO authenticated, anon;
