-- ============================================================
-- Migration 029: Push Notifications Infrastructure
-- Tables: user_device_tokens, notification_preferences, notifications
-- Applied: 2026-02-06
-- ============================================================

-- 1. user_device_tokens: FCM tokens per user/device
CREATE TABLE public.user_device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  device_info text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

COMMENT ON TABLE public.user_device_tokens IS 'FCM device tokens for push notifications';

ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own device tokens"
  ON public.user_device_tokens FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can register own device tokens"
  ON public.user_device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own device tokens"
  ON public.user_device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can remove own device tokens"
  ON public.user_device_tokens FOR DELETE
  USING (auth.uid() = user_id);

CREATE INDEX idx_device_tokens_user ON public.user_device_tokens(user_id);

-- 2. notification_preferences: per-category toggles + quiet hours
CREATE TABLE public.notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  streaming_alerts boolean NOT NULL DEFAULT true,
  talent_releases boolean NOT NULL DEFAULT true,
  new_episodes boolean NOT NULL DEFAULT true,
  social boolean NOT NULL DEFAULT true,
  marketing boolean NOT NULL DEFAULT false,
  quiet_hours_enabled boolean NOT NULL DEFAULT false,
  quiet_hours_start time DEFAULT '22:00',
  quiet_hours_end time DEFAULT '08:00',
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.notification_preferences IS 'Per-user notification category preferences and quiet hours';

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences"
  ON public.notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON public.notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON public.notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- 3. notifications: in-app notification history
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN ('streaming_alerts', 'talent_releases', 'new_episodes', 'social', 'marketing')),
  title text NOT NULL,
  body text NOT NULL,
  image_url text,
  data jsonb DEFAULT '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.notifications IS 'In-app notification history with deep link data';

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can mark their own notifications as read
CREATE POLICY "Users can mark own notifications as read"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- No INSERT policy needed: Edge Function uses service_role key (bypasses RLS)

CREATE INDEX idx_notifications_user_unread
  ON public.notifications(user_id)
  WHERE read_at IS NULL;

CREATE INDEX idx_notifications_created
  ON public.notifications(created_at DESC);
