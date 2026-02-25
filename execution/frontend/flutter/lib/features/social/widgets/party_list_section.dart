import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';
import '../controllers/watch_party_controller.dart';
import '../screens/watch_party_screen.dart';
import '../../watchlist/screens/watchlist_screen.dart';

/// Watch Party sections for the Friends tab.
/// Renders two sub-sections: Pending Invites + Active Parties.
/// Relies on parent to provide horizontal padding (e.g. ListView padding).
class PartyListSection extends StatelessWidget {
  const PartyListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = WatchPartyController.to.activeParties;

      if (active.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Watch Parties'),
            _emptyState(),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Watch Parties'),
          ...active.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: ESizes.xs),
                child: _ActivePartyTile(party: p),
              )),
        ],
      );
    });
  }

  Widget _emptyState() {
    return GestureDetector(
      onTap: () => Get.to(() => const WatchlistScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.md),
          border: Border.all(color: EColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined,
                color: EColors.textTertiary, size: 28),
            const SizedBox(width: ESizes.md),
            const Expanded(
              child: Text(
                'No active watch parties\nCreate one from any watchlist item',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSm,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: EColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Text(
        title,
        style: const TextStyle(
          color: EColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontSm,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Party Tile
// ---------------------------------------------------------------------------
class _ActivePartyTile extends StatelessWidget {
  final WatchParty party;

  const _ActivePartyTile({required this.party});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => WatchPartyScreen(
          partyId: party.id,
          tmdbId: party.tmdbId,
          mediaType: party.mediaType,
          partyName: party.name,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.md),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: EColors.surfaceLight,
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: const Icon(
                Icons.groups,
                color: EColors.primary,
                size: ESizes.iconMd,
              ),
            ),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.name,
                    style: const TextStyle(
                      color: EColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: ESizes.fontMd,
                    ),
                  ),
                  Text(
                    party.mediaType == 'tv' ? 'TV Show' : 'Movie',
                    style: const TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSm,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: EColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
