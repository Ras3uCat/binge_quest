import 'package:flutter/material.dart' hide Badge;
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/services/share_service.dart';
import '../../../shared/models/badge.dart';

/// Celebration dialog shown when a user earns a new badge.
class BadgeUnlockDialog extends StatefulWidget {
  final Badge badge;

  const BadgeUnlockDialog({super.key, required this.badge});

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(ESizes.lg),
            decoration: BoxDecoration(
              color: EColors.surface,
              borderRadius: BorderRadius.circular(ESizes.radiusLg),
              border: Border.all(color: _getCategoryColor(), width: 2),
              boxShadow: [
                BoxShadow(
                  color: _getCategoryColor().withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: ESizes.md),
                _buildBadgeIcon(),
                const SizedBox(height: ESizes.md),
                _buildBadgeName(),
                const SizedBox(height: ESizes.sm),
                _buildDescription(),
                const SizedBox(height: ESizes.lg),
                _buildShareButton(),
                const SizedBox(height: ESizes.sm),
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.celebration, color: EColors.accent, size: ESizes.iconMd),
        const SizedBox(width: ESizes.sm),
        Text(
          'Badge Unlocked!',
          style: TextStyle(
            fontSize: ESizes.fontXl,
            fontWeight: FontWeight.bold,
            color: EColors.accent,
          ),
        ),
        const SizedBox(width: ESizes.sm),
        Icon(Icons.celebration, color: EColors.accent, size: ESizes.iconMd),
      ],
    );
  }

  Widget _buildBadgeIcon() {
    return Container(
      width: ESizes.badgeLg,
      height: ESizes.badgeLg,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getCategoryColor().withValues(alpha: 0.2),
        border: Border.all(color: _getCategoryColor(), width: 3),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(widget.badge.emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }

  Widget _buildBadgeName() {
    return Text(
      widget.badge.name,
      style: TextStyle(
        fontSize: ESizes.fontXxl,
        fontWeight: FontWeight.bold,
        color: EColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.badge.description,
      style: TextStyle(fontSize: ESizes.fontMd, color: EColors.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ShareService.to.shareBadgeUnlock(widget.badge),
        icon: const Icon(Icons.share, size: 20),
        label: const Text('Share Achievement'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _getCategoryColor(),
          side: BorderSide(color: _getCategoryColor()),
          padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCategoryColor(),
          foregroundColor: EColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
          ),
        ),
        child: const Text(
          'Awesome!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getCategoryColor() => switch (widget.badge.category) {
    BadgeCategory.completion => EColors.success,
    BadgeCategory.milestone => EColors.accent,
    BadgeCategory.genre => EColors.primary,
    BadgeCategory.streak => EColors.secondary,
    BadgeCategory.activity => EColors.warning,
  };
}
