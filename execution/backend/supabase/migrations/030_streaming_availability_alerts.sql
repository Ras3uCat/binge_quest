-- Migration 030: Streaming Availability Alerts
-- Tables, RLS, and RPCs for provider change detection + user preferences

-- =============================================================================
-- 1. user_streaming_preferences — which providers each user wants alerts for
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_streaming_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id INTEGER NOT NULL,          -- TMDB provider ID (e.g., 8 = Netflix)
    provider_name TEXT NOT NULL,           -- Human-readable name
    provider_logo_path TEXT,               -- TMDB logo path (e.g., /t2yyOv40HZeVlLjYsCsPHnWLk4W.jpg)
    notify_enabled BOOLEAN NOT NULL DEFAULT true,
    include_rent_buy BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, provider_id)
);

-- Indexes
CREATE INDEX idx_user_streaming_prefs_user ON public.user_streaming_preferences(user_id);

-- RLS
ALTER TABLE public.user_streaming_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own streaming preferences"
    ON public.user_streaming_preferences FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streaming preferences"
    ON public.user_streaming_preferences FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaming preferences"
    ON public.user_streaming_preferences FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own streaming preferences"
    ON public.user_streaming_preferences FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- =============================================================================
-- 2. streaming_change_events — audit log of detected provider changes
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.streaming_change_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tmdb_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    provider_id INTEGER NOT NULL,
    provider_name TEXT NOT NULL,
    provider_type TEXT NOT NULL CHECK (provider_type IN ('flatrate', 'rent', 'buy', 'free')),
    change_type TEXT NOT NULL CHECK (change_type IN ('added', 'removed')),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notified_user_count INTEGER NOT NULL DEFAULT 0
);

-- Indexes
CREATE INDEX idx_streaming_changes_content ON public.streaming_change_events(tmdb_id, media_type);
CREATE INDEX idx_streaming_changes_detected ON public.streaming_change_events(detected_at DESC);

-- RLS — authenticated can read, only service_role can insert
ALTER TABLE public.streaming_change_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view streaming changes"
    ON public.streaming_change_events FOR SELECT
    TO authenticated
    USING (true);

-- No INSERT/UPDATE/DELETE policies for authenticated — service_role bypasses RLS

-- =============================================================================
-- 3. RPC: get_hot_watchlist_items_for_streaming_check
-- Returns content items that need provider freshness check, prioritized by:
--   1. No streaming_providers data at all (NULL)
--   2. Stale data (updated_at > 7 days ago)
--   3. Recently added to any watchlist
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_hot_watchlist_items_for_streaming_check(
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    tmdb_id INTEGER,
    media_type TEXT,
    title TEXT,
    streaming_providers JSONB,
    updated_at TIMESTAMPTZ,
    watchlist_user_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc.tmdb_id,
        cc.media_type,
        cc.title,
        cc.streaming_providers,
        cc.updated_at,
        COUNT(DISTINCT w.user_id) AS watchlist_user_count
    FROM public.content_cache cc
    INNER JOIN public.watchlist_items wi
        ON wi.tmdb_id = cc.tmdb_id AND wi.media_type = cc.media_type
    INNER JOIN public.watchlists w
        ON w.id = wi.watchlist_id
    WHERE
        -- Only content that people actually have in watchlists
        cc.tmdb_id IS NOT NULL
    GROUP BY cc.tmdb_id, cc.media_type, cc.title, cc.streaming_providers, cc.updated_at
    ORDER BY
        -- Priority: NULL providers first, then stale, then by user count
        (cc.streaming_providers IS NULL) DESC,
        (cc.updated_at < now() - INTERVAL '7 days') DESC,
        COUNT(DISTINCT w.user_id) DESC
    LIMIT limit_count;
END;
$$;

-- =============================================================================
-- 4. RPC: get_users_to_notify_for_provider
-- Given content + provider change, find users who:
--   1. Have this item in a watchlist
--   2. Have this provider in their streaming preferences (notify_enabled = true)
--   3. Have streaming_alerts enabled in notification_preferences
--   4. Optionally: respect include_rent_buy flag
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_users_to_notify_for_provider(
    p_tmdb_id INTEGER,
    p_media_type TEXT,
    p_provider_id INTEGER,
    p_provider_type TEXT DEFAULT 'flatrate'
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
    SELECT DISTINCT w.user_id
    FROM public.watchlists w
    INNER JOIN public.watchlist_items wi
        ON wi.watchlist_id = w.id
    INNER JOIN public.user_streaming_preferences usp
        ON usp.user_id = w.user_id
        AND usp.provider_id = p_provider_id
        AND usp.notify_enabled = true
    INNER JOIN public.notification_preferences np
        ON np.user_id = w.user_id
        AND np.streaming_alerts = true
    WHERE
        wi.tmdb_id = p_tmdb_id
        AND wi.media_type = p_media_type
        -- For rent/buy provider types, user must have opted in
        AND (
            p_provider_type IN ('flatrate', 'free')
            OR usp.include_rent_buy = true
        );
END;
$$;
