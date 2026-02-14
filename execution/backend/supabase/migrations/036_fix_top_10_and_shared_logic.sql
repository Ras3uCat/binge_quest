-- Migration: 036_fix_top_10_and_shared_logic.sql
-- Purpose:
-- 1. Update get_top_10_by_users to count both owners and accepted co-curators (members).
-- 2. Add get_user_shared_watchlist_ids to identify shared lists efficiently.

-- 1. Fix Top 10 Scoring Logic
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
    -- Count distinct users (owner + members) who have this item in their list
    COUNT(DISTINCT u.user_id) as user_count,
    cc.streaming_providers
  FROM watchlist_items wi
  JOIN (
    -- Combine owners and accepted members for each watchlist
    SELECT id as watchlist_id, user_id FROM watchlists
    UNION ALL
    SELECT watchlist_id, user_id FROM watchlist_members WHERE status = 'accepted'
  ) u ON wi.watchlist_id = u.watchlist_id
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = wi.tmdb_id
    AND cc.media_type = wi.media_type
  GROUP BY wi.tmdb_id, wi.media_type, cc.title, cc.poster_path, cc.streaming_providers
  ORDER BY user_count DESC
  LIMIT 10;
$$ LANGUAGE SQL STABLE;

-- 2. Add Helper RPC for Shared Watchlists
-- Returns IDs of watchlists that are "shared" involving the current user (either as owner or member)
CREATE OR REPLACE FUNCTION get_user_shared_watchlist_ids()
RETURNS SETOF uuid AS $$
BEGIN
  RETURN QUERY
  -- Watchlists owned by current user that have at least one accepted member
  SELECT w.id
  FROM watchlists w
  JOIN watchlist_members wm ON w.id = wm.watchlist_id
  WHERE w.user_id = auth.uid() AND wm.status = 'accepted'
  
  UNION
  
  -- Watchlists where current user is an accepted member
  SELECT wm.watchlist_id
  FROM watchlist_members wm
  WHERE wm.user_id = auth.uid() AND wm.status = 'accepted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_top_10_by_users() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_user_shared_watchlist_ids() TO authenticated;
