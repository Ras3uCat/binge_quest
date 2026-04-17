import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p/w500';
const RATE_LIMIT_DELAY = 250;

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

interface ShowToCheck {
  tmdb_id: number;
  title: string;
  poster_path: string | null;
  season_number: number;
  watchlist_user_count: number;
  last_detected_count: number | null;
}

interface TmdbEpisode {
  episode_number: number;
  name: string;
  overview: string;
  air_date: string | null;
  still_path: string | null;
  vote_average: number;
  runtime: number | null;
}

function buildEpisodeCopy(
  showTitle: string,
  seasonNumber: number,
  episodeNumber: number,
  episodeCount: number,
  isPremiere: boolean,
): { title: string; body: string } {
  if (isPremiere && episodeCount > 1) {
    return { title: `${showTitle} is back!`, body: `Season ${seasonNumber} just dropped ${episodeCount} episodes.` };
  }
  if (isPremiere) {
    return { title: `${showTitle} is back!`, body: `Season ${seasonNumber} Episode 1 is now available.` };
  }
  if (episodeCount > 1) {
    return { title: `New episodes of ${showTitle}`, body: `Season ${seasonNumber} — ${episodeCount} new episodes available.` };
  }
  return { title: `New episode of ${showTitle}`, body: `Season ${seasonNumber} Episode ${episodeNumber} is now available.` };
}

