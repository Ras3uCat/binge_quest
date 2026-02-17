import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

/// Standardized confirmation dialog used across the app.
///
/// Usage:
/// ```dart
/// EConfirmDialog.show(
///   title: 'Delete Watchlist',
///   message: 'Are you sure? This cannot be undone.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
///   onConfirm: () => controller.delete(),
/// );
/// ```
class EConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const EConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
  });

  /// Show the dialog via Get.dialog and return whether confirmed.
  static Future<bool> show({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) async {
    final result = await Get.dialog<bool>(
      EConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: EColors.textPrimary,
          fontSize: ESizes.fontLg,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: EColors.textSecondary,
          fontSize: ESizes.fontMd,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        ESizes.lg,
        0,
        ESizes.lg,
        ESizes.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: EColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back(result: true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDestructive ? EColors.error : EColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
