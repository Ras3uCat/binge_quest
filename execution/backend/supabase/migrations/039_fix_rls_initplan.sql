-- Migration: 039_fix_rls_initplan
-- Purpose: Rewrite all RLS policies affected by auth_rls_initplan performance
--          warning. Wrapping auth.uid() in (SELECT auth.uid()) prevents the
--          planner from re-evaluating the function on every row and instead
--          treats it as a stable init-plan evaluated once per query.
-- Affected tables: users, watchlists, watchlist_items, watch_progress,
--   user_episode_notifications, user_device_tokens, notification_preferences,
--   notifications, user_streaming_preferences, followed_talent,
--   user_blocks, friendships, watchlist_members, user_badges, reviews

-- ============================================================
-- TABLE: users
-- ============================================================

DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
CREATE POLICY "Users can view their own profile"
  ON public.users
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
  ON public.users
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
CREATE POLICY "Users can insert their own profile"
  ON public.users
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = id);

-- ============================================================
-- TABLE: watchlists
-- ============================================================

DROP POLICY IF EXISTS "Users can view their own watchlists" ON public.watchlists;
CREATE POLICY "Users can view their own watchlists"
  ON public.watchlists
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create their own watchlists" ON public.watchlists;
CREATE POLICY "Users can create their own watchlists"
  ON public.watchlists
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own watchlists" ON public.watchlists;
CREATE POLICY "Users can update their own watchlists"
  ON public.watchlists
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own watchlists" ON public.watchlists;
CREATE POLICY "Users can delete their own watchlists"
  ON public.watchlists
  FOR DELETE
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Co-owners can view shared watchlists" ON public.watchlists;
CREATE POLICY "Co-owners can view shared watchlists"
  ON public.watchlists
  FOR SELECT
  TO authenticated
  USING (is_watchlist_co_owner(id, (SELECT auth.uid())));

-- ============================================================
-- TABLE: watchlist_items
-- ============================================================

DROP POLICY IF EXISTS "Users can view items in their watchlists" ON public.watchlist_items;
CREATE POLICY "Users can view items in their watchlists"
  ON public.watchlist_items
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can add items to their watchlists" ON public.watchlist_items;
CREATE POLICY "Users can add items to their watchlists"
  ON public.watchlist_items
  FOR INSERT
  TO public
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update items in their watchlists" ON public.watchlist_items;
CREATE POLICY "Users can update items in their watchlists"
  ON public.watchlist_items
  FOR UPDATE
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can delete items from their watchlists" ON public.watchlist_items;
CREATE POLICY "Users can delete items from their watchlists"
  ON public.watchlist_items
  FOR DELETE
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM watchlists
      WHERE watchlists.id = watchlist_items.watchlist_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Co-owners can view shared watchlist items" ON public.watchlist_items;
CREATE POLICY "Co-owners can view shared watchlist items"
  ON public.watchlist_items
  FOR SELECT
  TO authenticated
  USING (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())));

DROP POLICY IF EXISTS "Co-owners can add items to shared watchlists" ON public.watchlist_items;
CREATE POLICY "Co-owners can add items to shared watchlists"
  ON public.watchlist_items
  FOR INSERT
  TO authenticated
  WITH CHECK (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())));

DROP POLICY IF EXISTS "Co-owners can update shared watchlist items" ON public.watchlist_items;
CREATE POLICY "Co-owners can update shared watchlist items"
  ON public.watchlist_items
  FOR UPDATE
  TO authenticated
  USING (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())));

DROP POLICY IF EXISTS "Co-owners can remove shared watchlist items" ON public.watchlist_items;
CREATE POLICY "Co-owners can remove shared watchlist items"
  ON public.watchlist_items
  FOR DELETE
  TO authenticated
  USING (is_watchlist_co_owner(watchlist_id, (SELECT auth.uid())));

-- ============================================================
-- TABLE: watch_progress
-- ============================================================

