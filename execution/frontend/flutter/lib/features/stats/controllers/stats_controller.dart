import 'package:get/get.dart';
import '../../../shared/models/mood_tag.dart';
import '../../../shared/models/stats_data.dart';
import '../../../shared/repositories/stats_repository.dart';

/// Time window options for the stats dashboard.
enum StatsWindow {
  week,
  month,
  year,
  all;

  String get value {
    switch (this) {
      case StatsWindow.week:
        return 'week';
      case StatsWindow.month:
        return 'month';
      case StatsWindow.year:
        return 'year';
      case StatsWindow.all:
        return 'all';
    }
  }

  String get displayName {
    switch (this) {
      case StatsWindow.week:
        return 'Week';
      case StatsWindow.month:
        return 'Month';
      case StatsWindow.year:
        return 'Year';
      case StatsWindow.all:
        return 'All Time';
    }
  }
}

/// Controller for the Advanced Stats Dashboard.
class StatsController extends GetxController {
  static StatsController get to => Get.find();

  final _selectedWindow = StatsWindow.month.obs;
  final _isLoading = false.obs;
  final _statsData = Rxn<StatsData>();

  StatsWindow get selectedWindow => _selectedWindow.value;
  bool get isLoading => _isLoading.value;
  StatsData? get statsData => _statsData.value;

  /// Mood stats derived from current statsData genre distribution.
  Map<MoodTag, MoodStats> get moodStats {
    final data = _statsData.value;
    if (data == null) return {};
    return StatsData.aggregateMoods(data.genreDistribution);
  }

  @override
  void onInit() {
    super.onInit();
    loadStats(_selectedWindow.value);
  }

  /// Load stats for the given [window] and update state.
  Future<void> loadStats(StatsWindow window) async {
    _selectedWindow.value = window;
    _isLoading.value = true;

    try {
      final data = await StatsRepository.getStatsDashboard(window.value);
      _statsData.value = data;
    } catch (_) {
      _statsData.value = StatsData.empty();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reload the currently selected window (used for pull-to-refresh).
  @override
  Future<void> refresh() => loadStats(_selectedWindow.value);
}
