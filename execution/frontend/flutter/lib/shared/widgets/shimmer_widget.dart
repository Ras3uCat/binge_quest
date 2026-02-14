import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

/// Base shimmer effect wrapper.
/// Wraps child widgets with a shimmer animation effect.
class ShimmerEffect extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: EColors.shimmerBase,
      highlightColor: EColors.shimmerHighlight,
      child: child,
    );
  }
}

/// Rectangular shimmer placeholder.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = ESizes.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: EColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Circular shimmer placeholder.
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: EColors.shimmerBase,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Text line shimmer placeholder.
class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: EColors.shimmerBase,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// Multiple text lines shimmer placeholder.
class ShimmerTextLines extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;
  final double? lastLineWidth;

  const ShimmerTextLines({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.spacing = 8,
    this.lastLineWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: ShimmerText(
            width: isLast && lastLineWidth != null
                ? lastLineWidth!
                : double.infinity,
            height: lineHeight,
          ),
        );
      }),
    );
  }
}
