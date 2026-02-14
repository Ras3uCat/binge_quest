-- Migration 032: Add username to users table
-- Enables friend discovery by unique handle. Required for social features.

-- =============================================================================
-- 1. Add username column
-- =============================================================================
ALTER TABLE public.users
    ADD COLUMN username TEXT;

-- Lowercase alphanumeric + underscores, 3-20 chars, must start with a letter
ALTER TABLE public.users
    ADD CONSTRAINT users_username_format
    CHECK (username ~ '^[a-z][a-z0-9_]{2,19}$');

-- Case-insensitive unique index
CREATE UNIQUE INDEX idx_users_username ON public.users (lower(username));

-- =============================================================================
-- 2. Update RLS: allow authenticated users to see other users' profiles
-- =============================================================================
-- Needed for friend search by username. The users table only contains
-- non-sensitive data (display_name, avatar_url, username, is_premium).
-- Block filtering is handled at query level, not in this policy.

CREATE POLICY "Authenticated users can view all profiles"
    ON public.users FOR SELECT
    TO authenticated
    USING (true);
