import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../search/controllers/search_controller.dart';
import '../controllers/playlist_detail_controller.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final String playlistId;

  const AddToPlaylistSheet({super.key, required this.playlistId});

  static void show({required String playlistId}) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(playlistId: playlistId),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  late final ContentSearchController _searchCtrl;
  final _textCtrl = TextEditingController();
  Timer? _debounce;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ContentSearchController>()) {
      _searchCtrl = Get.put(ContentSearchController());
    } else {
      _searchCtrl = ContentSearchController.to;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        _searchCtrl.search(query.trim());
      }
    });
  }

  Future<void> _addItem(TmdbSearchResult item) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);

    final ctrl = Get.find<PlaylistDetailController>(tag: widget.playlistId);
    final success = await ctrl.addItem(
      tmdbId: item.id,
      mediaType: item.mediaTypeString,
      title: item.title,
      posterPath: item.posterPath,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: EColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              _buildSearchField(),
              const Divider(color: EColors.border, height: 1),
              Expanded(child: _buildResults(scrollController)),
            ],
          ),
        );
      },
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
            'Add to Playlist',
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.sm),
      child: TextField(
        controller: _textCtrl,
        autofocus: true,
        style: const TextStyle(color: EColors.textPrimary),
        onChanged: _onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search movies & TV shows...',
          hintStyle: const TextStyle(color: EColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: EColors.textSecondary),
          filled: true,
          fillColor: EColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ScrollController scrollController) {
    return Obx(() {
      final results = _searchCtrl.searchResults
          .where((r) => r.mediaTypeString != 'person')
          .toList();

      if (_searchCtrl.isLoading) {
        return const Center(child: CircularProgressIndicator(color: EColors.primary));
      }

      if (results.isEmpty && _textCtrl.text.isNotEmpty) {
        return const Center(
          child: Text('No results found', style: TextStyle(color: EColors.textSecondary)),
        );
      }

      if (results.isEmpty) {
        return const Center(
          child: Text(
            'Search for movies or TV shows',
            style: TextStyle(color: EColors.textSecondary),
          ),
        );
      }

      return ListView.builder(
        controller: scrollController,
        itemCount: results.length,
        itemBuilder: (_, index) => _buildResultTile(results[index]),
      );
    });
  }

  Widget _buildResultTile(TmdbSearchResult item) {
    return ListTile(
      leading: item.posterPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.radiusXs),
              child: CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
                width: 40,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (ctx, url) =>
                    Container(width: 40, height: 60, color: EColors.surfaceLight),
                errorWidget: (ctx, url, err) =>
                    const Icon(Icons.movie, color: EColors.textTertiary),
              ),
            )
          : const Icon(Icons.movie, color: EColors.textTertiary),
      title: Text(
        item.title,
        style: const TextStyle(color: EColors.textPrimary, fontSize: ESizes.fontMd),
      ),
      subtitle: Text(
        item.mediaTypeString == 'tv' ? 'TV Show' : 'Movie',
        style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
      ),
      trailing: _isAdding
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: EColors.primary),
            )
          : const Icon(Icons.add_circle_outline, color: EColors.primary),
      onTap: () => _addItem(item),
    );
  }
}
