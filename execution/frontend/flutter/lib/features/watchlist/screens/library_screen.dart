import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../playlists/widgets/playlists_section.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/widgets/following_section.dart';
import 'watchlist_screen.dart';

/// Top-level Library destination combining Watchlists and Playlists tabs.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        DashboardController.to.libraryTabIndex.value = _tabController.index;
      }
    });
    ever(DashboardController.to.libraryTabIndex, (idx) {
      if (_tabController.index != idx) _tabController.animateTo(idx);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const Padding(
                padding: EdgeInsets.all(ESizes.lg),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Library',
                          style: TextStyle(
                            fontSize: ESizes.fontXxl,
                            fontWeight: FontWeight.bold,
                            color: EColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: EColors.primary,
                labelColor: EColors.textPrimary,
                unselectedLabelColor: EColors.textSecondary,
                tabs: const [
                  Tab(text: 'Watchlists'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Favorites'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    WatchlistScreen(showBackButton: false),
                    _PlaylistsTab(),
                    _FavoritesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(ESizes.lg),
      child: FollowingSection(),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final userId = AuthController.to.user?.id;
    if (userId == null) {
      return const Center(
        child: Text('Sign in to view playlists', style: TextStyle(color: EColors.textSecondary)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.lg),
      child: PlaylistsSection(userId: userId, isOwnProfile: true, showHeader: false),
    );
  }
}
