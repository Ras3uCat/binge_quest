import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../controllers/progress_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../search/widgets/content_detail_sheet.dart';
import '../../search/widgets/review_form_sheet.dart';
import '../../social/controllers/watch_party_controller.dart';
import '../../social/screens/create_party_sheet.dart';
import '../../social/screens/watch_party_screen.dart';
import '../widgets/move_item_sheet.dart';
import '../widgets/completed_rating_card.dart';
import '../widgets/movie_progress_section.dart';
import '../widgets/tv_progress_section.dart';
import '../widgets/item_detail_info_section.dart';

class ItemDetailScreen extends StatelessWidget {
  final WatchlistItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProgressController(item: item), tag: item.id);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [EColors.backgroundSecondary, EColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, controller),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: EColors.primary),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: controller.loadProgress,
                    color: EColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(ESizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ItemDetailInfoSection(
                            item: item,
                            controller: controller,
                            onPosterTap: _showTmdbInfo,
                          ),
                          _buildWatchPartyBadge(),
                          const SizedBox(height: ESizes.lg),
                          _buildProgressCard(controller),
                          const SizedBox(height: ESizes.lg),
                          if (controller.isMovie)
                            MovieProgressSection(
                              controller: controller,
                              itemTitle: item.title,
                            )
                          else
                            TvProgressSection(controller: controller),
                          const SizedBox(height: ESizes.xl),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProgressController controller) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: ESizes.fontXl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: EColors.textSecondary),
            color: EColors.surface,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'party',
                child: Row(children: [
                  Icon(Icons.groups, color: EColors.primary, size: 20),
                  SizedBox(width: ESizes.sm),
                  Text('Create Watch Party',
                      style: TextStyle(color: EColors.textPrimary)),
                ]),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(children: [
                  Icon(Icons.drive_file_move_outlined,
                      color: EColors.textPrimary, size: 20),
                  SizedBox(width: ESizes.sm),
                  Text(EText.moveTo,
                      style: TextStyle(color: EColors.textPrimary)),
                ]),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(children: [
                  Icon(Icons.delete, color: EColors.error, size: 20),
                  SizedBox(width: ESizes.sm),
                  Text('Remove from Watchlist',
                      style: TextStyle(color: EColors.error)),
                ]),
              ),
            ],
            onSelected: (value) {
              if (value == 'party') {
                _showCreatePartySheet();
              } else if (value == 'move') {
                _showMoveSheet(context);
              } else if (value == 'remove') {
                _confirmRemove();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCreatePartySheet() {
    _ensurePartyController();
    CreatePartySheet.show(
      tmdbId: item.tmdbId,
      mediaType: item.mediaType.name,
      contentTitle: item.title,
    );
  }

  WatchPartyController _ensurePartyController() {
    if (!Get.isRegistered<WatchPartyController>()) {
      Get.lazyPut(() => WatchPartyController(), fenix: true);
    }
    final ctrl = WatchPartyController.to;
    if (ctrl.activeParties.isEmpty && !ctrl.isLoading.value) {
      ctrl.loadParties();
    }
    return ctrl;
  }

  Widget _buildWatchPartyBadge() {
    final ctrl = _ensurePartyController();
    return Obx(() {
      final party = ctrl.activeParties.firstWhereOrNull(
        (p) => p.tmdbId == item.tmdbId && p.mediaType == item.mediaType.name,
      );
      if (party == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: ESizes.sm),
        child: GestureDetector(
          onTap: () => Get.to(() => WatchPartyScreen(
                partyId: party.id,
                tmdbId: party.tmdbId,
                mediaType: party.mediaType,
                partyName: party.name,
              )),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ESizes.md,
              vertical: ESizes.sm,
            ),
            decoration: BoxDecoration(
              color: EColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups, color: EColors.primary, size: 18),
                SizedBox(width: ESizes.xs),
                Text(
                  'Watch Party',
                  style: TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: ESizes.xs),
                Icon(Icons.chevron_right, color: EColors.primary, size: 18),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildProgressCard(ProgressController controller) {
    if (controller.isComplete) {
      return CompletedRatingCard(
        controller: controller,
        onEditThoughts: () => _openReviewForm(controller),
      );
    }
    return InProgressCard(controller: controller);
  }

  void _openReviewForm(ProgressController controller) async {
    final result = await Get.bottomSheet<bool>(
      ReviewFormSheet(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType.name,
        initialRating: controller.userRating,
        initialText: controller.userReviewText,
      ),
      isScrollControlled: true,
      backgroundColor: EColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
    if (result == true) controller.loadUserReview();
  }

  void _showTmdbInfo() {
    final isMovie = item.mediaType == MediaType.movie;
    final result = TmdbSearchResult(
      id: item.tmdbId,
      mediaTypeString: item.mediaType.name,
      titleField: isMovie ? item.title : null,
      name: !isMovie ? item.title : null,
      posterPath: item.posterPath,
      overview: null,
      releaseDate:
          isMovie ? item.releaseDate?.toIso8601String().split('T').first : null,
      firstAirDate:
          !isMovie ? item.releaseDate?.toIso8601String().split('T').first : null,
      voteAverage: 0,
    );
    if (!Get.isRegistered<ContentSearchController>()) {
      Get.put(ContentSearchController());
    }
    Get.bottomSheet(
      ContentDetailSheet(result: result, showWatchlistAction: false),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showMoveSheet(BuildContext context) {
    MoveItemSheet.show(
      context: context,
      item: item,
      currentWatchlistId: item.watchlistId,
      currentWatchlistName:
          WatchlistController.to.currentWatchlist?.name ?? 'Watchlist',
    );
  }

  void _confirmRemove() {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(EText.removeFromWatchlist,
            style: TextStyle(color: EColors.textPrimary)),
        content: Text('Remove "${item.title}" from your watchlist?',
            style: const TextStyle(color: EColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text(EText.cancel)),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await WatchlistController.to.removeItem(item.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: EColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
