import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/watchlist.dart';
import '../../../shared/repositories/watchlist_repository.dart';

class PlaylistWatchlistSheet extends StatefulWidget {
  final Future<void> Function(String watchlistId) onConfirm;

  const PlaylistWatchlistSheet({super.key, required this.onConfirm});

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function(String watchlistId) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaylistWatchlistSheet(onConfirm: onConfirm),
    );
  }

  @override
  State<PlaylistWatchlistSheet> createState() => _PlaylistWatchlistSheetState();
}

class _PlaylistWatchlistSheetState extends State<PlaylistWatchlistSheet> {
  List<Watchlist> _watchlists = [];
  String? _selectedId;
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadWatchlists();
  }

  Future<void> _loadWatchlists() async {
    try {
      final result = await WatchlistRepository.getWatchlists();
      if (mounted) {
        setState(() {
          _watchlists = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirm() async {
    if (_selectedId == null || _isConfirming) return;
    setState(() => _isConfirming = true);
    await widget.onConfirm(_selectedId!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(color: EColors.border, height: 1),
          Flexible(child: _buildList()),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: ESizes.sm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: EColors.border,
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
      child: Row(
        children: [
          const Text(
            'Add All to Watchlist',
            style: TextStyle(
              fontSize: ESizes.fontXl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: EColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(ESizes.lg),
          child: CircularProgressIndicator(color: EColors.primary),
        ),
      );
    }

    if (_watchlists.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(ESizes.lg),
          child: Text('No watchlists found', style: TextStyle(color: EColors.textSecondary)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _watchlists.length,
      itemBuilder: (_, index) {
        final watchlist = _watchlists[index];
        return RadioListTile<String>(
          value: watchlist.id,
          groupValue: _selectedId,
          onChanged: (val) => setState(() => _selectedId = val),
          title: Text(watchlist.name, style: const TextStyle(color: EColors.textPrimary)),
          activeColor: EColors.primary,
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: SizedBox(
        width: double.infinity,
        height: ESizes.buttonHeightMd,
        child: FilledButton(
          onPressed: _selectedId == null || _isConfirming ? null : _confirm,
          child: _isConfirming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: EColors.textOnPrimary),
                )
              : const Text('Add All'),
        ),
      ),
    );
  }
}
