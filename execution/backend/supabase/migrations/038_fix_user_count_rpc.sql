-- Migration: 038_fix_user_count_rpc.sql
-- Purpose: Update get_user_count_for_content to include co-owners of shared watchlists.

CREATE OR REPLACE FUNCTION get_user_count_for_content(
  p_tmdb_id INTEGER,
  p_media_type TEXT
)
RETURNS INTEGER AS $$
WITH relevant_watchlists AS (
    SELECT watchlist_id
    FROM watchlist_items
    WHERE tmdb_id = p_tmdb_id AND media_type = p_media_type
)
SELECT COUNT(DISTINCT user_id)::INTEGER
FROM (
    -- 1. Owners
    SELECT w.user_id
    FROM watchlists w
    JOIN relevant_watchlists rw ON w.id = rw.watchlist_id
    
    UNION
    
    -- 2. Accepted Co-owners
    SELECT wm.user_id
    FROM watchlist_members wm
    JOIN relevant_watchlists rw ON wm.watchlist_id = rw.watchlist_id
    WHERE wm.status = 'accepted'
) all_users;
$$ LANGUAGE SQL STABLE;
