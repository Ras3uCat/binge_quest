import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/e_colors.dart';
import '../models/content_cache.dart';

class StreamingBadge extends StatelessWidget {
  final List<StreamingProviderInfo>? streamingProviders;
  final bool showLogo;

  const StreamingBadge({
    super.key,
    this.streamingProviders,
    this.showLogo = true,
  });

  bool get hasStreaming =>
      streamingProviders != null && streamingProviders!.isNotEmpty;

  String? get _logoUrl {
    if (!hasStreaming) return null;
    final logoPath = streamingProviders!.first.logoPath;
    if (logoPath == null || logoPath.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w45$logoPath';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasStreaming) return const SizedBox.shrink();

    final logoUrl = showLogo ? _logoUrl : null;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EColors.surface.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(
                  Icons.play_circle_filled,
                  size: 18,
                  color: EColors.primary,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.play_circle_filled,
                  size: 18,
                  color: EColors.primary,
                ),
              ),
            )
          : const Icon(
              Icons.play_circle_filled,
              size: 18,
              color: EColors.primary,
            ),
    );
  }
}
