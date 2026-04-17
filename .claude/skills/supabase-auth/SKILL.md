---
name: supabase-auth
description: Supabase Auth implementation for Flutter — email/password, OAuth, magic links, session management, token storage, RLS with auth.uid(), and auth state in GetX. Trigger when a task involves login, signup, logout, session persistence, auth guards, or user identity.
when_to_use: Any task involving authentication flows, user sessions, login/signup screens, auth guards on routes, RLS policies that reference auth.uid(), or token storage.
scope: lib/features/auth/, lib/controllers/auth_controller.dart, lib/core/services/storage_service.dart, supabase/migrations/
authority: high
alwaysApply: false
---

# Supabase Auth Skill

## Non-Negotiables
- **Never store JWT in SharedPreferences** — use `flutter_secure_storage` only
- **Never trust client-side auth state** — re-verify via `supabase.auth.currentUser` on sensitive ops
- **Never expose service_role key** to Flutter client — anon key only
- **RLS is the real auth gate** — UI guards are UX only, not security
- **Session refresh** is handled automatically by `supabase_flutter` — don't roll your own

## Auth Methods Supported
| Method | When to use |
|---|---|
| Email + Password | Default for most apps |
| Magic Link | Low-friction, no password |
| OAuth (Google/Apple) | Social login, required for App Store apps with social accounts |
| Phone OTP | SMS-based, requires Twilio setup in Supabase |

## GetX Auth State Pattern
Auth state lives in `AuthController` (permanent, registered in `AppBindings`).
It listens to `supabase.auth.onAuthStateChange` — single source of truth.

```dart
// One stream → all controllers react
supabase.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  isLoggedIn.value = session != null;
  currentUser.value = session?.user;
});
```

## Route Guard Pattern
```dart
// lib/routes/app_pages.dart
GetPage(
  name: Routes.dashboard,
  page: () => const DashboardView(),
  middlewares: [AuthGuard()],
)
```

## RLS with auth.uid()
```sql
-- Users only see their own data
CREATE POLICY "users_own_data" ON public.items
  FOR ALL USING (auth.uid() = user_id);
```

## Critical: profiles Table
Always maintain a `profiles` table that mirrors `auth.users`.
Use a trigger to auto-create a profile on signup.

See `DETAILED_GUIDE.md` for complete implementation: AuthController, AuthRepository,
StorageService, OAuth setup, route guards, and the profiles trigger.
