import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../constants/e_colors.dart';
import '../../shared/models/watchlist_item.dart';
import '../../shared/repositories/notification_repository.dart';
import '../../shared/repositories/watchlist_repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/watchlist/screens/item_detail_screen.dart';
import '../../features/search/screens/person_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationRepository _repository = NotificationRepository();
  final AuthController _authController = Get.find<AuthController>();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Rxn<RemoteMessage> foregroundMessage = Rxn<RemoteMessage>();

  @override
  void onInit() {
    super.onInit();
    _initLocalNotifications();
    _initFCM();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings: initSettings);
  }

  Future<void> _initFCM() async {
    // 1. Always set up message handlers first
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );

        // Show in-app snackbar
        Get.snackbar(
          message.notification?.title ?? 'New Notification',
          message.notification?.body ?? '',
          snackPosition: SnackPosition.TOP,
          onTap: (_) => _handleMessageTap(message),
        );
      }

      // Notify listeners
      foregroundMessage.value = message;
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // 2. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 3. On iOS, wait for APNs token before requesting FCM token
    if (!kIsWeb && Platform.isIOS) {
      String? apnsToken = await _fcm.getAPNSToken();
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 3));
        apnsToken = await _fcm.getAPNSToken();
      }
      debugPrint('APNs token: ${apnsToken != null ? "received" : "null"}');
      if (apnsToken == null) {
        debugPrint('WARNING: No APNs token - push will not work');
      }
    }

    // 4. Get FCM token
    String? token = await _fcm.getToken();
    debugPrint('FCM token: ${token != null ? "${token.substring(0, 10)}..." : "null"}');
    if (token != null) {
      _registerToken(token);
    }

    // 5. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _registerToken(newToken);
    });
  }

  Future<void> _registerToken(String token) async {
    final user = _authController.user;
    if (user == null) return; // Only register if logged in

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown_device';
      String deviceType = 'unknown';

      if (kIsWeb) {
        deviceType = 'web';
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'unknown_web_agent';
      } else if (Platform.isAndroid) {
        deviceType = 'android';
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        deviceType = 'ios';
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }

      await _repository.registerDeviceToken(
        userId: user.id,
        fcmToken: token,
        deviceId: deviceId,
        deviceType: deviceType,
      );
      debugPrint(
        'FCM Token registered: ${token.substring(0, 10)}... Device: $deviceId',
      );
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final tmdbIdStr = data['tmdb_id'] as String?;
    final mediaType = data['media_type'] as String?;
    final personIdStr = data['person_id'] as String?;

    if (type == null) {
      Get.to(() => const NotificationsScreen());
      return;
    }

    switch (type) {
      case 'streaming_alert':
      case 'new_episode':
      case 'talent_release':
        if (tmdbIdStr != null && mediaType != null) {
          _navigateToContent(
            tmdbId: int.tryParse(tmdbIdStr),
            mediaType: mediaType,
            personId: personIdStr != null ? int.tryParse(personIdStr) : null,
          );
        } else {
          Get.to(() => const NotificationsScreen());
        }
        break;
      default:
        Get.to(() => const NotificationsScreen());
    }
  }

  Future<void> _navigateToContent({
    int? tmdbId,
    String? mediaType,
    int? personId,
  }) async {
    if (tmdbId == null || mediaType == null) {
      Get.to(() => const NotificationsScreen());
      return;
    }

    try {
      final item = await WatchlistRepository.getItemByTmdbId(
        tmdbId: tmdbId,
        mediaType: mediaType == 'movie' ? MediaType.movie : MediaType.tv,
      );

      if (item != null) {
        Get.to(() => ItemDetailScreen(item: item));
      } else if (personId != null) {
        Get.to(() => PersonDetailScreen(personId: personId));
      } else {
        Get.to(() => const NotificationsScreen());
      }
    } catch (e) {
      debugPrint('Deep link navigation error: $e');
      Get.to(() => const NotificationsScreen());
    }
  }

  Future<void> logout() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _repository.removeDeviceToken(token);
      }
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('Error removing FCM token on logout: $e');
    }
  }

  Future<void> sendTestNotification() async {
    final user = _authController.user;
    if (user == null) {
      Get.snackbar('Error', 'Must be logged in to send test notification');
      return;
    }

    try {
      await _repository.sendTestNotification(userId: user.id);

      // Show in-app snackbar confirmation
      Get.snackbar(
        'Test Notification',
        'Quest Complete! \u{1F3C6}',
        snackPosition: SnackPosition.TOP,
      );

      // Show a local system tray notification for testing
      await _localNotifications.show(
        id: 0,
        title: 'Test Notification',
        body: 'Quest Complete! \u{1F3C6}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'binge_quest_test',
            'BingeQuest Test',
            channelDescription: 'Test notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      Get.snackbar(
        'Error',
        'Failed to send test notification: $e',
        backgroundColor: EColors.error.withOpacity(0.1),
        colorText: EColors.error,
      );
    }
  }
}
