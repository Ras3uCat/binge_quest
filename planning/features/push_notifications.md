# Feature: Push Notifications Infrastructure

## Status
TODO

## Overview
Core push notification system using Firebase Cloud Messaging (FCM) that supports multiple notification types. This is the foundational infrastructure required by:
- `streaming_availability_alerts.md` - Alerts when watchlist items gain streaming options
- `follow_talent.md` - Alerts when followed actors/directors have new content
- Future: New episode alerts, social interactions, etc.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
├─────────────────────────────────────────────────────────────────┤
│  NotificationService (FCM init, token management, handlers)      │
│  NotificationController (GetX - in-app state, badge counts)      │
│  NotificationRepository (fetch/mark-read from Supabase)          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SUPABASE                                 │
├─────────────────────────────────────────────────────────────────┤
│  Tables:                                                         │
│    - user_device_tokens (FCM token storage)                      │
│    - notifications (in-app notification history)                 │
│    - notification_preferences (per-category toggles)             │
│                                                                  │
│  Edge Functions:                                                 │
│    - send-notification (called by other functions/triggers)      │
│    - check-streaming-changes (scheduled daily)                   │
│    - check-talent-releases (scheduled daily)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FIREBASE CLOUD MESSAGING                      │
└─────────────────────────────────────────────────────────────────┘
```

## Notification Categories

| Category | Key | Description | Default |
|----------|-----|-------------|---------|
| Streaming Alerts | `streaming_alerts` | New streaming availability | ON |
| Talent Releases | `talent_releases` | New content from followed talent | ON |
| New Episodes | `new_episodes` | New episode aired for watchlist show | ON |
| Social | `social` | Friend activity, comments, etc. | ON |
| Marketing | `marketing` | App updates, tips | OFF |

---

## Data Model

### user_device_tokens
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to auth.users |
| fcm_token | TEXT | Firebase device token |
| device_type | TEXT | 'ios', 'android', 'web' |
| device_name | TEXT | Optional device identifier |
| created_at | TIMESTAMPTZ | When registered |
| updated_at | TIMESTAMPTZ | Last token refresh |

**Notes:**
- Users may have multiple devices
- Tokens expire/change - updated on app launch
- Delete on logout

### notification_preferences
| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | PK, FK to auth.users |
| streaming_alerts | BOOLEAN | Default: true |
| talent_releases | BOOLEAN | Default: true |
| new_episodes | BOOLEAN | Default: true |
| social | BOOLEAN | Default: true |
| marketing | BOOLEAN | Default: false |
| quiet_hours_start | TIME | Optional: e.g., 22:00 |
| quiet_hours_end | TIME | Optional: e.g., 08:00 |
| updated_at | TIMESTAMPTZ | - |

### notifications
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to auth.users |
| category | TEXT | e.g., 'streaming_alerts' |
| title | TEXT | Notification title |
| body | TEXT | Notification body |
| image_url | TEXT | Optional image (poster) |
| data | JSONB | Deep link payload |
| read_at | TIMESTAMPTZ | NULL if unread |
| created_at | TIMESTAMPTZ | When created |

**data payload examples:**
```json
// Streaming alert
{
  "type": "streaming_alert",
  "tmdb_id": 550,
  "media_type": "movie",
  "provider_name": "Netflix"
}

// Talent release
{
  "type": "talent_release",
  "tmdb_id": 12345,
  "media_type": "movie",
  "person_id": 6193,
  "person_name": "Leonardo DiCaprio"
}
```

---

## Backend Implementation

### Migration: 029_push_notifications.sql

```sql
-- User device tokens for FCM
CREATE TABLE IF NOT EXISTS public.user_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN ('ios', 'android', 'web')),
    device_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- Notification preferences per user
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    streaming_alerts BOOLEAN DEFAULT true,
    talent_releases BOOLEAN DEFAULT true,
    new_episodes BOOLEAN DEFAULT true,
    social BOOLEAN DEFAULT true,
    marketing BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- In-app notification history
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    data JSONB DEFAULT '{}',
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_device_tokens_user ON public.user_device_tokens(user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, read_at) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_created ON public.notifications(created_at DESC);

