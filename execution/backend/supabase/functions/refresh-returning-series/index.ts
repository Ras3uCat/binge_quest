import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const TMDB_BASE = "https://api.themoviedb.org/3";
const RATE_LIMIT_DELAY = 300;
const SHOW_CAP = 100;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

interface CachedShow {
  tmdb_id: number;
  title: string;
  number_of_seasons: number;
  status: string;
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

Deno.serve(async (req: Request) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  // Auth: service_role key or vault cron token
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), { status: 401 });
  }
  const token = authHeader.replace("Bearer ", "");

  let isAuthorized = token === serviceRoleKey;
  if (!isAuthorized) {
    const { data: isValid, error: valError } = await supabase.rpc("validate_cron_token", { p_token: token });
    if (!valError && isValid === true) isAuthorized = true;
  }
  if (!isAuthorized) {
    return new Response(JSON.stringify({ error: "Service role key or valid cron token required" }), { status: 403 });
  }

  const tmdbApiKey = Deno.env.get("TMDB_API_KEY");
  if (!tmdbApiKey) {
    return new Response(JSON.stringify({ error: "TMDB_API_KEY not configured" }), { status: 500 });
  }

  // Fetch Returning Series shows, most stale first
  const { data: shows, error: fetchError } = await supabase
    .from("content_cache")
    .select("tmdb_id, title, number_of_seasons, status")
    .eq("media_type", "tv")
    .eq("status", "Returning Series")
    .order("updated_at", { ascending: true })
    .limit(SHOW_CAP);

  if (fetchError || !shows) {
    return new Response(JSON.stringify({ error: "Failed to fetch shows", details: fetchError?.message }), { status: 500 });
  }

  if (shows.length === 0) {
    return new Response(JSON.stringify({ success: true, checked: 0, updated: 0, new_seasons: 0 }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  let checked = 0;
  let updated = 0;
  let newSeasonsSeeded = 0;
  const errors: string[] = [];

  for (const show of shows as CachedShow[]) {
    try {
      await sleep(RATE_LIMIT_DELAY);

      // Fetch top-level show data from TMDB
      const resp = await fetch(`${TMDB_BASE}/tv/${show.tmdb_id}?api_key=${tmdbApiKey}`);
      if (!resp.ok) {
        console.warn(`TMDB ${resp.status} for ${show.title} (${show.tmdb_id})`);
        errors.push(`${show.title}: TMDB ${resp.status}`);
        continue;
      }

      const tmdb = await resp.json();
      checked++;

      const tmdbSeasons: number = tmdb.number_of_seasons ?? show.number_of_seasons;
      const tmdbStatus: string = tmdb.status ?? show.status;
      const metaChanged =
        tmdbSeasons !== show.number_of_seasons || tmdbStatus !== show.status;

      // Update content_cache if anything changed
      if (metaChanged) {
        await supabase
          .from("content_cache")
          .update({
            number_of_seasons: tmdbSeasons,
            number_of_episodes: tmdb.number_of_episodes ?? null,
            status: tmdbStatus,
            last_air_date: tmdb.last_air_date ?? null,
            updated_at: new Date().toISOString(),
          })
          .eq("tmdb_id", show.tmdb_id)
          .eq("media_type", "tv");

        updated++;
      }

      // Seed any seasons not yet in content_cache_episodes
      if (tmdbSeasons > show.number_of_seasons) {
        for (let s = show.number_of_seasons + 1; s <= tmdbSeasons; s++) {
          await sleep(RATE_LIMIT_DELAY);
          try {
            const seasonResp = await fetch(
              `${TMDB_BASE}/tv/${show.tmdb_id}/season/${s}?api_key=${tmdbApiKey}`
            );
            if (!seasonResp.ok) {
              console.warn(`TMDB ${seasonResp.status} for ${show.title} S${s}`);
              continue;
            }

            const seasonData = await seasonResp.json();
            const episodes: TmdbEpisode[] = seasonData.episodes ?? [];
            if (episodes.length === 0) continue;

            const upsertRows = episodes.map((ep) => ({
              tmdb_id: show.tmdb_id,
              season_number: s,
              episode_number: ep.episode_number,
              episode_name: ep.name || `Episode ${ep.episode_number}`,
              episode_overview: ep.overview || "",
              air_date: ep.air_date || null,
              still_path: ep.still_path || null,
              vote_average: ep.vote_average || null,
              runtime_minutes: ep.runtime || 0,
              updated_at: new Date().toISOString(),
            }));

            const { error: upsertError } = await supabase
              .from("content_cache_episodes")
              .upsert(upsertRows, {
                onConflict: "tmdb_id,season_number,episode_number",
                ignoreDuplicates: false,
              });

            if (upsertError) {
              console.error(`Episode upsert error for ${show.title} S${s}:`, upsertError);
            } else {
              // Create watch_progress rows for all users who have this show
              await supabase.rpc("ensure_episode_progress", {
                p_tmdb_id: show.tmdb_id,
                p_season_number: s,
              });
              newSeasonsSeeded++;
              console.log(`Seeded ${show.title} S${s}: ${upsertRows.length} episodes`);
            }
          } catch (seasonErr) {
            console.error(`Error seeding ${show.title} S${s}:`, seasonErr);
          }
        }
      }
    } catch (showErr) {
      console.error(`Error processing ${show.title}:`, showErr);
      errors.push(`${show.title}: ${String(showErr)}`);
    }
  }

  return new Response(
    JSON.stringify({
      success: true,
      checked,
      updated,
      new_seasons_seeded: newSeasonsSeeded,
      ...(errors.length > 0 ? { errors } : {}),
    }),
    { status: 200, headers: { "Content-Type": "application/json", Connection: "keep-alive" } }
  );
});
