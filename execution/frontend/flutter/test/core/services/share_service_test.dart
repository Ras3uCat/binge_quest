import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:binge_quest/core/services/share_service.dart';
import 'package:binge_quest/shared/models/badge.dart';
import 'package:binge_quest/shared/models/watchlist_item.dart';
import 'package:binge_quest/shared/models/content_cache.dart';

void main() {
  late ShareService shareService;

  setUp(() {
    shareService = ShareService();
    Get.put(shareService);
  });

  tearDown(() {
    Get.reset();
  });

  group('ShareService Content Generation', () {
    test('getBadgeShareText returns correctly formatted string', () {
      final badge = Badge(
        id: '1',
        name: 'Completionist',
        description: 'Completed 10 items',
        iconPath: 'emoji:🏆',
        category: BadgeCategory.completion,
        criteria: const BadgeCriteria(
          type: BadgeCriteriaType.itemsCompleted,
          value: 10,
        ),
      );

      final text = shareService.getBadgeShareText(badge);
      expect(
        text,
        contains('I earned the Completionist badge on BingeQuest! 🏆'),
      );
      expect(text, contains('https://bingequest.app'));
    });

    test('getCompletionShareText returns correctly formatted string', () {
      final item = WatchlistItem(
        id: '1',
        watchlistId: 'w1',
        tmdbId: 101,
        mediaType: MediaType.movie,
        addedAt: DateTime.now(),
        content: ContentCache(
          tmdbId: 101,
          mediaType: MediaType.movie,
          title: 'Inception',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final text = shareService.getCompletionShareText(item);
      expect(
        text,
        contains('I just finished watching Inception on BingeQuest! 🎬'),
      );
      expect(text, contains('https://bingequest.app'));
    });
  });
}
