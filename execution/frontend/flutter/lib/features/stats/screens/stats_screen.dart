import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/widgets/shimmer_widget.dart';
import '../controllers/stats_controller.dart';
import '../widgets/completion_ring.dart';
import '../widgets/mood_donut_chart.dart';
import '../widgets/peak_hours_chart.dart';
import '../widgets/stats_summary_row.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/time_window_picker.dart';
import '../widgets/watch_time_bar_chart.dart';

/// Full stats dashboard screen.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StatsController>()) {
      Get.lazyPut(() => StatsController());
    }

    return Scaffold(
      backgroundColor: EColors.background,
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
              Expanded(
                child: Obx(() {
                  final ctrl = StatsController.to;
                  return RefreshIndicator(
                    color: EColors.primary,
                    backgroundColor: EColors.surface,
                    onRefresh: ctrl.refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: ESizes.lg, vertical: ESizes.md),
                      child: Column(
                        children: [
                          const TimeWindowPicker(),
                          const SizedBox(height: ESizes.md),
                          ctrl.isLoading
                              ? _buildSkeletons()
                              : _buildContent(),
                          const SizedBox(height: ESizes.xxl),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
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
          const Text(
            'Your Stats',
            style: TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const StatsSummaryRow(),
        const SizedBox(height: ESizes.md),
        _SectionCard(title: 'Mood Distribution', child: const MoodDonutChart()),
        const SizedBox(height: ESizes.md),
        _SectionCard(title: 'Watch Time', child: const WatchTimeBarChart()),
        const SizedBox(height: ESizes.md),
        _SectionCard(title: 'Peak Hours', child: const PeakHoursChart()),
        const SizedBox(height: ESizes.md),
        _SectionCard(title: 'Streaks', child: const StreakIndicator()),
        const SizedBox(height: ESizes.md),
        _SectionCard(title: 'Completion', child: const CompletionRing()),
      ],
    );
  }

  Widget _buildSkeletons() {
    return ShimmerEffect(
      child: Column(
        children: [
          // Summary row skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: ESizes.sm,
            crossAxisSpacing: ESizes.sm,
            childAspectRatio: 2.4,
            children: List.generate(
              4,
              (_) => ShimmerBox(borderRadius: ESizes.radiusMd, height: 56),
            ),
          ),
          const SizedBox(height: ESizes.md),
          // Section card skeletons
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: ESizes.md),
              child: Container(
                padding: const EdgeInsets.all(ESizes.md),
                decoration: BoxDecoration(
                  color: EColors.surface,
                  borderRadius: BorderRadius.circular(ESizes.radiusMd),
                  border: Border.all(color: EColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerText(width: 120, height: 16),
                    const SizedBox(height: ESizes.md),
                    ShimmerBox(
                      width: double.infinity,
                      height: i == 0 ? 200 : 140,
                      borderRadius: ESizes.radiusMd,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard section card wrapper used throughout the stats screen.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        border: Border.all(color: EColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: ESizes.fontLg,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
          const SizedBox(height: ESizes.md),
          child,
        ],
      ),
    );
  }
}
