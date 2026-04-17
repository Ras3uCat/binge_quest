import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/watchlist.dart';
import '../../../shared/models/watchlist_member.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/watchlist_member_controller.dart';
import 'create_watchlist_dialog.dart';

/// Horizontal scrollable pill row for selecting the active watchlist.
/// Long-press any pill to edit, set as default, or delete.
class WatchlistPillSelector extends StatelessWidget {
  const WatchlistPillSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = WatchlistController.to;

      if (ctrl.isLoading && ctrl.watchlists.isEmpty) {
        return const SizedBox(
          height: 36,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: ctrl.watchlists.map((w) {
            final isSelected = w.id == ctrl.currentWatchlist?.id;
            return Padding(
              padding: const EdgeInsets.only(right: ESizes.xs),
              child: GestureDetector(
                onTap: () => ctrl.selectWatchlist(w),
                onLongPress: () => _showWatchlistOptions(context, w),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? EColors.primary : EColors.surfaceLight,
                    borderRadius: BorderRadius.circular(ESizes.radiusRound),
                    border: Border.all(color: isSelected ? EColors.primary : EColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (w.isDefault)
                        Padding(
                          padding: const EdgeInsets.only(right: ESizes.xs),
                          child: Icon(
                            Icons.star,
                            size: 10,
                            color: isSelected ? EColors.textOnPrimary : EColors.accent,
                          ),
                        ),
                      Text(
                        w.name,
                        style: TextStyle(
                          color: isSelected ? EColors.textOnPrimary : EColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: ESizes.fontSm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  void _showWatchlistOptions(BuildContext context, Watchlist watchlist) {
    final ctrl = WatchlistController.to;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: const BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: EColors.textSecondary),
              title: const Text(EText.editWatchlist, style: TextStyle(color: EColors.textPrimary)),
              onTap: () {
                Get.back();
                Get.dialog(CreateWatchlistDialog(watchlist: watchlist));
              },
            ),
            if (!watchlist.isDefault)
              ListTile(
                leading: const Icon(Icons.star_outline, color: EColors.textSecondary),
                title: const Text('Set as Default', style: TextStyle(color: EColors.textPrimary)),
                onTap: () {
                  Get.back();
                  ctrl.updateWatchlist(id: watchlist.id, isDefault: true);
                },
              ),
            if (!watchlist.isDefault && ctrl.watchlists.length > 1)
              ListTile(
                leading: const Icon(Icons.delete, color: EColors.error),
                title: const Text(EText.deleteWatchlist, style: TextStyle(color: EColors.error)),
                onTap: () {
                  Get.back();
                  _confirmDeleteWatchlist(context, watchlist);
                },
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + ESizes.lg),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteWatchlist(BuildContext context, Watchlist watchlist) async {
    if (!Get.isRegistered<WatchlistMemberController>()) {
      _showSimpleDeleteDialog(watchlist);
      return;
    }
    final coCurators = await WatchlistMemberController.to.getAcceptedCoCurators(watchlist.id);
    if (coCurators.isEmpty) {
      _showSimpleDeleteDialog(watchlist);
    } else {
      _showTransferOrDeleteDialog(watchlist, coCurators);
    }
  }

  void _showSimpleDeleteDialog(Watchlist watchlist) {
    EConfirmDialog.show(
      title: EText.deleteWatchlist,
      message: EText.deleteWatchlistConfirm,
      confirmLabel: EText.delete,
      isDestructive: true,
      onConfirm: () => WatchlistController.to.deleteWatchlist(watchlist.id),
    );
  }

  void _showTransferOrDeleteDialog(Watchlist watchlist, List<WatchlistMember> coCurators) {
    final selected = coCurators.first.obs;

    Get.dialog(
      Obx(
        () => AlertDialog(
          backgroundColor: EColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ESizes.radiusLg)),
          title: const Text(
            'This list has co-curators',
            style: TextStyle(color: EColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transfer ownership so the list lives on, or delete for everyone.',
                style: TextStyle(color: EColors.textSecondary),
              ),
              const SizedBox(height: ESizes.md),
              const Text(
                'Transfer to:',
                style: TextStyle(color: EColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: ESizes.xs),
              ...coCurators.map(
                (member) => RadioListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    member.user?.displayLabel ?? 'Unknown',
                    style: const TextStyle(color: EColors.textPrimary),
                  ),
                  value: member,
                  groupValue: selected.value,
                  onChanged: (val) {
                    if (val != null) selected.value = val;
                  },
                  activeColor: EColors.primary,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(ESizes.lg, 0, ESizes.lg, ESizes.md),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text(EText.cancel)),
            ElevatedButton(
              onPressed: () {
                Get.back();
                WatchlistController.to.deleteWatchlist(watchlist.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ESizes.radiusSm)),
              ),
              child: const Text('Delete for All'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                final member = selected.value;
                await WatchlistMemberController.to.transferOwnership(
                  watchlistId: watchlist.id,
                  newOwnerId: member.userId,
                  newOwnerName: member.user?.displayLabel ?? 'co-curator',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ESizes.radiusSm)),
              ),
              child: const Text('Transfer & Leave'),
            ),
          ],
        ),
      ),
    );
  }
}
