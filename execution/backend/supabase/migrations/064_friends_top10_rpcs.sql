-- Migration: 064_friends_top10_rpcs.sql
-- Adds two SECURITY DEFINER RPCs that mirror get_top_10_by_users and
-- get_top_10_by_rating but scoped to the calling user's accepted friends.

CREATE OR REPLACE FUNCTION public.get_friends_top10_by_users()
  RETURNS TABLE (
    tmdb_id             integer,
    media_type          text,
    title               text,
    poster_path         text,
    user_count          bigint,
    streaming_providers jsonb
  )
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = 'public'
AS $$
  WITH friend_ids AS (
    SELECT addressee_id AS friend_id FROM friendships
      WHERE requester_id = auth.uid() AND status = 'accepted'
    UNION
    SELECT requester_id AS friend_id FROM friendships
      WHERE addressee_id = auth.uid() AND status = 'accepted'
  ),
  friend_watchlist_users AS (
    SELECT id AS watchlist_id, user_id FROM watchlists
      WHERE user_id IN (SELECT friend_id FROM friend_ids)
    UNION ALL
    SELECT watchlist_id, user_id FROM watchlist_members
      WHERE status = 'accepted'
      AND user_id IN (SELECT friend_id FROM friend_ids)
  )
  SELECT
    wi.tmdb_id,
    wi.media_type,
    cc.title,
    cc.poster_path,
    COUNT(DISTINCT fwu.user_id) AS user_count,
    cc.streaming_providers
  FROM watchlist_items wi
  JOIN friend_watchlist_users fwu ON wi.watchlist_id = fwu.watchlist_id
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = wi.tmdb_id AND cc.media_type = wi.media_type
  GROUP BY wi.tmdb_id, wi.media_type, cc.title, cc.poster_path, cc.streaming_providers
  ORDER BY user_count DESC
  LIMIT 10;
$$;

CREATE OR REPLACE FUNCTION public.get_friends_top10_by_rating()
  RETURNS TABLE (
    tmdb_id             integer,
    media_type          text,
    title               text,
    poster_path         text,
    average_rating      numeric,
    review_count        bigint,
    streaming_providers jsonb
  )
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = 'public'
AS $$
  WITH friend_ids AS (
    SELECT addressee_id AS friend_id FROM friendships
      WHERE requester_id = auth.uid() AND status = 'accepted'
    UNION
    SELECT requester_id AS friend_id FROM friendships
      WHERE addressee_id = auth.uid() AND status = 'accepted'
  )
  SELECT
    r.tmdb_id,
    r.media_type,
    cc.title,
    cc.poster_path,
    ROUND(AVG(r.rating)::NUMERIC, 1) AS average_rating,
    COUNT(*) AS review_count,
    cc.streaming_providers
  FROM reviews r
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = r.tmdb_id AND cc.media_type = r.media_type
  WHERE r.user_id IN (SELECT friend_id FROM friend_ids)
  GROUP BY r.tmdb_id, r.media_type, cc.title, cc.poster_path, cc.streaming_providers
  ORDER BY average_rating DESC, review_count DESC
  LIMIT 10;
$$;
