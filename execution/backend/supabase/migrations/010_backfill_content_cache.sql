-- BingeQuest Migration: Backfill content_cache from existing watchlist_items
-- Run this after 009_content_cache.sql

-- ============================================
-- BACKFILL CONTENT CACHE
-- ============================================

-- Insert unique content from existing watchlist_items
-- Uses DISTINCT ON to get one row per (tmdb_id, media_type) combination
INSERT INTO public.content_cache (
    tmdb_id,
    media_type,
    title,
    poster_path,
    genre_ids,
    release_date,
    total_runtime_minutes,
    episode_runtime,
    created_at,
    updated_at
)
SELECT DISTINCT ON (tmdb_id, media_type)
    tmdb_id,
    media_type,
    title,
    poster_path,
    COALESCE(genre_ids, '{}'),
    release_date,
    COALESCE(total_runtime_minutes, 0),
    episode_runtime,
    NOW(),
    NOW()
FROM public.watchlist_items
ORDER BY tmdb_id, media_type, added_at ASC  -- Take the earliest added version
ON CONFLICT (tmdb_id, media_type) DO NOTHING;

-- Log how many rows were backfilled
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM public.content_cache;
    RAISE NOTICE 'Backfilled % content cache entries', row_count;
END $$;
