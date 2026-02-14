import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p/original';
const RATE_LIMIT_DELAY = 250; // ms between TMDB calls

interface HotItem {
    tmdb_id: number;
    media_type: string;
    title: string;
    streaming_providers: any[] | null;
    updated_at: string;
    watchlist_user_count: number;
}

interface TmdbProvider {
    provider_id: number;
    provider_name: string;
    logo_path: string | null;
}

interface ProvidersByType {
    flatrate?: TmdbProvider[];
    free?: TmdbProvider[];
    rent?: TmdbProvider[];
    buy?: TmdbProvider[];
}

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

Deno.serve(async (req) => {
    const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    try {
        // Handle CORS
        if (req.method === 'OPTIONS') {
            return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
        }

        // Verify caller is authenticated
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 });
        }
        const token = authHeader.replace('Bearer ', '');
        const { data: { user }, error: authError } = await supabase.auth.getUser(token);
        if (authError || !user) {
            return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 401 });
        }

        const tmdbApiKey = Deno.env.get('TMDB_API_KEY');
        if (!tmdbApiKey) {
            return new Response(JSON.stringify({ error: 'TMDB_API_KEY not configured' }), { status: 500 });
        }

        // 1. Get hot items via RPC
        const { data: hotItems, error: rpcError } = await supabase
            .rpc('get_hot_watchlist_items_for_streaming_check', { limit_count: 50 });

        if (rpcError) {
            console.error('RPC error:', rpcError);
            return new Response(JSON.stringify({ error: 'Failed to get hot items' }), { status: 500 });
        }

        if (!hotItems || hotItems.length === 0) {
            return new Response(JSON.stringify({ message: 'No items to check', checked: 0 }), {
                status: 200,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        console.log(`Checking ${hotItems.length} hot items for streaming changes`);

        let totalChanges = 0;
        let totalNotifications = 0;
        const results: any[] = [];

        // 2. Process each item
        for (const item of hotItems as HotItem[]) {
            try {
                await sleep(RATE_LIMIT_DELAY);

                // Fetch current providers from TMDB
                const tmdbUrl = `${TMDB_BASE}/${item.media_type}/${item.tmdb_id}/watch/providers?api_key=${tmdbApiKey}`;
                const tmdbResponse = await fetch(tmdbUrl);

                if (!tmdbResponse.ok) {
                    console.warn(`TMDB ${tmdbResponse.status} for ${item.title} (${item.tmdb_id})`);
                    continue;
                }

                const tmdbData = await tmdbResponse.json();
                const usData: ProvidersByType | undefined = tmdbData?.results?.US;

                // Build current provider list from all types
                const currentProviders: Map<number, { name: string; logo_path: string | null; type: string }> = new Map();

                for (const providerType of ['flatrate', 'free', 'rent', 'buy'] as const) {
                    const providers = usData?.[providerType] as TmdbProvider[] | undefined;
                    if (providers) {
                        for (const p of providers) {
                            if (!currentProviders.has(p.provider_id)) {
                                currentProviders.set(p.provider_id, {
                                    name: p.provider_name,
                                    logo_path: p.logo_path,
                                    type: providerType,
                                });
                            }
                        }
                    }
                }

                // Compare to cached providers
                const cachedProviderIds = new Set<number>(
                    (item.streaming_providers || []).map((p: any) => p.id)
                );

                const newProviders: { id: number; name: string; logo_path: string | null; type: string }[] = [];
                for (const [id, info] of currentProviders) {
                    if (!cachedProviderIds.has(id)) {
                        newProviders.push({ id, ...info });
                    }
                }

                // 3. Process new providers
                if (newProviders.length > 0) {
                    console.log(`${item.title}: ${newProviders.length} new provider(s) — ${newProviders.map(p => p.name).join(', ')}`);

                    for (const provider of newProviders) {
                        // Insert streaming_change_event
                        const { error: eventError } = await supabase
                            .from('streaming_change_events')
                            .insert({
                                tmdb_id: item.tmdb_id,
                                media_type: item.media_type,
                                provider_id: provider.id,
                                provider_name: provider.name,
                                provider_type: provider.type,
                                change_type: 'added',
                            });

                        if (eventError) {
                            console.error('Error inserting change event:', eventError);
                            continue;
                        }

                        totalChanges++;

                        // Find users to notify via RPC
                        const { data: usersToNotify, error: notifyError } = await supabase
                            .rpc('get_users_to_notify_for_provider', {
                                p_tmdb_id: item.tmdb_id,
                                p_media_type: item.media_type,
                                p_provider_id: provider.id,
                                p_provider_type: provider.type,
                            });

                        if (notifyError) {
                            console.error('Error getting users to notify:', notifyError);
                            continue;
                        }

                        if (usersToNotify && usersToNotify.length > 0) {
                            // Send notification to each user via send-notification Edge Function
                            for (const row of usersToNotify) {
                                try {
                                    const notificationPayload = {
                                        user_id: row.user_id,
                                        category: 'streaming_alerts',
                                        title: `Now on ${provider.name}!`,
                                        body: `${item.title} is now available on ${provider.name}`,
                                        ...(provider.logo_path ? {
                                            image_url: `${TMDB_IMAGE_BASE}${provider.logo_path}`
                                        } : {}),
                                        data: {
                                            type: 'streaming_alert',
                                            tmdb_id: String(item.tmdb_id),
                                            media_type: item.media_type,
                                            provider_name: provider.name,
                                            provider_id: String(provider.id),
                                        },
                                    };

                                    // Call send-notification directly via Supabase internal URL
                                    const { error: fnError } = await supabase.functions.invoke('send-notification', {
                                        body: notificationPayload,
                                    });

                                    if (fnError) {
                                        console.error(`Error sending notification to ${row.user_id}:`, fnError);
                                    } else {
                                        totalNotifications++;
                                    }
                                } catch (notifErr) {
                                    console.error(`Notification send error:`, notifErr);
                                }
                            }

                            // Update notified_user_count on the event
                            // (get the latest event for this provider/content combo)
                            await supabase
                                .from('streaming_change_events')
                                .update({ notified_user_count: usersToNotify.length })
                                .eq('tmdb_id', item.tmdb_id)
                                .eq('media_type', item.media_type)
                                .eq('provider_id', provider.id)
                                .eq('change_type', 'added')
                                .order('detected_at', { ascending: false })
                                .limit(1);
                        }
                    }
                }

                // 4. Update content_cache with fresh provider data (flatrate + free only, matching existing format)
                const freshProviders = [];
                for (const providerType of ['flatrate', 'free'] as const) {
                    const providers = usData?.[providerType] as TmdbProvider[] | undefined;
                    if (providers) {
                        for (const p of providers) {
                            if (!freshProviders.some(fp => fp.id === p.provider_id)) {
                                freshProviders.push({
                                    id: p.provider_id,
                                    name: p.provider_name,
                                    logo_path: p.logo_path,
                                });
                            }
                        }
                    }
                }

                await supabase
                    .from('content_cache')
                    .update({
                        streaming_providers: freshProviders.length > 0 ? freshProviders : null,
                        updated_at: new Date().toISOString(),
                    })
                    .eq('tmdb_id', item.tmdb_id)
                    .eq('media_type', item.media_type);

                results.push({
                    title: item.title,
                    tmdb_id: item.tmdb_id,
                    new_providers: newProviders.length,
                    cached_count: freshProviders.length,
                });

            } catch (itemErr) {
                console.error(`Error processing ${item.title}:`, itemErr);
            }
        }

        return new Response(JSON.stringify({
            success: true,
            checked: hotItems.length,
            changes_detected: totalChanges,
            notifications_sent: totalNotifications,
            results,
        }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
        });

    } catch (err) {
        console.error('Unexpected error:', err);
        return new Response(JSON.stringify({ error: 'Internal Server Error', details: String(err) }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        });
    }
});
