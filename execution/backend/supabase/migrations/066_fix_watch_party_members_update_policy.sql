-- Migration: 066_fix_watch_party_members_update_policy.sql
-- Feature: Fix Watch Party Members RLS — Update Policy (058)
-- Created: 2026-04-14
-- Adds a WITH CHECK clause to the update policy so members cannot self-promote
-- from pending → active. Members may only set their own row to 'left' (leave).
-- The status CHECK constraint already exists — not recreated here.

DROP POLICY IF EXISTS watch_party_members_update ON public.watch_party_members;

CREATE POLICY watch_party_members_update ON public.watch_party_members
  FOR UPDATE
  USING (
    -- Owner can update any member row
    is_party_owner(party_id, auth.uid())
    OR
    -- Member can update their own row
    user_id = auth.uid()
  )
  WITH CHECK (
    -- Owner can set any valid status
    is_party_owner(party_id, auth.uid())
    OR
    -- Member can only set their own row to 'left' (leave the party)
    (user_id = auth.uid() AND status = 'left')
  );
