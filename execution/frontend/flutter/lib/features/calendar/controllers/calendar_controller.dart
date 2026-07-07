import 'package:get/get.dart';
import '../../../shared/models/calendar_event.dart';
import '../../../shared/models/watchlist.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/calendar_repository.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

/// Thin seam over [CalendarRepository.getCalendarEvents] so tests can inject
/// a fake without refactoring the (static, like every other repository)
/// CalendarRepository itself.
abstract class CalendarEventsFetcher {
  Future<List<Map<String, dynamic>>> call(DateTime from, DateTime to);
}

class _RepositoryEventsFetcher implements CalendarEventsFetcher {
  const _RepositoryEventsFetcher();

  @override
  Future<List<Map<String, dynamic>>> call(DateTime from, DateTime to) =>
      CalendarRepository.getCalendarEvents(from, to);
}

class CalendarController extends GetxController {
  CalendarController({CalendarEventsFetcher? eventsFetcher})
    : _eventsFetcher = eventsFetcher ?? const _RepositoryEventsFetcher();

  static CalendarController get to => Get.find<CalendarController>();

  final CalendarEventsFetcher _eventsFetcher;

  final _allEvents = <CalendarEvent>[].obs;
  final selectedWatchlistId = 'all'.obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final selectedDate = Rxn<DateTime>();
  final _focusedMonth = DateTime.now().obs;

  // tmdbId → first WatchlistItem found; used for navigation to ItemDetailScreen
  final _itemByTmdbId = <int, WatchlistItem>{};

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  DateTime get focusedMonth => _focusedMonth.value;
  List<Watchlist> get watchlists => WatchlistController.to.watchlists;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = from.add(const Duration(days: 90));

      final rows = await _eventsFetcher(from, to);
      _itemByTmdbId.clear();
      final events = <CalendarEvent>[];

      for (final row in rows) {
        final tmdbId = row['tmdb_id'] as int;
        final mediaType = MediaType.fromString(row['media_type'] as String);
        final rawDate = DateTime.parse(row['event_date'] as String);
        final date = DateTime(rawDate.year, rawDate.month, rawDate.day);

        _itemByTmdbId.putIfAbsent(
          tmdbId,
          () => WatchlistItem(
            id: row['watchlist_item_id'] as String,
            watchlistId: row['watchlist_id'] as String,
            tmdbId: tmdbId,
            mediaType: mediaType,
            addedAt: DateTime.now(),
          ),
        );

        events.add(
          CalendarEvent(
            date: date,
            tmdbId: tmdbId,
            mediaType: mediaType,
            title: row['title'] as String? ?? '',
            posterPath: row['poster_path'] as String?,
            type: (row['event_type'] as String) == 'episode'
                ? CalendarEventType.episode
                : CalendarEventType.movieRelease,
            episodeCode: row['episode_code'] as String?,
            seasonNumber: row['season_number'] as int?,
            episodeNumber: row['episode_number'] as int?,
            watchlistId: row['watchlist_id'] as String,
            watchlistName: row['watchlist_name'] as String? ?? '',
          ),
        );
      }

      _allEvents.value = events;
    } catch (e) {
      _error.value = 'Failed to load calendar. Please try again.';
    } finally {
      _isLoading.value = false;
    }
  }

  // Reads selectedWatchlistId.value — Obx in views tracks this dependency.
  Map<DateTime, List<CalendarEvent>> get filteredEventsByDate {
    final filter = selectedWatchlistId.value;
    final source = filter == 'all'
        ? _deduplicated(_allEvents)
        : _allEvents.where((e) => e.watchlistId == filter).toList();
    final map = <DateTime, List<CalendarEvent>>{};
    for (final e in source) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    return map;
  }

  List<CalendarEvent> eventsForDate(DateTime date) => filteredEventsByDate[date] ?? [];

  bool hasEventsOnDate(DateTime date) => filteredEventsByDate.containsKey(date);

  WatchlistItem? watchlistItemFor(int tmdbId) => _itemByTmdbId[tmdbId];

  void selectDate(DateTime date) => selectedDate.value = date;

  void selectWatchlist(String id) => selectedWatchlistId.value = id;

  void previousMonth() {
    final d = _focusedMonth.value;
    _focusedMonth.value = DateTime(d.year, d.month - 1);
  }

  void nextMonth() {
    final d = _focusedMonth.value;
    _focusedMonth.value = DateTime(d.year, d.month + 1);
  }

  List<CalendarEvent> _deduplicated(List<CalendarEvent> events) {
    final seen = <String>{};
    final result = <CalendarEvent>[];
    for (final e in events) {
      final key = e.type == CalendarEventType.episode
          ? '${e.tmdbId}_${e.seasonNumber}_${e.episodeNumber}'
          : '${e.tmdbId}';
      if (seen.add(key)) result.add(e);
    }
    return result;
  }
}
