import 'package:flutter/material.dart' hide Badge;
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/badge.dart';

/// Card widget displaying a single badge with earned/locked state.
class BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.badge,
    required this.isEarned,
    this.earnedAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ESizes.sm),
        decoration: BoxDecoration(
          color: isEarned ? EColors.surface : EColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(
            color: isEarned ? _getCategoryColor() : EColors.border,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadgeIcon(),
            const SizedBox(height: ESizes.xs),
            _buildBadgeName(),
            const SizedBox(height: ESizes.xs),
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEarned
            ? _getCategoryColor().withValues(alpha: 0.2)
            : EColors.backgroundSecondary,
        border: Border.all(
          color: isEarned ? _getCategoryColor() : EColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isEarned ? badge.emoji : '🔒',
          style: TextStyle(
            fontSize: 28,
            color: isEarned ? null : EColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeName() {
    return Text(
      badge.name,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isEarned ? EColors.textPrimary : EColors.textTertiary,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      badge.description,
      style: TextStyle(
        fontSize: 11,
        color: isEarned ? EColors.textSecondary : EColors.textTertiary,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Color _getCategoryColor() => switch (badge.category) {
        BadgeCategory.completion => EColors.success,
        BadgeCategory.milestone => EColors.accent,
        BadgeCategory.genre => EColors.primary,
        BadgeCategory.streak => EColors.secondary,
        BadgeCategory.activity => EColors.warning,
      };
}

/// Compact badge chip for display in lists.
class BadgeChip extends StatelessWidget {
  final Badge badge;
  final bool isEarned;

  const BadgeChip({
    super.key,
    required this.badge,
    this.isEarned = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.sm,
        vertical: ESizes.xs,
      ),
      decoration: BoxDecoration(
        color: isEarned ? EColors.surface : EColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
        border: Border.all(
          color: isEarned ? EColors.accent : EColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: ESizes.xs),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isEarned ? EColors.textPrimary : EColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
