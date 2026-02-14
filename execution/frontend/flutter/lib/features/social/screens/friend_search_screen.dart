import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/user_profile.dart';
import '../controllers/friend_controller.dart';

/// Screen for searching users by email/name and sending friend requests.
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSending = false;

  FriendController get _friendCtrl => FriendController.to;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _friendCtrl.clearSearch();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // update clear button visibility
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _friendCtrl.searchUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        title: const Text('Find Friends'),
        backgroundColor: EColors.backgroundSecondary,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.md),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        autofocus: true,
        style: const TextStyle(color: EColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by email or name...',
          hintStyle: const TextStyle(color: EColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: EColors.textSecondary),
          filled: true,
          fillColor: EColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ESizes.md),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: EColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _friendCtrl.clearSearch();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Obx(() {
      if (_friendCtrl.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: EColors.primary),
        );
      }

      final results = _friendCtrl.searchResults;

      if (_searchController.text.length >= 2 && results.isEmpty) {
        return const Center(
          child: Text(
            'No users found',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontMd,
            ),
          ),
        );
      }

      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search,
                  size: 64, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: ESizes.md),
              const Text(
                'Search by email or name',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontMd,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md),
        itemCount: results.length,
        itemBuilder: (_, index) => Padding(
          padding: EdgeInsets.only(top: index > 0 ? ESizes.xs : 0),
          child: _buildUserTile(results[index]),
        ),
      );
    });
  }

  Widget _buildUserTile(UserProfile user) {
    final status = _friendCtrl.relationshipStatus(user.id);

    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: EColors.surfaceLight,
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, color: EColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      color: EColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.username != null || user.email != null)
                    Text(
                      user.username != null
                          ? '@${user.username}'
                          : user.email ?? '',
                      style: const TextStyle(
                        color: EColors.textSecondary,
                        fontSize: ESizes.fontSm,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: ESizes.sm),
            _buildActionButton(user, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(UserProfile user, String status) {
    switch (status) {
      case 'friends':
        return const Chip(
          label: Text('Friends', style: TextStyle(fontSize: 12)),
          backgroundColor: EColors.surfaceLight,
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      case 'pending_sent':
        return const Chip(
          label: Text('Pending', style: TextStyle(fontSize: 12)),
          backgroundColor: EColors.surfaceLight,
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      case 'pending_received':
        return TextButton(
          onPressed: () {
            final request = _friendCtrl.pendingReceived.firstWhereOrNull(
              (f) => f.requesterId == user.id,
            );
            if (request != null) _friendCtrl.acceptRequest(request);
          },
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Accept'),
        );
      default:
        return ElevatedButton(
          onPressed: _isSending
              ? null
              : () async {
                  setState(() => _isSending = true);
                  final sent = await _friendCtrl.sendFriendRequest(user);
                  if (sent && mounted) {
                    Get.back();
                    Get.snackbar(
                        'Sent', 'Friend request sent to ${user.displayLabel}');
                  } else if (mounted) {
                    setState(() => _isSending = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.textPrimary,
            disabledBackgroundColor: EColors.surfaceLight,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(
              horizontal: ESizes.md,
              vertical: ESizes.xs,
            ),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Friend'),
        );
    }
  }
}