DROP POLICY IF EXISTS "Users can view progress for their items" ON public.watch_progress;
CREATE POLICY "Users can view progress for their items"
  ON public.watch_progress
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can create progress for their items" ON public.watch_progress;
CREATE POLICY "Users can create progress for their items"
  ON public.watch_progress
  FOR INSERT
  TO public
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update progress for their items" ON public.watch_progress;
CREATE POLICY "Users can update progress for their items"
  ON public.watch_progress
  FOR UPDATE
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can delete progress for their items" ON public.watch_progress;
CREATE POLICY "Users can delete progress for their items"
  ON public.watch_progress
  FOR DELETE
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      JOIN watchlists ON watchlists.id = watchlist_items.watchlist_id
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND watchlists.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Co-owners can view shared progress" ON public.watch_progress;
CREATE POLICY "Co-owners can view shared progress"
  ON public.watch_progress
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Co-owners can create shared progress" ON public.watch_progress;
CREATE POLICY "Co-owners can create shared progress"
  ON public.watch_progress
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Co-owners can update shared progress" ON public.watch_progress;
CREATE POLICY "Co-owners can update shared progress"
  ON public.watch_progress
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Co-owners can delete shared progress" ON public.watch_progress;
CREATE POLICY "Co-owners can delete shared progress"
  ON public.watch_progress
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM watchlist_items
      WHERE watchlist_items.id = watch_progress.watchlist_item_id
        AND is_watchlist_co_owner(watchlist_items.watchlist_id, (SELECT auth.uid()))
    )
  );

-- ============================================================
-- TABLE: user_episode_notifications
-- ============================================================

DROP POLICY IF EXISTS "Users can view own episode notifications" ON public.user_episode_notifications;
CREATE POLICY "Users can view own episode notifications"
  ON public.user_episode_notifications
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own episode notifications" ON public.user_episode_notifications;
CREATE POLICY "Users can insert own episode notifications"
  ON public.user_episode_notifications
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own episode notifications" ON public.user_episode_notifications;
CREATE POLICY "Users can update own episode notifications"
  ON public.user_episode_notifications
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own episode notifications" ON public.user_episode_notifications;
CREATE POLICY "Users can delete own episode notifications"
  ON public.user_episode_notifications
  FOR DELETE
  TO public
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: user_device_tokens
-- ============================================================

DROP POLICY IF EXISTS "Users can view own device tokens" ON public.user_device_tokens;
CREATE POLICY "Users can view own device tokens"
  ON public.user_device_tokens
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can register own device tokens" ON public.user_device_tokens;
CREATE POLICY "Users can register own device tokens"
  ON public.user_device_tokens
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own device tokens" ON public.user_device_tokens;
CREATE POLICY "Users can update own device tokens"
  ON public.user_device_tokens
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can remove own device tokens" ON public.user_device_tokens;
CREATE POLICY "Users can remove own device tokens"
  ON public.user_device_tokens
  FOR DELETE
  TO public
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: notification_preferences
-- ============================================================

DROP POLICY IF EXISTS "Users can view own preferences" ON public.notification_preferences;
CREATE POLICY "Users can view own preferences"
  ON public.notification_preferences
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own preferences" ON public.notification_preferences;
CREATE POLICY "Users can insert own preferences"
  ON public.notification_preferences
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own preferences" ON public.notification_preferences;
CREATE POLICY "Users can update own preferences"
  ON public.notification_preferences
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: notifications
-- ============================================================

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can mark own notifications as read" ON public.notifications;
CREATE POLICY "Users can mark own notifications as read"
  ON public.notifications
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: user_streaming_preferences
-- ============================================================

DROP POLICY IF EXISTS "Users can view own streaming preferences" ON public.user_streaming_preferences;
CREATE POLICY "Users can view own streaming preferences"
  ON public.user_streaming_preferences
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own streaming preferences" ON public.user_streaming_preferences;
CREATE POLICY "Users can insert own streaming preferences"
  ON public.user_streaming_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own streaming preferences" ON public.user_streaming_preferences;
CREATE POLICY "Users can update own streaming preferences"
  ON public.user_streaming_preferences
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own streaming preferences" ON public.user_streaming_preferences;
CREATE POLICY "Users can delete own streaming preferences"
  ON public.user_streaming_preferences
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: followed_talent
-- ============================================================

DROP POLICY IF EXISTS "Users can view own followed talent" ON public.followed_talent;
CREATE POLICY "Users can view own followed talent"
  ON public.followed_talent
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can follow talent" ON public.followed_talent;
CREATE POLICY "Users can follow talent"
  ON public.followed_talent
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own followed talent" ON public.followed_talent;
CREATE POLICY "Users can update own followed talent"
  ON public.followed_talent
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can unfollow talent" ON public.followed_talent;
CREATE POLICY "Users can unfollow talent"
  ON public.followed_talent
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: user_blocks
-- ============================================================

DROP POLICY IF EXISTS "Users can view own blocks" ON public.user_blocks;
CREATE POLICY "Users can view own blocks"
  ON public.user_blocks
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = blocker_id);

DROP POLICY IF EXISTS "Users can block others" ON public.user_blocks;
CREATE POLICY "Users can block others"
  ON public.user_blocks
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = blocker_id);

