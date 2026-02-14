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
        // We assume the table is 'notification_preferences'
        const { data: prefs, error: prefsError } = await supabase
            .from('notification_preferences')
            .select('*')
            .eq('user_id', payload.user_id)
            .maybeSingle();

        if (prefsError) {
            console.error('Error fetching preferences:', prefsError);
            // Fallback: Proceed if error? Or fail? Let's log and proceed assuming defaults if not found.
        }

        // Check specific category preference
        if (prefs && prefs[payload.category] === false) {
            console.log(`Notification skipped: User disabled category '${payload.category}'`);
            return new Response(JSON.stringify({ skipped: 'disabled_by_user' }), {
                status: 200,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        // 2. Check quiet hours
        if (prefs?.quiet_hours_start && prefs?.quiet_hours_end) {
            // Basic time comparison logic (UTC vs Local is tricky without user timezone)
            // Ideally, we store quiet hours in UTC or store user's timezone.
            // For MVP, we will skip complex timezone logic here unless provided in payload context.
            // But let's implement the basic check assuming server time or rough heuristic if needed.
            // NOTE: This implementation assumes the times are stored without timezone and we act on UTC or ignore for now
            // to avoid blocking messages incorrectly.
            // TODO: Implement time-zone aware quiet hours.
        }

        // 3. Store in-app notification
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

        // 4. Get user's device tokens
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

        // 5. Send FCM push to all devices
        const messages = tokens.map((t) => ({
            token: t.fcm_token,
            notification: {
                title: payload.title,
                body: payload.body,
                // image: payload.image_url, // 'image' is supported in some SDKs, passed in data usually or apns/android config
            },
            ...(payload.data ? { data: payload.data } : {}), // Custom data payload
            android: {
                notification: {
                    ...(payload.image_url ? { imageUrl: payload.image_url } : {}),
                }
            },
            apns: {
                payload: {
                    aps: {
                        'mutable-content': 1, // Required for image on iOS
                    },
                    ...(payload.image_url ? { image: payload.image_url } : {}) // Not standard APNs, handled by extension usually
                },
                fcmOptions: {
                    ...(payload.image_url ? { image: payload.image_url } : {}),
                }
            }
        }));

        // Batch send is 'sendEach' in v1
        const batchResponse = await admin.messaging().sendEach(messages as any);

        console.log('FCM Batch Response:', JSON.stringify(batchResponse));

        return new Response(JSON.stringify({
            success: true,
            sent_count: batchResponse.successCount,
            failure_count: batchResponse.failureCount,
            results: batchResponse.responses
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
