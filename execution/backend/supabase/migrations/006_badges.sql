-- BingeQuest Badges Seed Data
-- Run this in Supabase SQL Editor after initial schema

-- ============================================
-- SEED INITIAL BADGES
-- ============================================

-- Completion Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('First Watch', 'Complete your first movie or show', 'emoji:🎬', 'completion', '{"type": "items_completed", "value": 1}'),
    ('Getting Started', 'Complete 5 movies or shows', 'emoji:🌟', 'completion', '{"type": "items_completed", "value": 5}'),
    ('Movie Buff', 'Complete 10 movies', 'emoji:🎥', 'completion', '{"type": "movies_completed", "value": 10}'),
    ('Series Addict', 'Complete 5 TV shows', 'emoji:📺', 'completion', '{"type": "shows_completed", "value": 5}'),
    ('Binge Master', 'Complete 25 movies or shows', 'emoji:👑', 'completion', '{"type": "items_completed", "value": 25}')
ON CONFLICT (name) DO NOTHING;

-- Milestone Badges (Time-based)
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Time Investor', 'Watch 10 hours of content', 'emoji:⏱️', 'milestone', '{"type": "hours_watched", "value": 10}'),
    ('Dedicated Viewer', 'Watch 50 hours of content', 'emoji:🕐', 'milestone', '{"type": "hours_watched", "value": 50}'),
    ('Century Club', 'Watch 100 hours of content', 'emoji:💯', 'milestone', '{"type": "hours_watched", "value": 100}'),
    ('Marathon Runner', 'Watch 250 hours of content', 'emoji:🏃', 'milestone', '{"type": "hours_watched", "value": 250}')
ON CONFLICT (name) DO NOTHING;

-- Genre Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Action Hero', 'Watch 5 action titles', 'emoji:💥', 'genre', '{"type": "genre_watched", "genre_id": 28, "value": 5}'),
    ('Comedy Fan', 'Watch 5 comedy titles', 'emoji:😂', 'genre', '{"type": "genre_watched", "genre_id": 35, "value": 5}'),
    ('Drama Queen', 'Watch 5 drama titles', 'emoji:🎭', 'genre', '{"type": "genre_watched", "genre_id": 18, "value": 5}'),
    ('Horror Survivor', 'Watch 5 horror titles', 'emoji:👻', 'genre', '{"type": "genre_watched", "genre_id": 27, "value": 5}'),
    ('Sci-Fi Explorer', 'Watch 5 sci-fi titles', 'emoji:🚀', 'genre', '{"type": "genre_watched", "genre_id": 878, "value": 5}'),
    ('Romance Enthusiast', 'Watch 5 romance titles', 'emoji:💕', 'genre', '{"type": "genre_watched", "genre_id": 10749, "value": 5}'),
    ('Thriller Seeker', 'Watch 5 thriller titles', 'emoji:🔪', 'genre', '{"type": "genre_watched", "genre_id": 53, "value": 5}'),
    ('Animation Lover', 'Watch 5 animated titles', 'emoji:🎨', 'genre', '{"type": "genre_watched", "genre_id": 16, "value": 5}'),
    ('Documentary Buff', 'Watch 5 documentaries', 'emoji:📚', 'genre', '{"type": "genre_watched", "genre_id": 99, "value": 5}'),
    ('Fantasy Dreamer', 'Watch 5 fantasy titles', 'emoji:🧙', 'genre', '{"type": "genre_watched", "genre_id": 14, "value": 5}')
ON CONFLICT (name) DO NOTHING;

-- Streak/Activity Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Weekend Warrior', 'Complete 3 items in one weekend', 'emoji:🗓️', 'streak', '{"type": "weekend_completions", "value": 3}'),
    ('Night Owl', 'Watch content after midnight 5 times', 'emoji:🦉', 'streak', '{"type": "late_night_watches", "value": 5}'),
    ('Early Bird', 'Watch content before 8am 5 times', 'emoji:🐦', 'streak', '{"type": "early_watches", "value": 5}')
ON CONFLICT (name) DO NOTHING;
