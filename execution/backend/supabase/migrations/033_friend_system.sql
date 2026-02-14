-- Migration 033: Friend System
-- Friendships, user blocks, and reusable helper functions for all social features

-- =============================================================================
-- 1. Create tables first (policies reference each other)
-- =============================================================================

-- 1a. user_blocks (created first — referenced by friendships INSERT policy)
CREATE TABLE IF NOT EXISTS public.user_blocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(blocker_id, blocked_id),
    CHECK (blocker_id != blocked_id)
);

CREATE INDEX idx_user_blocks_blocker ON public.user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked ON public.user_blocks(blocked_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- 1b. friendships
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(requester_id, addressee_id),
    CHECK (requester_id != addressee_id)
);

CREATE INDEX idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX idx_friendships_status ON public.friendships(status);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. RLS policies — user_blocks
-- =============================================================================

CREATE POLICY "Users can view own blocks"
    ON public.user_blocks FOR SELECT
    TO authenticated
    USING (auth.uid() = blocker_id);

CREATE POLICY "Users can block others"
    ON public.user_blocks FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock others"
    ON public.user_blocks FOR DELETE
    TO authenticated
    USING (auth.uid() = blocker_id);

-- =============================================================================
-- 3. RLS policies — friendships
-- =============================================================================

CREATE POLICY "Users can view own friendships"
    ON public.friendships FOR SELECT
    TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can send friend requests"
    ON public.friendships FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = requester_id
        AND NOT EXISTS (
            SELECT 1 FROM public.user_blocks
            WHERE (blocker_id = requester_id AND blocked_id = addressee_id)
               OR (blocker_id = addressee_id AND blocked_id = requester_id)
        )
    );

CREATE POLICY "Users can update own friendships"
    ON public.friendships FOR UPDATE
    TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can delete own friendships"
    ON public.friendships FOR DELETE
    TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- =============================================================================
-- 4. are_friends() — reusable helper for Co-Owners, Watch Party, etc.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.are_friends(user_a UUID, user_b UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.friendships
        WHERE status = 'accepted'
        AND (
            (requester_id = user_a AND addressee_id = user_b)
            OR (requester_id = user_b AND addressee_id = user_a)
        )
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public;

-- =============================================================================
-- 5. is_blocked() — reusable block check (bidirectional)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.is_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_blocks
        WHERE (blocker_id = user_a AND blocked_id = user_b)
           OR (blocker_id = user_b AND blocked_id = user_a)
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public;

-- =============================================================================
-- 6. Auto-remove friendship when a block is created
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_block_cleanup()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM public.friendships
    WHERE (requester_id = NEW.blocker_id AND addressee_id = NEW.blocked_id)
       OR (requester_id = NEW.blocked_id AND addressee_id = NEW.blocker_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE TRIGGER on_user_block_cleanup
    AFTER INSERT ON public.user_blocks
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_block_cleanup();

-- =============================================================================
-- 7. notify_friend_request() — RPC for client to create social notifications
-- =============================================================================
CREATE OR REPLACE FUNCTION public.notify_friend_request(
    addressee_id UUID,
    requester_name TEXT
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.notifications (user_id, category, title, body, data)
    VALUES (
        addressee_id,
        'social',
        'Friend Request',
        requester_name || ' sent you a friend request',
        jsonb_build_object('type', 'friend_request')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;
