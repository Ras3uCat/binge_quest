import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../../watchlist/screens/item_detail_screen.dart';

class TimeBlockSheet extends StatefulWidget {
  const TimeBlockSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const TimeBlockSheet(),
      backgroundColor: EColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  State<TimeBlockSheet> createState() => _TimeBlockSheetState();
}

class _TimeBlockSheetState extends State<TimeBlockSheet> {
  int _selectedMinutes = 60;
  static const List<int> _presets = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final controller = WatchlistController.to;
    if (controller.hasTimeBlockFilter) {
      _selectedMinutes = controller.timeBlockMinutes!;
    }
    controller.setTimeBlock(_selectedMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const SizedBox(height: ESizes.md),
          _buildTimeSelector(),
          const SizedBox(height: ESizes.lg),
          Flexible(child: _buildResults()),
          const SizedBox(height: ESizes.lg),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: ESizes.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: EColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.lg, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESizes.sm),
            decoration: BoxDecoration(
              color: EColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ESizes.radiusMd),
            ),
            child: const Icon(Icons.timer, color: EColors.accent, size: 24),
          ),
          const SizedBox(width: ESizes.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I Have Time For...',
                  style: TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Find content that fits your schedule',
                  style: TextStyle(
                    fontSize: ESizes.fontSm,
                    color: EColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              WatchlistController.to.clearTimeBlock();
              Get.back();
            },
            icon: const Icon(Icons.close, color: EColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
      child: Column(
        children: [
          // Preset buttons
          Row(
            children: _presets.map((minutes) {
              final isSelected = _selectedMinutes == minutes;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: minutes != _presets.last ? ESizes.sm : 0,
                  ),
                  child: RepaintBoundary(
                    child: _TimePresetButton(
                      minutes: minutes,
                      isSelected: isSelected,
                      onTap: () => _setMinutes(minutes),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: ESizes.md),
          // Slider for custom time
          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: EColors.accent,
                  inactiveTrackColor: EColors.surfaceLight,
                  thumbColor: EColors.accent,
                  overlayColor: EColors.accent.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _selectedMinutes.toDouble(),
                  min: 15,
                  max: 180,
                  divisions: 33, // 5 minute increments
                  onChanged: (value) => _setMinutes(value.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '15m',
                    style: TextStyle(
                      fontSize: ESizes.fontXs,
                      color: EColors.textTertiary,
                    ),
                  ),
                  Text(
                    _formatMinutes(_selectedMinutes),
                    style: const TextStyle(
                      fontSize: ESizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: EColors.accent,
                    ),
                  ),
                  const Text(
                    '3h',
                    style: TextStyle(
                      fontSize: ESizes.fontXs,
                      color: EColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Obx(() {
      final controller = WatchlistController.to;
      final items = controller.timeBlockItems;
      final isLoading = controller.isLoadingItems;
      final isEmpty = items.isEmpty;

      // IndexedStack for consistent widget structure (prevents semantics errors)
      final stateIndex = isLoading ? 0 : (isEmpty ? 1 : 2);

      return IndexedStack(
        index: stateIndex,
        sizing: StackFit.expand,
        children: [
          // State 0: Loading
          const Center(
            child: CircularProgressIndicator(color: EColors.accent),
          ),
          // State 1: Empty
          _buildEmptyState(),
          // State 2: Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                child: Text(
                  '${items.length} item${items.length == 1 ? '' : 's'} you can finish',
                  style: const TextStyle(
                    fontSize: ESizes.fontMd,
                    fontWeight: FontWeight.w600,
                    color: EColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: ESizes.md),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildItemTile(items[index]),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: EColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: ESizes.md),
          const Text(
            'No content fits this time',
            style: TextStyle(
              fontSize: ESizes.fontLg,
              color: EColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          Text(
            'Try selecting a longer time or add more content',
            style: TextStyle(
              fontSize: ESizes.fontSm,
              color: EColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(WatchlistItem item) {
    // For movies: show remaining time
    // For TV shows: show remaining time for partially watched episode, or full episode time
    final displayTime = item.mediaType == MediaType.movie
        ? item.minutesRemaining ?? item.totalRuntimeMinutes
        : item.nextEpisodeRemaining ??
              item.nextEpisodeRuntime ??
              item.episodeRuntime ??
              45;

    // Show "left" if there's partial progress, otherwise "next" for TV shows
    final hasPartialProgress =
        item.nextEpisodeRemaining != null &&
        item.nextEpisodeRuntime != null &&
        item.nextEpisodeRemaining! < item.nextEpisodeRuntime!;
    final timeLabel = item.mediaType == MediaType.movie || hasPartialProgress
        ? ' left'
        : ' next';

    return GestureDetector(
      onTap: () {
        Get.back();
        Get.to(() => ItemDetailScreen(item: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: ESizes.sm),
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surfaceLight,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
              child: item.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: EImages.tmdbPoster(item.posterPath),
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 50,
                      height: 75,
                      color: EColors.surface,
                      child: const Icon(Icons.movie, size: 24),
                    ),
            ),
            const SizedBox(width: ESizes.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: ESizes.fontMd,
                      fontWeight: FontWeight.w600,
                      color: EColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: ESizes.xs),
                  Row(
                    children: [
                      Icon(
                        item.mediaType == MediaType.movie
                            ? Icons.movie
                            : Icons.tv,
                        size: 14,
                        color: EColors.textTertiary,
                      ),
                      const SizedBox(width: ESizes.xs),
                      Text(
                        item.mediaType == MediaType.movie ? 'Movie' : 'TV Show',
                        style: const TextStyle(
                          fontSize: ESizes.fontXs,
                          color: EColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.sm,
                vertical: ESizes.xs,
              ),
              decoration: BoxDecoration(
                color: EColors.accent,
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: Text(
                '${_formatMinutes(displayTime)}$timeLabel',
                style: const TextStyle(
                  fontSize: ESizes.fontSm,
                  fontWeight: FontWeight.bold,
                  color: EColors.textOnAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setMinutes(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
    });
    WatchlistController.to.setTimeBlock(minutes);
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}m';
    }
    return '${minutes}m';
  }
}

class _TimePresetButton extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimePresetButton({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: ESizes.md),
        decoration: BoxDecoration(
          color: isSelected ? EColors.accent : EColors.surfaceLight,
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          border: Border.all(
            color: isSelected ? EColors.accent : EColors.border,
          ),
        ),
        child: Center(
          child: Text(
            _formatMinutes(minutes),
            style: TextStyle(
              fontSize: ESizes.fontMd,
              fontWeight: FontWeight.w600,
              color: isSelected ? EColors.textOnAccent : EColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}m';
    }
    return '${minutes}m';
  }
}
