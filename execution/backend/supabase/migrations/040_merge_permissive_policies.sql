-- Migration 040: Merge multiple permissive SELECT (and DML) policies
-- Resolves Supabase performance advisor warning: multiple_permissive_policies
-- For each affected table+cmd, the "owner" policy (role: public) and the
-- "co-owner" policy (role: authenticated) are merged into a single policy
-- on `authenticated` using an OR condition. authenticated users inherit both
-- the owner check and the co-owner check in one policy evaluation.

-- ============================================================
-- 1. users — SELECT
--    Old: "Users can view their own profile"  (public)  USING ((SELECT auth.uid()) = id)
--    Old: "Authenticated users can view all profiles"   (authenticated) USING (true)
--    Merged: USING (true)  — one of the conditions is already unconditional
-- ============================================================
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.users;

CREATE POLICY "Users can view profiles"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- 2. watchlists — SELECT
--    Old: "Users can view their own watchlists"       (public)        USING ((SELECT auth.uid()) = user_id)
--    Old: "Co-owners can view shared watchlists"      (authenticated) USING (is_watchlist_co_owner(id, (SELECT auth.uid())))
--    Merged: owner OR co-owner
-- ============================================================
DROP POLICY IF EXISTS "Users can view their own watchlists" ON public.watchlists;
DROP POLICY IF EXISTS "Co-owners can view shared watchlists" ON public.watchlists;

CREATE POLICY "Users can view watchlists"
  ON public.watchlists
  FOR SELECT
  TO authenticated
  USING (
    (( SELECT auth.uid() AS uid) = user_id)
    OR is_watchlist_co_owner(id, ( SELECT auth.uid() AS uid))
  );

-- ============================================================
-- 3. watchlist_items — SELECT, INSERT, UPDATE, DELETE
-- ============================================================

-- 3a. SELECT
--    Old: "Users can view items in their watchlists"     (public)
--         USING (EXISTS (SELECT 1 FROM watchlists WHERE watchlists.id = watchlist_items.watchlist_id AND watchlists.user_id = (SELECT auth.uid())))
--    Old: "Co-owners can view shared watchlist items"    (authenticated)
--         USING (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())))
DROP POLICY IF EXISTS "Users can view items in their watchlists" ON public.watchlist_items;
DROP POLICY IF EXISTS "Co-owners can view shared watchlist items" ON public.watchlist_items;

CREATE POLICY "Users can view watchlist items"
  ON public.watchlist_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR is_watchlist_co_owner(watchlist_id, ( SELECT auth.uid() AS uid))
  );

-- 3b. INSERT
--    Old: "Users can add items to their watchlists"     (public)
--         WITH CHECK (EXISTS (SELECT 1 FROM watchlists WHERE watchlists.id = watchlist_items.watchlist_id AND watchlists.user_id = (SELECT auth.uid())))
--    Old: "Co-owners can add items to shared watchlists" (authenticated)
--         WITH CHECK (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())))
DROP POLICY IF EXISTS "Users can add items to their watchlists" ON public.watchlist_items;
DROP POLICY IF EXISTS "Co-owners can add items to shared watchlists" ON public.watchlist_items;

CREATE POLICY "Users can add watchlist items"
  ON public.watchlist_items
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR is_watchlist_co_owner(watchlist_id, ( SELECT auth.uid() AS uid))
  );

-- 3c. UPDATE
--    Old: "Users can update items in their watchlists"     (public)
--         USING (EXISTS (SELECT 1 FROM watchlists WHERE watchlists.id = watchlist_items.watchlist_id AND watchlists.user_id = (SELECT auth.uid())))
--    Old: "Co-owners can update shared watchlist items"    (authenticated)
--         USING (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())))
DROP POLICY IF EXISTS "Users can update items in their watchlists" ON public.watchlist_items;
DROP POLICY IF EXISTS "Co-owners can update shared watchlist items" ON public.watchlist_items;

