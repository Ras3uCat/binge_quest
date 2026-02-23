import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';
import '../controllers/watch_party_controller.dart';
import '../screens/watch_party_screen.dart';

/// Watch Party sections for the Friends tab.
/// Renders two sub-sections: Pending Invites + Active Parties.
/// Relies on parent to provide horizontal padding (e.g. ListView padding).
class PartyListSection extends StatelessWidget {
  const PartyListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = WatchPartyController.to;
      final pending = ctrl.pendingParties;
      final active = ctrl.activeParties;

      if (pending.isEmpty && active.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isNotEmpty) ...[
            _sectionHeader('Watch Party Invites'),
            ...pending.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: _PendingPartyTile(party: p, ctrl: ctrl),
                )),
            const SizedBox(height: ESizes.sm),
          ],
          if (active.isNotEmpty) ...[
            _sectionHeader('Watch Parties'),
            ...active.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: _ActivePartyTile(party: p),
                )),
          ],
        ],
      );
    });
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
// Pending Party Tile
// ---------------------------------------------------------------------------
class _PendingPartyTile extends StatelessWidget {
  final WatchParty party;
  final WatchPartyController ctrl;

  const _PendingPartyTile({required this.party, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.md),
      ),
      child: Row(
        children: [
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
                const SizedBox(height: ESizes.xs),
                Text(
                  party.creatorUsername != null
                      ? '${party.creatorUsername} invited you'
                      : 'Invited you to watch together',
                  style: const TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSm,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              await ctrl.acceptInvite(party.id);
              await Get.to(
                () => WatchPartyScreen(
                  partyId: party.id,
                  tmdbId: party.tmdbId,
                  mediaType: party.mediaType,
                  partyName: party.name,
                ),
              );
            },
            child: const Text(
              'Accept',
              style: TextStyle(color: EColors.primary, fontSize: ESizes.fontSm),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => ctrl.declineInvite(party.id),
            child: const Text(
              'Decline',
              style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
            ),
          ),
        ],
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
