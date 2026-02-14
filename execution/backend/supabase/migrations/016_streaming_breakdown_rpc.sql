-- Migration: Add RPC function for streaming provider breakdown
-- Date: 2026-01-30
-- Description: Server-side aggregation of streaming providers across user's watchlists

-- Allowed provider IDs (matches StreamingProviders.all in Flutter):
-- Netflix=8, Prime Video=9, Hulu=15, Disney+=337, Apple TV+=350, Peacock=386, Paramount+=531, Max=1899

CREATE OR REPLACE FUNCTION get_streaming_breakdown(p_user_id UUID)
RETURNS TABLE (
  provider_id INT,
  provider_name TEXT,
  logo_path TEXT,
  item_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    (provider->>'id')::INT AS provider_id,
    provider->>'name' AS provider_name,
    provider->>'logo_path' AS logo_path,
    COUNT(*) AS item_count
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  JOIN content_cache cc ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
  CROSS JOIN LATERAL jsonb_array_elements(cc.streaming_providers) AS provider
  WHERE w.user_id = p_user_id
    AND cc.streaming_providers IS NOT NULL
    AND jsonb_array_length(cc.streaming_providers) > 0
    AND (provider->>'id')::INT IN (8, 9, 15, 337, 350, 386, 531, 1899)
  GROUP BY
    (provider->>'id')::INT,
    provider->>'name',
    provider->>'logo_path'
  ORDER BY item_count DESC;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_streaming_breakdown(UUID) TO authenticated;

COMMENT ON FUNCTION get_streaming_breakdown IS
  'Returns streaming provider breakdown for a user''s watchlist items, filtered to major US services.';
