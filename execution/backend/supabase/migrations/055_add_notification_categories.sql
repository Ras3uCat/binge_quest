-- Migration: 055_add_notification_categories.sql
-- Adds missing notification categories to the notifications.category CHECK constraint.
-- 'watch_party_invite' — used by watch party invite flow
-- 'archetype_updates'  — used by compute-archetypes edge function

ALTER TABLE public.notifications
  DROP CONSTRAINT notifications_category_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_category_check
    CHECK (category = ANY (ARRAY[
      'streaming_alerts'::text,
      'talent_releases'::text,
      'new_episodes'::text,
      'social'::text,
      'marketing'::text,
      'watch_party_invite'::text,
      'archetype_updates'::text
    ]));
