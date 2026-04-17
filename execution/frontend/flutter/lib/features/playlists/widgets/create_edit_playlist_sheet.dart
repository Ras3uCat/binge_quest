import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist.dart';

class CreateEditPlaylistSheet {
  CreateEditPlaylistSheet._();

  static void show({Playlist? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final isPublic = (existing?.isPublic ?? true).obs;
    final isRanked = (existing?.isRanked ?? false).obs;
    final isSaving = false.obs;

    Get.bottomSheet(
      Builder(
        builder: (context) {
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(ESizes.lg, ESizes.lg, ESizes.lg, ESizes.lg + bottomInset),
            decoration: const BoxDecoration(
              color: EColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(),
                const SizedBox(height: ESizes.md),
                _buildTitleRow(existing),
                const SizedBox(height: ESizes.lg),
                _buildNameField(nameCtrl),
                const SizedBox(height: ESizes.md),
                _buildDescField(descCtrl),
                const SizedBox(height: ESizes.sm),
                _buildPublicToggle(isPublic),
                _buildRankedToggle(isRanked),
                const SizedBox(height: ESizes.lg),
                _buildSaveButton(
                  existing: existing,
                  nameCtrl: nameCtrl,
                  descCtrl: descCtrl,
                  isPublic: isPublic,
                  isRanked: isRanked,
                  isSaving: isSaving,
                ),
                const SizedBox(height: ESizes.sm),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: EColors.border,
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
    );
  }

  static Widget _buildTitleRow(Playlist? existing) {
    return Row(
      children: [
        Text(
          existing == null ? 'New Playlist' : 'Edit Playlist',
          style: const TextStyle(
            fontSize: ESizes.fontXl,
            fontWeight: FontWeight.bold,
            color: EColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.close, color: EColors.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  static Widget _buildNameField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: EColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: const TextStyle(color: EColors.textSecondary),
        filled: true,
        fillColor: EColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: const BorderSide(color: EColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: const BorderSide(color: EColors.border),
        ),
      ),
    );
  }

  static Widget _buildDescField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: EColors.textPrimary),
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        labelStyle: const TextStyle(color: EColors.textSecondary),
        filled: true,
        fillColor: EColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: const BorderSide(color: EColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: const BorderSide(color: EColors.border),
        ),
      ),
    );
  }

  static Widget _buildPublicToggle(RxBool isPublic) {
    return Obx(
      () => SwitchListTile(
        value: isPublic.value,
        onChanged: (v) => isPublic.value = v,
        title: const Text('Public', style: TextStyle(color: EColors.textPrimary)),
        subtitle: Text(
          isPublic.value ? 'Anyone can view this playlist' : 'Only you can see this',
          style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
        ),
        activeColor: EColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  static Widget _buildRankedToggle(RxBool isRanked) {
    return Obx(
      () => SwitchListTile(
        value: isRanked.value,
        onChanged: (v) => isRanked.value = v,
        title: const Text('Ranked', style: TextStyle(color: EColors.textPrimary)),
        subtitle: Text(
          isRanked.value ? 'Items show ranking numbers' : 'Items have no rank display',
          style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
        ),
        activeColor: EColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  static Widget _buildSaveButton({
    required Playlist? existing,
    required TextEditingController nameCtrl,
    required TextEditingController descCtrl,
    required RxBool isPublic,
    required RxBool isRanked,
    required RxBool isSaving,
  }) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: ESizes.buttonHeightMd,
        child: FilledButton(
          onPressed: isSaving.value
              ? null
              : () => _onSave(
                  existing: existing,
                  nameCtrl: nameCtrl,
                  descCtrl: descCtrl,
                  isPublic: isPublic,
                  isRanked: isRanked,
                  isSaving: isSaving,
                ),
          child: isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: EColors.textOnPrimary),
                )
              : Text(existing == null ? 'Create' : 'Save'),
        ),
      ),
    );
  }

  static Future<void> _onSave({
    required Playlist? existing,
    required TextEditingController nameCtrl,
    required TextEditingController descCtrl,
    required RxBool isPublic,
    required RxBool isRanked,
    required RxBool isSaving,
  }) async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Name required',
        'Please enter a playlist name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
      return;
    }

    isSaving.value = true;
    final ctrl = PlaylistController.to;

    if (existing == null) {
      await ctrl.createPlaylist(
        name: name,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        isPublic: isPublic.value,
        isRanked: isRanked.value,
      );
    } else {
      await ctrl.updatePlaylist(
        id: existing.id,
        name: name,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        isPublic: isPublic.value,
        isRanked: isRanked.value,
      );
    }

    isSaving.value = false;
    Get.back();
  }
}
