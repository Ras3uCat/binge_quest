import 'package:flutter_test/flutter_test.dart';
import 'package:binge_quest/shared/models/content_cache_episode.dart';
import 'package:binge_quest/shared/models/watch_progress.dart';

void main() {
  group('ContentCacheEpisode Date Helpers', () {
    test('hasAired returns true for past dates', () {
      final episode = ContentCacheEpisode(
        id: '1',
        tmdbId: 1,
        seasonNumber: 1,
        episodeNumber: 1,
        runtimeMinutes: 30,
        airDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(episode.hasAired, isTrue);
      expect(episode.isUpcoming, isFalse);
    });

    test('isUpcoming returns true for future dates', () {
      final episode = ContentCacheEpisode(
        id: '1',
        tmdbId: 1,
        seasonNumber: 1,
        episodeNumber: 1,
        runtimeMinutes: 30,
        airDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(episode.isUpcoming, isTrue);
      expect(episode.hasAired, isFalse);
    });

    test('airDateDisplay returns TBA for null date', () {
      final episode = ContentCacheEpisode(
        id: '1',
        tmdbId: 1,
        seasonNumber: 1,
        episodeNumber: 1,
        runtimeMinutes: 30,
        airDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(episode.airDateDisplay, 'TBA');
    });
  });

  group('WatchProgress Date Helpers', () {
    test('hasAired and airDateDisplay match ContentCacheEpisode logic', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final progress = WatchProgress(
        id: '1',
        watchlistItemId: 'w1',
        episodeCacheId: 'e1',
        watched: false,
        runtimeMinutes: 30,
        airDate: pastDate,
      );
      expect(progress.hasAired, isTrue);
      expect(progress.airDateDisplay.startsWith('Aired:'), isTrue);
    });

    test('isUpcoming and airDateDisplay match ContentCacheEpisode logic', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final progress = WatchProgress(
        id: '1',
        watchlistItemId: 'w1',
        episodeCacheId: 'e1',
        watched: false,
        runtimeMinutes: 30,
        airDate: futureDate,
      );
      expect(progress.isUpcoming, isTrue);
      expect(progress.airDateDisplay.startsWith('Airs:'), isTrue);
    });
  });
}
