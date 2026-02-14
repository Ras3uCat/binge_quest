import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for Supabase initialization and access.
/// Handles database, auth, and storage operations.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  /// Initialize Supabase with project credentials.
  /// Call this in main() before runApp().
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Get the current authenticated user, if any.
  static User? get currentUser => auth.currentUser;

  /// Get the current user's ID, if authenticated.
  static String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated.
  static bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}
