import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';
import '../models/notification_preferences.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<void> registerDeviceToken({
    required String userId,
    required String fcmToken,
    required String deviceId,
    required String deviceType,
  }) async {
    await _supabase.from('user_device_tokens').upsert({
      'user_id': userId,
      'fcm_token': fcmToken,
      'device_info': '{"device_id":"$deviceId","device_type":"$deviceType"}',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, fcm_token');
  }

  Future<void> removeDeviceToken(String fcmToken) async {
    await _supabase
        .from('user_device_tokens')
        .delete()
        .eq('fcm_token', fcmToken);
  }

  Future<NotificationPreferences> getPreferences(String userId) async {
    final response = await _supabase
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Return defaults if no preferences set
      return NotificationPreferences.defaults(userId);
    }

    return NotificationPreferences.fromJson(response);
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await _supabase
        .from('notification_preferences')
        .upsert(preferences.toJson());
  }

  Future<List<AppNotification>> getNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('notifications')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .filter('read_at', 'is', null);

    return response;
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }

  Future<void> sendTestNotification({required String userId}) async {
    await _supabase.functions.invoke(
      'send-notification',
      body: {
        'title': 'Test Notification',
        'body': 'Quest Complete! 🏆',
        'user_id': userId,
        'category': 'marketing',
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'route': '/settings',
        },
      },
    );
  }
}
