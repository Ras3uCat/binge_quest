import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';
import '../../core/constants/e_text.dart';

/// Full-screen error state with retry functionality.
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool showIcon;
  final bool compact;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.subtitle,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = EText.tryAgain,
    this.showIcon = true,
    this.compact = false,
  });

  /// Network error preset
  factory ErrorStateWidget.network({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: EText.errorNetwork,
      subtitle: 'Please check your connection and try again',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Generic error preset
  factory ErrorStateWidget.generic({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: EText.errorGeneric,
      subtitle: 'Please try again later',
      onRetry: onRetry,
    );
  }

  /// Load failed preset
  factory ErrorStateWidget.loadFailed({
    required String itemName,
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'Failed to load $itemName',
      subtitle: 'Please try again',
      icon: Icons.refresh_rounded,
      onRetry: onRetry,
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
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(ESizes.lg),
                decoration: BoxDecoration(
                  color: EColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: EColors.error,
                ),
              ),
              const SizedBox(height: ESizes.lg),
            ],
            Text(
              title ?? EText.errorGeneric,
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
            if (onRetry != null) ...[
              const SizedBox(height: ESizes.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.lg,
                    vertical: ESizes.sm,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(
          color: EColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              size: 24,
              color: EColors.error,
            ),
            const SizedBox(width: ESizes.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? EText.errorGeneric,
                  style: const TextStyle(
                    fontSize: ESizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: EColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: ESizes.fontXs,
                      color: EColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: ESizes.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: EColors.error,
                padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
              ),
              child: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline error banner that can be dismissed.
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const InlineErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      padding: const EdgeInsets.all(ESizes.sm),
      decoration: BoxDecoration(
        color: EColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
        border: Border.all(
          color: EColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: EColors.error,
            size: 20,
          ),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textPrimary,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: EColors.error,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
              color: EColors.textSecondary,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }
}
