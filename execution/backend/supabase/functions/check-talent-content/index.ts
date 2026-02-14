import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const TMDB_BASE = "https://api.themoviedb.org/3";
const RATE_LIMIT_DELAY = 250; // ms between TMDB calls

interface PersonToCheck {
  tmdb_person_id: number;
  person_name: string;
  follower_count: number;
}

interface TmdbCredit {
  id: number;
  title?: string;
  name?: string;
  media_type: string;
  release_date?: string;
  first_air_date?: string;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Determines if a credit is "new" — released within the last 90 days
 * or upcoming (release date in the future).
 */
function isNewContent(credit: TmdbCredit): boolean {
  const dateStr = credit.release_date || credit.first_air_date;
  if (!dateStr) return false;
  const releaseDate = new Date(dateStr);
  const now = new Date();
  const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
  return releaseDate >= ninetyDaysAgo;
}

Deno.serve(async (req: Request) => {
  try {
    // --- Auth: validate user JWT ---
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const tmdbApiKey = Deno.env.get("TMDB_API_KEY")!;

    // Service-role client for DB writes
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Validate caller
    if (token !== serviceRoleKey) {
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (authError || !user) {
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // --- 1. Get persons to check ---
    const { data: persons, error: rpcError } = await supabase
      .rpc("get_followed_persons_to_check", { limit_count: 50 });

    if (rpcError) {
      return new Response(JSON.stringify({ error: "RPC failed", details: rpcError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!persons || persons.length === 0) {
      return new Response(JSON.stringify({ message: "No followed persons to check", checked: 0 }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    let totalChecked = 0;
    let totalNewContent = 0;
    let totalNotifications = 0;
    const results: Array<{ person_id: number; person_name: string; new_content: number; notifications: number }> = [];

    // --- 2. For each person, poll TMDB combined_credits ---
    for (const person of persons as PersonToCheck[]) {
      try {
        await sleep(RATE_LIMIT_DELAY);

        const tmdbUrl = `${TMDB_BASE}/person/${person.tmdb_person_id}/combined_credits?api_key=${tmdbApiKey}`;
        const tmdbRes = await fetch(tmdbUrl);

        if (!tmdbRes.ok) {
          console.error(`TMDB error for person ${person.tmdb_person_id}: ${tmdbRes.status}`);
          continue;
        }

        const tmdbData = await tmdbRes.json();
        const allCredits: TmdbCredit[] = [
          ...(tmdbData.cast || []),
          ...(tmdbData.crew || []).filter((c: { job?: string }) =>
            c.job === "Director" || c.job === "Executive Producer"
          ),
        ];

        // Deduplicate by content ID
        const seen = new Set<number>();
        const uniqueCredits = allCredits.filter((c) => {
          if (seen.has(c.id)) return false;
          seen.add(c.id);
          return true;
        });

        // Filter to new/upcoming content
        const newCredits = uniqueCredits.filter(isNewContent);

        let personNewContent = 0;
        let personNotifications = 0;

        // --- 3. For each new credit, check if we already logged it ---
        for (const credit of newCredits) {
          const contentTitle = credit.title || credit.name || "Unknown";
          const mediaType = credit.media_type === "movie" ? "movie" : "tv";

          // Upsert into talent_content_events (skip if already exists)
          const { data: eventData, error: insertError } = await supabase
            .from("talent_content_events")
            .upsert(
              {
                tmdb_person_id: person.tmdb_person_id,
                tmdb_content_id: credit.id,
                media_type: mediaType,
                content_title: contentTitle,
                detected_at: new Date().toISOString(),
              },
              { onConflict: "tmdb_person_id,tmdb_content_id", ignoreDuplicates: true }
            )
            .select();

          // If ignoreDuplicates returned no rows, this event was already known
          if (!eventData || eventData.length === 0) continue;

          personNewContent++;

          // --- 4. Get followers to notify ---
          const { data: followers, error: followersError } = await supabase
            .rpc("get_followers_of_person", { p_tmdb_person_id: person.tmdb_person_id });

          if (followersError || !followers || followers.length === 0) continue;

          // --- 5. Send notifications ---
          let notifiedCount = 0;
          for (const follower of followers) {
            try {
              await supabase.functions.invoke("send-notification", {
                body: {
                  user_id: follower.user_id,
                  category: "talent_releases",
                  title: `New from ${person.person_name}!`,
                  body: `${contentTitle} (${mediaType === "movie" ? "Movie" : "TV Show"}) — featuring ${person.person_name}`,
                  data: {
                    type: "talent_release",
                    tmdb_id: String(credit.id),
                    media_type: mediaType,
                    content_title: contentTitle,
                    person_name: person.person_name,
                    person_id: String(person.tmdb_person_id),
                  },
                },
              });
              notifiedCount++;
            } catch (notifErr) {
              console.error(`Notification failed for user ${follower.user_id}:`, notifErr);
            }
          }

          // Update notified count on the event
          if (notifiedCount > 0) {
            await supabase
              .from("talent_content_events")
              .update({ notified_user_count: notifiedCount })
              .eq("tmdb_person_id", person.tmdb_person_id)
              .eq("tmdb_content_id", credit.id);
          }

          personNotifications += notifiedCount;
        }

        totalChecked++;
        totalNewContent += personNewContent;
        totalNotifications += personNotifications;
        results.push({
          person_id: person.tmdb_person_id,
          person_name: person.person_name,
          new_content: personNewContent,
          notifications: personNotifications,
        });
      } catch (personErr) {
        console.error(`Error checking person ${person.tmdb_person_id}:`, personErr);
        continue;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        checked: totalChecked,
        new_content_detected: totalNewContent,
        notifications_sent: totalNotifications,
        results,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", "Connection": "keep-alive" },
      }
    );
  } catch (err) {
    console.error("check-talent-content error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(err) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
