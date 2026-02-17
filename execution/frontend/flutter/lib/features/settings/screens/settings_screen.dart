import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../../../shared/models/notification_preferences.dart';
import '../../../shared/repositories/episode_backfill_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../social/controllers/friend_controller.dart';
import 'privacy_policy_screen.dart';
import 'streaming_services_screen.dart';
import 'terms_of_service_screen.dart';
import '../../../shared/widgets/mood_guide_sheet.dart';
import '../../../shared/widgets/queue_efficiency_guide_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [EColors.backgroundSecondary, EColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ESizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'Legal',
                        children: [
                          _buildSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            label: EText.privacyPolicy,
                            onTap: () =>
                                Get.to(() => const PrivacyPolicyScreen()),
                          ),
                          _buildSettingsTile(
                            icon: Icons.description_outlined,
                            label: EText.termsOfService,
                            onTap: () =>
                                Get.to(() => const TermsOfServiceScreen()),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.xl),
                      _buildSection(
                        title: 'About',
                        children: [
                          _buildSettingsTile(
                            icon: Icons.info_outlined,
                            label: EText.appVersion,
                            trailing: const Text(
                              '1.0.0',
                              style: TextStyle(
                                color: EColors.textSecondary,
                                fontSize: ESizes.fontMd,
                              ),
                            ),
                            showChevron: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.xl),
                      _buildSection(
                        title: 'Help',
                        children: [
                          _buildSettingsTile(
                            icon: Icons.help_outline,
                            label: 'Mood Guide',
                            onTap: () => MoodGuideSheet.show(),
                          ),
                          _buildSettingsTile(
                            icon: Icons.insights,
                            label: 'Queue Health Score',
                            onTap: () => QueueEfficiencyGuideSheet.show(),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.xl),
                      _buildNotificationSection(context),
                      const SizedBox(height: ESizes.xl),
                      _buildPrivacySection(),
                      const SizedBox(height: ESizes.xl),
                      _buildSection(
                        title: 'Data',
                        children: [
                          _buildSettingsTile(
                            icon: Icons.sync,
                            label: 'Sync Episode Metadata',
                            onTap: () => _runEpisodeBackfill(),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.xl),
                      _buildSection(
                        title: 'Developer',
                        children: [
                          _buildSettingsTile(
                            icon: Icons.notifications_active,
                            label: 'Send Test Notification',
                            onTap: () {
                              if (Get.isRegistered<NotificationController>()) {
                                Get.find<NotificationController>()
                                    .sendTestNotification();
                              } else {
                                Get.put(
                                  NotificationController(),
                                ).sendTestNotification();
                              }
                            },
                          ),
                          _buildSettingsTile(
                            icon: Icons.live_tv,
                            label: 'Check Streaming Changes',
                            onTap: () => _runStreamingCheck(),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.xl),
                      _buildSection(
                        title: 'Danger Zone',
                        titleColor: EColors.error,
                        children: [
                          _buildSettingsTile(
                            icon: Icons.delete_forever_outlined,
                            label: EText.deleteAccount,
                            iconColor: EColors.error,
                            labelColor: EColors.error,
                            onTap: () => _showDeleteAccountDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESizes.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          const Text(
            EText.settings,
            style: TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color titleColor = EColors.textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: ESizes.xs, bottom: ESizes.sm),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: ESizes.fontSm,
              fontWeight: FontWeight.w600,
              color: titleColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: EColors.surface,
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            border: Border.all(color: EColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, color: EColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevron = true,
    Color iconColor = EColors.textSecondary,
    Color labelColor = EColors.textPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ESizes.md),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: ESizes.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: ESizes.fontMd, color: labelColor),
                ),
              ),
              if (trailing != null) trailing,
              if (showChevron && onTap != null)
                Icon(Icons.chevron_right, color: EColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    EConfirmDialog.show(
      title: EText.deleteAccount,
      message: EText.deleteAccountWarning,
      confirmLabel: EText.delete,
      isDestructive: true,
      onConfirm: () => _confirmDeleteAccount(),
    );
  }

  void _confirmDeleteAccount() {
    Get.back(); // Close first dialog

    // Show second confirmation
    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          EText.areYouSure,
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: const Text(
          EText.deleteAccountFinal,
          style: TextStyle(color: EColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(EText.cancel),
          ),
          Obx(() {
            final isLoading = AuthController.to.isLoading;
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      await AuthController.to.deleteAccount();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: EColors.error),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EColors.textOnPrimary,
                      ),
                    )
                  : const Text(EText.deleteForever),
            );
          }),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _runEpisodeBackfill() async {
    final progressMessages = <String>[].obs;
    final isRunning = true.obs;

    Get.dialog(
      Obx(
        () => AlertDialog(
          backgroundColor: EColors.surface,
          title: Row(
            children: [
              if (isRunning.value)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EColors.primary,
                  ),
                )
              else
                const Icon(Icons.check_circle, color: EColors.success),
              const SizedBox(width: ESizes.sm),
              Text(
                isRunning.value ? 'Syncing Episodes...' : 'Sync Complete',
                style: const TextStyle(color: EColors.textPrimary),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: progressMessages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    progressMessages[index],
                    style: const TextStyle(
                      fontSize: ESizes.fontSm,
                      color: EColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            if (!isRunning.value)
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Done'),
              ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await EpisodeBackfillRepository.backfillAll(
        onProgress: (message) {
          progressMessages.add(message);
        },
      );
    } catch (e) {
      progressMessages.add('Error: $e');
    } finally {
      isRunning.value = false;
    }
  }

  void _runStreamingCheck() async {
    Get.snackbar(
      'Checking...',
      'Scanning watchlist for streaming changes',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'check-streaming-changes',
      );

      final data = response.data as Map<String, dynamic>?;
      final checked = data?['checked'] ?? 0;
      final changes = data?['changes_detected'] ?? 0;
      final notifs = data?['notifications_sent'] ?? 0;

      Get.snackbar(
        'Streaming Check Complete',
        'Checked: $checked items, Changes: $changes, Notifications: $notifs',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Streaming check failed: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: EColors.error.withValues(alpha: 0.1),
        colorText: EColors.error,
      );
    }
  }

  Widget _buildPrivacySection() {
    if (!Get.isRegistered<FriendController>()) {
      Get.put(FriendController());
    }
    final controller = Get.find<FriendController>();

    return _buildSection(
      title: 'Privacy',
      children: [
        Obx(
          () => _buildSwitchTile(
            label: 'Share Watching Activity',
            subtitle: 'Allow friends to see what you are watching',
            value: controller.shareWatchingActivity.value,
            onChanged: (val) => controller.toggleShareWatchingActivity(val),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
    }
    final controller = Get.find<NotificationController>();

    return _buildSection(
      title: 'Notifications',
      children: [
        Obx(() {
          final prefs = controller.preferences.value;
          if (prefs == null) {
            return const Padding(
              padding: EdgeInsets.all(ESizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            children: [
              _buildSwitchTile(
                label: 'Streaming Alerts',
                subtitle: 'Get notified when content is available to stream',
                value: prefs.streamingAlerts,
                onChanged: (val) => controller.updatePreferences(
                  prefs.copyWith(streamingAlerts: val),
                ),
              ),
              const Divider(height: 1, color: EColors.border),
              _buildSettingsTile(
                icon: Icons.live_tv,
                label: 'My Streaming Services',
                onTap: () => Get.to(() => const StreamingServicesScreen()),
              ),
              const Divider(height: 1, color: EColors.border),
              _buildSwitchTile(
                label: 'New Episodes',
                subtitle: 'Alerts for new episode releases',
                value: prefs.newEpisodes,
                onChanged: (val) => controller.updatePreferences(
                  prefs.copyWith(newEpisodes: val),
                ),
              ),
              const Divider(height: 1, color: EColors.border),
              _buildSwitchTile(
                label: 'Talent Releases',
                subtitle: 'New content from actors & directors you follow',
                value: prefs.talentReleases,
                onChanged: (val) => controller.updatePreferences(
                  prefs.copyWith(talentReleases: val),
                ),
              ),
              const Divider(height: 1, color: EColors.border),
              _buildSwitchTile(
                label: 'Features & Updates',
                value: prefs.marketing,
                onChanged: (val) => controller.updatePreferences(
                  prefs.copyWith(marketing: val),
                ),
              ),
              const Divider(height: 1, color: EColors.border),
              _buildQuietHoursTile(context, prefs, controller),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: ESizes.fontMd,
                    color: EColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: ESizes.fontXs,
                      color: EColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: EColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursTile(
    BuildContext context,
    NotificationPreferences prefs,
    NotificationController controller,
  ) {
    return _buildSettingsTile(
      icon: Icons.nightlight_round,
      label: 'Quiet Hours',
      showChevron: true,
      trailing: Text(
        prefs.quietHoursEnabled
            ? '${prefs.quietHoursStart} - ${prefs.quietHoursEnd}'
            : 'Off',
        style: const TextStyle(
          color: EColors.textSecondary,
          fontSize: ESizes.fontSm,
        ),
      ),
      onTap: () => _showQuietHoursDialog(context, prefs, controller),
    );
  }

  void _showQuietHoursDialog(
    BuildContext context,
    NotificationPreferences prefs,
    NotificationController controller,
  ) {
    final enabled = prefs.quietHoursEnabled.obs;
    final start = prefs.quietHoursStart.obs;
    final end = prefs.quietHoursEnd.obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: EColors.surface,
        title: const Text(
          'Quiet Hours',
          style: TextStyle(color: EColors.textPrimary),
        ),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Enable Quiet Hours',
                  style: TextStyle(color: EColors.textPrimary),
                ),
                value: enabled.value,
                onChanged: (val) => enabled.value = val,
                activeColor: EColors.primary,
              ),
              const SizedBox(height: ESizes.md),
              if (enabled.value) ...[
                _buildTimePickerRow(context, 'Start Time', start),
                const SizedBox(height: ESizes.sm),
                _buildTimePickerRow(context, 'End Time', end),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updatePreferences(
                prefs.copyWith(
                  quietHoursEnabled: enabled.value,
                  quietHoursStart: start.value,
                  quietHoursEnd: end.value,
                ),
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: EColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow(
    BuildContext context,
    String label,
    RxString timeObs,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: EColors.textSecondary)),
        TextButton(
          onPressed: () async {
            final parts = timeObs.value.split(':');
            final time = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: EColors.primary,
                      surface: EColors.surface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final h = picked.hour.toString().padLeft(2, '0');
              final m = picked.minute.toString().padLeft(2, '0');
              timeObs.value = '$h:$m';
            }
          },
          child: Text(
            timeObs.value,
            style: const TextStyle(
              fontSize: ESizes.fontLg,
              fontWeight: FontWeight.bold,
              color: EColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
