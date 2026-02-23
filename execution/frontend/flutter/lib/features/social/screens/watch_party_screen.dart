import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../controllers/watch_party_controller.dart';
import '../widgets/party_member_avatars.dart';
import '../widgets/party_screen_helpers.dart';

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

  @override
  void initState() {
    super.initState();
    _ctrl = WatchPartyController.to;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.openParty(widget.partyId);
    });
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
      return all.firstWhereOrNull((p) => p.id == widget.partyId)?.createdBy ==
          _currentUserId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openWatchlistItem() async {
    final mediaType =
        widget.mediaType == 'tv' ? MediaType.tv : MediaType.movie;
    final item = await WatchlistRepository.getItemByTmdbId(
      tmdbId: widget.tmdbId,
      mediaType: mediaType,
    );
    if (item != null) {
      await Get.to(() => ItemDetailScreen(item: item));
    } else {
      Get.snackbar(
          'Not in Watchlist', 'Add this title to your watchlist first');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Obx(() => PartyMemberAvatars(
                members: _ctrl.membersByParty[widget.partyId] ?? [],
                progress: _ctrl.progressByParty[widget.partyId] ?? [],
                mediaType: widget.mediaType,
              )),
          Expanded(
            child: widget.mediaType == 'tv'
                ? PartyTvBody(
                    ctrl: _ctrl,
                    partyId: widget.partyId,
                    partyName: widget.partyName,
                  )
                : PartyMovieBody(
                    ctrl: _ctrl,
                    partyId: widget.partyId,
                    partyName: widget.partyName,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: EColors.backgroundSecondary,
      title: Text(
        widget.partyName,
        style: const TextStyle(color: EColors.textPrimary),
      ),
      iconTheme: const IconThemeData(color: EColors.textPrimary),
      actions: [
        PopupMenuButton<String>(
          color: EColors.surface,
          icon: const Icon(Icons.more_vert, color: EColors.textSecondary),
          onSelected: _onMenuSelected,
          itemBuilder: (_) => [
            if (!_isCreator)
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave Party',
                    style: TextStyle(color: EColors.textPrimary)),
              ),
            if (_isCreator)
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Party',
                    style: TextStyle(color: EColors.error)),
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
        child: OutlinedButton(
          onPressed: _openWatchlistItem,
          style: OutlinedButton.styleFrom(
            foregroundColor: EColors.primary,
            side: const BorderSide(color: EColors.primary),
            padding: const EdgeInsets.symmetric(vertical: ESizes.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
          ),
          child: const Text('View in Watchlist'),
        ),
      ),
    );
  }

  void _onMenuSelected(String value) {
    if (value == 'leave') _confirmLeave();
    if (value == 'delete') _confirmDelete();
  }

  void _confirmLeave() {
    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: const Text('Leave Party',
          style: TextStyle(color: EColors.textPrimary)),
      content: const Text('Are you sure you want to leave?',
          style: TextStyle(color: EColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(color: EColors.textSecondary))),
        TextButton(
            onPressed: () {
              Get.back();
              _ctrl.leaveParty(widget.partyId);
            },
            child:
                const Text('Leave', style: TextStyle(color: EColors.error))),
      ],
    ));
  }

  void _confirmDelete() {
    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: const Text('Delete Party',
          style: TextStyle(color: EColors.textPrimary)),
      content: const Text('This will delete the party for all members.',
          style: TextStyle(color: EColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(color: EColors.textSecondary))),
        TextButton(
            onPressed: () {
              Get.back();
              _ctrl.deleteParty(widget.partyId);
            },
            child:
                const Text('Delete', style: TextStyle(color: EColors.error))),
      ],
    ));
  }
}