DROP POLICY IF EXISTS "Users can unblock others" ON public.user_blocks;
CREATE POLICY "Users can unblock others"
  ON public.user_blocks
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = blocker_id);

-- ============================================================
-- TABLE: friendships
-- ============================================================

DROP POLICY IF EXISTS "Users can view own friendships" ON public.friendships;
CREATE POLICY "Users can view own friendships"
  ON public.friendships
  FOR SELECT
  TO authenticated
  USING (
    ((SELECT auth.uid()) = requester_id)
    OR ((SELECT auth.uid()) = addressee_id)
  );

DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
CREATE POLICY "Users can send friend requests"
  ON public.friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    ((SELECT auth.uid()) = requester_id)
    AND (
      NOT EXISTS (
        SELECT 1
        FROM user_blocks
        WHERE (
          (user_blocks.blocker_id = friendships.requester_id AND user_blocks.blocked_id = friendships.addressee_id)
          OR (user_blocks.blocker_id = friendships.addressee_id AND user_blocks.blocked_id = friendships.requester_id)
        )
      )
    )
  );

DROP POLICY IF EXISTS "Users can update own friendships" ON public.friendships;
CREATE POLICY "Users can update own friendships"
  ON public.friendships
  FOR UPDATE
  TO authenticated
  USING (
    ((SELECT auth.uid()) = requester_id)
    OR ((SELECT auth.uid()) = addressee_id)
  );

DROP POLICY IF EXISTS "Users can delete own friendships" ON public.friendships;
CREATE POLICY "Users can delete own friendships"
  ON public.friendships
  FOR DELETE
  TO authenticated
  USING (
    ((SELECT auth.uid()) = requester_id)
    OR ((SELECT auth.uid()) = addressee_id)
  );

-- ============================================================
-- TABLE: watchlist_members
-- ============================================================

DROP POLICY IF EXISTS "Members can view watchlist membership" ON public.watchlist_members;
CREATE POLICY "Members can view watchlist membership"
  ON public.watchlist_members
  FOR SELECT
  TO authenticated
  USING (
    (user_id = (SELECT auth.uid()))
    OR (invited_by = (SELECT auth.uid()))
    OR (
      EXISTS (
        SELECT 1
        FROM watchlists
        WHERE watchlists.id = watchlist_members.watchlist_id
          AND watchlists.user_id = (SELECT auth.uid())
      )
    )
  );

DROP POLICY IF EXISTS "Watchlist owner can invite co-owners" ON public.watchlist_members;
CREATE POLICY "Watchlist owner can invite co-owners"
  ON public.watchlist_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (invited_by = (SELECT auth.uid()))
    AND (
      EXISTS (
        SELECT 1
        FROM watchlists
        WHERE watchlists.id = watchlist_members.watchlist_id
          AND watchlists.user_id = (SELECT auth.uid())
      )
    )
    AND are_friends((SELECT auth.uid()), user_id)
  );

DROP POLICY IF EXISTS "Invitee can respond to co-owner invite" ON public.watchlist_members;
CREATE POLICY "Invitee can respond to co-owner invite"
  ON public.watchlist_members
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Members can be removed or leave" ON public.watchlist_members;
CREATE POLICY "Members can be removed or leave"
  ON public.watchlist_members
  FOR DELETE
  TO authenticated
  USING (
    (user_id = (SELECT auth.uid()))
    OR (
      EXISTS (
        SELECT 1
        FROM watchlists
        WHERE watchlists.id = watchlist_members.watchlist_id
          AND watchlists.user_id = (SELECT auth.uid())
      )
    )
  );

-- ============================================================
-- TABLE: user_badges
-- ============================================================

DROP POLICY IF EXISTS "Users can view their own badges" ON public.user_badges;
CREATE POLICY "Users can view their own badges"
  ON public.user_badges
  FOR SELECT
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "System can grant badges" ON public.user_badges;
CREATE POLICY "System can grant badges"
  ON public.user_badges
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================
-- TABLE: reviews
-- ============================================================

DROP POLICY IF EXISTS "Users can insert own reviews" ON public.reviews;
CREATE POLICY "Users can insert own reviews"
  ON public.reviews
  FOR INSERT
  TO public
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own reviews" ON public.reviews;
CREATE POLICY "Users can update own reviews"
  ON public.reviews
  FOR UPDATE
  TO public
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own reviews" ON public.reviews;
CREATE POLICY "Users can delete own reviews"
  ON public.reviews
  FOR DELETE
  TO public
  USING ((SELECT auth.uid()) = user_id);
