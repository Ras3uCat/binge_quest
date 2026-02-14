import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watchlist.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../watchlist/controllers/watchlist_controller.dart';

/// Bottom sheet for selecting multiple watchlists when adding content.
class WatchlistSelectorSheet extends StatefulWidget {
  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final Future<void> Function(List<String> watchlistIds) onConfirm;

  const WatchlistSelectorSheet({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.onConfirm,
  });

  /// Show the watchlist selector sheet.
  static Future<void> show({
    required BuildContext context,
    required int tmdbId,
    required MediaType mediaType,
    required String title,
    required Future<void> Function(List<String> watchlistIds) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatchlistSelectorSheet(
        tmdbId: tmdbId,
        mediaType: mediaType,
        title: title,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<WatchlistSelectorSheet> createState() => _WatchlistSelectorSheetState();
}

class _WatchlistSelectorSheetState extends State<WatchlistSelectorSheet> {
  List<Watchlist> _watchlists = [];
  Set<String> _existingWatchlistIds = {};
  Set<String> _selectedWatchlistIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load watchlists and check which ones already have this item
      final watchlists = await WatchlistRepository.getWatchlists();
      final existingIds = await WatchlistRepository.getWatchlistsContainingItem(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
      );

      // Pre-select the current watchlist if item isn't in any watchlist yet
      final currentWatchlistId = WatchlistController.to.currentWatchlist?.id;
      final initialSelection = existingIds.isEmpty && currentWatchlistId != null
          ? {currentWatchlistId}
          : <String>{};

      if (mounted) {
        setState(() {
          _watchlists = watchlists;
          _existingWatchlistIds = existingIds;
          _selectedWatchlistIds = initialSelection;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Error',
          'Failed to load watchlists',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: EColors.error,
          colorText: EColors.textOnPrimary,
        );
      }
    }
  }

  void _toggleWatchlist(String watchlistId) {
    // Can't toggle if already exists in this watchlist
    if (_existingWatchlistIds.contains(watchlistId)) return;

    setState(() {
      if (_selectedWatchlistIds.contains(watchlistId)) {
        _selectedWatchlistIds.remove(watchlistId);
      } else {
        _selectedWatchlistIds.add(watchlistId);
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (_selectedWatchlistIds.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onConfirm(_selectedWatchlistIds.toList());
      // Close sheet after successful add
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Only reset submitting state on error (don't close sheet)
      if (mounted) {
        setState(() => _isSubmitting = false);
        Get.snackbar(
          'Error',
          'Failed to add to watchlists',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: EColors.error,
          colorText: EColors.textOnPrimary,
        );
      }
    }
  }

  int get _newSelectionsCount => _selectedWatchlistIds.length;

  bool get _allAlreadyAdded =>
      _watchlists.isNotEmpty &&
      _existingWatchlistIds.length == _watchlists.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: ESizes.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(ESizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Watchlists',
                  style: TextStyle(
                    fontSize: ESizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: EColors.textPrimary,
                  ),
                ),
                const SizedBox(height: ESizes.xs),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: ESizes.fontMd,
                    color: EColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: EColors.border),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(ESizes.xxl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildWatchlistList(),
          ),
          // Footer with confirm button
          if (!_isLoading) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildWatchlistList() {
    if (_watchlists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(ESizes.xl),
        child: Text(
          'No watchlists found',
          style: TextStyle(color: EColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
      itemCount: _watchlists.length,
      itemBuilder: (context, index) {
        final watchlist = _watchlists[index];
        final isExisting = _existingWatchlistIds.contains(watchlist.id);
        final isSelected = _selectedWatchlistIds.contains(watchlist.id);

        return _buildWatchlistTile(watchlist, isExisting, isSelected);
      },
    );
  }

  Widget _buildWatchlistTile(
    Watchlist watchlist,
    bool isExisting,
    bool isSelected,
  ) {
    return ListTile(
      onTap: isExisting ? null : () => _toggleWatchlist(watchlist.id),
      leading: _buildCheckbox(isExisting, isSelected),
      title: Row(
        children: [
          Expanded(
            child: Text(
              watchlist.name,
              style: TextStyle(
                color: isExisting ? EColors.textTertiary : EColors.textPrimary,
              ),
            ),
          ),
          if (watchlist.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: EColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: const Text(
                'Default',
                style: TextStyle(
                  fontSize: ESizes.fontXs,
                  color: EColors.primary,
                ),
              ),
            ),
        ],
      ),
      subtitle: isExisting
          ? const Text(
              'Already added',
              style: TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.success,
              ),
            )
          : null,
    );
  }

  Widget _buildCheckbox(bool isExisting, bool isSelected) {
    if (isExisting) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: EColors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
          border: Border.all(color: EColors.success),
        ),
        child: const Icon(
          Icons.check,
          size: 16,
          color: EColors.success,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? EColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
        border: Border.all(
          color: isSelected ? EColors.primary : EColors.border,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: EColors.textOnPrimary,
            )
          : null,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: ESizes.buttonHeightLg,
          child: ElevatedButton(
            onPressed: _isSubmitting || (_newSelectionsCount == 0 && !_allAlreadyAdded)
                ? null
                : _handleConfirm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        EColors.textOnPrimary,
                      ),
                    ),
                  )
                : Text(_getButtonText()),
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_allAlreadyAdded) {
      return 'Already in all watchlists';
    }
    if (_newSelectionsCount == 0) {
      return 'Select a watchlist';
    }
    if (_newSelectionsCount == 1) {
      return 'Add to 1 Watchlist';
    }
    return 'Add to $_newSelectionsCount Watchlists';
  }
}
