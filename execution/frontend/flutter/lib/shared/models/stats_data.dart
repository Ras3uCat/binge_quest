import 'mood_tag.dart';

/// Summary totals for the stats dashboard.
class StatsSummary {
  final int minutesWatched;
  final int itemsCompleted;
  final int totalItems;
  final int episodesWatched;
  final int moviesCompleted;
  final int showsCompleted;

  const StatsSummary({
    required this.minutesWatched,
    required this.itemsCompleted,
    required this.totalItems,
    required this.episodesWatched,
    required this.moviesCompleted,
    required this.showsCompleted,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      minutesWatched: (json['minutes_watched'] as num?)?.toInt() ?? 0,
      itemsCompleted: (json['items_completed'] as num?)?.toInt() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      episodesWatched: (json['episodes_watched'] as num?)?.toInt() ?? 0,
      moviesCompleted: (json['movies_completed'] as num?)?.toInt() ?? 0,
      showsCompleted: (json['shows_completed'] as num?)?.toInt() ?? 0,
    );
  }

  static StatsSummary empty() => const StatsSummary(
    minutesWatched: 0,
    itemsCompleted: 0,
    totalItems: 0,
    episodesWatched: 0,
    moviesCompleted: 0,
    showsCompleted: 0,
  );
}

/// Daily watch time trend data point (Date-based, legacy).
class WatchTimeTrend {
  final DateTime date;
  final int minutes;

  const WatchTimeTrend({required this.date, required this.minutes});

