import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/friend_watching.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/review_repository.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../social/controllers/friend_controller.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../controllers/search_controller.dart';
import 'content_detail_body.dart';
import 'content_detail_header.dart';
import 'content_where_to_watch.dart';
import 'person_detail_sheet.dart';
import 'reviews_section.dart';
import 'watchlist_selector_sheet.dart';

class ContentDetailSheet extends StatefulWidget {
  final TmdbSearchResult result;
  final bool showWatchlistAction;

  const ContentDetailSheet({super.key, required this.result, this.showWatchlistAction = true});

  @override
  State<ContentDetailSheet> createState() => _ContentDetailSheetState();
}

class _ContentDetailSheetState extends State<ContentDetailSheet> {
  int _existingWatchlistCount = 0;
  int _totalWatchlistCount = 0;
  bool _checkingWatchlist = true;
  WatchlistItem? _ownedItem;
  int _userCount = 0;
  double? _bqRating;
  int _bqReviewCount = 0;
  List<FriendWatching> _friendsWatching = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _checkWatchlistStatus();
    _loadVideosAndProviders();
    _loadUserCount();
    _loadReviewStats();
    _loadFriendsWatching();
  }

  Future<void> _loadFriendsWatching() async {
    if (!Get.isRegistered<FriendController>()) return;
    final ctrl = FriendController.to;
    if (ctrl.friends.isEmpty) await ctrl.refresh();
    final friendIds = ctrl.friendIds.toList();
    if (friendIds.isEmpty) return;
    try {
      final friends = await WatchlistRepository.getFriendsWatching(
        tmdbId: widget.result.id,
        mediaType: widget.result.mediaType,
        friendIds: friendIds,
      );
      if (mounted && friends.isNotEmpty) setState(() => _friendsWatching = friends);
    } catch (e) {
      debugPrint('Error loading friends watching: $e');
    }
  }

  Future<void> _loadReviewStats() async {
    final stats = await ReviewRepository.getAverageRating(
      tmdbId: widget.result.id,
      mediaType: widget.result.mediaTypeString,
    );
    if (mounted)
      setState(() {
        _bqRating = stats.average;
        _bqReviewCount = stats.count;
      });
  }

  Future<void> _loadUserCount() async {
    final count = await WatchlistRepository.getUserCount(
      tmdbId: widget.result.id,
      mediaType: widget.result.mediaTypeString,
    );
    if (mounted) setState(() => _userCount = count);
  }

  Future<void> _loadDetails() async {
    await ContentSearchController.to.getContentDetails(widget.result);
  }

  Future<void> _loadVideosAndProviders() async {
    final controller = ContentSearchController.to;
    await Future.wait([
      controller.loadVideos(widget.result.id, widget.result.mediaType),
      controller.loadWatchProviders(widget.result.id, widget.result.mediaType),
    ]);
  }

  Future<void> _checkWatchlistStatus() async {
    try {
      final existingIds = await WatchlistRepository.getWatchlistsContainingItem(
        tmdbId: widget.result.id,
        mediaType: widget.result.mediaType,
      );
      final watchlists = await WatchlistRepository.getWatchlists();
      WatchlistItem? ownedItem;
      if (existingIds.isNotEmpty) {
        ownedItem = await WatchlistRepository.getItemByTmdbId(
          tmdbId: widget.result.id,
          mediaType: widget.result.mediaType,
        );
      }
      if (mounted) {
        setState(() {
          _existingWatchlistCount = existingIds.length;
          _totalWatchlistCount = watchlists.length;
          _ownedItem = ownedItem;
          _checkingWatchlist = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _checkingWatchlist = false);
    }
  }

  bool get _isInSomeWatchlists => _existingWatchlistCount > 0;

  void _shareContent(TmdbContent content) {
    final type = content is TmdbMovie ? 'movie' : 'tv';
    final link = 'https://raspucat.com/bingequest/content?type=$type&id=${widget.result.id}';
    Share.share('Check out ${content.title} on BingeQuest!\n$link');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: ESizes.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: Obx(() {
              final controller = ContentSearchController.to;
              final content = controller.selectedContent;
              if (controller.isLoadingDetails || content == null) {
                return const Padding(
                  padding: EdgeInsets.all(ESizes.xxl),
                  child: Center(child: CircularProgressIndicator(color: EColors.primary)),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(ESizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContentDetailHeader(
                      content: content,
                      bqRating: _bqRating,
                      bqReviewCount: _bqReviewCount,
                      userCount: _userCount,
                      friendsWatching: _friendsWatching,
                      onShare: () => _shareContent(content),
                    ),
                    const SizedBox(height: ESizes.lg),
                    ContentDetailBody(content: content, onPersonTap: _openPersonDetail),
                    const ContentWhereToWatch(),
                    const SizedBox(height: ESizes.lg),
                    _buildAddButton(content),
                    const SizedBox(height: ESizes.lg),
                    ReviewsSection(
                      tmdbId: widget.result.id,
                      mediaType: widget.result.mediaTypeString,
                    ),
                    const SizedBox(height: ESizes.lg),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openPersonDetail(int personId) {
    Get.back();
    Get.bottomSheet(
      PersonDetailSheet(personId: personId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildAddButton(TmdbContent content) {
    if (!widget.showWatchlistAction) return const SizedBox.shrink();
    if (_isInSomeWatchlists && _ownedItem != null) {
      return SizedBox(
        width: double.infinity,
        height: ESizes.buttonHeightLg,
        child: ElevatedButton.icon(
          onPressed: _navigateToWatchlistItem,
          icon: const Icon(Icons.visibility),
          label: const Text('View in Watchlist'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: ESizes.buttonHeightLg,
      child: ElevatedButton.icon(
        onPressed: _checkingWatchlist ? null : () => _showWatchlistSelector(content),
        icon: const Icon(Icons.add),
        label: Text(_getAddButtonText()),
      ),
    );
  }

  void _navigateToWatchlistItem() {
    if (_ownedItem == null) return;
    Get.back();
    Get.to(() => ItemDetailScreen(item: _ownedItem!));
  }

  String _getAddButtonText() {
    if (_isInSomeWatchlists) {
      final remaining = _totalWatchlistCount - _existingWatchlistCount;
      return 'Add to $remaining more watchlist${remaining > 1 ? 's' : ''}';
    }
    return EText.addToWatchlist;
  }

  void _showWatchlistSelector(TmdbContent content) {
    WatchlistSelectorSheet.show(
      context: context,
      tmdbId: content.id,
      mediaType: content is TmdbMovie ? MediaType.movie : MediaType.tv,
      title: content.title,
      onConfirm: (watchlistIds) => _addToWatchlists(content, watchlistIds),
    );
  }

  Future<void> _addToWatchlists(TmdbContent content, List<String> watchlistIds) async {
    final controller = ContentSearchController.to;
    bool success = false;
    if (content is TmdbMovie) {
      success = await controller.addMovieToWatchlists(content, watchlistIds);
    } else if (content is TmdbTvShow) {
      success = await controller.addTvShowToWatchlists(content, watchlistIds);
    }
    if (success) {
      await _checkWatchlistStatus();
      final countText = watchlistIds.length == 1 ? 'watchlist' : 'watchlists';
      Get.snackbar(
        'Added!',
        '${content.title} added to ${watchlistIds.length} $countText',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.success,
        colorText: EColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
    } else {
      final error = controller.error;
      if (error != null) {
        Get.snackbar(
          'Error',
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: EColors.error,
          colorText: EColors.textOnPrimary,
        );
        controller.clearError();
      }
    }
  }
}
