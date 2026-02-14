import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/streaming_provider.dart';
import '../controllers/streaming_preferences_controller.dart';

class StreamingServicesScreen extends StatelessWidget {
  const StreamingServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StreamingPreferencesController>()) {
      Get.put(StreamingPreferencesController());
    }
    final controller = Get.find<StreamingPreferencesController>();

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
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.all(ESizes.lg),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: ESizes.md),
                        child: Text(
                          'Select the streaming services you subscribe to. '
                          "You'll get notified when watchlist items become "
                          'available on these platforms.',
                          style: TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontSm,
                          ),
                        ),
                      ),
                      _buildProviderGrid(controller),
                      const SizedBox(height: ESizes.xl),
                      _buildRentBuyToggle(controller),
                    ],
                  );
                }),
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
            'Streaming Services',
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

  Widget _buildProviderGrid(StreamingPreferencesController controller) {
    return Container(
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < StreamingProviders.all.length; i++) ...[
            _buildProviderTile(
              provider: StreamingProviders.all[i],
              controller: controller,
            ),
            if (i < StreamingProviders.all.length - 1)
              const Divider(height: 1, color: EColors.border),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderTile({
    required StreamingProvider provider,
    required StreamingPreferencesController controller,
  }) {
    return Obx(() {
      final isSelected = controller.selectedProviderIds.contains(provider.id);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.toggleProvider(provider),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ESizes.md,
              vertical: ESizes.sm,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: provider.logoUrl,
                    width: 40,
                    height: 40,
                    placeholder: (_, __) => Container(
                      width: 40,
                      height: 40,
                      color: EColors.surface,
                      child: const Icon(
                        Icons.tv,
                        color: EColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: EColors.surface,
                      child: const Icon(
                        Icons.tv,
                        color: EColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ESizes.md),
                Expanded(
                  child: Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: ESizes.fontMd,
                      color: EColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: isSelected,
                  onChanged: (_) => controller.toggleProvider(provider),
                  activeColor: EColors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRentBuyToggle(StreamingPreferencesController controller) {
    return Container(
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md,
            vertical: ESizes.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Include Rent/Buy',
                      style: TextStyle(
                        fontSize: ESizes.fontMd,
                        color: EColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Also alert when content is available to rent or buy',
                      style: TextStyle(
                        fontSize: ESizes.fontXs,
                        color: EColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: controller.includeRentBuy.value,
                onChanged: controller.toggleIncludeRentBuy,
                activeColor: EColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