  factory WatchTimeTrend.fromJson(Map<String, dynamic> json) {
    return WatchTimeTrend(
      date: DateTime.parse(json['date'] as String),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Aggregated watch time by weekday.
class WatchTimeWeekday {
  final int weekday; // 0=Sun ... 6=Sat
  final String dayName;
  final int minutes;

  const WatchTimeWeekday({
    required this.weekday,
    required this.dayName,
    required this.minutes,
  });

  factory WatchTimeWeekday.fromJson(Map<String, dynamic> json) {
    return WatchTimeWeekday(
      weekday: (json['weekday'] as num?)?.toInt() ?? 0,
      dayName: json['day_name'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> get weekdayLabels => [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
}

/// Genre-level watch statistics.
class GenreStats {
  final int genreId;
  final int minutes;
  final int count;

  const GenreStats({
    required this.genreId,
    required this.minutes,
    required this.count,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) {
    return GenreStats(
      genreId: (json['genre_id'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Aggregated mood-level watch statistics.
class MoodStats {
  final MoodTag mood;
  final int totalMinutes;
  final int itemCount;

  const MoodStats({
    required this.mood,
    required this.totalMinutes,
    required this.itemCount,
  });
}

/// Hourly viewing distribution.
class PeakHour {
  final int hour;
  final int minutes;

  const PeakHour({required this.hour, required this.minutes});

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Viewing streak information.
class StreakData {
  final int currentStreak;
  final int longestStreak;

  const StreakData({required this.currentStreak, required this.longestStreak});

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }

  static StreakData empty() =>
      const StreakData(currentStreak: 0, longestStreak: 0);
}

/// Episode-watching pace statistics.
class EpisodePace {
  final double episodesPerDay;
  final int daysInWindow;

  const EpisodePace({required this.episodesPerDay, required this.daysInWindow});

  factory EpisodePace.fromJson(Map<String, dynamic> json) {
    return EpisodePace(
      episodesPerDay: (json['episodes_per_day'] as num?)?.toDouble() ?? 0.0,
      daysInWindow: (json['days_in_window'] as num?)?.toInt() ?? 0,
    );
  }

  static EpisodePace empty() =>
      const EpisodePace(episodesPerDay: 0.0, daysInWindow: 0);
}

/// Top-level model aggregating all stats dashboard data.
class StatsData {
  final StatsSummary summary;
  final List<WatchTimeWeekday> watchTimeByWeekday;
  final List<bool> currentWeekActivity;
  final List<GenreStats> genreDistribution;
  final List<PeakHour> peakHours;
  final StreakData streaks;
  final EpisodePace episodePace;

  const StatsData({
    required this.summary,
    required this.watchTimeByWeekday,
    required this.currentWeekActivity,
    required this.genreDistribution,
    required this.peakHours,
    required this.streaks,
    required this.episodePace,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final trendList = (json['watch_time_trend'] as List?) ?? [];
    final weekdayJson = json['watch_time_by_weekday'] as List?;
    final weekActivityJson = json['current_week_activity'] as List?;
    final genreList = (json['genre_distribution'] as List?) ?? [];
    final peakList = (json['peak_hours'] as List?) ?? [];
    final streaksJson = json['streaks'] as Map<String, dynamic>? ?? {};
    final paceJson = json['episode_pace'] as Map<String, dynamic>? ?? {};

    final trends = trendList
        .cast<Map<String, dynamic>>()
        .map(WatchTimeTrend.fromJson)
        .toList();

    // Fallback logic for watchTimeByWeekday
    List<WatchTimeWeekday> weekdays;
    if (weekdayJson != null) {
      weekdays = weekdayJson
          .cast<Map<String, dynamic>>()
          .map(WatchTimeWeekday.fromJson)
          .toList();
    } else {
      // Aggregate from trends (legacy)
      final map = <int, int>{};
      for (final t in trends) {
        final dow =
            t.date.weekday % 7; // Convert 1-7 (Mon-Sun) to 0-6 (Sun-Sat)
        map[dow] = (map[dow] ?? 0) + t.minutes;
      }
      weekdays = List.generate(7, (i) {
        return WatchTimeWeekday(
          weekday: i,
          dayName: WatchTimeWeekday.weekdayLabels[i],
          minutes: map[i] ?? 0,
        );
      });
    }

    // Fallback logic for currentWeekActivity
    List<bool> weekActivity;
    if (weekActivityJson != null) {
      weekActivity = weekActivityJson.cast<bool>();
    } else {
      // Derive from trends (look at last 7 days)
      final now = DateTime.now();
      weekActivity = List.generate(7, (i) {
        // Find date for weekday i in the current week (Sun-Sat)
        final diff = now.weekday % 7 - i;
        final targetDate = DateTime(now.year, now.month, now.day - diff);
        return trends.any(
          (t) =>
              t.date.year == targetDate.year &&
              t.date.month == targetDate.month &&
              t.date.day == targetDate.day &&
              t.minutes > 0,
        );
      });
    }

    return StatsData(
      summary: StatsSummary.fromJson(summaryJson),
      watchTimeByWeekday: weekdays,
      currentWeekActivity: weekActivity,
      genreDistribution: genreList
          .cast<Map<String, dynamic>>()
          .map(GenreStats.fromJson)
          .toList(),
      peakHours: peakList
          .cast<Map<String, dynamic>>()
          .map(PeakHour.fromJson)
          .toList(),
      streaks: StreakData.fromJson(streaksJson),
      episodePace: EpisodePace.fromJson(paceJson),
    );
  }

  static StatsData empty() => StatsData(
    summary: StatsSummary.empty(),
    watchTimeByWeekday: List.generate(
      7,
      (i) => WatchTimeWeekday(
        weekday: i,
        dayName: WatchTimeWeekday.weekdayLabels[i],
        minutes: 0,
      ),
    ),
    currentWeekActivity: List.filled(7, false),
    genreDistribution: const [],
    peakHours: const [],
    streaks: StreakData.empty(),
    episodePace: EpisodePace.empty(),
  );

  /// Aggregates genre-level data into mood-level MoodStats.
  static Map<MoodTag, MoodStats> aggregateMoods(List<GenreStats> genreData) {
    final result = <MoodTag, MoodStats>{};
    for (final mood in MoodTag.values) {
      final matching = genreData.where(
        (g) => mood.genreIds.contains(g.genreId),
      );
      result[mood] = MoodStats(
        mood: mood,
        totalMinutes: matching.fold(0, (s, g) => s + g.minutes),
        itemCount: matching.fold(0, (s, g) => s + g.count),
      );
    }
    return result;
  }
}
