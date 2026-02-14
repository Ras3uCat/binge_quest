import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/watchlist_member_controller.dart';
import '../widgets/shared_list_indicator.dart';
import 'create_watchlist_dialog.dart';

class WatchlistSelectorWidget extends StatelessWidget {
  const WatchlistSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = WatchlistController.to;
      final watchlists = controller.watchlists;
      final current = controller.currentWatchlist;

      if (controller.isLoading) {
        return const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showWatchlistPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md,
                  vertical: ESizes.sm,
                ),
                decoration: BoxDecoration(
                  color: EColors.surface,
                  borderRadius: BorderRadius.circular(ESizes.radiusMd),
                  border: Border.all(color: EColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.playlist_play,
                      color: EColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: ESizes.sm),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              current?.name ?? 'Select Watchlist',
                              style: const TextStyle(
                                fontSize: ESizes.fontMd,
                                fontWeight: FontWeight.w500,
                                color: EColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (current != null &&
                              WatchlistMemberController.to
                                  .isShared(current.id)) ...[
                            const SizedBox(width: ESizes.xs),
                            const SharedListIndicator(size: 14),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: ESizes.sm),
                    Text(
                      '${watchlists.length}',
                      style: const TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: ESizes.xs),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: EColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          IconButton(
            onPressed: () => _showCreateWatchlistDialog(context),
            icon: const Icon(Icons.add_circle_outline),
            color: EColors.primary,
            tooltip: EText.createWatchlist,
          ),
        ],
      );
    });
  }

  void _showWatchlistPicker(BuildContext context) {
    final controller = WatchlistController.to;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(ESizes.lg),
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
                const Text(
                  EText.myWatchlists,
                  style: TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  color: EColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: ESizes.md),
            Obx(() {
              final watchlists = controller.watchlists;
              final current = controller.currentWatchlist;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: watchlists.length,
                itemBuilder: (context, index) {
                  final watchlist = watchlists[index];
                  final isSelected = watchlist.id == current?.id;

                  final isSharedList = WatchlistMemberController.to
                      .isShared(watchlist.id);
                  return ListTile(
                    onTap: () {
                      controller.selectWatchlist(watchlist);
                      Get.back();
                    },
                    leading: Icon(
                      watchlist.isDefault ? Icons.star : Icons.playlist_play,
                      color: isSelected
                          ? EColors.primary
                          : EColors.textSecondary,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            watchlist.name,
                            style: TextStyle(
                              color: isSelected
                                  ? EColors.primary
                                  : EColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSharedList) ...[
                          const SizedBox(width: ESizes.xs),
                          const SharedListIndicator(size: 14),
                        ],
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: EColors.primary)
                        : IconButton(
                            icon: const Icon(Icons.more_vert),
                            color: EColors.textTertiary,
                            onPressed: () =>
                                _showWatchlistOptions(context, watchlist),
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ESizes.radiusMd),
                    ),
                    selectedTileColor: EColors.primary.withValues(alpha: 0.1),
                    selected: isSelected,
                  );
                },
              );
            }),
            const SizedBox(height: ESizes.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  _showCreateWatchlistDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text(EText.createWatchlist),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWatchlistOptions(BuildContext context, watchlist) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: const BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ESizes.radiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: EColors.textSecondary),
              title: const Text(
                EText.editWatchlist,
                style: TextStyle(color: EColors.textPrimary),
              ),
              onTap: () {
                Get.back();
                Get.back();
                _showEditWatchlistDialog(context, watchlist);
              },
            ),
            if (!watchlist.isDefault)
              ListTile(
                leading: const Icon(
                  Icons.star_outline,
                  color: EColors.textSecondary,
                ),
                title: const Text(
                  'Set as Default',
                  style: TextStyle(color: EColors.textPrimary),
                ),
                onTap: () {
                  Get.back();
                  Get.back();
                  WatchlistController.to.updateWatchlist(
                    id: watchlist.id,
                    isDefault: true,
                  );
                },
              ),
            if (!watchlist.isDefault &&
                WatchlistController.to.watchlists.length > 1)
              ListTile(
                leading: const Icon(Icons.delete, color: EColors.error),
                title: const Text(
                  EText.deleteWatchlist,
                  style: TextStyle(color: EColors.error),
                ),
                onTap: () {
                  Get.back();
                  Get.back();
                  _confirmDeleteWatchlist(context, watchlist);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateWatchlistDialog(BuildContext context) {
    Get.dialog(const CreateWatchlistDialog());
  }

  void _showEditWatchlistDialog(BuildContext context, watchlist) {
    Get.dialog(CreateWatchlistDialog(watchlist: watchlist));
  }

  void _confirmDeleteWatchlist(BuildContext context, watchlist) {
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          EText.deleteWatchlist,
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: const Text(
          EText.deleteWatchlistConfirm,
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(EText.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              WatchlistController.to.deleteWatchlist(watchlist.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: EColors.error),
            child: const Text(EText.delete),
          ),
        ],
      ),
    );
  }
}
