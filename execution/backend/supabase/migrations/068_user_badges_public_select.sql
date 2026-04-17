-- Allow any authenticated user to view any user's earned badges.
-- Badges are public achievements — needed for friend profile screens.
DROP POLICY IF EXISTS "Users can view their own badges" ON public.user_badges;

CREATE POLICY "Badges are publicly viewable"
  ON public.user_badges
  FOR SELECT
  TO public
  USING (true);
