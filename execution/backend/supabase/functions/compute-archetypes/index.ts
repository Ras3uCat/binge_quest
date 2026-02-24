import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface ArchetypeResult {
  new_archetype: string | null;
  prev_archetype: string | null;
}

interface ActiveUser {
  user_id: string;
}

/** Converts a snake_case archetype ID to Title Case for notifications. */
function formatArchetypeName(id: string): string {
  return id
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

Deno.serve(async (req: Request) => {
  try {
    // ── Auth: service_role only ──────────────────────────────────────────────
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

    // Service-role client used for both auth validation and DB operations.
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Accept: (1) service_role key directly, or (2) vault-stored cron secret.
    let isAuthorized = token === serviceRoleKey;

    if (!isAuthorized) {
      // validate_cron_token is a SECURITY DEFINER function that compares the
      // supplied token against the vault secret without exposing the secret value.
      const { data: isValid, error: valError } = await supabase.rpc(
        "validate_cron_token",
        { p_token: token }
      );
      if (!valError && isValid === true) {
        isAuthorized = true;
      }
    }

    if (!isAuthorized) {
      return new Response(
        JSON.stringify({ error: "Service role key or valid cron token required" }),
        {
          status: 403,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // ── Resolve target user(s) ───────────────────────────────────────────────
    let targetUserId: string | null = null;
    if (req.method === "POST") {
      try {
        const body = await req.json();
        targetUserId = body?.user_id ?? null;
      } catch (_) {
        // No body or non-JSON body — treat as batch mode.
      }
    }

    let userIds: string[];

    if (targetUserId) {
      // Single-user mode: compute only the specified user.
      userIds = [targetUserId];
    } else {
      // Batch mode: all users with watch activity in the last 90 days.
      const { data: activeUsers, error: batchError } = await supabase.rpc(
        "get_active_user_ids_90d"
      );
      if (batchError) {
        return new Response(
          JSON.stringify({
            error: "Failed to fetch active users",
            details: batchError.message,
          }),
          {
            status: 500,
            headers: { "Content-Type": "application/json" },
          }
        );
      }
      userIds = (activeUsers as ActiveUser[]).map((row) => row.user_id);
    }

    if (userIds.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          mode: "batch",
          processed: 0,
          skipped: 0,
          notified: 0,
          message: "No active users in 90-day window.",
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json", Connection: "keep-alive" },
        }
      );
    }

    // ── Process each user ────────────────────────────────────────────────────
    let processed = 0;
    let skipped = 0;
    let notified = 0;
    const errors: string[] = [];

    for (const userId of userIds) {
      try {
        const { data: result, error: rpcError } = await supabase.rpc(
          "compute_user_archetype",
          { p_user_id: userId }
        );

        if (rpcError) {
          console.error(`compute_user_archetype failed for ${userId}:`, rpcError.message);
          errors.push(`${userId}: ${rpcError.message}`);
          skipped++;
          continue;
        }

        processed++;

        // ── Notify on archetype change ────────────────────────────────────────
        // new_archetype is null when the user is below the activity threshold.
        // prev_archetype is null on first-ever computation — skip notification
        // for first assignments to avoid spurious "you changed!" messages.
        const { new_archetype, prev_archetype } = result as ArchetypeResult;

        if (
          new_archetype !== null &&
          prev_archetype !== null &&
          new_archetype !== prev_archetype
        ) {
          try {
            await supabase.functions.invoke("send-notification", {
              body: {
                user_id: userId,
                category: "archetype_updates",
                title: "Your viewer archetype changed!",
                body: `You've evolved into: ${formatArchetypeName(new_archetype)}`,
                data: {
                  type: "archetype_change",
                  new_archetype,
                  prev_archetype,
                },
              },
            });
            notified++;
          } catch (notifErr) {
            // Non-fatal: log and continue processing remaining users.
            console.error(`Notification failed for ${userId}:`, notifErr);
          }
        }
      } catch (userErr) {
        console.error(`Unexpected error for ${userId}:`, userErr);
        errors.push(`${userId}: ${String(userErr)}`);
        skipped++;
      }
    }

    // ── Summary response ─────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({
        success: true,
        mode: targetUserId ? "single" : "batch",
        total: userIds.length,
        processed,
        skipped,
        notified,
        ...(errors.length > 0 ? { errors } : {}),
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", Connection: "keep-alive" },
      }
    );
  } catch (err) {
    console.error("compute-archetypes fatal error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(err) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
