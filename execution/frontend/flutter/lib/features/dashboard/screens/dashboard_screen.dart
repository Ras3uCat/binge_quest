import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_sizes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../../watchlist/widgets/watchlist_pill_selector.dart';
import '../../watchlist/widgets/create_watchlist_dialog.dart';
import '../../watchlist/screens/library_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../social/screens/friend_list_screen.dart';
import '../../social/controllers/friend_controller.dart';
import '../../profile/screens/profile_screen.dart';
import '../../stats/screens/stats_nav_screen.dart';
import '../../../core/services/deep_link_service.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/queue_health_card.dart';
import '../widgets/time_block_sheet.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/bingequest_top10_section.dart';
import '../../notifications/widgets/notification_bell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _ctrl;

  static const List<Widget> _screens = [
    _HomeTab(),
    LibraryScreen(),
    SearchScreen(),
    FriendListScreen(),
    StatsNavScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(DashboardController());
    WidgetsBinding.instance.addPostFrameCallback((_) => DeepLinkService.to.consumeAndDispatch());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(index: _ctrl.selectedIndex.value, children: _screens),
        bottomNavigationBar: Obx(() {
          final pendingCount = FriendController.to.pendingReceived.length;
          return NavigationBar(
            selectedIndex: _ctrl.selectedIndex.value,
            onDestinationSelected: _ctrl.navigateToTab,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(Icons.video_library),
                label: 'Library',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: EText.search,
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.group_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.group),
                ),
                label: 'Social',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home tab body (previously the DashboardScreen body)
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [EColors.backgroundSecondary, EColors.background],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await WatchlistController.to.refresh();
          },
          color: EColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: ESizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                  child: _HomeHeader(),
                ),
                const SizedBox(height: ESizes.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Watchlists',
                        style: TextStyle(
                          fontSize: ESizes.fontXl,
                          fontWeight: FontWeight.bold,
                          color: EColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.dialog(const CreateWatchlistDialog()),
                        child: const Text(
                          'Create Watchlist',
                          style: TextStyle(color: EColors.primary, fontSize: ESizes.fontMd),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ESizes.sm),
                const WatchlistPillSelector(),
                const SizedBox(height: ESizes.lg),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: ESizes.lg),
                  child: QueueHealthCard(),
                ),
                const SizedBox(height: ESizes.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: TimeBlockSheet.show,
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('I Have Time For...'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EColors.accent,
                        foregroundColor: EColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ESizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ESizes.lg),
                const RecommendationsSection(),
                const SizedBox(height: ESizes.lg),
                const BingeQuestTop10Section(),
                const SizedBox(height: ESizes.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              EText.welcomeBack,
              style: const TextStyle(fontSize: ESizes.fontMd, color: EColors.textSecondary),
            ),
            const SizedBox(height: ESizes.xs),
            Obx(() {
              final username = FriendController.to.username.value;
              final user = AuthController.to.user;
              final firstName =
                  (user?.userMetadata?['full_name'] ??
                          user?.userMetadata?['name'] ??
                          (user?.email?.contains('@privaterelay.appleid.com') == true
                              ? 'Apple'
                              : user?.email?.split('@').first) ??
                          'User')
                      .toString()
                      .split(' ')
                      .first;
              return Text(
                username ?? firstName,
                style: const TextStyle(
                  fontSize: ESizes.fontXxl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              );
            }),
          ],
        ),
        Row(
          children: [
            const NotificationBell(),
            const SizedBox(width: ESizes.md),
            GestureDetector(
              onTap: () => Get.to(() => const ProfileScreen()),
              child: Obx(() {
                final user = AuthController.to.user;
                final avatarUrl =
                    user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
                if (avatarUrl != null) {
                  return CircleAvatar(
                    radius: ESizes.avatarMd / 2,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: EColors.primary,
                  );
                }
                return Container(
                  width: ESizes.avatarMd,
                  height: ESizes.avatarMd,
                  decoration: BoxDecoration(
                    gradient: EColors.primaryGradient,
                    borderRadius: BorderRadius.circular(ESizes.radiusRound),
                  ),
                  child: const Icon(Icons.person, color: EColors.textOnPrimary),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
