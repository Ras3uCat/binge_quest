-- Indexes for calendar query performance.
-- content_cache_episodes: covers the tmdb_id JOIN + air_date range filter.
CREATE INDEX IF NOT EXISTS idx_cce_tmdb_air_date
  ON content_cache_episodes (tmdb_id, air_date);

-- content_cache: covers the movie release_date range filter.
CREATE INDEX IF NOT EXISTS idx_cc_media_type_release_date
  ON content_cache (media_type, release_date)
  WHERE release_date IS NOT NULL;

-- ---------------------------------------------------------------------------
-- get_calendar_events(from_date, to_date)
--
-- Returns all upcoming episodes and movie theatrical releases for the
-- authenticated user's watchlists in a single server-side join.
-- RLS on watchlist_items + watchlists scopes results to the calling user.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_calendar_events(from_date date, to_date date)
RETURNS TABLE (
  watchlist_item_id uuid,
  tmdb_id           integer,
  media_type        text,
  title             text,
  poster_path       text,
  event_date        date,
  event_type        text,    -- 'episode' | 'movie_release'
  episode_code      text,    -- 'S01E05', TV only
  season_number     integer,
  episode_number    integer,
  watchlist_id      uuid,
  watchlist_name    text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  -- Upcoming TV episodes
  SELECT
    wi.id              AS watchlist_item_id,
    wi.tmdb_id,
    'tv'::text         AS media_type,
    cc.title,
    cc.poster_path,
    cce.air_date       AS event_date,
    'episode'::text    AS event_type,
    'S' || LPAD(cce.season_number::text, 2, '0')
      || 'E' || LPAD(cce.episode_number::text, 2, '0') AS episode_code,
    cce.season_number,
    cce.episode_number,
    wi.watchlist_id,
    w.name             AS watchlist_name
  FROM   watchlist_items wi
  JOIN   watchlists w
      ON w.id = wi.watchlist_id
  JOIN   content_cache cc
      ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = 'tv'
  JOIN   content_cache_episodes cce
      ON cce.tmdb_id = wi.tmdb_id
     AND cce.air_date BETWEEN from_date AND to_date
  WHERE  wi.media_type = 'tv'

  UNION ALL

  -- Upcoming theatrical movie releases
  SELECT
    wi.id                  AS watchlist_item_id,
    wi.tmdb_id,
    'movie'::text          AS media_type,
    cc.title,
    cc.poster_path,
    cc.release_date        AS event_date,
    'movie_release'::text  AS event_type,
    NULL::text             AS episode_code,
    NULL::integer          AS season_number,
    NULL::integer          AS episode_number,
    wi.watchlist_id,
    w.name                 AS watchlist_name
  FROM   watchlist_items wi
  JOIN   watchlists w
      ON w.id = wi.watchlist_id
  JOIN   content_cache cc
      ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = 'movie'
  WHERE  wi.media_type = 'movie'
     AND cc.release_date BETWEEN from_date AND to_date

  ORDER BY event_date;
$$;

GRANT EXECUTE ON FUNCTION public.get_calendar_events(date, date) TO authenticated;
