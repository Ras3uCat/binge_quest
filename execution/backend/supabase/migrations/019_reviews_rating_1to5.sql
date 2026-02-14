-- Migration: 019_reviews_rating_1to5.sql
-- Description: Change rating constraint from 1-10 to 1-5

-- Drop the old constraint
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_rating_check;

-- Add new constraint (1-5 scale)
ALTER TABLE reviews ADD CONSTRAINT reviews_rating_check CHECK (rating >= 1 AND rating <= 5);

-- Update comment
COMMENT ON COLUMN reviews.rating IS 'Rating from 1-5 (TV screen icons)';
