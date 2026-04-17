import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/e_colors.dart';
import 'core/constants/e_animations.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/tmdb_service.dart';
import 'core/services/share_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/badges/controllers/badge_controller.dart';
import 'features/dashboard/controllers/queue_health_controller.dart';
import 'features/social/controllers/friend_controller.dart';
import 'features/social/controllers/watch_party_controller.dart';
import 'features/watchlist/controllers/watchlist_controller.dart';
import 'features/watchlist/controllers/watchlist_member_controller.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'features/profile/controllers/archetype_controller.dart';
import 'core/services/deep_link_service.dart';
import 'features/auth/screens/splash_screen.dart';

/// Top-level background message handler required by firebase_messaging.
/// Must be a top-level function (not a class method).
/// Notification messages are displayed by the OS automatically;
/// this handler exists so the plugin can properly route background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: notification display is handled by the OS for notification messages.
}

bool _isMainInitialized = false;

Future<void> main() async {
  if (_isMainInitialized) return;
  _isMainInitialized = true;

  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: EColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase + Crashlytics first so all subsequent errors are caught
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else {
      debugPrint('Firebase already initialized via native configuration');
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await ErrorService.initialize();
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint('Firebase already configured (duplicate-app catch-all)');
      await ErrorService.initialize();
    } else {
      debugPrint('Firebase initialization failed: ${e.code} - ${e.message}');
    }
  } catch (e) {
    debugPrint('Firebase/Crashlytics initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await SupabaseService.initialize(
      supabaseUrl: Env.supabaseUrl,
      supabaseAnonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // Initialize TMDB
  TmdbService.initialize(apiKey: Env.tmdbApiKey);

  // Register services and controllers globally
  Get.put(ConnectivityService()); // Initialize immediately for network monitoring
  Get.lazyPut(() => AuthController(), fenix: true);
  try {
    Get.put(NotificationService()); // Initialize Notification Service
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }
  Get.put(ShareService()); // Register share service
  Get.put(DeepLinkService()); // Register deep link service
  Get.lazyPut(() => BadgeController(), fenix: true);
  Get.lazyPut(() => QueueHealthController(), fenix: true);
  Get.lazyPut(() => FriendController(), fenix: true);
  Get.lazyPut(() => WatchPartyController(), fenix: true);
  Get.lazyPut(() => WatchlistController(), fenix: true);
  Get.lazyPut(() => WatchlistMemberController(), fenix: true);
  Get.lazyPut(() => NotificationController(), fenix: true);
  Get.lazyPut(() => ArchetypeController(), fenix: true);

  runApp(const BingeQuestApp());
}

class BingeQuestApp extends StatefulWidget {
  const BingeQuestApp({super.key});

  @override
  State<BingeQuestApp> createState() => _BingeQuestAppState();
}

class _BingeQuestAppState extends State<BingeQuestApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    // Live links (app warm): dispatch immediately — navigator is ready.
    _linkSub = appLinks.uriLinkStream.listen(DeepLinkService.to.dispatch, onError: (_) {});
    // Cold-start link: schedule for after DashboardScreen mounts.
    final initial = await appLinks.getInitialLink();
    if (initial != null) DeepLinkService.to.schedule(initial);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      child: GetMaterialApp(
        title: 'BingeQuest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        defaultTransition: Transition.fadeIn,
        transitionDuration: EAnimations.normal,
        navigatorObservers: [AnalyticsService.observer],
        home: const SplashScreen(),
      ),
    );
  }
}