-- RLS
ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users manage own device tokens" ON public.user_device_tokens
    FOR ALL TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users manage own preferences" ON public.notification_preferences
    FOR ALL TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users read own notifications" ON public.notifications
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users update own notifications" ON public.notifications
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);
```

### Edge Function: send-notification

Core function that other features call to send notifications:

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationPayload {
  user_id: string
  category: string
  title: string
  body: string
  image_url?: string
  data?: Record<string, unknown>
}

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const payload: NotificationPayload = await req.json()

  // 1. Check user preferences
  const { data: prefs } = await supabase
    .from('notification_preferences')
    .select('*')
    .eq('user_id', payload.user_id)
    .single()

  if (prefs && !prefs[payload.category]) {
    return new Response(JSON.stringify({ skipped: 'disabled_by_user' }), { status: 200 })
  }

  // 2. Check quiet hours
  if (prefs?.quiet_hours_start && prefs?.quiet_hours_end) {
    const now = new Date()
    const hour = now.getHours()
    const start = parseInt(prefs.quiet_hours_start.split(':')[0])
    const end = parseInt(prefs.quiet_hours_end.split(':')[0])
    if ((start < end && hour >= start && hour < end) ||
        (start > end && (hour >= start || hour < end))) {
      return new Response(JSON.stringify({ skipped: 'quiet_hours' }), { status: 200 })
    }
  }

  // 3. Store in-app notification
  await supabase.from('notifications').insert({
    user_id: payload.user_id,
    category: payload.category,
    title: payload.title,
    body: payload.body,
    image_url: payload.image_url,
    data: payload.data || {},
  })

  // 4. Get user's device tokens
  const { data: tokens } = await supabase
    .from('user_device_tokens')
    .select('fcm_token')
    .eq('user_id', payload.user_id)

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, in_app: true }), { status: 200 })
  }

  // 5. Send FCM push to all devices
  const fcmKey = Deno.env.get('FCM_SERVER_KEY')!
  const fcmPayload = {
    registration_ids: tokens.map(t => t.fcm_token),
    notification: {
      title: payload.title,
      body: payload.body,
      image: payload.image_url,
    },
    data: payload.data,
  }

  const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${fcmKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(fcmPayload),
  })

  const result = await fcmResponse.json()
  return new Response(JSON.stringify({ sent: result.success, failed: result.failure }), { status: 200 })
})
```

---

## Frontend Implementation

### 1. NotificationService (lib/core/services/notification_service.dart)

```dart
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final _messaging = FirebaseMessaging.instance;

  Future<NotificationService> init() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and store FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    return this;
  }

  Future<void> _registerToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('user_device_tokens').upsert({
      'user_id': user.id,
      'fcm_token': token,
      'device_type': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,fcm_token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app banner or update badge count
    NotificationController.to.onNewNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Deep link based on message.data
    final data = message.data;
    switch (data['type']) {
      case 'streaming_alert':
      case 'talent_release':
        Get.toNamed('/item/${data['media_type']}/${data['tmdb_id']}');
        break;
    }
  }

  Future<void> removeToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await Supabase.instance.client
          .from('user_device_tokens')
          .delete()
          .eq('fcm_token', token);
    }
  }
}
```

### 2. NotificationRepository (lib/shared/repositories/notification_repository.dart)

```dart
class NotificationRepository {
  static final _client = Supabase.instance.client;

  static Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AppNotification.fromJson(json))
        .toList();
  }

  static Future<int> getUnreadCount() async {
    final response = await _client
        .from('notifications')
        .select('id')
        .isFilter('read_at', null);
    return (response as List).length;
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  static Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .isFilter('read_at', null);
  }

  static Future<NotificationPreferences> getPreferences() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Return defaults
      return NotificationPreferences.defaults();
    }
    return NotificationPreferences.fromJson(response);
  }

  static Future<void> updatePreferences(NotificationPreferences prefs) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('notification_preferences').upsert({
      'user_id': userId,
      ...prefs.toJson(),
    });
  }
}
```

