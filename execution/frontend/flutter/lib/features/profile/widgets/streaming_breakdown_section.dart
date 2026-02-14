import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/streaming_breakdown.dart';
import '../controllers/profile_controller.dart';

/// Displays streaming provider breakdown on user profile.
class StreamingBreakdownSection extends StatelessWidget {
  const StreamingBreakdownSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;

    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.subscriptions, color: EColors.primary, size: 20),
              SizedBox(width: ESizes.sm),
              Text(
                'Streaming Services',
                style: TextStyle(
                  fontSize: ESizes.fontLg,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.md),
          Obx(() {
            if (controller.isLoadingBreakdown) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(ESizes.md),
                  child: CircularProgressIndicator(color: EColors.primary),
                ),
              );
            }

            final breakdown = controller.streamingBreakdown;
            if (breakdown.isEmpty) {
              return const Text(
                'No streaming data available yet',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSm,
                ),
              );
            }

            final maxCount = breakdown.first.itemCount;
            return Column(
              children: breakdown
                  .take(6)
                  .map((item) => _buildProviderRow(item, maxCount))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProviderRow(StreamingBreakdownItem item, int maxCount) {
    final percentage = maxCount > 0 ? item.itemCount / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Row(
        children: [
          // Provider logo
          ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.radiusSm),
            child: item.logoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.logoUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: ESizes.sm),
          // Provider name
          Expanded(
            flex: 2,
            child: Text(
              item.providerName,
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Progress bar
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: EColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(EColors.primary),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          // Count
          SizedBox(
            width: 30,
            child: Text(
              '${item.itemCount}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                fontWeight: FontWeight.bold,
                color: EColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 32,
      height: 32,
      color: EColors.surfaceLight,
      child: const Icon(Icons.tv, size: 16, color: EColors.textTertiary),
    );
  }
}
