-- Migration: 020_reviews_users_fk.sql
-- Description: Add foreign key from reviews to public.users for PostgREST joins

-- Add FK to public.users (needed for Supabase join syntax)
-- Note: This is in addition to the auth.users FK for cascade delete
ALTER TABLE reviews
ADD CONSTRAINT reviews_user_id_fkey_public
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
