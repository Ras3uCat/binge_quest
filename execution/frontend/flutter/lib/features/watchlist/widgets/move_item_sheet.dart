import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/watchlist.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../controllers/watchlist_controller.dart';

class MoveItemSheet extends StatefulWidget {
  final WatchlistItem item;
  final String currentWatchlistId;
  final String currentWatchlistName;

  const MoveItemSheet({
    super.key,
    required this.item,
    required this.currentWatchlistId,
    required this.currentWatchlistName,
  });

  static Future<bool?> show({
    required BuildContext context,
    required WatchlistItem item,
    required String currentWatchlistId,
    required String currentWatchlistName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoveItemSheet(
        item: item,
        currentWatchlistId: currentWatchlistId,
        currentWatchlistName: currentWatchlistName,
      ),
    );
  }

  @override
  State<MoveItemSheet> createState() => _MoveItemSheetState();
}

class _MoveItemSheetState extends State<MoveItemSheet> {
  final _controller = WatchlistController.to;
  Set<String> _containingWatchlistIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContainingWatchlists();
  }

  Future<void> _loadContainingWatchlists() async {
    try {
      final ids = await WatchlistRepository.getWatchlistsContainingItem(
        tmdbId: widget.item.tmdbId,
        mediaType: widget.item.mediaType,
      );
      if (mounted) {
        setState(() {
          _containingWatchlistIds = ids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: ESizes.lg,
        left: ESizes.lg,
        right: ESizes.lg,
        bottom: ESizes.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EText.movingItem.replaceAll('%s', widget.item.title),
                      style: const TextStyle(
                        fontSize: ESizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: EColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: ESizes.xs),
                    Text(
                      EText.currentlyIn.replaceAll(
                        '%s',
                        widget.currentWatchlistName,
                      ),
                      style: const TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
                color: EColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: ESizes.lg),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(ESizes.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _controller.watchlists.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: EColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final watchlist = _controller.watchlists[index];
                  final isCurrent = watchlist.id == widget.currentWatchlistId;
                  final alreadyExists = _containingWatchlistIds.contains(
                    watchlist.id,
                  );
                  final isDisabled = isCurrent || alreadyExists;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: isDisabled ? null : () => _confirmMove(watchlist),
                    leading: Container(
                      padding: const EdgeInsets.all(ESizes.sm),
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? EColors.surfaceLight
                            : EColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                      ),
                      child: Icon(
                        watchlist.isDefault ? Icons.star : Icons.playlist_play,
                        color: isDisabled
                            ? EColors.textTertiary
                            : EColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      watchlist.name,
                      style: TextStyle(
                        color: isDisabled
                            ? EColors.textTertiary
                            : EColors.textPrimary,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: alreadyExists && !isCurrent
                        ? const Text(
                            EText.alreadyInWatchlist,
                            style: TextStyle(
                              color: EColors.error,
                              fontSize: ESizes.fontXs,
                            ),
                          )
                        : null,
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle,
                            color: EColors.success,
                            size: 20,
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: EColors.textTertiary,
                            size: 20,
                          ),
                  );
                },
              ),
            ),
          const SizedBox(height: ESizes.lg),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                EText.cancel,
                style: TextStyle(color: EColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmMove(Watchlist destination) {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          EText.moveConfirmTitle.replaceAll('%s', destination.name),
          style: const TextStyle(color: EColors.textPrimary),
        ),
        content: const Text(
          EText.moveConfirmDesc,
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(EText.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog
              _performMove(destination);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.textOnPrimary,
            ),
            child: const Text(EText.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _performMove(Watchlist destination) async {
    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final success = await _controller.moveItem(widget.item, destination.id);

    Get.back(); // Close loading indicator
    Get.back(result: success); // Close sheet with result

    if (success) {
      Get.snackbar(
        EText.moveItem,
        EText.moveSuccess.replaceAll('%s', destination.name),
        backgroundColor: EColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(ESizes.md),
      );
    } else {
      Get.snackbar(
        EText.moveItem,
        _controller.error ?? EText.errorGeneric,
        backgroundColor: EColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(ESizes.md),
      );
    }
  }
}
