-- ============================================================
-- Migration 050: create_archetypes_tables
-- Archetypes reference table + 12 seed rows, user_archetypes
-- computed results table, archetype columns on users, RLS.
-- ============================================================

-- 1. Reference table (no FK deps, created first)
CREATE TABLE public.archetypes (
  id           text PRIMARY KEY,
  display_name text NOT NULL,
  tagline      text NOT NULL,
  description  text NOT NULL,
  icon_name    text NOT NULL,
  color_hex    text NOT NULL,
  sort_order   smallint NOT NULL
);

ALTER TABLE public.archetypes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "archetypes_select_auth"
  ON public.archetypes FOR SELECT
  TO authenticated USING (true);

-- 2. Seed 12 archetypes
INSERT INTO public.archetypes (id, display_name, tagline, description, icon_name, color_hex, sort_order) VALUES
  ('weekend_warrior',
   'Weekend Warrior',
   'Vanishes Mon–Thu. Storms back Friday night.',
   'They vanish Monday through Thursday, then return like a storm front. Entire seasons fall between Friday night and Sunday midnight.',
   'weekend_warrior', '#FF6B35', 1),

  ('genre_loyalist',
   'Genre Loyalist',
   'Found their lane. Never swerved.',
   'They found their lane and never swerved. Their watchlist is a cathedral dedicated to one flavor of story.',
   'local_movies', '#E63946', 2),

  ('sampler_surfer',
   'Sampler Surfer',
   'Starts everything. Finishes almost nothing.',
   'They start everything. Finish almost nothing. Their "Continue Watching" row is a museum of beginnings.',
   'shuffle', '#457B9D', 3),

  ('season_slayer',
   'Season Slayer',
   'No show left unfinished.',
   'No show left unfinished. If they start Episode 1, they will reach the final credits.',
   'military_tech', '#2A9D8F', 4),

  ('backlog_excavator',
   'Backlog Excavator',
   'Digs into the vault. Long-ignored titles finally get their moment.',
   'They dig into the vault. Long-ignored titles finally get their moment. Their queue gets shorter while everyone else''s grows.',
   'archive', '#8B5E3C', 5),

  ('midnight_drifter',
   'Midnight Drifter',
   '11 PM to 3 AM is sacred storytelling time.',
   'Their prime viewing hours begin when the world goes quiet. 11 PM to 3 AM is sacred storytelling time.',
   'nights_stay', '#6A0572', 6),

  ('social_curator',
   'Social Curator',
   'Watches so they can recommend.',
   'They watch so they can recommend. Their group chat depends on them. "Trust me, just watch episode 3" is their signature phrase.',
   'recommend', '#F4A261', 7),

  ('binge_sprinter',
   'Binge Sprinter',
   'Doesn''t watch shows — devours them.',
   'They don''t watch shows — they devour them. Three episodes? That''s a warm-up. An entire season in one sitting? Now we''re talking.',
   'bolt', '#E9C46A', 8),

  ('mood_surfer',
   'Mood Surfer',
   'Doesn''t pick shows — follows feelings.',
   'They don''t pick shows — they follow feelings. Their queue changes with the weather of their soul.',
   'waves', '#48CAE4', 9),

  ('finish_first',
   'Finish-First Strategist',
   'Efficiency is the game. Knock out the nearest finish.',
   'Efficiency is the game. They pick the show closest to done and knock it out. Their "in progress" list is always short and shrinking.',
   'checklist', '#52B788', 10),

  ('trend_chaser',
   'Trend Chaser',
   'Rides the algorithm''s wave.',
   'They ride the algorithm''s wave. Top 10 lists, viral clips, what everyone''s talking about right now.',
   'trending_up', '#F72585', 11),

  ('deep_cut',
   'Deep Cut Explorer',
   'Digs where others don''t.',
   'They dig where others don''t. Foreign films, indie gems, forgotten series from 2009.',
   'explore', '#7B2D8B', 12);

-- 3. Add archetype columns to users
--    (archetypes table must exist before FK can be declared)
ALTER TABLE public.users
  ADD COLUMN primary_archetype    text REFERENCES public.archetypes(id),
  ADD COLUMN secondary_archetype  text REFERENCES public.archetypes(id),
  ADD COLUMN archetype_updated_at timestamptz;

-- 4. Computed results table
CREATE TABLE public.user_archetypes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  archetype_id text NOT NULL REFERENCES public.archetypes(id),
  score        numeric(4,3) NOT NULL CHECK (score BETWEEN 0 AND 1),
  rank         smallint NOT NULL,           -- 1–12; 1 = highest score
  computed_at  timestamptz NOT NULL DEFAULT now(),
  is_pinned    boolean NOT NULL DEFAULT false,
  metadata     jsonb,                       -- e.g. {"dominant_genre_id": 28}
  UNIQUE (user_id, archetype_id, computed_at)
);

CREATE INDEX idx_user_archetypes_user_computed
  ON public.user_archetypes (user_id, computed_at DESC);

-- 5. RLS
ALTER TABLE public.user_archetypes ENABLE ROW LEVEL SECURITY;

-- Read: own rows + confirmed friends' rows
CREATE POLICY "user_archetypes_select"
  ON public.user_archetypes FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR are_friends(auth.uid(), user_id));

-- Client may only flip is_pinned on own rows (score/rank written by service_role only)
CREATE POLICY "user_archetypes_update_pin"
  ON public.user_archetypes FOR UPDATE TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
