-- BingeQuest Migration: Add episode_runtime to watchlist_items
-- Run this in Supabase SQL Editor after 002_add_release_date.sql

-- Add episode_runtime column for TV shows (average episode length in minutes)
ALTER TABLE public.watchlist_items
ADD COLUMN IF NOT EXISTS episode_runtime INTEGER;
