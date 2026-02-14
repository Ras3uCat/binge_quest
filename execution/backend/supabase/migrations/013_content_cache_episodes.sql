-- BingeQuest Migration: Episode metadata cache
-- Creates content_cache_episodes table for shared episode metadata
-- and adds FK from watch_progress to reference cached episodes

-- Create content_cache_episodes table (shared across all users)
CREATE TABLE IF NOT EXISTS public.content_cache_episodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tmdb_id INTEGER NOT NULL,           -- TV show's TMDB ID
    season_number INTEGER NOT NULL,
    episode_number INTEGER NOT NULL,
    episode_name TEXT,
    episode_overview TEXT,
    runtime_minutes INTEGER NOT NULL DEFAULT 0,
    air_date DATE,
    still_path TEXT,
    vote_average FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tmdb_id, season_number, episode_number)
);

-- Create indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_episode_cache_tmdb ON content_cache_episodes(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_episode_cache_season ON content_cache_episodes(tmdb_id, season_number);

-- Enable Row Level Security (shared data, similar to content_cache)
ALTER TABLE content_cache_episodes ENABLE ROW LEVEL SECURITY;

-- RLS policies: Anyone authenticated can read, insert, and update episode cache
-- Drop existing policies first to avoid conflicts on re-run
DROP POLICY IF EXISTS "Anyone can read episode cache" ON content_cache_episodes;
DROP POLICY IF EXISTS "Authenticated users can insert episode cache" ON content_cache_episodes;
DROP POLICY IF EXISTS "Authenticated users can update episode cache" ON content_cache_episodes;

CREATE POLICY "Anyone can read episode cache"
    ON content_cache_episodes FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can insert episode cache"
    ON content_cache_episodes FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Authenticated users can update episode cache"
    ON content_cache_episodes FOR UPDATE
    TO authenticated
    USING (true);

-- Add episode_cache_id FK to watch_progress table
ALTER TABLE public.watch_progress
ADD COLUMN IF NOT EXISTS episode_cache_id UUID REFERENCES content_cache_episodes(id);

-- Create index for efficient joins
CREATE INDEX IF NOT EXISTS idx_watch_progress_episode_cache ON watch_progress(episode_cache_id);

-- Note: Existing watch_progress entries will have episode_cache_id = NULL
-- The app handles this gracefully with backwards compatibility:
-- - If episode_cache_id exists, episode metadata comes from the join
-- - If NULL (legacy entries), falls back to stored season_number/episode_number
