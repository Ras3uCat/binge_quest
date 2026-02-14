import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for tracking user behavior via Firebase Analytics.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Set user ID for analytics (call on sign-in, clear on sign-out).
  static Future<void> setUserId(String? userId) =>
      _analytics.setUserId(id: userId);

  /// Set a user property.
  static Future<void> setUserProperty(String name, String? value) =>
      _analytics.setUserProperty(name: name, value: value);

  // --- Auth Events ---

  static Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  static Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  static Future<void> logSignOut() => _log('sign_out');

  static Future<void> logDeleteAccount() => _log('delete_account');

  // --- Watchlist Events ---

  static Future<void> logCreateWatchlist(String name) =>
      _log('create_watchlist', {'name': name});

  static Future<void> logDeleteWatchlist() => _log('delete_watchlist');

  static Future<void> logAddToWatchlist({
    required int tmdbId,
    required String mediaType,
  }) =>
      _log('add_to_watchlist', {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
      });

  static Future<void> logRemoveFromWatchlist() =>
      _log('remove_from_watchlist');

  static Future<void> logMoveItem() => _log('move_item');

  // --- Watch Progress Events ---

  static Future<void> logMarkWatched({
    required int tmdbId,
    required String mediaType,
  }) =>
      _log('mark_watched', {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
      });

  // --- Social Events ---

  static Future<void> logSendFriendRequest() => _log('send_friend_request');

  static Future<void> logAcceptFriendRequest() =>
      _log('accept_friend_request');

  static Future<void> logBlockUser() => _log('block_user');

  static Future<void> logClaimUsername() => _log('claim_username');

  // --- Content Events ---

  static Future<void> logSubmitReview({
    required int tmdbId,
    required String mediaType,
  }) =>
      _log('submit_review', {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
      });

  static Future<void> logShareContent({
    required String contentType,
  }) =>
      _log('share_content', {'content_type': contentType});

  // --- Badge Events ---

  static Future<void> logBadgeEarned(String badgeName) =>
      _log('badge_earned', {'badge_name': badgeName});

  // --- Generic ---

  static Future<void> _log(
    String name, [
    Map<String, Object>? params,
  ]) =>
      _analytics.logEvent(name: name, parameters: params);
}
