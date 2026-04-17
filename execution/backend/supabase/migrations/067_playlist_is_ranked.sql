-- Add is_ranked flag to playlists: when true, position-based order is treated as an explicit ranking
ALTER TABLE public.playlists
  ADD COLUMN is_ranked BOOLEAN NOT NULL DEFAULT false;
