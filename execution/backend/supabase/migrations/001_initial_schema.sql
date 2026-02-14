-- BingeQuest Initial Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension (usually enabled by default)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================
-- WATCHLISTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.watchlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_watchlists_user_id ON public.watchlists(user_id);

-- RLS for watchlists
ALTER TABLE public.watchlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own watchlists"
    ON public.watchlists FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own watchlists"
    ON public.watchlists FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own watchlists"
    ON public.watchlists FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own watchlists"
    ON public.watchlists FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- WATCHLIST ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.watchlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    watchlist_id UUID NOT NULL REFERENCES public.watchlists(id) ON DELETE CASCADE,
    tmdb_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    title TEXT NOT NULL,
    poster_path TEXT,
    total_runtime_minutes INTEGER DEFAULT 0,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(watchlist_id, tmdb_id, media_type)
);

-- Indexes
CREATE INDEX idx_watchlist_items_watchlist_id ON public.watchlist_items(watchlist_id);
CREATE INDEX idx_watchlist_items_tmdb ON public.watchlist_items(tmdb_id, media_type);

-- RLS for watchlist_items (through watchlist ownership)
ALTER TABLE public.watchlist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view items in their watchlists"
    ON public.watchlist_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_items.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add items to their watchlists"
    ON public.watchlist_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_items.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update items in their watchlists"
    ON public.watchlist_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_items.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete items from their watchlists"
    ON public.watchlist_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_items.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
    );

-- ============================================
-- WATCH PROGRESS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.watch_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    watchlist_item_id UUID NOT NULL REFERENCES public.watchlist_items(id) ON DELETE CASCADE,
    season_number INTEGER, -- NULL for movies
    episode_number INTEGER, -- NULL for movies
    runtime_minutes INTEGER NOT NULL DEFAULT 0,
    watched BOOLEAN DEFAULT FALSE,
    watched_at TIMESTAMPTZ,
    UNIQUE(watchlist_item_id, season_number, episode_number)
);

-- Index
CREATE INDEX idx_watch_progress_item ON public.watch_progress(watchlist_item_id);

-- RLS for watch_progress (through watchlist ownership)
ALTER TABLE public.watch_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view progress for their items"
    ON public.watch_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            JOIN public.watchlists ON watchlists.id = watchlist_items.watchlist_id
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND watchlists.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create progress for their items"
    ON public.watch_progress FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            JOIN public.watchlists ON watchlists.id = watchlist_items.watchlist_id
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND watchlists.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update progress for their items"
    ON public.watch_progress FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            JOIN public.watchlists ON watchlists.id = watchlist_items.watchlist_id
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND watchlists.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete progress for their items"
    ON public.watch_progress FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            JOIN public.watchlists ON watchlists.id = watchlist_items.watchlist_id
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND watchlists.user_id = auth.uid()
        )
    );

-- ============================================
-- BADGES TABLE (for future Phase 2)
-- ============================================
CREATE TABLE IF NOT EXISTS public.badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon_path TEXT,
    category TEXT NOT NULL CHECK (category IN ('genre', 'completion', 'streak', 'milestone')),
    criteria_json JSONB
);

-- RLS for badges (public read)
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view badges"
    ON public.badges FOR SELECT
    TO authenticated
    USING (true);

-- ============================================
-- USER BADGES TABLE (for future Phase 2)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- Index
CREATE INDEX idx_user_badges_user ON public.user_badges(user_id);

-- RLS for user_badges
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own badges"
    ON public.user_badges FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "System can grant badges"
    ON public.user_badges FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get minutes remaining for a watchlist item
CREATE OR REPLACE FUNCTION get_minutes_remaining(item_id UUID)
RETURNS INTEGER AS $$
    SELECT COALESCE(
        SUM(CASE WHEN NOT watched THEN runtime_minutes ELSE 0 END),
        0
    )::INTEGER
    FROM public.watch_progress
    WHERE watchlist_item_id = item_id;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Function to get completion percentage for a watchlist item
CREATE OR REPLACE FUNCTION get_completion_percentage(item_id UUID)
RETURNS NUMERIC AS $$
    SELECT CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND((COUNT(*) FILTER (WHERE watched)::NUMERIC / COUNT(*)::NUMERIC) * 100, 1)
    END
    FROM public.watch_progress
    WHERE watchlist_item_id = item_id;
$$ LANGUAGE SQL SECURITY DEFINER;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
