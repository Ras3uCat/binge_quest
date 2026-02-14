import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';

/// Small icon badge indicating a watchlist is shared with co-owners.
class SharedListIndicator extends StatelessWidget {
  final double size;

  const SharedListIndicator({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Shared watchlist',
      child: Icon(
        Icons.group,
        size: size,
        color: EColors.tertiary,
      ),
    );
  }
}
