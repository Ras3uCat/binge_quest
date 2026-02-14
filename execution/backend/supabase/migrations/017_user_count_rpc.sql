-- Migration: get_user_count_for_content
-- Description: Returns count of unique users who have a specific content in their watchlist

CREATE OR REPLACE FUNCTION get_user_count_for_content(
  p_tmdb_id INTEGER,
  p_media_type TEXT
)
RETURNS INTEGER AS $$
  SELECT COUNT(DISTINCT w.user_id)::INTEGER
  FROM watchlist_items wi
  JOIN watchlists w ON wi.watchlist_id = w.id
  WHERE wi.tmdb_id = p_tmdb_id
    AND wi.media_type = p_media_type;
$$ LANGUAGE SQL STABLE;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_count_for_content(INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_count_for_content(INTEGER, TEXT) TO anon;
