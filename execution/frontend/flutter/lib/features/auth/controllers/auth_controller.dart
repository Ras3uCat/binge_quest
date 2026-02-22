import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/error_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../badges/controllers/badge_controller.dart';
import '../../dashboard/controllers/queue_health_controller.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../social/controllers/friend_controller.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../../watchlist/controllers/watchlist_member_controller.dart';
import '../screens/onboarding_screen.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final _isLoading = false.obs;
  final _user = Rxn<User>();
  final _errorMessage = ''.obs;

  bool get isLoading => _isLoading.value;
  User? get user => _user.value;
  Rxn<User> get userRx => _user;
  bool get isAuthenticated => _user.value != null;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    _user.value = SupabaseService.currentUser;
    // Set Crashlytics + Analytics user ID if already signed in
    if (_user.value != null) {
      ErrorService.setUserIdentifier(_user.value!.id);
      AnalyticsService.setUserId(_user.value!.id);
    }

    // Listen to auth state changes
    SupabaseService.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _user.value = session.user;
        ErrorService.setUserIdentifier(session.user.id);
        AnalyticsService.setUserId(session.user.id);
        _createUserProfile(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _user.value = null;
        ErrorService.setUserIdentifier(null);
        AnalyticsService.setUserId(null);
      }
    });
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      if (kIsWeb) {
        await _signInWithGoogleWeb();
      } else {
        await _signInWithGoogleNative();
      }
    } catch (e) {
      _errorMessage.value = 'Google sign-in failed. Please try again.';
      debugPrint('Google sign-in error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _signInWithGoogleNative() async {
    // Web client ID is used as serverClientId for Android
    const webClientId =
        '58540891155-pcj46caefias3og8349fkouv6on173os.apps.googleusercontent.com';
    const iosClientId =
        '315193779894-92ddcpuemons8mhlnkp3b1jdi37dn76k.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      clientId: defaultTargetPlatform == TargetPlatform.iOS ? iosClientId : null,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Failed to get Google auth tokens');
    }

    await SupabaseService.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    AnalyticsService.logLogin('google');
    _navigateToDashboard();
  }

  Future<void> _signInWithGoogleWeb() async {
    await SupabaseService.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.bingequest://login-callback',
    );
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      await SupabaseService.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      AnalyticsService.logLogin('apple');
      _navigateToDashboard();
    } catch (e) {
      _errorMessage.value = 'Apple sign-in failed. Please try again.';
      debugPrint('Apple sign-in error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      AnalyticsService.logSignOut();
      await GoogleSignIn().signOut();
      await SupabaseService.auth.signOut();
      _user.value = null;

      // Clean up controllers
      _cleanupControllers();

      Get.offAll(() => const OnboardingScreen());
    } catch (e) {
      _errorMessage.value = 'Sign out failed. Please try again.';
      debugPrint('Sign out error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete user account permanently
  /// This is required for iOS App Store compliance
  Future<bool> deleteAccount() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      AnalyticsService.logDeleteAccount();
      // Call the database function to delete all user data
      await SupabaseService.client.rpc('delete_user_account');

      // Sign out the user (this also cleans up the auth session)
      await SupabaseService.auth.signOut();
      _user.value = null;

      // Clean up controllers
      _cleanupControllers();

      Get.offAll(() => const OnboardingScreen());
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to delete account. Please try again.';
      debugPrint('Delete account error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clean up all registered controllers on sign out.
  void _cleanupControllers() {
    if (Get.isRegistered<WatchlistController>()) {
      Get.delete<WatchlistController>();
    }
    if (Get.isRegistered<BadgeController>()) {
      Get.delete<BadgeController>();
    }
    if (Get.isRegistered<FriendController>()) {
      Get.delete<FriendController>();
    }
    if (Get.isRegistered<WatchlistMemberController>()) {
      Get.delete<WatchlistMemberController>();
    }
    if (Get.isRegistered<QueueHealthController>()) {
      Get.delete<QueueHealthController>();
    }
    if (Get.isRegistered<NotificationController>()) {
      Get.delete<NotificationController>();
    }
  }

  /// Create user profile in Supabase if it doesn't exist
  Future<void> _createUserProfile(User user) async {
    try {
      final existing = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await SupabaseService.client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'display_name':
              user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              user.email?.split('@').first ??
              'User',
          'avatar_url':
              user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
          'is_premium': false,
        });
        // Default watchlist is created by ensureDefaultWatchlist() in WatchlistController
      }
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  void _navigateToDashboard() {
    // Initialize watchlist controller if not already
    if (!Get.isRegistered<WatchlistController>()) {
      Get.put(WatchlistController());
    }
    Get.offAll(() => const DashboardScreen());
  }

  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
