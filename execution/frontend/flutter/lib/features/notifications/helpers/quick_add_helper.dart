import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../search/widgets/watchlist_selector_sheet.dart';
import '../../search/controllers/search_controller.dart';

/// Helper for quick-adding content to a watchlist from notifications.
/// Extracted to keep notification card widgets under 300 lines.
class QuickAddHelper {
  QuickAddHelper._();

  /// Show a quick-add flow for content from a notification.
  /// Checks if already in a watchlist; if so, shows info snackbar.
  /// Otherwise, opens the watchlist selector sheet.
  static Future<void> quickAddToWatchlist({
    required int tmdbId,
    required String mediaType,
    required String contentTitle,
  }) async {
    final mType = mediaType == 'movie' ? MediaType.movie : MediaType.tv;

    // Check if already in a watchlist
    final existing = await WatchlistRepository.getWatchlistsContainingItem(
      tmdbId: tmdbId,
      mediaType: mType,
    );

    if (existing.isNotEmpty) {
      Get.snackbar(
        'Already Added',
        '$contentTitle is already in your watchlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.info,
        colorText: EColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Show watchlist selector
    final context = Get.context;
    if (context == null) return;

    WatchlistSelectorSheet.show(
      context: context,
      tmdbId: tmdbId,
      mediaType: mType,
      title: contentTitle,
      onConfirm: (watchlistIds) => _addToWatchlists(
        tmdbId: tmdbId,
        mediaType: mediaType,
        contentTitle: contentTitle,
        watchlistIds: watchlistIds,
      ),
    );
  }

  static Future<void> _addToWatchlists({
    required int tmdbId,
    required String mediaType,
    required String contentTitle,
    required List<String> watchlistIds,
  }) async {
    try {
      final controller = ContentSearchController.to;

      // Build a minimal search result to trigger the add flow
      final result = TmdbSearchResult(
        id: tmdbId,
        titleField: contentTitle,
        mediaTypeString: mediaType,
        voteAverage: 0,
      );

      // Load content details then add
      await controller.getContentDetails(result);
      final content = controller.selectedContent;

      if (content == null) {
        Get.snackbar(
          'Error',
          'Failed to load content details',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: EColors.error,
          colorText: EColors.textOnPrimary,
        );
        return;
      }

      bool success = false;
      if (content is TmdbMovie) {
        success =
            await controller.addMovieToWatchlists(content, watchlistIds);
      } else if (content is TmdbTvShow) {
        success =
            await controller.addTvShowToWatchlists(content, watchlistIds);
      }

      if (success) {
        Get.snackbar(
          'Added!',
          '$contentTitle added to watchlist',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: EColors.success,
          colorText: EColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add to watchlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }
}
