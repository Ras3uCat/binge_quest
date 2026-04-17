import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../shared/models/tmdb_watch_provider.dart';
import '../controllers/search_controller.dart';

class ContentWhereToWatch extends StatelessWidget {
  const ContentWhereToWatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ContentSearchController.to;
      if (controller.isLoadingProviders) {
        return const Padding(
          padding: EdgeInsets.only(top: ESizes.lg),
          child: SizedBox(
            height: 60,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }

      final providers = controller.watchProviders;
      if (providers == null || !providers.hasAnyProvider) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: ESizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  EText.whereToWatch,
                  style: TextStyle(
                    fontSize: ESizes.fontLg,
                    fontWeight: FontWeight.w600,
                    color: EColors.textPrimary,
                  ),
                ),
                if (providers.link != null)
                  GestureDetector(
                    onTap: () => _openJustWatch(providers.link!),
                    child: const Row(
                      children: [
                        Icon(Icons.open_in_new, size: 14, color: EColors.primary),
                        SizedBox(width: ESizes.xs),
                        Text(
                          EText.checkAvailability,
                          style: TextStyle(
                            fontSize: ESizes.fontSm,
                            color: EColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ESizes.sm),
            if (providers.hasStreaming) ...[
              _buildProviderRow(EText.stream, providers.flatrate, providers.link),
              const SizedBox(height: ESizes.sm),
            ],
            if (providers.hasRent) ...[
              _buildProviderRow(EText.rent, providers.rent, providers.link),
              const SizedBox(height: ESizes.sm),
            ],
            if (providers.hasBuy) ...[
              _buildProviderRow(EText.buy, providers.buy, providers.link),
              const SizedBox(height: ESizes.sm),
            ],
            const Text(
              EText.poweredByJustWatch,
              style: TextStyle(fontSize: ESizes.fontXs, color: EColors.textTertiary),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProviderRow(String label, List<TmdbWatchProvider> providers, String? link) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: ESizes.fontSm, color: EColors.textSecondary),
          ),
        ),
        const SizedBox(width: ESizes.sm),
        Expanded(
          child: Wrap(
            spacing: ESizes.sm,
            runSpacing: ESizes.sm,
            children: providers.take(6).map((provider) {
              final icon = ClipRRect(
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
                child: provider.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: provider.logoUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildProviderPlaceholder(),
                      )
                    : _buildProviderPlaceholder(),
              );
              return Tooltip(
                message: provider.providerName,
                child: link != null
                    ? GestureDetector(onTap: () => _openJustWatch(link), child: icon)
                    : icon,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      color: EColors.surfaceLight,
      child: const Icon(Icons.tv, size: 18, color: EColors.textTertiary),
    );
  }

  Future<void> _openJustWatch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch JustWatch URL: $e');
      Get.snackbar(
        'Error',
        'Could not open link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: EColors.textOnPrimary,
      );
    }
  }
}
