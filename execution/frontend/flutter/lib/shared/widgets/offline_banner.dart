import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';
import '../../core/constants/e_text.dart';
import '../../core/services/connectivity_service.dart';

/// Banner that displays when the app is offline.
/// Use this at the top of screens that require network connectivity.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure service is registered
    if (!Get.isRegistered<ConnectivityService>()) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final isOffline = ConnectivityService.to.isOffline;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isOffline ? null : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isOffline ? 1.0 : 0.0,
          child: isOffline
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.md,
                    vertical: ESizes.sm,
                  ),
                  color: EColors.error,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: EColors.textOnPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: ESizes.sm),
                      const Text(
                        EText.offline,
                        style: TextStyle(
                          color: EColors.textOnPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: ESizes.fontSm,
                        ),
                      ),
                      const SizedBox(width: ESizes.xs),
                      Text(
                        '- ${EText.offlineMessage}',
                        style: TextStyle(
                          color: EColors.textOnPrimary.withValues(alpha: 0.8),
                          fontSize: ESizes.fontSm,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }
}

/// Wrap screens with this to add offline awareness.
/// Shows the offline banner and optionally disables interactions.
class OfflineAwareScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool disableWhenOffline;

  const OfflineAwareScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.disableWhenOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: disableWhenOffline
                ? Obx(() {
                    final isOffline = Get.isRegistered<ConnectivityService>()
                        ? ConnectivityService.to.isOffline
                        : false;
                    return IgnorePointer(
                      ignoring: isOffline,
                      child: Opacity(
                        opacity: isOffline ? 0.5 : 1.0,
                        child: body,
                      ),
                    );
                  })
                : body,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