### 3. NotificationController (lib/features/notifications/controllers/notification_controller.dart)

```dart
class NotificationController extends GetxController {
  static NotificationController get to => Get.find();

  final notifications = <AppNotification>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      notifications.value = await NotificationRepository.getNotifications();
      unreadCount.value = await NotificationRepository.getUnreadCount();
    } finally {
      isLoading.value = false;
    }
  }

  void onNewNotification(RemoteMessage message) {
    // Increment badge, optionally show snackbar
    unreadCount.value++;
    Get.snackbar(
      message.notification?.title ?? 'New notification',
      message.notification?.body ?? '',
      onTap: (_) => Get.toNamed('/notifications'),
    );
  }

  Future<void> markAsRead(String id) async {
    await NotificationRepository.markAsRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      notifications[index] = notifications[index].copyWith(
        readAt: DateTime.now(),
      );
      unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
    }
  }

  Future<void> markAllAsRead() async {
    await NotificationRepository.markAllAsRead();
    notifications.value = notifications
        .map((n) => n.copyWith(readAt: n.readAt ?? DateTime.now()))
        .toList();
    unreadCount.value = 0;
  }
}
```

### 4. UI Components

**Notification Bell (AppBar badge):**
```dart
Obx(() {
  final count = NotificationController.to.unreadCount.value;
  return Badge(
    isLabelVisible: count > 0,
    label: Text('$count'),
    child: IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => Get.toNamed('/notifications'),
    ),
  );
})
```

**Notification Settings Screen:**
- Toggle switches for each category
- Quiet hours time pickers
- Clear all notifications button

**Notification List Screen:**
- Shows notification history
- Tap to deep link
- Swipe to dismiss/mark read

---

## Files to Create

| File | Purpose |
|------|---------|
| `migrations/029_push_notifications.sql` | Tables and RLS |
| `functions/send-notification/index.ts` | Core FCM sender |
| `lib/core/services/notification_service.dart` | FCM init + handlers |
| `lib/shared/repositories/notification_repository.dart` | DB access |
| `lib/shared/models/app_notification.dart` | Notification model |
| `lib/shared/models/notification_preferences.dart` | Preferences model |
| `lib/features/notifications/controllers/notification_controller.dart` | GetX state |
| `lib/features/notifications/screens/notifications_screen.dart` | History list |
| `lib/features/settings/widgets/notification_settings_section.dart` | Toggles UI |

---

## Firebase Setup Checklist

- [ ] Create Firebase project
- [ ] Enable Cloud Messaging
- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Add FCM server key to Supabase secrets
- [ ] Configure iOS APNs certificates
- [ ] Add firebase_messaging to pubspec.yaml

---

## Dependencies

### pubspec.yaml additions:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
```

### Environment Variables (Supabase):
- `FCM_SERVER_KEY` - Firebase Cloud Messaging server key

---

## Testing Checklist

- [ ] FCM token registered on login
- [ ] Token removed on logout
- [ ] Token refreshed when changed
- [ ] Foreground notification shows banner
- [ ] Background notification shows in system tray
- [ ] Tapping notification deep links correctly
- [ ] Preferences respected (disabled = no push)
- [ ] Quiet hours respected
- [ ] In-app notification list loads
- [ ] Mark as read works
- [ ] Unread count badge accurate

---

## Dependent Features

After this infrastructure is complete:

1. **Streaming Availability Alerts** (`streaming_availability_alerts.md`)
   - Adds `check-streaming-changes` edge function
   - Calls `send-notification` when changes detected

2. **Follow Talent** (`follow_talent.md`)
   - Adds `check-talent-releases` edge function
   - Calls `send-notification` for new content

3. **New Episode Alerts** (future)
   - Adds trigger on `content_cache_episodes` insert
   - Calls `send-notification` for watchlisted shows
