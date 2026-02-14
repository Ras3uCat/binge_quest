import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

/// Full-screen empty state with optional CTA.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;
  final bool compact;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.compact = false,
  });

  /// Empty watchlist preset
  factory EmptyStateWidget.watchlist({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.movie_filter_outlined,
      title: 'Your watchlist is empty',
      subtitle: 'Start adding movies and shows to track your progress',
      actionLabel: 'Browse Content',
      onAction: onAction,
    );
  }

  /// No search results preset
  factory EmptyStateWidget.noResults({String? query}) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: query != null
          ? 'No matches for "$query"'
          : 'Try a different search term',
    );
  }

  /// No badges preset
  factory EmptyStateWidget.noBadges({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.emoji_events_outlined,
      title: 'No badges yet',
      subtitle: 'Start watching to earn badges and achievements',
      actionLabel: 'Start Watching',
      onAction: onAction,
    );
  }

  /// No recommendations preset
  factory EmptyStateWidget.noRecommendations({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.lightbulb_outline_rounded,
      title: 'No recommendations yet',
      subtitle: 'Add some content to your watchlist to get started',
      actionLabel: 'Add Your First Title',
      onAction: onAction,
    );
  }

  /// Offline mode preset
  factory EmptyStateWidget.offline({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'You\'re offline',
      subtitle: 'Connect to the internet to see your content',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ESizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else
              _buildIconContainer(),
            const SizedBox(height: ESizes.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.w600,
                color: EColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: ESizes.sm),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: ESizes.fontMd,
                  color: EColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ESizes.xl),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.xl,
                    vertical: ESizes.sm,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: EColors.textTertiary,
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              fontWeight: FontWeight.w500,
              color: EColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: ESizes.xs),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: ESizes.md),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: EColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md,
                  vertical: ESizes.xs,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        color: EColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: EColors.border,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 48,
        color: EColors.textTertiary,
      ),
    );
  }
}
