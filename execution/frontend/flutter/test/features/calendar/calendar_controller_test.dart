import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:binge_quest/features/calendar/controllers/calendar_controller.dart';

class MockCalendarEventsFetcher extends Mock implements CalendarEventsFetcher {}

Map<String, dynamic> _episodeRow({
  required int tmdbId,
  required String eventDate,
  int seasonNumber = 1,
  int episodeNumber = 1,
  String watchlistId = 'wl-1',
  String watchlistName = 'My Shows',
}) {
  return {
    'watchlist_item_id': 'item-$tmdbId',
    'tmdb_id': tmdbId,
    'media_type': 'tv',
    'title': 'Show $tmdbId',
    'poster_path': '/poster.jpg',
    'event_date': eventDate,
    'event_type': 'episode',
    'episode_code':
        'S${seasonNumber.toString().padLeft(2, '0')}'
        'E${episodeNumber.toString().padLeft(2, '0')}',
    'season_number': seasonNumber,
    'episode_number': episodeNumber,
    'watchlist_id': watchlistId,
    'watchlist_name': watchlistName,
  };
}

Map<String, dynamic> _movieRow({
  required int tmdbId,
  required String eventDate,
  String watchlistId = 'wl-1',
  String watchlistName = 'My Shows',
}) {
  return {
    'watchlist_item_id': 'item-$tmdbId',
    'tmdb_id': tmdbId,
    'media_type': 'movie',
    'title': 'Movie $tmdbId',
    'poster_path': '/poster.jpg',
    'event_date': eventDate,
    'event_type': 'movie_release',
    'episode_code': null,
    'season_number': null,
    'episode_number': null,
    'watchlist_id': watchlistId,
    'watchlist_name': watchlistName,
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
  });

  late MockCalendarEventsFetcher mockFetcher;
  late CalendarController controller;

  setUp(() {
    mockFetcher = MockCalendarEventsFetcher();
    controller = CalendarController(eventsFetcher: mockFetcher);
  });

  group('loadEvents', () {
    test('populates events and clears loading/error on success', () async {
      when(
        () => mockFetcher.call(any(), any()),
      ).thenAnswer((_) async => [_episodeRow(tmdbId: 1, eventDate: '2026-08-01')]);

      await controller.loadEvents();

      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.eventsForDate(DateTime(2026, 8, 1)), hasLength(1));
    });

    test('sets an error message and clears loading when fetch throws', () async {
      when(() => mockFetcher.call(any(), any())).thenThrow(Exception('network down'));

      await controller.loadEvents();

      expect(controller.isLoading, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.eventsForDate(DateTime(2026, 8, 1)), isEmpty);
    });

    test('normalizes event_date, stripping any time-of-day component', () async {
      when(
        () => mockFetcher.call(any(), any()),
      ).thenAnswer((_) async => [_episodeRow(tmdbId: 1, eventDate: '2026-08-01T15:30:00Z')]);

      await controller.loadEvents();

      expect(controller.eventsForDate(DateTime(2026, 8, 1)), hasLength(1));
    });

    test('tracks a WatchlistItem per tmdbId for navigation', () async {
      when(() => mockFetcher.call(any(), any())).thenAnswer(
        (_) async => [_episodeRow(tmdbId: 42, eventDate: '2026-08-01', watchlistId: 'wl-9')],
      );

      await controller.loadEvents();

      final item = controller.watchlistItemFor(42);
      expect(item, isNotNull);
      expect(item!.watchlistId, 'wl-9');
    });
  });

  group('filteredEventsByDate — "all" filter deduplication', () {
    test('dedupes episodes by (tmdbId, seasonNumber, episodeNumber)', () async {
      when(() => mockFetcher.call(any(), any())).thenAnswer(
        (_) async => [
          _episodeRow(tmdbId: 1, eventDate: '2026-08-01', watchlistId: 'wl-1'),
          _episodeRow(tmdbId: 1, eventDate: '2026-08-01', watchlistId: 'wl-2'),
        ],
      );

      await controller.loadEvents();
      controller.selectWatchlist('all');

      expect(controller.eventsForDate(DateTime(2026, 8, 1)), hasLength(1));
    });

    test('does not dedupe distinct episodes of the same show', () async {
      when(() => mockFetcher.call(any(), any())).thenAnswer(
        (_) async => [
          _episodeRow(tmdbId: 1, eventDate: '2026-08-01', episodeNumber: 1),
          _episodeRow(tmdbId: 1, eventDate: '2026-08-01', episodeNumber: 2),
        ],
      );

      await controller.loadEvents();
      controller.selectWatchlist('all');

      expect(controller.eventsForDate(DateTime(2026, 8, 1)), hasLength(2));
    });

    test('dedupes movie releases by tmdbId alone', () async {
      when(() => mockFetcher.call(any(), any())).thenAnswer(
        (_) async => [
          _movieRow(tmdbId: 7, eventDate: '2026-08-01', watchlistId: 'wl-1'),
          _movieRow(tmdbId: 7, eventDate: '2026-08-01', watchlistId: 'wl-2'),
        ],
      );

      await controller.loadEvents();
      controller.selectWatchlist('all');

      expect(controller.eventsForDate(DateTime(2026, 8, 1)), hasLength(1));
    });
  });

  group('filteredEventsByDate — per-watchlist filter', () {
    test('only returns events for the selected watchlist', () async {
      when(() => mockFetcher.call(any(), any())).thenAnswer(
        (_) async => [
          _episodeRow(tmdbId: 1, eventDate: '2026-08-01', watchlistId: 'wl-1'),
          _episodeRow(tmdbId: 2, eventDate: '2026-08-01', watchlistId: 'wl-2'),
        ],
      );

      await controller.loadEvents();
      controller.selectWatchlist('wl-2');

      final events = controller.eventsForDate(DateTime(2026, 8, 1));
      expect(events, hasLength(1));
      expect(events.first.tmdbId, 2);
    });
  });

  group('hasEventsOnDate', () {
    test('true for a date with events, false otherwise', () async {
      when(
        () => mockFetcher.call(any(), any()),
      ).thenAnswer((_) async => [_episodeRow(tmdbId: 1, eventDate: '2026-08-01')]);

      await controller.loadEvents();

      expect(controller.hasEventsOnDate(DateTime(2026, 8, 1)), isTrue);
      expect(controller.hasEventsOnDate(DateTime(2026, 8, 2)), isFalse);
    });
  });

  group('selection state', () {
    test('selectDate updates selectedDate', () {
      final date = DateTime(2026, 8, 15);
      controller.selectDate(date);
      expect(controller.selectedDate.value, date);
    });

    test('selectWatchlist updates selectedWatchlistId', () {
      controller.selectWatchlist('wl-3');
      expect(controller.selectedWatchlistId.value, 'wl-3');
    });
  });

  group('month navigation', () {
    test('nextMonth advances the focused month by one', () {
      final start = controller.focusedMonth;
      final expected = DateTime(start.year, start.month + 1);

      controller.nextMonth();

      expect(controller.focusedMonth.year, expected.year);
      expect(controller.focusedMonth.month, expected.month);
    });

    test('previousMonth moves the focused month back by one', () {
      final start = controller.focusedMonth;
      final expected = DateTime(start.year, start.month - 1);

      controller.previousMonth();

      expect(controller.focusedMonth.year, expected.year);
      expect(controller.focusedMonth.month, expected.month);
    });

    test('previousMonth then nextMonth returns to the original month', () {
      final start = controller.focusedMonth;

      controller.previousMonth();
      controller.nextMonth();

      expect(controller.focusedMonth.year, start.year);
      expect(controller.focusedMonth.month, start.month);
    });
  });
}
