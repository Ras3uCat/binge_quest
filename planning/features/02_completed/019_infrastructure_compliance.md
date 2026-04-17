# Feature: Infrastructure & Compliance

## Status
Complete — 4 of 4 items done

## Overview
Essential infrastructure for app stability, analytics, and legal compliance.

## Acceptance Criteria
- [x] Error tracking (Firebase Crashlytics) integrated
- [x] Analytics (Firebase Analytics) integrated
- [x] Privacy Policy and Terms of Service screens implemented
- [x] Delete Account functionality (iOS requirement)

---

## Completed Items

### Privacy Policy & Terms of Service
- `lib/features/settings/screens/privacy_policy_screen.dart` — full policy, last updated Jan 2026
- `lib/features/settings/screens/terms_of_service_screen.dart` — full ToS, last updated Jan 2026
- Both linked from Settings screen under "Legal" section

### Delete Account
- **Backend:** `delete_user_account()` RPC in migration `008_delete_account.sql` — cascades through watch_progress, watchlist_items, watchlists, user_badges, user profile
- **Frontend:** `AuthController.deleteAccount()` calls RPC, signs out, cleans up GetX controllers, returns to onboarding
- **UI:** Settings > Danger Zone with dual-confirmation dialogs (warning + final confirm)

---

### Error Tracking (Firebase Crashlytics)
- `firebase_crashlytics: ^5.0.7` in `pubspec.yaml`
- `lib/core/services/error_service.dart` — wired to `FirebaseCrashlytics.instance`:
  - `FlutterError.onError` → `recordFlutterFatalError`
  - `PlatformDispatcher.instance.onError` → `recordError(fatal: true)`
  - `reportError()` → `recordError` + custom keys for context/extras
  - `logIssue()` → `Crashlytics.log`
  - `setUserIdentifier()` → sets Crashlytics user ID
  - Crashlytics collection disabled in debug mode (`kDebugMode`)
- `main.dart` — `ErrorService.initialize()` called after `Firebase.initializeApp()`
- `AuthController` — sets/clears Crashlytics user ID on sign-in/sign-out

### Analytics (Firebase Analytics)
- `firebase_analytics: ^12.1.2` in `pubspec.yaml`
- `lib/core/services/analytics_service.dart` — static methods wrapping `FirebaseAnalytics.instance`:
  - Auth: `logLogin`, `logSignUp`, `logSignOut`, `logDeleteAccount`
  - Watchlist: `logCreateWatchlist`, `logDeleteWatchlist`, `logAddToWatchlist`, `logRemoveFromWatchlist`, `logMoveItem`
  - Progress: `logMarkWatched`
  - Social: `logSendFriendRequest`, `logAcceptFriendRequest`, `logBlockUser`, `logClaimUsername`
  - Content: `logSubmitReview`, `logShareContent`, `logBadgeEarned`
- `main.dart` — `FirebaseAnalyticsObserver` added to `navigatorObservers` for automatic screen tracking
- `AuthController` — sets/clears analytics user ID on sign-in/sign-out
- `WatchlistController` — events on create/delete watchlist, add/remove/move items
- `FriendController` — events on claim username, send/accept request, block user

---

## QA Checklist
- [x] Verify account deletion removes all user data from Supabase
- [ ] Verify analytics events appear in Firebase Analytics dashboard
- [ ] Verify crash reports appear in Firebase Crashlytics dashboard
- [ ] Verify screen views auto-tracked via navigator observer
