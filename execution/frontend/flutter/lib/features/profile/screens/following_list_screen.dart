import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/followed_talent.dart';
import '../../search/controllers/search_controller.dart';
import '../../search/widgets/person_detail_sheet.dart';
import '../controllers/followed_talent_controller.dart';

/// Full-screen tabbed list of followed talent (All, Actors, Directors).
class FollowingListScreen extends StatelessWidget {
  const FollowingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [EColors.backgroundSecondary, EColors.background],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const TabBar(
                  indicatorColor: EColors.primary,
                  labelColor: EColors.textPrimary,
                  unselectedLabelColor: EColors.textSecondary,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Actors'),
                    Tab(text: 'Directors'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _FollowingTab(filter: null),
                      _FollowingTab(filter: 'actor'),
                      _FollowingTab(filter: 'director'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          const Expanded(
            child: Text(
              'Following',
              style: TextStyle(
                fontSize: ESizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Following Tab (filtered by personType)
// =============================================================================

class _FollowingTab extends StatelessWidget {
  final String? filter;

  const _FollowingTab({required this.filter});

  List<FollowedTalent> _filtered(List<FollowedTalent> all) {
    if (filter == null) return all;
    return all.where((t) => t.personType == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = FollowedTalentController.to;

      if (ctrl.isLoading.value && ctrl.followedTalent.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = _filtered(ctrl.followedTalent);

      if (items.isEmpty) {
        final label = filter == null
            ? 'anyone'
            : filter == 'actor'
                ? 'any actors'
                : 'any directors';
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search, size: 40,
                  color: EColors.textTertiary),
              const SizedBox(height: ESizes.sm),
              Text(
                'Not following $label yet',
                style: const TextStyle(
                  fontSize: ESizes.fontMd,
                  color: EColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => ctrl.loadFollowedTalent(),
        child: ListView.builder(
          padding: const EdgeInsets.all(ESizes.md),
          itemCount: items.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: ESizes.xs),
            child: _FollowedTalentTile(talent: items[i]),
          ),
        ),
      );
    });
  }
}

// =============================================================================
// Talent Tile
// =============================================================================

class _FollowedTalentTile extends StatelessWidget {
  final FollowedTalent talent;

  const _FollowedTalentTile({required this.talent});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPersonDetail,
        borderRadius: BorderRadius.circular(ESizes.md),
        child: Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: EColors.surface,
            borderRadius: BorderRadius.circular(ESizes.md),
          ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: ESizes.md),
              Expanded(child: _buildInfo()),
              _buildUnfollowButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: EColors.surfaceLight,
      backgroundImage: talent.profilePath != null
          ? CachedNetworkImageProvider(
              EImages.tmdbProfile(talent.profilePath))
          : null,
      child: talent.profilePath == null
          ? const Icon(Icons.person, color: EColors.textSecondary)
          : null,
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          talent.personName,
          style: const TextStyle(
            color: EColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: ESizes.xs),
        _buildTypeBadge(),
      ],
    );
  }

  Widget _buildTypeBadge() {
    final isActor = talent.isActor;
    final color = isActor ? EColors.primary : EColors.accent;
    final label = isActor ? 'Actor' : 'Director';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: ESizes.fontXs,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUnfollowButton() {
    return IconButton(
      onPressed: () {
        FollowedTalentController.to.toggleFollow(
          tmdbPersonId: talent.tmdbPersonId,
          personName: talent.personName,
          personType: talent.personType,
          profilePath: talent.profilePath,
        );
      },
      icon: const Icon(Icons.favorite, color: EColors.secondary, size: 20),
      tooltip: 'Unfollow ${talent.personName}',
    );
  }

  void _openPersonDetail() {
    if (!Get.isRegistered<ContentSearchController>()) {
      Get.put(ContentSearchController());
    }
    Get.bottomSheet(
      PersonDetailSheet(personId: talent.tmdbPersonId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
