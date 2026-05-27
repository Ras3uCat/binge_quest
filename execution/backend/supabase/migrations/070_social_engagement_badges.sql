-- Social Engagement Badges
-- Extends the category CHECK constraint and seeds 21 new social badges.

-- ============================================
-- STEP 1: EXTEND CATEGORY CHECK CONSTRAINT
-- ============================================

ALTER TABLE public.badges DROP CONSTRAINT IF EXISTS badges_category_check;
ALTER TABLE public.badges ADD CONSTRAINT badges_category_check
  CHECK (category IN ('completion', 'milestone', 'genre', 'streak', 'activity', 'social'));

-- ============================================
-- STEP 2: SEED SOCIAL BADGES
-- ============================================

-- Review Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('First Critic', 'Leave your first review', 'emoji:🖊️', 'social', '{"type": "reviews_left", "value": 1}'),
    ('Film Critic', 'Leave 5 reviews', 'emoji:📰', 'social', '{"type": "reviews_left", "value": 5}'),
    ('Master Critic', 'Leave 25 reviews', 'emoji:⭐', 'social', '{"type": "reviews_left", "value": 25}')
ON CONFLICT (name) DO NOTHING;

-- Playlist Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Curator', 'Create your first playlist', 'emoji:📋', 'social', '{"type": "playlists_created", "value": 1}'),
    ('Playlist Pro', 'Create 5 playlists', 'emoji:🎵', 'social', '{"type": "playlists_created", "value": 5}'),
    ('Master Curator', 'Create 10 playlists', 'emoji:🏆', 'social', '{"type": "playlists_created", "value": 10}')
ON CONFLICT (name) DO NOTHING;

-- Co-curator Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Collaborator', 'Add your first co-curator', 'emoji:🤝', 'social', '{"type": "cocurators_added", "value": 1}'),
    ('Team Player', 'Add 3 co-curators across your lists', 'emoji:👥', 'social', '{"type": "cocurators_added", "value": 3}'),
    ('Super Collaborator', 'Add 10 co-curators across your lists', 'emoji:🌟', 'social', '{"type": "cocurators_added", "value": 10}')
ON CONFLICT (name) DO NOTHING;

-- Friend Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('First Friend', 'Make your first friend on BingeQuest', 'emoji:👋', 'social', '{"type": "friends_added", "value": 1}'),
    ('Social Circle', 'Have 5 friends on BingeQuest', 'emoji:🫂', 'social', '{"type": "friends_added", "value": 5}'),
    ('Well Connected', 'Have 25 friends on BingeQuest', 'emoji:🌐', 'social', '{"type": "friends_added", "value": 25}')
ON CONFLICT (name) DO NOTHING;

-- Sharing Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Spread the Word', 'Share your first recommendation', 'emoji:📣', 'social', '{"type": "items_shared", "value": 1}'),
    ('Influencer', 'Share 10 recommendations', 'emoji:🚀', 'social', '{"type": "items_shared", "value": 10}'),
    ('Hype Machine', 'Share 50 recommendations', 'emoji:📡', 'social', '{"type": "items_shared", "value": 50}')
ON CONFLICT (name) DO NOTHING;

-- Watch Party — Host Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Party Starter', 'Host your first watch party', 'emoji:🎬', 'social', '{"type": "watch_parties_hosted", "value": 1}'),
    ('Host with the Most', 'Host 5 watch parties', 'emoji:🎉', 'social', '{"type": "watch_parties_hosted", "value": 5}')
ON CONFLICT (name) DO NOTHING;

-- Watch Party — Join Badges
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Party Crasher', 'Join your first watch party', 'emoji:🥳', 'social', '{"type": "watch_parties_joined", "value": 1}'),
    ('Watch Party Regular', 'Join 5 watch parties', 'emoji:🍿', 'social', '{"type": "watch_parties_joined", "value": 5}')
ON CONFLICT (name) DO NOTHING;

-- Watch Party — Combined Badge
INSERT INTO public.badges (name, description, icon_path, category, criteria_json)
VALUES
    ('Social Butterfly', 'Participate in 10 watch parties as host or guest', 'emoji:🦋', 'social', '{"type": "watch_parties_total", "value": 10}')
ON CONFLICT (name) DO NOTHING;
