-- BingeQuest Migration: Add release_date to watchlist_items
-- Run this in Supabase SQL Editor after 001_initial_schema.sql

-- Add release_date column to watchlist_items
ALTER TABLE public.watchlist_items
ADD COLUMN IF NOT EXISTS release_date DATE;

-- Create index for Fresh First sorting
CREATE INDEX IF NOT EXISTS idx_watchlist_items_release_date
ON public.watchlist_items(release_date DESC NULLS LAST);