CREATE POLICY "Users can update watchlist items"
  ON public.watchlist_items
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR is_watchlist_co_owner(watchlist_id, ( SELECT auth.uid() AS uid))
  );

-- 3d. DELETE
--    Old: "Users can delete items from their watchlists"     (public)
--         USING (EXISTS (SELECT 1 FROM watchlists WHERE watchlists.id = watchlist_items.watchlist_id AND watchlists.user_id = (SELECT auth.uid())))
--    Old: "Co-owners can remove shared watchlist items"      (authenticated)
--         USING (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())))
DROP POLICY IF EXISTS "Users can delete items from their watchlists" ON public.watchlist_items;
DROP POLICY IF EXISTS "Co-owners can remove shared watchlist items" ON public.watchlist_items;

CREATE POLICY "Users can delete watchlist items"
  ON public.watchlist_items
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR is_watchlist_co_owner(watchlist_id, ( SELECT auth.uid() AS uid))
  );

-- ============================================================
-- 4. watch_progress — SELECT, INSERT, UPDATE, DELETE
-- ============================================================

-- 4a. SELECT
--    Old: "Users can view progress for their items"  (public)
--         USING (EXISTS (SELECT 1 FROM watchlist_items JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
--                        WHERE watchlist_items.id = watch_progress.watchlist_item_id AND watchlists.user_id = (SELECT auth.uid())))
--    Old: "Co-owners can view shared progress"       (authenticated)
--         USING (EXISTS (SELECT 1 FROM watchlist_items WHERE watchlist_items.id = watch_progress.watchlist_item_id
--                        AND is_watchlist_co_owner(watchlist_items.watchlist_id, (SELECT auth.uid()))))
DROP POLICY IF EXISTS "Users can view progress for their items" ON public.watch_progress;
DROP POLICY IF EXISTS "Co-owners can view shared progress" ON public.watch_progress;

CREATE POLICY "Users can view watch progress"
  ON public.watch_progress
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, ( SELECT auth.uid() AS uid))
    )
  );

-- 4b. INSERT
--    Old: "Users can create progress for their items"  (public)
--         WITH CHECK (EXISTS (SELECT 1 FROM watchlist_items JOIN watchlists ... AND watchlists.user_id = (SELECT auth.uid())))
--    Old: "Co-owners can create shared progress"       (authenticated)
--         WITH CHECK (EXISTS (SELECT 1 FROM watchlist_items WHERE ... AND is_watchlist_co_owner(...)))
DROP POLICY IF EXISTS "Users can create progress for their items" ON public.watch_progress;
DROP POLICY IF EXISTS "Co-owners can create shared progress" ON public.watch_progress;

CREATE POLICY "Users can create watch progress"
  ON public.watch_progress
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, ( SELECT auth.uid() AS uid))
    )
  );

-- 4c. UPDATE
--    Old: "Users can update progress for their items"  (public)   USING (...)
--    Old: "Co-owners can update shared progress"       (authenticated) USING (...)
DROP POLICY IF EXISTS "Users can update progress for their items" ON public.watch_progress;
DROP POLICY IF EXISTS "Co-owners can update shared progress" ON public.watch_progress;

CREATE POLICY "Users can update watch progress"
  ON public.watch_progress
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, ( SELECT auth.uid() AS uid))
    )
  );

-- 4d. DELETE
--    Old: "Users can delete progress for their items"  (public)   USING (...)
--    Old: "Co-owners can delete shared progress"       (authenticated) USING (...)
DROP POLICY IF EXISTS "Users can delete progress for their items" ON public.watch_progress;
DROP POLICY IF EXISTS "Co-owners can delete shared progress" ON public.watch_progress;

CREATE POLICY "Users can delete watch progress"
  ON public.watch_progress
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = ( SELECT auth.uid() AS uid)
    )
    OR EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, ( SELECT auth.uid() AS uid))
    )
  );
