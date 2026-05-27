import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class CalendarRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> getCalendarEvents(DateTime from, DateTime to) async {
    final result = await _client.rpc(
      'get_calendar_events',
      params: {'from_date': _dateStr(from), 'to_date': _dateStr(to)},
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  static String _dateStr(DateTime dt) => dt.toIso8601String().split('T').first;
}
