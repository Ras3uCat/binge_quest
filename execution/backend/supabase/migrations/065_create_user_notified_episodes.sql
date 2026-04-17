-- Migration: 065_create_user_notified_episodes.sql
-- Feature: Episode Notification — Release Date Trigger (051)
-- Created: 2026-04-14
-- Description: Dedicated deduplication table for air_date-based episode notifications.
--   Separate from user_episode_notifications (which is event/count-delta based).
--   Unique on (user_id, tmdb_id, season_number, episode_number) prevents duplicate
--   notifications when the cron runs multiple times on the same day.

CREATE TABLE IF NOT EXISTS user_notified_episodes (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  tmdb_id         INTEGER     NOT NULL,
  season_number   INTEGER     NOT NULL,
  episode_number  INTEGER     NOT NULL,
  notified_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, tmdb_id, season_number, episode_number)
);

COMMENT ON TABLE user_notified_episodes IS
  'Deduplication log for air_date-triggered episode notifications. One row per user per episode.';

-- Efficient lookup: has this user already been notified for this episode?
CREATE INDEX IF NOT EXISTS idx_user_notified_episodes_lookup
  ON user_notified_episodes(user_id, tmdb_id, season_number, episode_number);

-- Cleanup index: prune old rows by notified_at if needed in future
CREATE INDEX IF NOT EXISTS idx_user_notified_episodes_notified_at
  ON user_notified_episodes(notified_at);

ALTER TABLE user_notified_episodes ENABLE ROW LEVEL SECURITY;

-- Service role (edge functions) bypasses RLS — no INSERT policy needed.
-- Users can read their own records (e.g. for debug/support tooling).
CREATE POLICY "Users can view own notified episodes"
  ON user_notified_episodes FOR SELECT
  USING (auth.uid() = user_id);
