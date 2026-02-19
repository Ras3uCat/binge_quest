import '../../core/services/supabase_service.dart';
import '../models/stats_data.dart';

/// Repository for stats dashboard database operations.
class StatsRepository {
  StatsRepository._();

  static final _client = SupabaseService.client;

  /// Fetch full stats dashboard for the current user.
  ///
  /// [timeWindow] must be one of: 'week', 'month', 'year', 'all'.
  static Future<StatsData> getStatsDashboard(String timeWindow) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.rpc(
      'get_stats_dashboard',
      params: {'p_user_id': userId, 'p_time_window': timeWindow},
    );

    if (response == null) return StatsData.empty();

    // RPC may return a list with one element or a map directly.
    final Map<String, dynamic> data;
    if (response is List && response.isNotEmpty) {
      data = response[0] as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      data = response;
    } else {
      return StatsData.empty();
    }

    return StatsData.fromJson(data);
  }
}
