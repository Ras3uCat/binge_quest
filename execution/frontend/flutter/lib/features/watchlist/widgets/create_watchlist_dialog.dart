import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/watchlist.dart';
import '../controllers/watchlist_controller.dart';

class CreateWatchlistDialog extends StatefulWidget {
  final Watchlist? watchlist;

  const CreateWatchlistDialog({super.key, this.watchlist});

  @override
  State<CreateWatchlistDialog> createState() => _CreateWatchlistDialogState();
}

class _CreateWatchlistDialogState extends State<CreateWatchlistDialog> {
  late final TextEditingController _nameController;
  bool _isLoading = false;

  bool get isEditing => widget.watchlist != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.watchlist?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a watchlist name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await WatchlistController.to.updateWatchlist(
          id: widget.watchlist!.id,
          name: name,
        );
      } else {
        await WatchlistController.to.createWatchlist(name: name);
      }
      Get.back();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EColors.surface,
      title: Text(
        isEditing ? EText.editWatchlist : EText.createWatchlist,
        style: const TextStyle(color: EColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: EColors.textPrimary),
            decoration: InputDecoration(
              labelText: EText.watchlistName,
              labelStyle: const TextStyle(color: EColors.textSecondary),
              hintText: 'e.g., Movie Night, Weekend Binge',
              hintStyle: const TextStyle(color: EColors.textTertiary),
              filled: true,
              fillColor: EColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.radiusMd),
                borderSide: const BorderSide(color: EColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text(EText.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(EColors.textOnPrimary),
                  ),
                )
              : Text(isEditing ? EText.save : EText.createWatchlist),
        ),
      ],
    );
  }
}
