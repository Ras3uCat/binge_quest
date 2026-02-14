-- Migration 034: Watchlist Co-Owners
-- Shared watchlists with co-owner access. Progress is shared (not per-user).

-- =============================================================================
-- 1. watchlist_members table (created first — referenced by helper function)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.watchlist_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    watchlist_id UUID NOT NULL REFERENCES public.watchlists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'co_owner' CHECK (role IN ('owner', 'co_owner')),
    invited_by UUID NOT NULL REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    UNIQUE(watchlist_id, user_id)
);

CREATE INDEX idx_watchlist_members_watchlist ON public.watchlist_members(watchlist_id);
CREATE INDEX idx_watchlist_members_user ON public.watchlist_members(user_id);
CREATE INDEX idx_watchlist_members_status ON public.watchlist_members(status);

ALTER TABLE public.watchlist_members ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. Helper: check if a user is an accepted co-owner of a watchlist
-- =============================================================================
CREATE OR REPLACE FUNCTION public.is_watchlist_co_owner(wl_id UUID, uid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.watchlist_members
        WHERE watchlist_id = wl_id
        AND user_id = uid
        AND status = 'accepted'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public;

-- =============================================================================
-- 3. RLS policies — watchlist_members
-- =============================================================================

-- SELECT: user is a member OR owns the watchlist
CREATE POLICY "Members can view watchlist membership"
    ON public.watchlist_members FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR invited_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_members.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
    );

-- INSERT: only watchlist owner can invite, invitee must be a friend
CREATE POLICY "Watchlist owner can invite co-owners"
    ON public.watchlist_members FOR INSERT
    TO authenticated
    WITH CHECK (
        invited_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_members.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
        AND public.are_friends(auth.uid(), user_id)
    );

-- UPDATE: invitee can accept/decline their own pending invite
CREATE POLICY "Invitee can respond to co-owner invite"
    ON public.watchlist_members FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid());

-- DELETE: owner can remove co-owners; co-owner can leave
CREATE POLICY "Members can be removed or leave"
    ON public.watchlist_members FOR DELETE
    TO authenticated
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.watchlists
            WHERE watchlists.id = watchlist_members.watchlist_id
            AND watchlists.user_id = auth.uid()
        )
    );

-- =============================================================================
-- 4. Co-owner policies on watchlists (SELECT only — co-owners can view)
-- =============================================================================

CREATE POLICY "Co-owners can view shared watchlists"
    ON public.watchlists FOR SELECT
    TO authenticated
    USING (
        public.is_watchlist_co_owner(id, auth.uid())
    );

-- =============================================================================
-- 5. Co-owner policies on watchlist_items (full CRUD)
-- =============================================================================

CREATE POLICY "Co-owners can view shared watchlist items"
    ON public.watchlist_items FOR SELECT
    TO authenticated
    USING (
        public.is_watchlist_co_owner(watchlist_id, auth.uid())
    );

CREATE POLICY "Co-owners can add items to shared watchlists"
    ON public.watchlist_items FOR INSERT
    TO authenticated
    WITH CHECK (
        public.is_watchlist_co_owner(watchlist_id, auth.uid())
    );

CREATE POLICY "Co-owners can update shared watchlist items"
    ON public.watchlist_items FOR UPDATE
    TO authenticated
    USING (
        public.is_watchlist_co_owner(watchlist_id, auth.uid())
    );

CREATE POLICY "Co-owners can remove shared watchlist items"
    ON public.watchlist_items FOR DELETE
    TO authenticated
    USING (
        public.is_watchlist_co_owner(watchlist_id, auth.uid())
    );

-- =============================================================================
-- 6. Co-owner policies on watch_progress (full CRUD — shared progress)
-- =============================================================================

CREATE POLICY "Co-owners can view shared progress"
    ON public.watch_progress FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND public.is_watchlist_co_owner(watchlist_items.watchlist_id, auth.uid())
        )
    );

CREATE POLICY "Co-owners can create shared progress"
    ON public.watch_progress FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND public.is_watchlist_co_owner(watchlist_items.watchlist_id, auth.uid())
        )
    );

CREATE POLICY "Co-owners can update shared progress"
    ON public.watch_progress FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND public.is_watchlist_co_owner(watchlist_items.watchlist_id, auth.uid())
        )
    );

CREATE POLICY "Co-owners can delete shared progress"
    ON public.watch_progress FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.watchlist_items
            WHERE watchlist_items.id = watch_progress.watchlist_item_id
            AND public.is_watchlist_co_owner(watchlist_items.watchlist_id, auth.uid())
        )
    );

-- =============================================================================
-- 7. Notification RPC for co-owner invites
-- =============================================================================
CREATE OR REPLACE FUNCTION public.notify_co_owner_invite(
    invitee_id UUID,
    inviter_name TEXT,
    watchlist_name TEXT,
    p_watchlist_id UUID DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.notifications (user_id, category, title, body, data)
    VALUES (
        invitee_id,
        'social',
        'Watchlist Invite',
        inviter_name || ' invited you to co-own "' || watchlist_name || '"',
        jsonb_build_object('type', 'co_owner_invite', 'watchlist_name', watchlist_name, 'watchlist_id', p_watchlist_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;
