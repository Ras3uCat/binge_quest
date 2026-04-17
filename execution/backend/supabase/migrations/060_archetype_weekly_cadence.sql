-- Switch archetype computation from daily cron → weekly cron + on-demand frontend trigger.
-- A 90-day rolling window changes too slowly for daily snapshots to be meaningful.

-- Step 1: Reschedule cron from daily (0 3 * * *) to weekly (Sunday 3am UTC).
SELECT cron.unschedule('nightly-compute-archetypes');
SELECT cron.schedule(
  'weekly-compute-archetypes',
  '0 3 * * 0',
  'SELECT private.cron_compute_archetypes()'
);

-- Step 2: Replace compute_user_archetype with updated guards:
--   (a) Caller identity check — prevents an authenticated user from computing for another user.
--       Service-role calls (cron/edge function) have auth.uid() = NULL, so they bypass this.
--   (b) Staleness guard changed from "already computed today" → "already computed this week (7 days)".
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
  -- (a) Identity check: authenticated callers may only compute their own archetype.
  IF auth.uid() IS NOT NULL AND auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'permission denied';
  END IF;

  SELECT COALESCE(np.timezone, 'UTC') INTO v_tz
  FROM notification_preferences np WHERE np.user_id = p_user_id;
  v_tz := COALESCE(v_tz, 'UTC');

  -- (b) Skip if already computed within the last 7 days.
  IF EXISTS (
    SELECT 1 FROM user_archetypes
    WHERE user_id = p_user_id
      AND computed_at >= now() - interval '7 days'
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
