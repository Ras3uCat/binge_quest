import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/widgets/e_confirm_dialog.dart';
import '../../../shared/models/friendship.dart';
import '../controllers/friend_controller.dart';
import '../controllers/watch_party_controller.dart';
import '../../../features/profile/controllers/archetype_controller.dart';
import '../../../features/profile/widgets/archetype_badge.dart';
import '../../../shared/models/archetype.dart';
import '../../../shared/models/user_profile.dart';
import '../widgets/friend_tab_sections.dart';
import '../widgets/party_list_section.dart';
import 'friend_search_screen.dart';

/// Main friends screen with tabs: Friends, Requests, Blocked.
class FriendListScreen extends StatelessWidget {
  final int initialTab;
  const FriendListScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
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
                    Tab(text: 'Parties & Friends'),
                    Tab(text: 'Requests'),
                    Tab(text: 'Blocked'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _FriendsTab(),
                      FriendRequestsTab(),
                      FriendBlockedTab(),
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
              'Friends & Watch Parties',
              style: TextStyle(
                fontSize: ESizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Find Friends',
            color: EColors.textPrimary,
            onPressed: () async {
              await Get.to(() => const FriendSearchScreen());
              FriendController.to.refresh();
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Friends Tab
// =============================================================================
class _FriendsTab extends StatefulWidget {
  const _FriendsTab();

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  @override
  void initState() {
    super.initState();
    WatchPartyController.to.loadParties();
  }

  Widget _friendsHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: ESizes.sm),
      child: Text(
        'Friends',
        style: TextStyle(
          color: EColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontSm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = FriendController.to;
      if (ctrl.isLoading.value && ctrl.friends.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.friends.isEmpty) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(ESizes.md),
              child: const PartyListSection(),
            ),
            Expanded(
              child: friendEmptyState(
                icon: Icons.people_outline,
                message: 'No friends yet',
                sub: 'Tap the + icon to find friends',
              ),
            ),
          ],
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          await ctrl.refresh();
          await WatchPartyController.to.loadParties();
        },
        child: ListView(
          padding: const EdgeInsets.all(ESizes.md),
          children: [
            const PartyListSection(),
            const SizedBox(height: ESizes.md),
            _friendsHeader(),
            ...ctrl.friends.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: ESizes.xs),
                  child: _FriendTile(friendship: f, ctrl: ctrl),
                )),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Friend Tile
// ---------------------------------------------------------------------------

class _FriendTile extends StatelessWidget {
  final Friendship friendship;
  final FriendController ctrl;

  const _FriendTile({required this.friendship, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final friend = friendship.friend;
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: EColors.surfaceLight,
            backgroundImage: friend?.avatarUrl != null
                ? NetworkImage(friend!.avatarUrl!)
                : null,
            child: friend?.avatarUrl == null
                ? const Icon(Icons.person, color: EColors.textSecondary)
                : null,
          ),
          const SizedBox(width: ESizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend?.displayName ?? 'User',
                  style: const TextStyle(
                    color: EColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (friend?.username != null)
                  Text(
                    '@${friend!.username}',
                    style: const TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSm,
                    ),
                  ),
                if (friend?.primaryArchetype != null)
                  Obx(() => Padding(
                        padding: const EdgeInsets.only(top: ESizes.xs),
                        child: _buildCompactArchetypeBadge(friend!),
                      )),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: EColors.textSecondary),
            color: EColors.surface,
            onSelected: (value) {
              if (value == 'remove') {
                _confirmRemove();
              } else if (value == 'block') {
                ctrl.blockUser(
                  friendship.friendId(ctrl.friends.first.requesterId),
                  displayName: friend?.displayName,
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Friend',
                    style: TextStyle(color: EColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User',
                    style: TextStyle(color: EColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactArchetypeBadge(UserProfile friend) {
    final archetype =
        ArchetypeController.to.archetypeById(friend.primaryArchetype!);
    if (archetype == null) return const SizedBox.shrink();
    return ArchetypeBadge(
      primary: UserArchetype.displayOnly(
        userId: friend.id,
        archetype: archetype,
      ),
    );
  }

  void _confirmRemove() {
    EConfirmDialog.show(
      title: 'Remove Friend',
      message:
          'Remove ${friendship.friend?.displayName ?? "this user"} from your friends?',
      confirmLabel: 'Remove',
      isDestructive: true,
      onConfirm: () => ctrl.removeFriend(friendship),
    );
  }
}
