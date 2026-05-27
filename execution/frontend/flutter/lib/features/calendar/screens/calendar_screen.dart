import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/calendar_event.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_month_grid.dart';

class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        backgroundColor: EColors.backgroundSecondary,
        elevation: 0,
        title: const Text(
          'Release Calendar',
          style: TextStyle(color: EColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EColors.textPrimary),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator(color: EColors.primary));
        }
        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error!, style: const TextStyle(color: EColors.textSecondary)),
                const SizedBox(height: ESizes.md),
                TextButton(
                  onPressed: controller.loadEvents,
                  child: const Text('Retry', style: TextStyle(color: EColors.primary)),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            _FilterChipsRow(controller: controller),
            _MonthNavHeader(controller: controller),
            CalendarMonthGrid(controller: controller),
            const Divider(color: EColors.backgroundSecondary, height: 1),
            Expanded(child: _DayDetailSection(controller: controller)),
          ],
        );
      }),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedWatchlistId.value;
      return SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
          children: [
            _FilterChip(
              label: 'All',
              selected: selected == 'all',
              onTap: () => controller.selectWatchlist('all'),
            ),
            ...controller.watchlists.map(
              (w) => _FilterChip(
                label: w.name,
                selected: selected == w.id,
                onTap: () => controller.selectWatchlist(w.id),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: ESizes.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
          decoration: BoxDecoration(
            color: selected ? EColors.primary : EColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(ESizes.radiusRound),
            border: Border.all(
              color: selected ? EColors.primary : EColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : EColors.textSecondary,
              fontSize: ESizes.fontSm,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavHeader extends StatelessWidget {
  const _MonthNavHeader({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = DateFormat('MMMM yyyy').format(controller.focusedMonth);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.xs),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: EColors.textPrimary),
              onPressed: controller.previousMonth,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EColors.textPrimary,
                  fontSize: ESizes.fontLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: EColors.textPrimary),
              onPressed: controller.nextMonth,
            ),
          ],
        ),
      );
    });
  }
}

class _DayDetailSection extends StatelessWidget {
  const _DayDetailSection({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final date = controller.selectedDate.value;
      if (date == null) return const SizedBox.shrink();

      final events = controller.eventsForDate(date);
      final label = DateFormat('MMMM d').format(date);
      final count = events.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ESizes.md, ESizes.sm, ESizes.md, ESizes.xs),
            child: Text(
              '$label — $count ${count == 1 ? 'release' : 'releases'}',
              style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No releases on this day',
                      style: TextStyle(color: EColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: ESizes.md),
                    itemCount: events.length,
                    itemBuilder: (_, i) {
                      final event = events[i];
                      return CalendarEventCard(event: event, onTap: () => _navigateToDetail(event));
                    },
                  ),
          ),
        ],
      );
    });
  }

  void _navigateToDetail(CalendarEvent event) {
    final item = controller.watchlistItemFor(event.tmdbId);
    if (item != null) Get.to(() => ItemDetailScreen(item: item));
  }
}
