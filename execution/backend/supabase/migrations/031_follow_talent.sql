-- Migration 031: Follow Talent (Actors & Directors)
-- Tables, RLS, indexes, and RPCs for talent following + content detection

-- =============================================================================
-- 1. followed_talent — users follow actors/directors by TMDB person ID
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.followed_talent (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tmdb_person_id INTEGER NOT NULL,
    person_name TEXT NOT NULL,
    person_type TEXT NOT NULL CHECK (person_type IN ('actor', 'director')),
    profile_path TEXT,                  -- TMDB profile image path
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, tmdb_person_id)
);

-- Indexes
CREATE INDEX idx_followed_talent_user ON public.followed_talent(user_id);
CREATE INDEX idx_followed_talent_person ON public.followed_talent(tmdb_person_id);

-- RLS
ALTER TABLE public.followed_talent ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own followed talent"
    ON public.followed_talent FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can follow talent"
    ON public.followed_talent FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own followed talent"
    ON public.followed_talent FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can unfollow talent"
    ON public.followed_talent FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- =============================================================================
-- 2. talent_content_events — detected new content for followed people
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.talent_content_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tmdb_person_id INTEGER NOT NULL,
    tmdb_content_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    content_title TEXT NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notified_user_count INTEGER NOT NULL DEFAULT 0,
    UNIQUE(tmdb_person_id, tmdb_content_id)
);

-- Indexes
CREATE INDEX idx_talent_events_person ON public.talent_content_events(tmdb_person_id);
CREATE INDEX idx_talent_events_detected ON public.talent_content_events(detected_at DESC);

-- RLS — authenticated can read, only service_role can insert
ALTER TABLE public.talent_content_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view talent content events"
    ON public.talent_content_events FOR SELECT
    TO authenticated
    USING (true);

-- No INSERT/UPDATE/DELETE policies — service_role bypasses RLS

-- =============================================================================
-- 3. RPC: get_followed_persons_to_check
-- Returns distinct TMDB person IDs that have at least one follower,
-- ordered by most followers first. Capped to limit TMDB API calls.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_followed_persons_to_check(
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    tmdb_person_id INTEGER,
    person_name TEXT,
    follower_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ft.tmdb_person_id,
        ft.person_name,
        COUNT(DISTINCT ft.user_id) AS follower_count
    FROM public.followed_talent ft
    GROUP BY ft.tmdb_person_id, ft.person_name
    ORDER BY COUNT(DISTINCT ft.user_id) DESC
    LIMIT limit_count;
END;
$$;

-- =============================================================================
-- 4. RPC: get_followers_of_person
-- Given a TMDB person ID, returns user IDs who follow that person
-- AND have talent_alerts enabled in notification_preferences.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_followers_of_person(
    p_tmdb_person_id INTEGER
)
RETURNS TABLE (
    user_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ft.user_id
    FROM public.followed_talent ft
    INNER JOIN public.notification_preferences np
        ON np.user_id = ft.user_id
        AND np.talent_releases = true
    WHERE ft.tmdb_person_id = p_tmdb_person_id;
END;
$$;
