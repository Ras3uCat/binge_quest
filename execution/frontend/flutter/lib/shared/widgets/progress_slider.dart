import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';

/// A draggable slider widget for tracking partial progress on movies/episodes.
class ProgressSlider extends StatefulWidget {
  /// Total runtime in minutes.
  final int totalMinutes;

  /// Current minutes watched.
  final int minutesWatched;

  /// Whether the item is fully watched.
  final bool isWatched;

  /// Callback when slider value changes (debounced).
  final ValueChanged<int> onChanged;

  /// Callback when slider interaction ends.
  final ValueChanged<int>? onChangeEnd;

  /// Whether to show the time labels.
  final bool showLabels;

  /// Whether the slider is compact (for episode list items).
  final bool compact;

  const ProgressSlider({
    super.key,
    required this.totalMinutes,
    required this.minutesWatched,
    required this.onChanged,
    this.isWatched = false,
    this.onChangeEnd,
    this.showLabels = true,
    this.compact = false,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  late double _currentValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.isWatched
        ? widget.totalMinutes.toDouble()
        : widget.minutesWatched.toDouble();
  }

  @override
  void didUpdateWidget(ProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update value if external state changes and not currently dragging
    if (!_isDragging) {
      _currentValue = widget.isWatched
          ? widget.totalMinutes.toDouble()
          : widget.minutesWatched.toDouble();
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  double get _percentage {
    if (widget.totalMinutes == 0) return 0;
    return (_currentValue / widget.totalMinutes * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalMinutes == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabels && !widget.compact) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMinutes(_currentValue.round()),
                style: TextStyle(
                  fontSize: widget.compact ? ESizes.fontXs : ESizes.fontSm,
                  color: EColors.textSecondary,
                ),
              ),
              Text(
                '${_percentage.round()}%',
                style: TextStyle(
                  fontSize: widget.compact ? ESizes.fontXs : ESizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: _percentage >= 100 ? EColors.success : EColors.primary,
                ),
              ),
              Text(
                _formatMinutes(widget.totalMinutes),
                style: TextStyle(
                  fontSize: widget.compact ? ESizes.fontXs : ESizes.fontSm,
                  color: EColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.xs),
        ],
        SizedBox(
          height: widget.compact ? 20 : 24,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: widget.compact ? 4 : 6,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: widget.compact ? 6 : 8,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: widget.compact ? 12 : 16,
              ),
              activeTrackColor: _percentage >= 100 ? EColors.success : EColors.primary,
              inactiveTrackColor: EColors.surfaceLight,
              thumbColor: _percentage >= 100 ? EColors.success : EColors.primary,
              overlayColor: (_percentage >= 100 ? EColors.success : EColors.primary)
                  .withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _currentValue.clamp(0, widget.totalMinutes.toDouble()),
              min: 0,
              max: widget.totalMinutes.toDouble(),
              onChanged: (value) {
                setState(() {
                  _isDragging = true;
                  _currentValue = value;
                });
                widget.onChanged(value.round());
              },
              onChangeEnd: (value) {
                setState(() {
                  _isDragging = false;
                });
                widget.onChangeEnd?.call(value.round());
              },
            ),
          ),
        ),
        if (widget.compact && widget.showLabels) ...[
          const SizedBox(height: 2),
          Text(
            '${_formatMinutes(_currentValue.round())} of ${_formatMinutes(widget.totalMinutes)}',
            style: const TextStyle(
              fontSize: ESizes.fontXs,
              color: EColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

/// A minimal progress bar (non-interactive) for display purposes.
class ProgressBar extends StatelessWidget {
  final int totalMinutes;
  final int minutesWatched;
  final bool isWatched;
  final double height;

  const ProgressBar({
    super.key,
    required this.totalMinutes,
    required this.minutesWatched,
    this.isWatched = false,
    this.height = 4,
  });

  double get _percentage {
    if (isWatched) return 100;
    if (totalMinutes == 0) return 0;
    return (minutesWatched / totalMinutes * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: EColors.surfaceLight,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _percentage / 100,
        child: Container(
          decoration: BoxDecoration(
            color: _percentage >= 100 ? EColors.success : EColors.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
