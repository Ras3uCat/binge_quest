import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/utils/formatters.dart';
import 'trailer_player_dialog.dart';
import 'watchlist_selector_sheet.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/tmdb_video.dart';
import '../../../shared/models/tmdb_watch_provider.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../controllers/search_controller.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../../../shared/repositories/review_repository.dart';
import 'reviews_section.dart';
import 'person_detail_sheet.dart';

class ContentDetailSheet extends StatefulWidget {
  final TmdbSearchResult result;
  final bool showWatchlistAction;

  const ContentDetailSheet({
    super.key,
    required this.result,
    this.showWatchlistAction = true,
  });

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

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _checkWatchlistStatus();
    _loadVideosAndProviders();
    _loadUserCount();
    _loadReviewStats();
  }

  Future<void> _loadReviewStats() async {
    final stats = await ReviewRepository.getAverageRating(
      tmdbId: widget.result.id,
      mediaType: widget.result.mediaTypeString,
    );
    if (mounted) {
      setState(() {
        _bqRating = stats.average;
        _bqReviewCount = stats.count;
      });
    }
  }

  Future<void> _loadUserCount() async {
    final count = await WatchlistRepository.getUserCount(
      tmdbId: widget.result.id,
      mediaType: widget.result.mediaTypeString,
    );
    if (mounted) {
      setState(() => _userCount = count);
    }
  }

  Future<void> _loadDetails() async {
    await ContentSearchController.to.getContentDetails(widget.result);
  }

  Future<void> _loadVideosAndProviders() async {
    final controller = ContentSearchController.to;
    // Load videos and providers in parallel
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

      // Fetch the actual WatchlistItem if owned (for navigation)
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
      if (mounted) {
        setState(() => _checkingWatchlist = false);
      }
    }
  }

  bool get _isInSomeWatchlists => _existingWatchlistCount > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: ESizes.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Flexible(
            child: Obx(() {
              final controller = ContentSearchController.to;
              final content = controller.selectedContent;
              final isLoading = controller.isLoadingDetails;

              if (isLoading || content == null) {
                return _buildLoadingState();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(ESizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(content),
                    const SizedBox(height: ESizes.lg),
                    _buildMetadata(content),
                    const SizedBox(height: ESizes.lg),
                    _buildTrailerButton(),
                    _buildOverview(content),
                    if (content is TmdbMovie && content.cast != null)
                      _buildCast(content.cast!),
                    if (content is TmdbTvShow && content.cast != null)
                      _buildCast(content.cast!),
                    if (content is TmdbTvShow) _buildSeasons(content),
                    _buildWhereToWatch(),
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

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(ESizes.xxl),
      child: Center(child: CircularProgressIndicator(color: EColors.primary)),
    );
  }

  Widget _buildHeader(TmdbContent content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster
        ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          child: content.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: EImages.tmdbPoster(
                    content.posterPath,
                    size: 'w185',
                  ),
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 100,
                  height: 150,
                  color: EColors.surfaceLight,
                  child: const Icon(Icons.movie, size: 40),
                ),
        ),
        const SizedBox(width: ESizes.md),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
              const SizedBox(height: ESizes.xs),
              _buildInfoRow(content),
              const SizedBox(height: ESizes.sm),
              Row(
                children: [
                  _buildRatingBadge(content.voteAverage),
                  if (_bqRating != null) ...[
                    const SizedBox(width: ESizes.md),
                    _buildBqRatingBadge(),
                  ],
                ],
              ),
              if (_userCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.sm),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 14,
                        color: EColors.textSecondary,
                      ),
                      const SizedBox(width: ESizes.xs),
                      Text(
                        '${formatCompactNumber(_userCount)} ${_userCount == 1 ? 'user' : 'users'} watching',
                        style: const TextStyle(
                          fontSize: ESizes.fontSm,
                          color: EColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (content is TmdbMovie && content.tagline != null)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.sm),
                  child: Text(
                    '"${content.tagline}"',
                    style: const TextStyle(
                      fontSize: ESizes.fontSm,
                      fontStyle: FontStyle.italic,
                      color: EColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(TmdbContent content) {
    final items = <String>[];

    if (content is TmdbMovie) {
      if (content.year != null) items.add(content.year!);
      if (content.runtime != null) items.add(content.formattedRuntime);
    } else if (content is TmdbTvShow) {
      if (content.year != null) items.add(content.year!);
      items.add(
        '${content.numberOfSeasons} Season${content.numberOfSeasons > 1 ? 's' : ''}',
      );
      items.add('${content.numberOfEpisodes} Episodes');
    }

    return Wrap(
      spacing: ESizes.sm,
      children: items.map((item) => _buildInfoChip(item)).toList(),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.surfaceLight,
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: ESizes.fontXs,
          color: EColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Row(
      children: [
        Icon(Icons.star, size: 18, color: _getRatingColor(rating)),
        const SizedBox(width: ESizes.xs),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.bold,
            color: _getRatingColor(rating),
          ),
        ),
        const Text(
          ' / 10',
          style: TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildBqRatingBadge() {
    return Row(
      children: [
        const Icon(Icons.live_tv, size: 18, color: EColors.primary),
        const SizedBox(width: ESizes.xs),
        Text(
          _bqRating!.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.bold,
            color: EColors.primary,
          ),
        ),
        Text(
          ' ($_bqReviewCount)',
          style: const TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(TmdbContent content) {
    List<TmdbGenre> genres = [];
    String? status;

    if (content is TmdbMovie) {
      genres = content.genres;
      status = content.status;
    } else if (content is TmdbTvShow) {
      genres = content.genres;
      status = content.status;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genres
        if (genres.isNotEmpty)
          Wrap(
            spacing: ESizes.xs,
            runSpacing: ESizes.xs,
            children: genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.sm,
                  vertical: ESizes.xs,
                ),
                decoration: BoxDecoration(
                  color: EColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ESizes.radiusRound),
                  border: Border.all(
                    color: EColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  genre.name,
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        // Status
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: ESizes.sm),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: EColors.textTertiary,
                ),
                const SizedBox(width: ESizes.xs),
                Text(
                  'Status: $status',
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOverview(TmdbContent content) {
    if (content.overview == null || content.overview!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          EText.overview,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Text(
          content.overview!,
          style: const TextStyle(
            fontSize: ESizes.fontMd,
            color: EColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCast(List<TmdbCastMember> cast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ESizes.lg),
        const Text(
          EText.cast,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final member = cast[index];
              return GestureDetector(
                onTap: () => _openPersonDetail(member.id),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: ESizes.sm),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: EColors.surfaceLight,
                        backgroundImage: member.profilePath != null
                            ? CachedNetworkImageProvider(
                                EImages.tmdbPoster(
                                  member.profilePath,
                                  size: 'w92',
                                ),
                              )
                            : null,
                        child: member.profilePath == null
                            ? const Icon(
                                Icons.person,
                                color: EColors.textTertiary,
                              )
                            : null,
                      ),
                      const SizedBox(height: ESizes.xs),
                      Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: ESizes.fontXs,
                          color: EColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeasons(TmdbTvShow tvShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ESizes.lg),
        Text(
          '${EText.seasons} (${tvShow.numberOfSeasons})',
          style: const TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        ...tvShow.seasons
            .take(5)
            .map(
              (season) => Padding(
                padding: const EdgeInsets.only(bottom: ESizes.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: EColors.textSecondary,
                    ),
                    const SizedBox(width: ESizes.sm),
                    Text(
                      season.name ?? 'Season ${season.seasonNumber}',
                      style: const TextStyle(
                        fontSize: ESizes.fontMd,
                        color: EColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${season.episodeCount} episodes',
                      style: const TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (tvShow.seasons.length > 5)
          Text(
            '+ ${tvShow.seasons.length - 5} more seasons',
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              color: EColors.textTertiary,
            ),
          ),
      ],
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
    // Hide button if viewing from ItemDetailScreen
    if (!widget.showWatchlistAction) {
      return const SizedBox.shrink();
    }

    // In watchlist - show "View in Watchlist" button
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

    // Can add to watchlists
    return SizedBox(
      width: double.infinity,
      height: ESizes.buttonHeightLg,
      child: ElevatedButton.icon(
        onPressed: _checkingWatchlist
            ? null
            : () => _showWatchlistSelector(content),
        icon: const Icon(Icons.add),
        label: Text(_getAddButtonText()),
      ),
    );
  }

  void _navigateToWatchlistItem() {
    if (_ownedItem == null) return;
    Get.back(); // Close sheet
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

  Future<void> _addToWatchlists(
    TmdbContent content,
    List<String> watchlistIds,
  ) async {
    final controller = ContentSearchController.to;
    bool success = false;

    if (content is TmdbMovie) {
      success = await controller.addMovieToWatchlists(content, watchlistIds);
    } else if (content is TmdbTvShow) {
      success = await controller.addTvShowToWatchlists(content, watchlistIds);
    }

    if (success) {
      // Re-check watchlist status to update UI (fetches _ownedItem and counts)
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

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return Colors.green;
    if (rating >= 5.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTrailerButton() {
    return Obx(() {
      final controller = ContentSearchController.to;
      final isLoading = controller.isLoadingVideos;
      final trailer = controller.bestTrailer;

      if (isLoading) {
        return const Padding(
          padding: EdgeInsets.only(bottom: ESizes.lg),
          child: SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }

      if (trailer == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: ESizes.lg),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openTrailer(trailer),
            icon: const Icon(Icons.play_circle_outline, color: EColors.accent),
            label: const Text(
              EText.watchTrailer,
              style: TextStyle(color: EColors.accent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: EColors.accent),
              padding: const EdgeInsets.symmetric(vertical: ESizes.md),
            ),
          ),
        ),
      );
    });
  }

  void _openTrailer(TmdbVideo trailer) {
    TrailerPlayerDialog.show(context, trailer);
  }

  Widget _buildWhereToWatch() {
    return Obx(() {
      final controller = ContentSearchController.to;
      final isLoading = controller.isLoadingProviders;
      final providers = controller.watchProviders;

      if (isLoading) {
        return const Padding(
          padding: EdgeInsets.only(top: ESizes.lg),
          child: SizedBox(
            height: 60,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }

      if (providers == null || !providers.hasAnyProvider) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: ESizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              EText.whereToWatch,
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.w600,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            // Streaming providers
            if (providers.hasStreaming) ...[
              _buildProviderRow(EText.stream, providers.flatrate),
              const SizedBox(height: ESizes.sm),
            ],
            // Rent providers
            if (providers.hasRent) ...[
              _buildProviderRow(EText.rent, providers.rent),
              const SizedBox(height: ESizes.sm),
            ],
            // Buy providers
            if (providers.hasBuy) ...[
              _buildProviderRow(EText.buy, providers.buy),
              const SizedBox(height: ESizes.sm),
            ],
            // JustWatch link
            if (providers.link != null)
              GestureDetector(
                onTap: () => _openJustWatch(providers.link!),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: EColors.primary,
                    ),
                    const SizedBox(width: ESizes.xs),
                    const Text(
                      EText.checkAvailability,
                      style: TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: ESizes.xs),
            const Text(
              EText.poweredByJustWatch,
              style: TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProviderRow(String label, List<TmdbWatchProvider> providers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              color: EColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: ESizes.sm),
        Expanded(
          child: Wrap(
            spacing: ESizes.sm,
            runSpacing: ESizes.sm,
            children: providers.take(6).map((provider) {
              return Tooltip(
                message: provider.providerName,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ESizes.radiusSm),
                  child: provider.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: provider.logoUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _buildProviderPlaceholder(),
                        )
                      : _buildProviderPlaceholder(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      color: EColors.surfaceLight,
      child: const Icon(Icons.tv, size: 18, color: EColors.textTertiary),
    );
  }

  Future<void> _openJustWatch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch JustWatch URL: $e');
      Get.snackbar(
        'Error',
        'Could not open link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }
}
