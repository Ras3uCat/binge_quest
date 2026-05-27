import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../controllers/calendar_controller.dart';

class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({required this.controller, super.key});

  final CalendarController controller;

  static const _weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.focusedMonth;
      final selected = controller.selectedDate.value;
      final eventDates = controller.filteredEventsByDate.keys.toSet();
      final firstDay = DateTime(month.year, month.month, 1);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      // weekday: 1=Mon..7=Sun; % 7 → 0 blanks for Sunday, 1 for Monday, etc.
      final leadingBlanks = firstDay.weekday % 7;
      final today = DateTime.now();
      final todayNorm = DateTime(today.year, today.month, today.day);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm),
        child: Column(
          children: [
            Row(
              children: _weekdays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontXs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: ESizes.xs),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (_, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = index - leadingBlanks + 1;
                final date = DateTime(month.year, month.month, day);
                return GestureDetector(
                  onTap: () => controller.selectDate(date),
                  child: _DayCell(
                    day: day,
                    isToday: date == todayNorm,
                    isSelected: selected != null && date == selected,
                    hasEvents: eventDates.contains(date),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? EColors.primary
                  : isToday
                  ? EColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: isToday && !isSelected ? Border.all(color: EColors.primary) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? Colors.white : EColors.textPrimary,
                  fontSize: ESizes.fontSm,
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasEvents ? EColors.primary : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
