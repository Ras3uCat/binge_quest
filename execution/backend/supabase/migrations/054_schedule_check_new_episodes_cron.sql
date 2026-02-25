-- Migration: 054_schedule_check_new_episodes_cron.sql
-- Feature: New Episode Notifications + Episode Cache Refresh
-- Created: 2026-02-24
-- Registers a nightly cron job for the check-new-episodes edge function.
-- Reuses the existing compute_archetypes_cron_secret vault secret (shared cron token).

-- ============================================================================
-- Wrapper function: private.cron_check_new_episodes
-- Reads the shared cron secret from vault and calls the edge function.
-- ============================================================================
CREATE OR REPLACE FUNCTION private.cron_check_new_episodes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'net', 'vault', 'public'
AS $$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets
  WHERE name = 'compute_archetypes_cron_secret'
  LIMIT 1;

  IF v_secret IS NULL THEN
    RAISE WARNING 'compute_archetypes_cron_secret not found in vault — skipping check-new-episodes cron run';
    RETURN;
  END IF;

  PERFORM net.http_post(
    url     := 'https://ffodlqpscvabcguzbqif.supabase.co/functions/v1/check-new-episodes',
    body    := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || v_secret
    )
  );
END;
$$;

-- ============================================================================
-- Cron schedule: nightly at 03:30 UTC (30 min after compute-archetypes at 03:00)
-- ============================================================================
SELECT cron.schedule(
  'check-new-episodes-nightly',
  '30 3 * * *',
  'SELECT private.cron_check_new_episodes()'
);
