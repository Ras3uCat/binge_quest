import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';
import admin from 'npm:firebase-admin@12.0.0';

interface NotificationPayload {
    user_id: string;
    category: string;
    title: string;
    body: string;
    image_url?: string;
    data?: Record<string, string>; // FCM data values must be strings
}

// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
    const serviceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccount) {
        throw new Error('Missing FIREBASE_SERVICE_ACCOUNT environment variable');
    }

    admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(serviceAccount)),
    });
}

Deno.serve(async (req) => {
    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        );

        // Handle CORS
        if (req.method === 'OPTIONS') {
            return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
        }

        // Verify caller is authenticated (user JWT or service_role key)
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 });
        }
        const token = authHeader.replace('Bearer ', '');
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const isServiceRole = token === serviceRoleKey;
        if (!isServiceRole) {
            const { data: { user }, error: authError } = await supabase.auth.getUser(token);
            if (authError || !user) {
                return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 401 });
            }
        }

        const payload: NotificationPayload = await req.json();

        // 1. Check user preferences
        const { data: prefs, error: prefsError } = await supabase
            .from('notification_preferences')
            .select('*')
            .eq('user_id', payload.user_id)
            .maybeSingle();

        if (prefsError) {
            console.error('Error fetching preferences:', prefsError);
        }

        // Check specific category preference
        if (prefs && prefs[payload.category] === false) {
            console.log(`Notification skipped: User disabled category '${payload.category}'`);
            return new Response(JSON.stringify({ skipped: 'disabled_by_user' }), {
                status: 200,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        // 2. Store in-app notification
        const { error: insertError } = await supabase.from('notifications').insert({
            user_id: payload.user_id,
            category: payload.category,
            title: payload.title,
            body: payload.body,
            image_url: payload.image_url,
            data: payload.data || {},
        });

        if (insertError) {
            console.error('Error storing notification:', insertError);
            return new Response(JSON.stringify({ error: 'Failed to store notification' }), { status: 500 });
        }

        // 3. Get user's device tokens
        const { data: tokens, error: tokenError } = await supabase
            .from('user_device_tokens')
            .select('fcm_token')
            .eq('user_id', payload.user_id);

        if (tokenError) {
            console.error('Error fetching tokens:', tokenError);
            return new Response(JSON.stringify({ error: 'Failed to fetch tokens' }), { status: 500 });
        }

        if (!tokens || tokens.length === 0) {
            console.log('No devices registered for user');
            return new Response(JSON.stringify({ sent: 0, in_app: true, message: 'No devices found' }), {
                status: 200,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        // 4. Send FCM push to all devices
        const messages = tokens.map((t) => ({
            token: t.fcm_token,
            notification: {
                title: payload.title,
                body: payload.body,
                ...(payload.image_url ? { imageUrl: payload.image_url } : {}),
            },
            ...(payload.data ? { data: payload.data } : {}),
            android: {
                priority: 'high' as const,
                notification: {
                    channelId: 'high_importance_channel',
                    sound: 'default',
                    ...(payload.image_url ? { imageUrl: payload.image_url } : {}),
                }
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
                fcmOptions: {
                    ...(payload.image_url ? { image: payload.image_url } : {}),
                }
            }
        }));

        const batchResponse = await admin.messaging().sendEach(messages as any);

        // Collect stale tokens to delete
        const staleTokens: string[] = [];
        batchResponse.responses.forEach((resp, i) => {
            if (!resp.success) {
                const code = resp.error?.code ?? '';
                console.error(`FCM send failed for token ${i}: ${code}`);
                if (
                    code === 'messaging/registration-token-not-registered' ||
                    code === 'messaging/invalid-registration-token'
                ) {
                    staleTokens.push(tokens[i].fcm_token);
                }
            }
        });

        // Delete stale tokens so they don't accumulate
        if (staleTokens.length > 0) {
            const { error: deleteError } = await supabase
                .from('user_device_tokens')
                .delete()
                .in('fcm_token', staleTokens);
            if (deleteError) {
                console.error('Failed to delete stale tokens:', deleteError);
            } else {
                console.log(`Deleted ${staleTokens.length} stale token(s)`);
            }
        }

        return new Response(JSON.stringify({
            success: true,
            sent_count: batchResponse.successCount,
            failure_count: batchResponse.failureCount,
            stale_tokens_removed: staleTokens.length,
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
