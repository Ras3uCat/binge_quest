-- BingeQuest Migration: Add minutes_watched to watch_progress
-- Run this in Supabase SQL Editor after 003_add_episode_runtime.sql

-- Add minutes_watched column for partial movie progress tracking
ALTER TABLE public.watch_progress
ADD COLUMN IF NOT EXISTS minutes_watched INTEGER DEFAULT 0;

-- Update existing watched entries to have full minutes_watched
UPDATE public.watch_progress
SET minutes_watched = runtime_minutes
WHERE watched = true AND minutes_watched = 0;
