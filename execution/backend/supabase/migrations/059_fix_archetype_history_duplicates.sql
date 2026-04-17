-- Fix: Archetype history duplicate entries
-- Root cause: ON CONFLICT key uses full timestamp; hourly cron inserts 12 new rows
--             every hour because each hour's now() differs — no conflict is ever triggered.
-- Fix: (1) cleanup existing dupes, (2) unique index at date level, (3) date-level guard in function.

-- Step 1: Cleanup — keep only the latest run per (user_id, archetype_id, calendar day UTC).
-- Each run inserts 12 rows sharing the same computed_at; we keep the latest set.
DELETE FROM user_archetypes
WHERE id NOT IN (
  SELECT DISTINCT ON (user_id, archetype_id, (computed_at AT TIME ZONE 'UTC')::date) id
  FROM user_archetypes
  ORDER BY user_id, archetype_id, (computed_at AT TIME ZONE 'UTC')::date, computed_at DESC
);

-- Step 2: Unique index — one score per archetype per user per UTC calendar day.
-- Uses (computed_at AT TIME ZONE 'UTC')::date which is immutable (literal timezone).
-- This is a safety net; the function guard (step 3) is the primary enforcement.
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_archetypes_user_archetype_date
  ON public.user_archetypes (user_id, archetype_id, ((computed_at AT TIME ZONE 'UTC')::date));

-- Step 3: Replace function with date-level guard.
-- Guard uses user's local timezone so midnight in their zone resets the window.
CREATE OR REPLACE FUNCTION public.compute_user_archetype(p_user_id uuid)
 RETURNS archetype_result
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_window      timestamptz := now() - interval '90 days';
  v_tz          text;
  v_completed   int;
  v_eps_watched int;
  v_now         timestamptz := now();
  v_prev        text;
  v_top1_id     text;
  v_top1_score  numeric(4,3);
  v_top2_id     text;
  v_top2_score  numeric(4,3);
  v_gl_score    numeric(4,3);
  v_gl_genre    integer;
  result        public.archetype_result;
BEGIN
  SELECT COALESCE(np.timezone, 'UTC') INTO v_tz
  FROM notification_preferences np WHERE np.user_id = p_user_id;
  v_tz := COALESCE(v_tz, 'UTC');

  -- Skip if already computed today (in user's local timezone)
  IF EXISTS (
    SELECT 1 FROM user_archetypes
    WHERE user_id = p_user_id
      AND DATE(computed_at AT TIME ZONE v_tz) = DATE(now() AT TIME ZONE v_tz)
  ) THEN
    SELECT primary_archetype INTO result.prev_archetype FROM users WHERE id = p_user_id;
    result.new_archetype := result.prev_archetype;
    RETURN result;
  END IF;

  SELECT
    COUNT(DISTINCT wi.tmdb_id) FILTER (WHERE wp.watched = true),
    COUNT(*)                   FILTER (WHERE wp.watched = true AND wi.media_type = 'tv')
  INTO v_completed, v_eps_watched
  FROM watch_progress  wp
  JOIN watchlist_items wi ON wi.id = wp.watchlist_item_id
  JOIN watchlists      w  ON w.id  = wi.watchlist_id
  WHERE w.user_id = p_user_id AND wp.watched_at >= v_window;

  IF v_completed < 5 OR v_eps_watched < 20 THEN
    result.new_archetype  := NULL;
    SELECT primary_archetype INTO result.prev_archetype FROM users WHERE id = p_user_id;
    RETURN result;
  END IF;

  SELECT s.score, s.dominant_genre_id
  INTO v_gl_score, v_gl_genre
  FROM public._score_genre_loyalist(p_user_id, v_window) s;

  WITH raw_scores (archetype_id, score) AS (
    VALUES
      ('weekend_warrior'::text,   public._score_weekend_warrior(p_user_id, v_window, v_tz)),
      ('genre_loyalist'::text,    v_gl_score),
      ('sampler_surfer'::text,    public._score_sampler_surfer(p_user_id, v_window)),
      ('season_slayer'::text,     public._score_season_slayer(p_user_id, v_window)),
      ('backlog_excavator'::text, public._score_backlog_excavator(p_user_id, v_window)),
      ('midnight_drifter'::text,  public._score_midnight_drifter(p_user_id, v_window, v_tz)),
      ('social_curator'::text,    public._score_social_curator(p_user_id, v_window)),
      ('binge_sprinter'::text,    public._score_binge_sprinter(p_user_id, v_window)),
      ('mood_surfer'::text,       public._score_mood_surfer(p_user_id, v_window, v_tz)),
      ('finish_first'::text,      public._score_finish_first(p_user_id, v_window)),
      ('trend_chaser'::text,      public._score_trend_chaser(p_user_id, v_window)),
      ('deep_cut'::text,          public._score_deep_cut(p_user_id, v_window))
  ),
  ranked AS (
    SELECT archetype_id, score, RANK() OVER (ORDER BY score DESC)::smallint AS rnk
    FROM raw_scores
  )
  INSERT INTO public.user_archetypes (user_id, archetype_id, score, rank, computed_at, metadata)
  SELECT
    p_user_id, r.archetype_id, r.score, r.rnk, v_now,
    CASE WHEN r.archetype_id = 'genre_loyalist' AND v_gl_genre IS NOT NULL
         THEN jsonb_build_object('dominant_genre_id', v_gl_genre)
         ELSE NULL END
  FROM ranked r
  ON CONFLICT (user_id, archetype_id, computed_at) DO NOTHING;

  SELECT archetype_id, score INTO v_top1_id, v_top1_score
  FROM user_archetypes WHERE user_id = p_user_id AND computed_at = v_now AND rank = 1 LIMIT 1;

  SELECT archetype_id, score INTO v_top2_id, v_top2_score
  FROM user_archetypes WHERE user_id = p_user_id AND computed_at = v_now AND rank = 2 LIMIT 1;

  IF (v_top1_score - v_top2_score) > 0.05 THEN v_top2_id := NULL; END IF;

  SELECT primary_archetype INTO v_prev FROM users WHERE id = p_user_id;

  UPDATE users SET
    primary_archetype    = v_top1_id,
    secondary_archetype  = v_top2_id,
    archetype_updated_at = v_now
  WHERE id = p_user_id;

  result.new_archetype  := v_top1_id;
  result.prev_archetype := v_prev;
  RETURN result;
END;
$function$
;
