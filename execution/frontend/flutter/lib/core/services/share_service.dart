import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/models/badge.dart';
import '../../shared/models/watchlist_item.dart';

/// Service for handling external sharing to social media and other platforms.
class ShareService extends GetxService {
  static ShareService get to => Get.find<ShareService>();

  /// Default app link for sharing.
  final String appLink = "https://bingequest.app";

  /// Shared text content for badge unlocks.
  String getBadgeShareText(Badge badge) {
    return "I earned the ${badge.name} badge on BingeQuest! ${badge.emoji}\n\nDownload the app: $appLink";
  }

  /// Shared text content for completion milestones.
  String getCompletionShareText(WatchlistItem item) {
    return "I just finished watching ${item.title} on BingeQuest! 🎬\n\nDownload the app: $appLink";
  }

  /// Share plain text using native share sheet.
  Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  /// Share message with a link.
  Future<void> shareWithLink(String message, String link) async {
    await Share.share('$message\n\n$link');
  }

  /// Share a badge unlock achievement.
  Future<void> shareBadgeUnlock(Badge badge) async {
    await shareText(getBadgeShareText(badge), subject: "Badge Unlocked!");
  }

  /// Share a watchlist item completion milestone.
  Future<void> shareCompletionMilestone(WatchlistItem item) async {
    await shareText(getCompletionShareText(item), subject: "Movie Completed!");
  }
}
