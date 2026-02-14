-- BingeQuest Delete Account Function
-- Allows users to delete their own account and all associated data

-- Function to delete a user's account and all their data
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get the current user's ID
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete in order respecting foreign key constraints
    -- 1. Delete watch progress (depends on watchlist_items)
    DELETE FROM public.watch_progress
    WHERE watchlist_item_id IN (
        SELECT wi.id FROM public.watchlist_items wi
        JOIN public.watchlists w ON w.id = wi.watchlist_id
        WHERE w.user_id = current_user_id
    );

    -- 2. Delete watchlist items (depends on watchlists)
    DELETE FROM public.watchlist_items
    WHERE watchlist_id IN (
        SELECT id FROM public.watchlists
        WHERE user_id = current_user_id
    );

    -- 3. Delete watchlists
    DELETE FROM public.watchlists
    WHERE user_id = current_user_id;

    -- 4. Delete user badges
    DELETE FROM public.user_badges
    WHERE user_id = current_user_id;

    -- 5. Delete user profile
    DELETE FROM public.users
    WHERE id = current_user_id;

    -- Note: The auth.users record will be deleted by Supabase
    -- when we call auth.admin.deleteUser() from the client
    -- or the user can be marked for deletion
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
