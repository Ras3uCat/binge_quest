import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../search/widgets/watchlist_selector_sheet.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../controllers/watch_party_controller.dart';
import '../widgets/party_member_avatars.dart';
import '../widgets/party_screen_helpers.dart';
import '../../../shared/widgets/watch_party_guide_sheet.dart';
import 'friend_list_screen.dart';

/// Full-screen view for a single Watch Party.
/// Shows member progress (TV: season tabs via PartyTvBody,
/// Movie: progress bars via PartyMovieBody).
/// Read-only — no progress writes from this screen.
class WatchPartyScreen extends StatefulWidget {
  final String partyId;
  final int tmdbId;
  final String mediaType;
  final String partyName;

  const WatchPartyScreen({
    super.key,
    required this.partyId,
    required this.tmdbId,
    required this.mediaType,
    required this.partyName,
  });

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  late final WatchPartyController _ctrl;
  bool _isInWatchlist = true; // optimistic default; updated async

  @override
  void initState() {
    super.initState();
    _ctrl = WatchPartyController.to;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.openParty(widget.partyId);
      _refreshWatchlistStatus();
    });
  }

  Future<void> _refreshWatchlistStatus() async {
    final mediaType = widget.mediaType == 'tv' ? MediaType.tv : MediaType.movie;
    final item = await WatchlistRepository.getItemByTmdbId(
      tmdbId: widget.tmdbId,
      mediaType: mediaType,
    );
    if (mounted) setState(() => _isInWatchlist = item != null);
  }

  @override
  void dispose() {
    _ctrl.closeParty();
    super.dispose();
  }

  String get _currentUserId => SupabaseService.currentUserId ?? '';

  bool get _isCreator {
    try {
      final all = [..._ctrl.activeParties, ..._ctrl.pendingParties];
      return all.firstWhereOrNull((p) => p.id == widget.partyId)?.createdBy == _currentUserId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openWatchlistItem() async {
    final mediaType = widget.mediaType == 'tv' ? MediaType.tv : MediaType.movie;

    final item = await WatchlistRepository.getItemByTmdbId(
      tmdbId: widget.tmdbId,
      mediaType: mediaType,
    );

    if (item != null) {
      await Get.to(() => ItemDetailScreen(item: item));
      return;
    }

    // Not in any watchlist — fetch title from content_cache then show picker.
    if (!mounted) return;
    final row = await SupabaseService.client
        .from('content_cache')
        .select('title')
        .eq('tmdb_id', widget.tmdbId)
        .eq('media_type', widget.mediaType)
        .maybeSingle();
    final contentTitle = (row?['title'] as String?) ?? widget.partyName;

    if (!mounted) return;
    await WatchlistSelectorSheet.show(
      context: context,
      tmdbId: widget.tmdbId,
      mediaType: mediaType,
      title: contentTitle,
      onConfirm: (watchlistIds) async {
        final items = await WatchlistRepository.addItemToMultipleWatchlists(
          watchlistIds: watchlistIds,
          tmdbId: widget.tmdbId,
          mediaType: mediaType,
        );

        // For TV shows, seed watch_progress rows from content_cache_episodes
        // (already populated by the party creator's add flow).
        if (mediaType == MediaType.tv && items.isNotEmpty) {
          final episodes = await SupabaseService.client
              .from('content_cache_episodes')
              .select('id')
              .eq('tmdb_id', widget.tmdbId);

          for (final item in items) {
            for (final ep in (episodes as List<dynamic>)) {
              await WatchlistRepository.createWatchProgress(
                watchlistItemId: item.id,
                episodeCacheId: ep['id'] as String,
                isBackfill: true,
              );
            }
          }
        }

        // Refresh the watchlist controller so item counts are up to date.
        try {
          await WatchlistController.to.refresh();
        } catch (_) {}
      },
    );

    // After the sheet closes, navigate to the item detail if it was added.
    if (!mounted) return;
    final addedItem = await WatchlistRepository.getItemByTmdbId(
      tmdbId: widget.tmdbId,
      mediaType: mediaType,
    );
    if (addedItem != null && mounted) {
      setState(() => _isInWatchlist = true);
      await Get.to(() => ItemDetailScreen(item: addedItem));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Obx(
            () => PartyMemberAvatars(
              members: _ctrl.membersByParty[widget.partyId] ?? [],
              progress: _ctrl.progressByParty[widget.partyId] ?? [],
              mediaType: widget.mediaType,
            ),
          ),
          Expanded(
            child: widget.mediaType == 'tv'
                ? PartyTvBody(ctrl: _ctrl, partyId: widget.partyId, partyName: widget.partyName)
                : PartyMovieBody(ctrl: _ctrl, partyId: widget.partyId, partyName: widget.partyName),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: EColors.backgroundSecondary,
      title: Text(widget.partyName, style: const TextStyle(color: EColors.textPrimary)),
      iconTheme: const IconThemeData(color: EColors.textPrimary),
      actions: [
        IconButton(
          icon: const Icon(Icons.group_outlined, color: EColors.textSecondary),
          iconSize: 20,
          tooltip: 'All Parties',
          onPressed: () => Get.to(() => const FriendListScreen()),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: EColors.textSecondary),
          iconSize: 20,
          onPressed: WatchPartyGuideSheet.show,
        ),
        PopupMenuButton<String>(
          color: EColors.surface,
          icon: const Icon(Icons.more_vert, color: EColors.textSecondary),
          onSelected: _onMenuSelected,
          itemBuilder: (_) => [
            if (!_isCreator)
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave Party', style: TextStyle(color: EColors.textPrimary)),
              ),
            if (_isCreator)
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Party', style: TextStyle(color: EColors.error)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ESizes.md),
        child: SizedBox(
          width: double.infinity,
          height: ESizes.buttonHeightLg,
          child: ElevatedButton.icon(
            onPressed: _openWatchlistItem,
            icon: Icon(_isInWatchlist ? Icons.visibility : Icons.add),
            label: Text(_isInWatchlist ? 'View in Watchlist' : 'Add to Watchlist'),
          ),
        ),
      ),
    );
  }

  void _onMenuSelected(String value) {
    if (value == 'leave') _confirmLeave();
    if (value == 'delete') _confirmDelete();
  }

  void _confirmLeave() {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text('Leave Party', style: TextStyle(color: EColors.textPrimary)),
        content: const Text(
          'Are you sure you want to leave?',
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: EColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _ctrl.leaveParty(widget.partyId);
            },
            child: const Text('Leave', style: TextStyle(color: EColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text('Delete Party', style: TextStyle(color: EColors.textPrimary)),
        content: const Text(
          'This will delete the party for all members.',
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: EColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _ctrl.deleteParty(widget.partyId);
            },
            child: const Text('Delete', style: TextStyle(color: EColors.error)),
          ),
        ],
      ),
    );
  }
}
