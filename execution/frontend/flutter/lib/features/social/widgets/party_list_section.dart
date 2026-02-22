import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watch_party.dart';
import '../controllers/watch_party_controller.dart';
import '../screens/watch_party_screen.dart';

/// Widget that renders Watch Party sections inside the Social/Friends tab.
/// Renders two sub-sections: Pending Invites + Active Parties.
/// Uses Obx for reactive updates.
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
            ...pending.map((p) => _PendingPartyTile(party: p, ctrl: ctrl)),
            const SizedBox(height: ESizes.sm),
          ],
          if (active.isNotEmpty) ...[
            _sectionHeader('Watch Parties'),
            ...active.map((p) => _ActivePartyTile(party: p)),
          ],
        ],
      );
    });
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, ESizes.md, ESizes.md, ESizes.xs),
      child: Text(
        title,
        style: const TextStyle(
          color: EColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontSm,
          letterSpacing: 0.5,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.xs,
      ),
      tileColor: EColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      title: Text(
        party.name,
        style: const TextStyle(
          color: EColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontMd,
        ),
      ),
      subtitle: Text(
        party.creatorUsername != null
            ? '${party.creatorUsername} invited you to watch together'
            : 'Invited you to watch together',
        style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.xs,
      ),
      tileColor: EColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      leading: _buildLeading(),
      title: Text(
        party.name,
        style: const TextStyle(
          color: EColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontMd,
        ),
      ),
      subtitle: Text(
        party.mediaType == 'tv' ? 'TV Show' : 'Movie',
        style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
      ),
      trailing: const Icon(Icons.chevron_right, color: EColors.textTertiary),
      onTap: () => Get.to(
        () => WatchPartyScreen(
          partyId: party.id,
          tmdbId: party.tmdbId,
          mediaType: party.mediaType,
          partyName: party.name,
        ),
      ),
    );
  }

  Widget _buildLeading() {
    return Container(
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
    );
  }
}
