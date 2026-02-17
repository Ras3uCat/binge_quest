import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/friend_controller.dart';

/// Bottom sheet prompting the user to claim a username.
/// Shown on app open if the user hasn't set one yet.
class UsernameClaimSheet extends StatefulWidget {
  const UsernameClaimSheet({super.key});

  /// Show the sheet as a modal bottom sheet.
  static Future<void> show() async {
    await Get.bottomSheet(
      const UsernameClaimSheet(),
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<UsernameClaimSheet> createState() => _UsernameClaimSheetState();
}

class _UsernameClaimSheetState extends State<UsernameClaimSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isChecking = false;
  bool _isSaving = false;
  bool? _isAvailable;
  Timer? _debounce;

  static final _usernameRegex = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final lower = value.toLowerCase();
    setState(() => _isAvailable = null);

    if (!_usernameRegex.hasMatch(lower)) return;

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isChecking = true);
      try {
        final available =
            await FriendController.to.isUsernameAvailable(lower);
        if (mounted && _controller.text.toLowerCase() == lower) {
          setState(() {
            _isAvailable = available;
            _isChecking = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isChecking = false);
      }
    });
  }

  Future<void> _claim() async {
    if (!_formKey.currentState!.validate() || _isAvailable != true) return;
    setState(() => _isSaving = true);
    final success =
        await FriendController.to.setUsername(_controller.text.trim());
    if (success && mounted) {
      Get.back();
      Get.snackbar('Username Set', '@${_controller.text.trim()} is yours!');
    } else if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    final lower = value.toLowerCase();
    if (lower.length < 3) return 'At least 3 characters';
    if (lower.length > 20) return 'Max 20 characters';
    if (!_usernameRegex.hasMatch(lower)) {
      return 'Lowercase letters, numbers, underscores only. Must start with a letter.';
    }
    if (_isAvailable == false) return 'Username is taken';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.lg)),
      ),
      padding: EdgeInsets.only(
        left: ESizes.xl,
        right: ESizes.xl,
        top: ESizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ESizes.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ESizes.lg),
            const Text(
              'Claim Your Username',
              style: TextStyle(
                fontSize: ESizes.fontXl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.xs),
            const Text(
              'Pick a unique username to find and connect with friends.',
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESizes.lg),
            TextFormField(
              controller: _controller,
              validator: _validate,
              onChanged: _onChanged,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(color: EColors.textPrimary),
              decoration: InputDecoration(
                prefixText: '@ ',
                prefixStyle: TextStyle(
                  color: EColors.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'username',
                hintStyle: const TextStyle(color: EColors.textTertiary),
                filled: true,
                fillColor: EColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.md),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _buildSuffix(),
              ),
            ),
            const SizedBox(height: ESizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isAvailable == true && !_isSaving) ? _claim : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ESizes.md),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: EColors.textPrimary,
                        ),
                      )
                    : const Text('Claim Username'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSuffix() {
    if (_isChecking) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_isAvailable == true) {
      return const Icon(Icons.check_circle, color: EColors.success);
    }
    if (_isAvailable == false) {
      return const Icon(Icons.cancel, color: EColors.error);
    }
    return null;
  }
}
