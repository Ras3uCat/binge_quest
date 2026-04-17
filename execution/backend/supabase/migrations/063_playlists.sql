-- playlists: curated recommendation lists (single owner, shareable, 25-item cap)
CREATE TABLE public.playlists (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  description TEXT,
  is_public   BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.playlist_items (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  playlist_id UUID        NOT NULL REFERENCES public.playlists(id) ON DELETE CASCADE,
  tmdb_id     INT         NOT NULL,
  media_type  TEXT        NOT NULL CHECK (media_type IN ('movie', 'tv')),
  title       TEXT        NOT NULL,
  poster_path TEXT,
  position    INT         NOT NULL DEFAULT 0,
  note        TEXT,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (playlist_id, tmdb_id, media_type)
);

-- =============================================================================
-- Indexes
-- =============================================================================
CREATE INDEX idx_playlists_user_id        ON public.playlists(user_id);
CREATE INDEX idx_playlist_items_playlist  ON public.playlist_items(playlist_id, position);

-- =============================================================================
-- updated_at trigger
-- =============================================================================
CREATE OR REPLACE FUNCTION public.trg_playlists_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_playlists_updated_at
  BEFORE UPDATE ON public.playlists
  FOR EACH ROW EXECUTE FUNCTION public.trg_playlists_set_updated_at();

-- =============================================================================
-- RLS
-- =============================================================================
ALTER TABLE public.playlists      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlist_items ENABLE ROW LEVEL SECURITY;

-- playlists: owner can do everything; anyone can read public ones
CREATE POLICY "owner_all" ON public.playlists
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "public_read" ON public.playlists
  FOR SELECT USING (is_public = true);

-- playlist_items: mirrors parent playlist visibility
CREATE POLICY "owner_all" ON public.playlist_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.playlists
      WHERE id = playlist_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "public_read" ON public.playlist_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.playlists
      WHERE id = playlist_id AND is_public = true
    )
  );
