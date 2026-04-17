import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../social/controllers/watch_party_controller.dart';
import '../../social/screens/watch_party_screen.dart';

/// Tappable badge shown on item detail when the user has one or more
/// watch parties for this content. Single party → navigates directly.
/// Multiple parties → shows a picker bottom sheet.
class WatchPartyBadge extends StatelessWidget {
  final WatchlistItem item;

  const WatchPartyBadge({super.key, required this.item});

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

  @override
  Widget build(BuildContext context) {
    final ctrl = _ensurePartyController();
    return Obx(() {
      final matches = ctrl.activeParties
          .where((p) => p.tmdbId == item.tmdbId && p.mediaType == item.mediaType.name)
          .toList();
      if (matches.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: ESizes.sm),
        child: GestureDetector(
          onTap: () {
            if (matches.length == 1) {
              final party = matches.first;
              Get.to(
                () => WatchPartyScreen(
                  partyId: party.id,
                  tmdbId: party.tmdbId,
                  mediaType: party.mediaType,
                  partyName: party.name,
                ),
              );
            } else {
              _showPartyPicker(matches);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            decoration: BoxDecoration(
              color: EColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups, color: EColors.primary, size: 18),
                const SizedBox(width: ESizes.xs),
                const Text(
                  'Watch Party',
                  style: TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (matches.length > 1) ...[
                  const SizedBox(width: ESizes.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: EColors.primary,
                      borderRadius: BorderRadius.circular(ESizes.radiusRound),
                    ),
                    child: Text(
                      '${matches.length}',
                      style: const TextStyle(
                        color: EColors.textOnPrimary,
                        fontSize: ESizes.fontXs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: ESizes.xs),
                const Icon(Icons.chevron_right, color: EColors.primary, size: 18),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showPartyPicker(List<WatchParty> parties) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: const BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a Watch Party',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            ...parties.map(
              (party) => ListTile(
                leading: const Icon(Icons.groups, color: EColors.primary),
                title: Text(party.name, style: const TextStyle(color: EColors.textPrimary)),
                subtitle: party.creatorUsername != null
                    ? Text(
                        '@${party.creatorUsername}',
                        style: const TextStyle(
                          color: EColors.textSecondary,
                          fontSize: ESizes.fontSm,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right, color: EColors.textSecondary),
                onTap: () {
                  Get.back();
                  Get.to(
                    () => WatchPartyScreen(
                      partyId: party.id,
                      tmdbId: party.tmdbId,
                      mediaType: party.mediaType,
                      partyName: party.name,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom + ESizes.xs),
          ],
        ),
      ),
    );
  }
}
