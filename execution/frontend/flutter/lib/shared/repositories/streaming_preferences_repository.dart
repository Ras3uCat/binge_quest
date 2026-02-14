import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_streaming_preference.dart';

class StreamingPreferencesRepository {
  final SupabaseClient _supabase;

  StreamingPreferencesRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<UserStreamingPreference>> getUserPreferences(
      String userId) async {
    final response = await _supabase
        .from('user_streaming_preferences')
        .select()
        .eq('user_id', userId)
        .order('provider_name');

    return (response as List)
        .map((e) => UserStreamingPreference.fromJson(e))
        .toList();
  }

  Future<void> addPreference({
    required String userId,
    required int providerId,
    required String providerName,
    String? providerLogoPath,
  }) async {
    await _supabase.from('user_streaming_preferences').upsert(
      {
        'user_id': userId,
        'provider_id': providerId,
        'provider_name': providerName,
        'provider_logo_path': providerLogoPath,
        'notify_enabled': true,
        'include_rent_buy': false,
      },
      onConflict: 'user_id, provider_id',
    );
  }

  Future<void> removePreference({
    required String userId,
    required int providerId,
  }) async {
    await _supabase
        .from('user_streaming_preferences')
        .delete()
        .eq('user_id', userId)
        .eq('provider_id', providerId);
  }

  Future<void> updateIncludeRentBuy({
    required String userId,
    required bool includeRentBuy,
  }) async {
    await _supabase
        .from('user_streaming_preferences')
        .update({'include_rent_buy': includeRentBuy})
        .eq('user_id', userId);
  }
}
