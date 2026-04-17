# Supabase Auth — Detailed Implementation Guide

## 1. Migration: profiles table + trigger

```sql
-- supabase/migrations/YYYYMMDDHHMMSS_create_profiles_table.sql

CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT,
  display_name  TEXT,
  avatar_url    TEXT,
  is_premium    BOOLEAN NOT NULL DEFAULT false,
  stripe_customer_id TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_own_profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own_profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## 2. StorageService — Secure Token Storage

```dart
// lib/core/services/storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class StorageService extends GetxService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keySession = 'supabase_session';

  Future<void> saveSession(String sessionJson) =>
      _storage.write(key: _keySession, value: sessionJson);

  Future<String?> getSession() =>
      _storage.read(key: _keySession);

  Future<void> clearSession() =>
      _storage.delete(key: _keySession);
}
```

## 3. AuthRepository

```dart
// lib/features/auth/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/base/base_repository.dart';

class AuthRepository extends BaseRepository {
  final _auth = Supabase.instance.client.auth;

  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) return Left(ApiFailure('Sign in failed'));
      return Right(res.user!);
    } on AuthException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signUp(email: email, password: password);
      if (res.user == null) return Left(ApiFailure('Sign up failed'));
      return Right(res.user!);
    } on AuthException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  Future<Either<Failure, void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  Future<Either<Failure, void>> sendMagicLink(String email) async {
    try {
      await _auth.signInWithOtp(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }

  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(OAuthProvider.google);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }
}
```

## 4. AuthController

```dart
// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/base/base_controller.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../routes/routes.dart';

class AuthController extends BaseController {
  final AuthRepository _repo = Get.find();

  final isLoggedIn = false.obs;
  final currentUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    // Single source of truth — react to Supabase auth state
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      isLoggedIn.value = session != null;
      currentUser.value = session?.user;

      if (session != null) {
        Get.offAllNamed(Routes.dashboard);
      } else if (data.event == AuthChangeEvent.signedOut) {
        Get.offAllNamed(Routes.login);
      }
    });

    // Restore existing session
    final session = Supabase.instance.client.auth.currentSession;
    isLoggedIn.value = session != null;
    currentUser.value = session?.user;
  }

  Future<void> login({required String email, required String password}) async {
    setLoading(true);
    final result = await _repo.signInWithEmail(email: email, password: password);
    result.fold(
      (f) => setError(f.message),
      (_) => clearError(),
    );
    setLoading(false);
  }

  Future<void> signUp({required String email, required String password}) async {
    setLoading(true);
    final result = await _repo.signUpWithEmail(email: email, password: password);
    result.fold(
      (f) => setError(f.message),
      (_) {
        clearError();
        // Show "check your email" — don't navigate yet
      },
    );
    setLoading(false);
  }

  Future<void> logout() async {
    await _repo.signOut();
    // onAuthStateChange listener handles navigation
  }
}
```

## 5. AuthGuard Middleware

```dart
// lib/routes/auth_guard.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'routes.dart';

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) {
      return const RouteSettings(name: Routes.login);
    }
    return null;
  }
}
```

## 6. Deep Link Setup (Magic Link / OAuth Redirect)

### pubspec.yaml
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  app_links: ^6.0.0  # for deep link handling
```

### AndroidManifest.xml
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="yourapp" android:host="login-callback" />
</intent-filter>
```

### main.dart
```dart
await Supabase.initialize(
  url: AppConfig.supabaseUrl,
  anonKey: AppConfig.supabaseAnonKey,
  authOptions: FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce, // required for OAuth
  ),
);
```

## 7. pubspec.yaml dependencies
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  flutter_secure_storage: ^9.2.2
  app_links: ^6.0.0
```
