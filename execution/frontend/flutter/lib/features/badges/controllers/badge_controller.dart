import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import '../../../shared/models/badge.dart';
import '../../../shared/models/user_badge.dart';
import '../../../shared/repositories/badge_repository.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../widgets/badge_unlock_dialog.dart';

/// Controller for badge management and achievement tracking.
class BadgeController extends GetxController {
  static BadgeController get to => Get.find();

  // Observable state
  final _isLoading = false.obs;
  final _allBadges = <Badge>[].obs;
  final _earnedBadges = <UserBadge>[].obs;
  final _recentBadges = <UserBadge>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  List<Badge> get allBadges => _allBadges;
  List<UserBadge> get earnedBadges => _earnedBadges;
  List<UserBadge> get recentBadges => _recentBadges;

  int get earnedCount => _earnedBadges.length;
  int get totalCount => _allBadges.length;

  /// Get set of earned badge IDs for quick lookup.
  Set<String> get earnedBadgeIds =>
      _earnedBadges.map((ub) => ub.badgeId).toSet();

  /// Get badges organized by category.
  Map<BadgeCategory, List<Badge>> get badgesByCategory {
    final grouped = <BadgeCategory, List<Badge>>{};
    for (final badge in _allBadges) {
      grouped.putIfAbsent(badge.category, () => []).add(badge);
    }
    return grouped;
  }

  @override
  void onInit() {
    super.onInit();
    loadBadges();
  }

  /// Load all badges and user's earned badges.
  Future<void> loadBadges() async {
    _isLoading.value = true;

    try {
      final results = await Future.wait([
        BadgeRepository.getAllBadges(),
        BadgeRepository.getUserBadges(),
        BadgeRepository.getRecentBadges(limit: 3),
      ]);

      _allBadges.value = results[0] as List<Badge>;
      _earnedBadges.value = results[1] as List<UserBadge>;
      _recentBadges.value = results[2] as List<UserBadge>;
    } catch (e) {
      // Badges failed to load, use empty lists
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check for new badges based on current user stats.
  /// Call this after user completes content.
  Future<void> checkForNewBadges() async {
    try {
      // Get current user stats
      final stats = await WatchlistRepository.getUserStats();

      // Add genre stats (requires additional computation)
      final genreStats = await _computeGenreStats();
      stats['genre_stats'] = genreStats;

      // Add efficiency stats for efficiency badges
      final efficiency = await WatchlistRepository.getQueueEfficiency();
      stats['efficiency_score'] = efficiency.efficiencyScore;
      stats['stale_items'] = efficiency.staleItems;
      stats['active_items'] = efficiency.activeItems;
      stats['idle_items'] = efficiency.idleItems;

      // Check and award eligible badges
      final newBadges = await BadgeRepository.checkAndAwardBadges(stats);

      if (newBadges.isNotEmpty) {
        // Reload earned badges
        await loadBadges();

        // Show unlock notification for each new badge
        for (final badge in newBadges) {
          await _showBadgeUnlockedNotification(badge);
        }
      }
    } catch (e) {
      // Badge check failed silently
    }
  }

  /// Compute genre watch counts for badge checking.
  Future<Map<int, int>> _computeGenreStats() async {
    final genreStats = <int, int>{};

    try {
      final watchlists = await WatchlistRepository.getWatchlists();

      for (final watchlist in watchlists) {
        final items = await WatchlistRepository.getWatchlistItems(watchlist.id);

        for (final item in items) {
          if (item.isCompleted) {
            for (final genreId in item.genreIds) {
              genreStats[genreId] = (genreStats[genreId] ?? 0) + 1;
            }
          }
        }
      }
    } catch (e) {
      // Genre stats computation failed
    }

    return genreStats;
  }

  /// Show a celebration dialog when a badge is unlocked.
  Future<void> _showBadgeUnlockedNotification(Badge badge) async {
    if (Get.context == null) return;

    await showDialog(
      context: Get.context!,
      barrierDismissible: true,
      builder: (context) => BadgeUnlockDialog(badge: badge),
    );
  }

  /// Check if a specific badge is earned.
  bool isBadgeEarned(String badgeId) => earnedBadgeIds.contains(badgeId);

  /// Get earned date for a badge, or null if not earned.
  DateTime? getEarnedDate(String badgeId) {
    final userBadge = _earnedBadges.firstWhereOrNull(
      (ub) => ub.badgeId == badgeId,
    );
    return userBadge?.earnedAt;
  }
}
