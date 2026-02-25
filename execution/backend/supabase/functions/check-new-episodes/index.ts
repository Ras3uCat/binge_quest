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

Deno.serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  // Auth: accept service_role key OR vault-stored cron secret (same as compute-archetypes)
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 });
  }
  const token = authHeader.replace('Bearer ', '');

  let isAuthorized = token === Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!isAuthorized) {
    const { data: isValid, error: valError } = await supabase.rpc('validate_cron_token', { p_token: token });
    if (!valError && isValid === true) isAuthorized = true;
  }
  if (!isAuthorized) {
    return new Response(JSON.stringify({ error: 'Service role key or valid cron token required' }), { status: 403 });
  }

  const tmdbApiKey = Deno.env.get('TMDB_API_KEY');
  if (!tmdbApiKey) {
    return new Response(JSON.stringify({ error: 'TMDB_API_KEY not configured' }), { status: 500 });;
  }

  // 1. Get shows to check
  const { data: shows, error: rpcError } = await supabase
    .rpc('get_tv_shows_for_episode_check', { limit_count: 50 });

  if (rpcError) {
    console.error('RPC error:', rpcError);
    return new Response(JSON.stringify({ error: 'Failed to get shows' }), { status: 500 });
  }

  if (!shows || shows.length === 0) {
    return new Response(JSON.stringify({ message: 'No shows to check', checked: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  console.log(`Checking ${shows.length} shows for new episodes`);

  let episodesRefreshed = 0;
  let eventsCreated = 0;
  let notificationsSent = 0;
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

  for (const show of shows as ShowToCheck[]) {
    try {
      await sleep(RATE_LIMIT_DELAY);

      // 2. Fetch season data from TMDB
      const url = `${TMDB_BASE}/tv/${show.tmdb_id}/season/${show.season_number}?api_key=${tmdbApiKey}`;
      const resp = await fetch(url);
      if (!resp.ok) {
        console.warn(`TMDB ${resp.status} for ${show.title} S${show.season_number}`);
        continue;
      }

      const seasonData = await resp.json();
      const episodes: TmdbEpisode[] = seasonData.episodes ?? [];
      if (episodes.length === 0) continue;

      // 3. Upsert episode metadata — replaces stale "Episode N" placeholders
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
        .upsert(upsertRows, {
          onConflict: 'tmdb_id,season_number,episode_number',
          ignoreDuplicates: false,
        });

      if (upsertError) {
        console.error(`Episode upsert error for ${show.title}:`, upsertError);
      } else {
        episodesRefreshed += upsertRows.length;
      }

      // 4. Count episodes that have aired (air_date <= today)
      const airedEpisodes = episodes.filter(ep => ep.air_date && ep.air_date <= today);
      const airedCount = airedEpisodes.length;
      if (airedCount === 0) continue;

      const lastCount = show.last_detected_count ?? 0;
      if (airedCount <= lastCount) continue; // nothing new since last detection

      // 5. Build notification copy
      const newCount = airedCount - lastCount;
      const isPremiere = lastCount === 0;
      const latestEp = airedEpisodes.sort((a, b) => b.episode_number - a.episode_number)[0];

      let notifTitle: string;
      let notifBody: string;
      if (isPremiere && newCount > 1) {
        notifTitle = `${show.title} is back!`;
        notifBody = `Season ${show.season_number} just dropped ${newCount} episodes.`;
      } else if (isPremiere) {
        notifTitle = `${show.title} is back!`;
        notifBody = `Season ${show.season_number} Episode 1 is now available.`;
      } else {
        notifTitle = `New episode of ${show.title}`;
        notifBody = `Season ${show.season_number} Episode ${latestEp.episode_number} is now available.`;
      }

      // 6. Insert new_episode_events
      const { data: eventRow, error: eventError } = await supabase
        .from('new_episode_events')
        .insert({
          tmdb_id: show.tmdb_id,
          season_number: show.season_number,
          episode_count: airedCount,
        })
        .select('id')
        .single();

      if (eventError || !eventRow) {
        console.error(`Event insert error for ${show.title}:`, eventError);
        continue;
      }
      eventsCreated++;

      // 7. Find users with this show in any watchlist
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

      // 8. Filter to users with new_episodes notifications enabled
      const { data: prefRows } = await supabase
        .from('notification_preferences')
        .select('user_id')
        .in('user_id', allUserIds)
        .eq('new_episodes', true);

      const notifiableIds = (prefRows ?? []).map((r: any) => r.user_id) as string[];

      // 9. Notify each user
      for (const userId of notifiableIds) {
        try {
          const { error: fnError } = await supabase.functions.invoke('send-notification', {
            body: {
              user_id: userId,
              category: 'new_episodes',
              title: notifTitle,
              body: notifBody,
              ...(show.poster_path
                ? { image_url: `${TMDB_IMAGE_BASE}${show.poster_path}` }
                : {}),
              data: {
                type: 'new_episode',
                tmdb_id: String(show.tmdb_id),
                media_type: 'tv',
                season_number: String(show.season_number),
                episode_count: String(airedCount),
              },
            },
          });

          if (fnError) {
            console.error(`Notification error for user ${userId}:`, fnError);
          } else {
            notificationsSent++;
            await supabase.from('user_episode_notifications').insert({
              user_id: userId,
              event_id: eventRow.id,
              notified_at: new Date().toISOString(),
            });
          }
        } catch (notifErr) {
          console.error('Notification send error:', notifErr);
        }
      }

      console.log(`${show.title} S${show.season_number}: ${airedCount} aired, ${notifiableIds.length} users notified`);

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
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
