-- Schedule weekly refresh of Returning Series show metadata.
-- Detects new seasons added by TMDB, seeds content_cache_episodes + watch_progress.
-- Runs Sunday 4:30am UTC (30 min after cleanup-stale-content-cache).

-- Private dispatcher — same pattern as cron_check_new_episodes.
CREATE OR REPLACE FUNCTION private.cron_refresh_returning_series()
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
    RAISE WARNING 'compute_archetypes_cron_secret not found in vault — skipping refresh-returning-series cron run';
    RETURN;
  END IF;

  PERFORM net.http_post(
    url     := 'https://ffodlqpscvabcguzbqif.supabase.co/functions/v1/refresh-returning-series',
    body    := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || v_secret
    )
  );
END;
$$;

-- Weekly cron: Sunday 4:30am UTC
SELECT cron.schedule(
  'weekly-refresh-returning-series',
  '30 4 * * 0',
  'SELECT private.cron_refresh_returning_series()'
);
