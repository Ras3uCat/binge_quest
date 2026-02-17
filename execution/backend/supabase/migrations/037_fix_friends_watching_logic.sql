-- Migration: 037_fix_friends_watching_logic.sql
-- Purpose: 
-- 1. Ensure `share_watching_activity` column exists on users table.
-- 2. Update `get_friends_watching_content` to include co-owners of shared watchlists.

-- 1. Ensure privacy column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'share_watching_activity'
    ) THEN
        ALTER TABLE public.users
        ADD COLUMN share_watching_activity BOOLEAN NOT NULL DEFAULT true;
    END IF;
END $$;

-- 2. Update RPC to include co-owners
CREATE OR REPLACE FUNCTION public.get_friends_watching_content(
  p_tmdb_id INTEGER,
  p_media_type TEXT,
  p_friend_ids UUID[]
)
RETURNS TABLE (user_id UUID, display_name TEXT, username TEXT, avatar_url TEXT)
AS $$
  WITH relevant_watchlists AS (
    -- Get IDs of all watchlists containing this item
    SELECT watchlist_id
    FROM watchlist_items
    WHERE tmdb_id = p_tmdb_id AND media_type = p_media_type
  ),
  relevant_users AS (
    -- 1. Owners of these watchlists
    SELECT w.user_id
    FROM watchlists w
    JOIN relevant_watchlists rw ON w.id = rw.watchlist_id
    
    UNION
    
    -- 2. Accepted Co-owners of these watchlists
    SELECT wm.user_id
    FROM watchlist_members wm
    JOIN relevant_watchlists rw ON wm.watchlist_id = rw.watchlist_id
    WHERE wm.status = 'accepted'
  )
  -- Select details of relevant users who are also in the friend list AND have privacy enabling sharing
  SELECT DISTINCT u.id, u.display_name, u.username, u.avatar_url
  FROM relevant_users ru
  JOIN users u ON ru.user_id = u.id
  WHERE u.id = ANY(p_friend_ids)
    AND u.share_watching_activity = true;
$$ LANGUAGE SQL STABLE SET search_path = public;
