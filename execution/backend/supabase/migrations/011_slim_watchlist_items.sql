-- BingeQuest Migration: Remove redundant columns from watchlist_items
-- Run this after 010_backfill_content_cache.sql
--
-- IMPORTANT: Ensure backfill completed successfully before running this migration.
-- This migration removes columns that are now stored in content_cache.

-- ============================================
-- ADD FOREIGN KEY CONSTRAINT
-- ============================================

-- First, ensure all watchlist_items have corresponding content_cache entries
-- (This should already be true from the backfill, but let's be safe)
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM public.watchlist_items wi
    WHERE NOT EXISTS (
        SELECT 1 FROM public.content_cache cc
        WHERE cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
    );

    IF orphan_count > 0 THEN
        RAISE EXCEPTION 'Found % watchlist_items without content_cache entries. Run backfill first.', orphan_count;
    END IF;
END $$;

-- Add foreign key constraint
ALTER TABLE public.watchlist_items
ADD CONSTRAINT fk_watchlist_items_content_cache
FOREIGN KEY (tmdb_id, media_type)
REFERENCES public.content_cache(tmdb_id, media_type);

-- ============================================
-- DROP REDUNDANT COLUMNS
-- ============================================

-- Drop columns that are now in content_cache
ALTER TABLE public.watchlist_items
DROP COLUMN IF EXISTS title,
DROP COLUMN IF EXISTS poster_path,
DROP COLUMN IF EXISTS total_runtime_minutes,
DROP COLUMN IF EXISTS episode_runtime,
DROP COLUMN IF EXISTS genre_ids,
DROP COLUMN IF EXISTS release_date;

-- ============================================
-- DROP REDUNDANT INDEXES
-- ============================================

-- Drop indexes on removed columns
DROP INDEX IF EXISTS idx_watchlist_items_release_date;
DROP INDEX IF EXISTS idx_watchlist_items_genres;

-- ============================================
-- VERIFY FINAL STRUCTURE
-- ============================================

-- The watchlist_items table should now only have:
-- - id (UUID, PK)
-- - watchlist_id (UUID, FK to watchlists)
-- - tmdb_id (INTEGER, part of FK to content_cache)
-- - media_type (TEXT, part of FK to content_cache)
-- - added_at (TIMESTAMPTZ)

DO $$
DECLARE
    col_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'watchlist_items';

    RAISE NOTICE 'watchlist_items now has % columns', col_count;
END $$;
