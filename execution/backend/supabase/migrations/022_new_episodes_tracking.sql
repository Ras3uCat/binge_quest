-- Migration: 022_new_episodes_tracking.sql
-- Feature: New Episodes Tracking & Notifications
-- Created: 2026-02-02
-- Description: Tracks when new episodes are detected and per-user notification status

-- ============================================================================
-- NOTE: new_episode_events are shared across all users (detected by system).
-- user_episode_notifications tracks per-user read/notified state.
-- ============================================================================

-- ============================================================================
-- Table: new_episode_events
-- Tracks when new episodes are detected for a TV show season (shared across users)
-- ============================================================================

CREATE TABLE IF NOT EXISTS new_episode_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tmdb_id INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  episode_count INTEGER NOT NULL,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tmdb_id, season_number, detected_at)
);

-- Add comments for documentation
COMMENT ON TABLE new_episode_events IS 'Tracks when new episodes are detected for TV shows';
COMMENT ON COLUMN new_episode_events.tmdb_id IS 'TMDB ID of the TV show';
COMMENT ON COLUMN new_episode_events.season_number IS 'Season number with new episodes';
COMMENT ON COLUMN new_episode_events.episode_count IS 'Number of new episodes detected';
COMMENT ON COLUMN new_episode_events.detected_at IS 'When the new episodes were detected';

-- Index for efficient lookups by tmdb_id
CREATE INDEX IF NOT EXISTS idx_new_episode_events_tmdb_id
  ON new_episode_events(tmdb_id);

-- Enable Row Level Security
ALTER TABLE new_episode_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Anyone can read new episode events (public data)
CREATE POLICY "New episode events are viewable by everyone"
  ON new_episode_events FOR SELECT USING (true);

-- ============================================================================
-- Table: user_episode_notifications
-- Tracks per-user notification status for new episode events
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_episode_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES public.new_episode_events(id) ON DELETE CASCADE,
  notified_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

-- Add comments for documentation
COMMENT ON TABLE user_episode_notifications IS 'Per-user notification status for new episode events';
COMMENT ON COLUMN user_episode_notifications.user_id IS 'Reference to the user';
COMMENT ON COLUMN user_episode_notifications.event_id IS 'Reference to the new episode event';
COMMENT ON COLUMN user_episode_notifications.notified_at IS 'When the user was notified (NULL = pending)';
COMMENT ON COLUMN user_episode_notifications.read_at IS 'When the user read the notification (NULL = unread)';
COMMENT ON COLUMN user_episode_notifications.created_at IS 'When this notification record was created';

-- Partial index for efficiently finding pending notifications (notified_at IS NULL)
CREATE INDEX IF NOT EXISTS idx_user_episode_notifications_pending
  ON user_episode_notifications(user_id)
  WHERE notified_at IS NULL;

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_user_episode_notifications_user_id
  ON user_episode_notifications(user_id);

-- Enable Row Level Security
ALTER TABLE user_episode_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own notification records

CREATE POLICY "Users can view own episode notifications"
  ON user_episode_notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own episode notifications"
  ON user_episode_notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own episode notifications"
  ON user_episode_notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own episode notifications"
  ON user_episode_notifications FOR DELETE
  USING (auth.uid() = user_id);
