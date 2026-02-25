-- Migration: 056_fix_is_party_member_include_pending.sql
-- is_party_member previously only checked status = 'active'.
-- Pending invitees also need to read the watch_parties row via RLS
-- (watch_parties_select policy: created_by OR is_party_member).

CREATE OR REPLACE FUNCTION public.is_party_member(p_party_id uuid, p_user_id uuid)
  RETURNS boolean
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM watch_party_members
    WHERE party_id = p_party_id
      AND user_id = p_user_id
      AND status IN ('active', 'pending')
  );
$$;
