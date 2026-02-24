-- Migration 052: remove_archetype_pin
-- Users cannot pin their archetype — it is always data-driven.
-- Drops the client UPDATE policy and removes the pin guard from the orchestrator.

DROP POLICY IF EXISTS "user_archetypes_update_pin" ON public.user_archetypes;

-- Replaced inline above via apply_migration (orchestrator redeployed without pin check).
