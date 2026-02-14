import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_sizes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../watchlist/controllers/watchlist_controller.dart';
import '../../watchlist/widgets/watchlist_selector_widget.dart';
import '../../search/screens/search_screen.dart';
import '../../watchlist/screens/watchlist_screen.dart';
import '../widgets/queue_health_card.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/bingequest_top10_section.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../profile/screens/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          child: RefreshIndicator(
            onRefresh: () async {
              // WatchlistController refresh triggers QueueHealthController via listener
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
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: ESizes.md),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: ESizes.lg),
                    child: WatchlistSelectorWidget(),
                  ),
                  const SizedBox(height: ESizes.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: ESizes.lg),
                    child: QueueHealthCard(),
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
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const SearchScreen()),
        backgroundColor: EColors.accent,
        child: const Icon(Icons.add, color: EColors.textOnAccent),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              EText.welcomeBack,
              style: const TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESizes.xs),
            Obx(() {
              final user = AuthController.to.user;
              final name =
                  user?.userMetadata?['full_name'] ??
                  user?.userMetadata?['name'] ??
                  user?.email?.split('@').first ??
                  'User';
              return Text(
                name,
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
                    user?.userMetadata?['avatar_url'] ??
                    user?.userMetadata?['picture'];

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

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            // Watchlist
            Get.to(() => const WatchlistScreen());
            break;
          case 2:
            // Search
            Get.to(() => const SearchScreen());
            break;
          case 3:
            // Profile
            Get.to(() => const ProfileScreen());
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: EText.dashboard,
        ),
        NavigationDestination(
          icon: Icon(Icons.list_outlined),
          selectedIcon: Icon(Icons.list),
          label: EText.watchlist,
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: EText.search,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: EText.profile,
        ),
      ],
    );
  }
}
