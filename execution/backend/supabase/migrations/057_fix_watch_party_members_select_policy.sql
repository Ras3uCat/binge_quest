-- Migration: 057_fix_watch_party_members_select_policy.sql
-- Fix watch_party_members SELECT policy so any party member can see all
-- members in their party, not just their own row.
-- Previously: user_id = auth.uid() OR is_party_owner(...)
-- A non-owner invitee who accepted could only see themselves.

DROP POLICY IF EXISTS watch_party_members_select ON public.watch_party_members;

CREATE POLICY watch_party_members_select ON public.watch_party_members
  FOR SELECT
  USING (
    is_party_owner(party_id, auth.uid()) OR
    is_party_member(party_id, auth.uid())
  );
