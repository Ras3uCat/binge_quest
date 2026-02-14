import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
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
import 'features/watchlist/controllers/watchlist_controller.dart';
import 'features/watchlist/controllers/watchlist_member_controller.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'features/auth/screens/splash_screen.dart';

Future<void> main() async {
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

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize error handling + Crashlytics (must be after Firebase init)
  await ErrorService.initialize();

  // Initialize Supabase
  await SupabaseService.initialize(
    supabaseUrl: Env.supabaseUrl,
    supabaseAnonKey: Env.supabaseAnonKey,
  );

  // Initialize TMDB
  TmdbService.initialize(apiKey: Env.tmdbApiKey);

  // Register services and controllers globally
  Get.put(
    ConnectivityService(),
  ); // Initialize immediately for network monitoring
  Get.lazyPut(() => AuthController(), fenix: true);
  Get.put(NotificationService()); // Initialize Notification Service
  Get.put(ShareService()); // Register share service
  Get.lazyPut(() => BadgeController(), fenix: true);
  Get.lazyPut(() => QueueHealthController(), fenix: true);
  Get.lazyPut(() => FriendController(), fenix: true);
  Get.lazyPut(() => WatchlistController(), fenix: true);
  Get.lazyPut(() => WatchlistMemberController(), fenix: true);
  Get.lazyPut(() => NotificationController(), fenix: true);

  runApp(const BingeQuestApp());
}

class BingeQuestApp extends StatelessWidget {
  const BingeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BingeQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      defaultTransition: Transition.fadeIn,
      transitionDuration: EAnimations.normal,
      navigatorObservers: [AnalyticsService.observer],
      home: const SplashScreen(),
    );
  }
}
