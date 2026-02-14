-- Migration: 018_reviews.sql
-- Feature: Reviews & Ratings
-- Created: 2026-01-31
-- Description: Adds reviews table for user ratings and text reviews of movies/TV shows

-- ============================================================================
-- NOTE: Reviews join with public.users table to get display_name for reviewer.
-- Query pattern: SELECT *, users(display_name) FROM reviews ...
-- ============================================================================

-- Reviews table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT CHECK (review_text IS NULL OR char_length(review_text) <= 500),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, tmdb_id, media_type)
);

-- Add comment for documentation
COMMENT ON TABLE reviews IS 'User reviews and ratings for movies and TV shows';
COMMENT ON COLUMN reviews.rating IS 'Rating from 1-5 (TV screen icons)';
COMMENT ON COLUMN reviews.review_text IS 'Optional review text, max 500 characters';

-- Indexes for efficient queries
CREATE INDEX idx_reviews_content ON reviews(tmdb_id, media_type);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);

-- Enable Row Level Security
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Anyone can read reviews (public feature)
CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT USING (true);

-- Users can insert their own reviews
CREATE POLICY "Users can insert own reviews"
  ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own reviews
CREATE POLICY "Users can update own reviews"
  ON reviews FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own reviews
CREATE POLICY "Users can delete own reviews"
  ON reviews FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- RPC Functions
-- ============================================================================

-- Get average rating and review count for content
CREATE OR REPLACE FUNCTION get_average_rating(
  p_tmdb_id INTEGER,
  p_media_type TEXT
)
RETURNS TABLE(average_rating NUMERIC, review_count INTEGER) AS $$
  SELECT
    ROUND(AVG(rating)::NUMERIC, 1) as average_rating,
    COUNT(*)::INTEGER as review_count
  FROM reviews
  WHERE tmdb_id = p_tmdb_id AND media_type = p_media_type;
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION get_average_rating(INTEGER, TEXT) IS 'Returns average rating (1 decimal) and total review count for a movie or TV show';

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_average_rating(INTEGER, TEXT) TO authenticated, anon;

-- ============================================================================
-- Trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_reviews_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_reviews_updated_at();
