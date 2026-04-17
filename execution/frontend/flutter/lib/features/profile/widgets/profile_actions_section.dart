import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../controllers/profile_controller.dart';

class ProfileActionsSection extends StatelessWidget {
  const ProfileActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.logout,
          label: EText.signOut,
          onTap: _confirmSignOut,
          isDestructive: true,
        ),
      ],
    );
  }

  void _confirmSignOut() {
    EConfirmDialog.show(
      title: EText.signOut,
      message: EText.signOutConfirm,
      confirmLabel: EText.signOut,
      isDestructive: true,
      onConfirm: () => ProfileController.to.signOut(),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? EColors.error : EColors.textPrimary;
    return Material(
      color: EColors.surface,
      borderRadius: BorderRadius.circular(ESizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive ? EColors.error.withValues(alpha: 0.3) : EColors.border,
            ),
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: ESizes.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: ESizes.fontMd,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
