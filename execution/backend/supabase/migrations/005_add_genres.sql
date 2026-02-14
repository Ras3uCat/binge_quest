-- BingeQuest Migration: Add genre_ids to watchlist_items
-- Run this in Supabase SQL Editor after 004_add_minutes_watched.sql

-- Add genre_ids column to store TMDB genre IDs as integer array
ALTER TABLE public.watchlist_items
ADD COLUMN IF NOT EXISTS genre_ids INTEGER[] DEFAULT '{}';

-- Create GIN index for efficient array containment queries
CREATE INDEX IF NOT EXISTS idx_watchlist_items_genres
ON public.watchlist_items USING GIN (genre_ids);
