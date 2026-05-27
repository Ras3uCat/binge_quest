-- Migration: 069_add_second_episode_check_cron.sql
-- Adds a second daily cron run for check-new-episodes at 10:30 UTC (6:30am ET).
-- The existing 03:30 UTC run catches weekday primetime shows.
-- The 10:30 UTC run catches late-night US shows (e.g. SNL, air_date=Saturday)
-- via the PATH A "yesterday" filter — Sunday 10:30 UTC sees yesterday=Saturday.

SELECT cron.schedule(
  'check-new-episodes-morning',
  '30 10 * * *',
  'SELECT private.cron_check_new_episodes()'
);
