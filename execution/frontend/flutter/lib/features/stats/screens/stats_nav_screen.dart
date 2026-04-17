import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/archetype_section.dart';
import '../../profile/widgets/badges_section.dart';
import '../../profile/widgets/streaming_breakdown_section.dart';
import 'stats_screen.dart';

/// Top-level Stats nav tab — 3 sub-tabs: Your Stats, Streaming, Badges.
class StatsNavScreen extends StatelessWidget {
  const StatsNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
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
                    Tab(text: 'Your Stats'),
                    Tab(text: 'Streaming'),
                    Tab(text: 'Awards'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [StatsScreen(showHeader: false), _StreamingTab(), _AwardsTab()],
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
    return const Padding(
      padding: EdgeInsets.all(ESizes.lg),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Stats',
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
    );
  }
}

class _StreamingTab extends StatelessWidget {
  const _StreamingTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(ESizes.lg),
      child: StreamingBreakdownSection(),
    );
  }
}

class _AwardsTab extends StatelessWidget {
  const _AwardsTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(ESizes.lg),
      child: Column(
        children: [
          ArchetypeSection(),
          SizedBox(height: ESizes.lg),
          BadgesSection(),
        ],
      ),
    );
  }
}
