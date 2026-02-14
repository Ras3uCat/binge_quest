-- BingeQuest Migration: Add missing columns to content_cache
-- Run this if content_cache was created before tagline, last_air_date, cast_members were added

-- Add tagline column
ALTER TABLE public.content_cache
ADD COLUMN IF NOT EXISTS tagline TEXT;

-- Add last_air_date column (TV only)
ALTER TABLE public.content_cache
ADD COLUMN IF NOT EXISTS last_air_date DATE;

-- Add cast_members column
ALTER TABLE public.content_cache
ADD COLUMN IF NOT EXISTS cast_members JSONB;
