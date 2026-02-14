import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/badge.dart';
import '../../../shared/widgets/skeleton_loaders.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../controllers/badge_controller.dart';
import '../widgets/badge_card.dart';
import '../../search/screens/search_screen.dart';

/// Screen displaying all badges organized by category.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        backgroundColor: EColors.background,
        title: const Text('Badges'),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: ESizes.md),
                child: Center(
                  child: Text(
                    '${BadgeController.to.earnedCount}/${BadgeController.to.totalCount}',
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontMd,
                    ),
                  ),
                ),
              )),
        ],
      ),
      body: Obx(() {
        final controller = BadgeController.to;

        if (controller.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(ESizes.md),
            child: const BadgeGridSkeleton(count: 9, crossAxisCount: 3),
          );
        }

        if (controller.allBadges.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadBadges,
          color: EColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(ESizes.md),
            children: [
              _buildCategorySection(
                'Completion',
                'Complete movies and shows',
                BadgeCategory.completion,
                controller,
              ),
              _buildCategorySection(
                'Milestones',
                'Watch time achievements',
                BadgeCategory.milestone,
                controller,
              ),
              _buildCategorySection(
                'Genres',
                'Explore different genres',
                BadgeCategory.genre,
                controller,
              ),
              _buildCategorySection(
                'Activity',
                'Watching habits',
                BadgeCategory.streak,
                controller,
              ),
              const SizedBox(height: ESizes.xl),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget.noBadges(
      onAction: () => Get.to(() => const SearchScreen()),
    );
  }

  Widget _buildCategorySection(
    String title,
    String subtitle,
    BadgeCategory category,
    BadgeController controller,
  ) {
    final badges = controller.badgesByCategory[category] ?? [];
    if (badges.isEmpty) return const SizedBox.shrink();

    final earnedInCategory = badges
        .where((b) => controller.isBadgeEarned(b.id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ESizes.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ESizes.fontLg,
                        fontWeight: FontWeight.bold,
                        color: EColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.sm,
                  vertical: ESizes.xs,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ESizes.radiusSm),
                ),
                child: Text(
                  '$earnedInCategory/${badges.length}',
                  style: TextStyle(
                    fontSize: ESizes.fontSm,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(category),
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: ESizes.sm,
            mainAxisSpacing: ESizes.sm,
            childAspectRatio: 0.75,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final isEarned = controller.isBadgeEarned(badge.id);
            final earnedAt = controller.getEarnedDate(badge.id);

            return AnimatedListItem(
              index: index,
              child: BadgeCard(
                badge: badge,
                isEarned: isEarned,
                earnedAt: earnedAt,
                onTap: () => _showBadgeDetail(context, badge, isEarned, earnedAt),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    Badge badge,
    bool isEarned,
    DateTime? earnedAt,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _BadgeDetailDialog(
        badge: badge,
        isEarned: isEarned,
        earnedAt: earnedAt,
      ),
    );
  }

  Color _getCategoryColor(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.completion:
        return EColors.success;
      case BadgeCategory.milestone:
        return EColors.accent;
      case BadgeCategory.genre:
        return EColors.primary;
      case BadgeCategory.streak:
        return EColors.secondary;
      case BadgeCategory.activity:
        return EColors.warning;
    }
  }
}

class _BadgeDetailDialog extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final DateTime? earnedAt;

  const _BadgeDetailDialog({
    required this.badge,
    required this.isEarned,
    this.earnedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusLg),
          border: Border.all(
            color: isEarned ? _getCategoryColor() : EColors.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ESizes.badgeLg,
              height: ESizes.badgeLg,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? _getCategoryColor().withValues(alpha: 0.2)
                    : EColors.backgroundSecondary,
                border: Border.all(
                  color: isEarned ? _getCategoryColor() : EColors.border,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  isEarned ? badge.emoji : '🔒',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: ESizes.md),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: ESizes.fontXl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ESizes.md),
            if (isEarned && earnedAt != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md,
                  vertical: ESizes.sm,
                ),
                decoration: BoxDecoration(
                  color: EColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ESizes.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: EColors.success,
                      size: ESizes.iconSm,
                    ),
                    const SizedBox(width: ESizes.sm),
                    Text(
                      'Earned on ${_formatDate(earnedAt!)}',
                      style: TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md,
                  vertical: ESizes.sm,
                ),
                decoration: BoxDecoration(
                  color: EColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(ESizes.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: EColors.textTertiary,
                      size: ESizes.iconSm,
                    ),
                    const SizedBox(width: ESizes.sm),
                    Text(
                      'Not yet earned',
                      style: TextStyle(
                        fontSize: ESizes.fontSm,
                        color: EColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: ESizes.lg),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: EColors.textSecondary,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getCategoryColor() => switch (badge.category) {
        BadgeCategory.completion => EColors.success,
        BadgeCategory.milestone => EColors.accent,
        BadgeCategory.genre => EColors.primary,
        BadgeCategory.streak => EColors.secondary,
        BadgeCategory.activity => EColors.warning,
      };
}
