-- Migration: 021_top_10_rpcs.sql
-- Description: RPC functions for BingeQuest Top 10 feature
-- Created: 2026-02-01

--------------------------------------------------------------------------------
-- get_top_10_by_users()
--
-- Returns the top 10 content items ranked by the number of unique users who
-- have added them to their watchlist. This reflects the most popular content
-- across the BingeQuest community based on watchlist additions.
--
-- Joins: watchlist_items -> watchlists (for user_id) -> content_cache (for metadata)
--
-- Returns: tmdb_id, media_type, title, poster_path, user_count
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_top_10_by_users()
RETURNS TABLE(
  tmdb_id INTEGER,
  media_type TEXT,
  title TEXT,
  poster_path TEXT,
  user_count BIGINT
) AS $$
  SELECT
    wi.tmdb_id,
    wi.media_type,
    cc.title,
    cc.poster_path,
    COUNT(DISTINCT w.user_id) as user_count
  FROM watchlist_items wi
  JOIN watchlists w ON wi.watchlist_id = w.id
  JOIN content_cache cc ON wi.tmdb_id = cc.tmdb_id AND wi.media_type = cc.media_type
  GROUP BY wi.tmdb_id, wi.media_type, cc.title, cc.poster_path
  ORDER BY user_count DESC
  LIMIT 10;
$$ LANGUAGE SQL STABLE;

GRANT EXECUTE ON FUNCTION get_top_10_by_users() TO authenticated, anon;

--------------------------------------------------------------------------------
-- get_top_10_by_rating()
--
-- Returns the top 10 content items ranked by average BingeQuest user rating.
-- Content must have a minimum of 2 reviews to qualify, ensuring statistical
-- relevance. Results are ordered by average rating (descending), with review
-- count as a secondary sort for ties.
--
-- Joins: reviews -> content_cache (for metadata)
--
-- Returns: tmdb_id, media_type, title, poster_path, average_rating, review_count
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_top_10_by_rating()
RETURNS TABLE(
  tmdb_id INTEGER,
  media_type TEXT,
  title TEXT,
  poster_path TEXT,
  average_rating NUMERIC,
  review_count BIGINT
) AS $$
  SELECT
    r.tmdb_id,
    r.media_type,
    cc.title,
    cc.poster_path,
    ROUND(AVG(r.rating)::NUMERIC, 1) as average_rating,
    COUNT(*) as review_count
  FROM reviews r
  LEFT JOIN content_cache cc ON r.tmdb_id = cc.tmdb_id AND r.media_type = cc.media_type
  GROUP BY r.tmdb_id, r.media_type, cc.title, cc.poster_path
  HAVING COUNT(*) >= 2
  ORDER BY average_rating DESC, review_count DESC
  LIMIT 10;
$$ LANGUAGE SQL STABLE;

GRANT EXECUTE ON FUNCTION get_top_10_by_rating() TO authenticated, anon;