Deno.serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  const token = req.headers.get('Authorization')?.replace('Bearer ', '');
  if (!token) return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 });

  let isAuthorized = token === serviceRoleKey;
  if (!isAuthorized) {
    const { data: isValid, error: valError } = await supabase.rpc('validate_cron_token', { p_token: token });
    if (!valError && isValid === true) isAuthorized = true;
  }
  if (!isAuthorized) return new Response(JSON.stringify({ error: 'Service role key or valid cron token required' }), { status: 403 });

  const tmdbApiKey = Deno.env.get('TMDB_API_KEY');
  if (!tmdbApiKey) return new Response(JSON.stringify({ error: 'TMDB_API_KEY not configured' }), { status: 500 });

  const { data: shows, error: rpcError } = await supabase
    .rpc('get_tv_shows_for_episode_check', { limit_count: 50 });
  if (rpcError) return new Response(JSON.stringify({ error: 'Failed to get shows' }), { status: 500 });

  if (!shows || shows.length === 0) {
    return new Response(JSON.stringify({ message: 'No shows to check', checked: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  console.log(`Checking ${shows.length} shows for new episodes`);

  const today = new Date().toISOString().split('T')[0];
  let episodesRefreshed = 0;
  let eventsCreated = 0;
  let notificationsSent = 0;
  let airDateNotificationsSent = 0;

  for (const show of shows as ShowToCheck[]) {
    try {
      await sleep(RATE_LIMIT_DELAY);

      // 1. Fetch season data from TMDB
      const url = `${TMDB_BASE}/tv/${show.tmdb_id}/season/${show.season_number}?api_key=${tmdbApiKey}`;
      const resp = await fetch(url);
      if (!resp.ok) {
        console.warn(`TMDB ${resp.status} for ${show.title} S${show.season_number}`);
        continue;
      }

      const seasonData = await resp.json();
      const episodes: TmdbEpisode[] = seasonData.episodes ?? [];
      if (episodes.length === 0) continue;

      // 2. Upsert episode metadata
      const upsertRows = episodes.map(ep => ({
        tmdb_id: show.tmdb_id,
        season_number: show.season_number,
        episode_number: ep.episode_number,
        episode_name: ep.name || `Episode ${ep.episode_number}`,
        episode_overview: ep.overview || '',
        air_date: ep.air_date || null,
        still_path: ep.still_path || null,
        vote_average: ep.vote_average || null,
        runtime_minutes: ep.runtime || 0,
        updated_at: new Date().toISOString(),
      }));

      const { error: upsertError } = await supabase
        .from('content_cache_episodes')
        .upsert(upsertRows, { onConflict: 'tmdb_id,season_number,episode_number', ignoreDuplicates: false });

      if (!upsertError) {
        episodesRefreshed += upsertRows.length;
        const { error: progressError } = await supabase.rpc('ensure_episode_progress', {
          p_tmdb_id: show.tmdb_id,
          p_season_number: show.season_number,
        });
        if (progressError) console.error(`ensure_episode_progress failed for ${show.title}:`, progressError.message);
      }

      // 3. Fetch notifiable users (shared between both paths)
      const { data: watchlistRows, error: wlError } = await supabase
        .from('watchlist_items')
        .select('watchlists!inner(user_id)')
        .eq('tmdb_id', show.tmdb_id)
        .eq('media_type', 'tv');

      if (wlError || !watchlistRows) continue;

      const allUserIds = [
        ...new Set(watchlistRows.map((r: any) => r.watchlists?.user_id).filter(Boolean))
      ] as string[];
      if (allUserIds.length === 0) continue;

      const { data: prefRows } = await supabase
        .from('notification_preferences')
        .select('user_id')
        .in('user_id', allUserIds)
        .eq('new_episodes', true);

      const notifiableIds = (prefRows ?? []).map((r: any) => r.user_id) as string[];
      if (notifiableIds.length === 0) continue;

      // --- PATH A: Air-date trigger ---
      // Fires on the release day itself, even when episode count hasn't changed.
      const todayEps = episodes.filter(ep => ep.air_date === today);

      if (todayEps.length > 0) {
        const todayEpNumbers = todayEps.map(ep => ep.episode_number);

        // Batch-check who's already been notified for any of today's episodes
        const { data: alreadyNotified } = await supabase
          .from('user_notified_episodes')
          .select('user_id')
          .eq('tmdb_id', show.tmdb_id)
          .eq('season_number', show.season_number)
          .in('episode_number', todayEpNumbers)
          .in('user_id', notifiableIds);

        const alreadyNotifiedSet = new Set((alreadyNotified ?? []).map((r: any) => r.user_id));
        const airDateTargets = notifiableIds.filter(uid => !alreadyNotifiedSet.has(uid));

        if (airDateTargets.length > 0) {
          const isPremiere = (show.last_detected_count ?? 0) === 0;
          const firstEp = [...todayEps].sort((a, b) => a.episode_number - b.episode_number)[0];
          const { title: notifTitle, body: notifBody } = buildEpisodeCopy(
            show.title, show.season_number, firstEp.episode_number, todayEps.length, isPremiere,
          );

          for (const userId of airDateTargets) {
            try {
              const { error: fnError } = await supabase.functions.invoke('send-notification', {
                body: {
                  user_id: userId, category: 'new_episodes', title: notifTitle, body: notifBody,
                  ...(show.poster_path ? { image_url: `${TMDB_IMAGE_BASE}${show.poster_path}` } : {}),
                  data: { type: 'new_episode', tmdb_id: String(show.tmdb_id), media_type: 'tv',
                    season_number: String(show.season_number), episode_count: String(todayEps.length) },
                },
              });
              if (!fnError) {
                airDateNotificationsSent++;
                await supabase.from('user_notified_episodes').insert(
                  todayEpNumbers.map(epNum => ({
                    user_id: userId, tmdb_id: show.tmdb_id,
                    season_number: show.season_number, episode_number: epNum,
                  }))
                );
              }
            } catch (err) {
              console.error(`Air-date notification error for ${show.title}:`, err);
            }
          }
          console.log(`${show.title} S${show.season_number}: ${todayEps.length} ep(s) airing today, ${airDateTargets.length} air-date notifications sent`);
        }
      }

      // --- PATH B: Count-delta trigger ---
      // Fires when the aired episode count has increased since last detection.
      const airedEpisodes = episodes.filter(ep => ep.air_date && ep.air_date <= today);
      const airedCount = airedEpisodes.length;
      const lastCount = show.last_detected_count ?? 0;
      if (airedCount <= lastCount) continue;

      const newCount = airedCount - lastCount;
      const isPremiere = lastCount === 0;
      const latestEp = [...airedEpisodes].sort((a, b) => b.episode_number - a.episode_number)[0];

      // Skip users already notified via Path A for the latest episode
      const { data: alreadyNotifiedDelta } = await supabase
        .from('user_notified_episodes')
        .select('user_id')
        .eq('tmdb_id', show.tmdb_id)
        .eq('season_number', show.season_number)
        .eq('episode_number', latestEp.episode_number)
        .in('user_id', notifiableIds);

      const alreadyNotifiedDeltaSet = new Set((alreadyNotifiedDelta ?? []).map((r: any) => r.user_id));
      const deltaTargets = notifiableIds.filter(uid => !alreadyNotifiedDeltaSet.has(uid));
      if (deltaTargets.length === 0) continue;

      const { title: notifTitle, body: notifBody } = buildEpisodeCopy(
        show.title, show.season_number, latestEp.episode_number, newCount, isPremiere,
      );

      const { data: eventRow, error: eventError } = await supabase
        .from('new_episode_events')
        .insert({ tmdb_id: show.tmdb_id, season_number: show.season_number, episode_count: airedCount })
        .select('id')
        .single();

      if (eventError || !eventRow) {
        console.error(`Event insert error for ${show.title}:`, eventError);
        continue;
      }
      eventsCreated++;

      for (const userId of deltaTargets) {
        try {
          const { error: fnError } = await supabase.functions.invoke('send-notification', {
            body: {
              user_id: userId, category: 'new_episodes', title: notifTitle, body: notifBody,
              ...(show.poster_path ? { image_url: `${TMDB_IMAGE_BASE}${show.poster_path}` } : {}),
              data: { type: 'new_episode', tmdb_id: String(show.tmdb_id), media_type: 'tv',
                season_number: String(show.season_number), episode_count: String(airedCount) },
            },
          });
          if (!fnError) {
            notificationsSent++;
            await supabase.from('user_episode_notifications').insert({
              user_id: userId, event_id: eventRow.id, notified_at: new Date().toISOString(),
            });
            // Cross-dedup: prevent Path A from re-firing for the same episode
            await supabase.from('user_notified_episodes').insert({
              user_id: userId, tmdb_id: show.tmdb_id,
              season_number: show.season_number, episode_number: latestEp.episode_number,
            });
          }
        } catch (err) {
          console.error(`Delta notification error for ${show.title}:`, err);
        }
      }

      console.log(`${show.title} S${show.season_number}: ${airedCount} aired, ${deltaTargets.length} delta notifications sent`);

    } catch (showErr) {
      console.error(`Error processing ${show.title}:`, showErr);
    }
  }

  return new Response(JSON.stringify({
    success: true,
    shows_checked: shows.length,
    episodes_refreshed: episodesRefreshed,
    new_events_created: eventsCreated,
    notifications_sent: notificationsSent,
    air_date_notifications_sent: airDateNotificationsSent,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
