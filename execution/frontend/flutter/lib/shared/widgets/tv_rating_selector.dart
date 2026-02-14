import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';

class TvRatingSelector extends StatelessWidget {
  final int? rating;
  final ValueChanged<int> onRatingChanged;
  final bool enabled;
  final Color? iconColor;
  final Color? selectedColor;
  final double iconSize;

  const TvRatingSelector({
    super.key,
    this.rating,
    required this.onRatingChanged,
    this.enabled = true,
    this.iconColor,
    this.selectedColor,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = iconColor ?? EColors.textTertiary;
    final activeColor = selectedColor ?? EColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isSelected = rating != null && value <= rating!;

        return GestureDetector(
          onTap: enabled ? () => onRatingChanged(value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.live_tv,
              size: iconSize,
              color: isSelected ? activeColor : unselectedColor,
            ),
          ),
        );
      }),
    );
  }
}
