-- BingeQuest Migration: Create content_cache table
-- Shared content metadata table - one row per TMDB title, shared across all users

-- ============================================
-- CONTENT CACHE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.content_cache (
    tmdb_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),

    -- Basic info
    title TEXT NOT NULL,
    tagline TEXT,
    poster_path TEXT,
    backdrop_path TEXT,
    overview TEXT,

    -- Ratings & popularity
    vote_average FLOAT,
    vote_count INTEGER,
    popularity_score FLOAT,

    -- Categorization
    genre_ids INTEGER[] DEFAULT '{}',
    status TEXT,  -- "Released", "Returning Series", etc.

    -- Dates
    release_date DATE,  -- movies: release_date, TV: first_air_date
    last_air_date DATE, -- TV only: when the show last aired (or ended)

    -- Runtime
    total_runtime_minutes INTEGER DEFAULT 0,  -- movies: runtime, TV: estimated total
    episode_runtime INTEGER,                  -- TV: average episode runtime

    -- TV-specific
    number_of_seasons INTEGER,
    number_of_episodes INTEGER,

    -- Streaming availability (lazy-loaded)
    streaming_providers JSONB,  -- [{id: 8, name: "Netflix", logo_path: "..."}]

    -- Cast (top 10 actors)
    cast_members JSONB,  -- [{id: 123, name: "Actor Name", character: "Role", profile_path: "..."}]

    -- Freshness tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tmdb_id, media_type)
);

-- Index for freshness queries
CREATE INDEX IF NOT EXISTS idx_content_cache_updated_at
ON public.content_cache(updated_at);

-- Index for popularity sorting
CREATE INDEX IF NOT EXISTS idx_content_cache_popularity
ON public.content_cache(popularity_score DESC NULLS LAST);

-- Index for genre filtering
CREATE INDEX IF NOT EXISTS idx_content_cache_genres
ON public.content_cache USING GIN (genre_ids);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE public.content_cache ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotent migration)
DROP POLICY IF EXISTS "Anyone can read content cache" ON public.content_cache;
DROP POLICY IF EXISTS "Authenticated users can insert content cache" ON public.content_cache;
DROP POLICY IF EXISTS "Authenticated users can update content cache" ON public.content_cache;

-- Everyone can read content cache (it's shared data)
CREATE POLICY "Anyone can read content cache"
    ON public.content_cache FOR SELECT
    TO authenticated
    USING (true);

-- Users can insert content cache entries (when adding to watchlist)
CREATE POLICY "Authenticated users can insert content cache"
    ON public.content_cache FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Users can update content cache entries (for refreshing stale data)
CREATE POLICY "Authenticated users can update content cache"
    ON public.content_cache FOR UPDATE
    TO authenticated
    USING (true);

-- ============================================
-- HELPER FUNCTION: Update timestamp on modification
-- ============================================
CREATE OR REPLACE FUNCTION update_content_cache_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS content_cache_updated_at_trigger ON public.content_cache;

CREATE TRIGGER content_cache_updated_at_trigger
    BEFORE UPDATE ON public.content_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_content_cache_updated_at();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT ALL ON public.content_cache TO authenticated;
