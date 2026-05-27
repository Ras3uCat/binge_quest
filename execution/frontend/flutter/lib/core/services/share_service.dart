import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/badge.dart';
import '../../shared/models/watchlist_item.dart';

/// Service for handling external sharing to social media and other platforms.
class ShareService extends GetxService {
  static ShareService get to => Get.find<ShareService>();

  final shareCount = 0.obs;

  /// Default app link for sharing.
  final String appLink = "https://raspucat.com/bingequest";

  @override
  void onInit() {
    super.onInit();
    _loadShareCount();
  }

  Future<void> _loadShareCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      shareCount.value = prefs.getInt('bq_share_count') ?? 0;
    } catch (_) {}
  }

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
    try {
      await Share.share(text, subject: subject);
    } on PlatformException catch (e) {
      Get.snackbar(
        'Share unavailable',
        e.message ?? 'Could not open share sheet.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      shareCount.value++;
      await prefs.setInt('bq_share_count', shareCount.value);
    } catch (_) {}
  }

  /// Share message with a link.
  Future<void> shareWithLink(String message, String link) async {
    await shareText('$message\n\n$link');
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
