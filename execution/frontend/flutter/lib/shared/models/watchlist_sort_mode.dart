import 'package:flutter/material.dart';

/// Sort modes for watchlist items.
enum WatchlistSortMode {
  recentActivity,
  alphabetical,
  popularity,
  minutesRemaining,
  releaseDate;

  String get displayName => switch (this) {
    WatchlistSortMode.recentActivity => 'Recent Activity',
    WatchlistSortMode.alphabetical => 'A-Z',
    WatchlistSortMode.popularity => 'Popularity',
    WatchlistSortMode.minutesRemaining => 'Time Left',
    WatchlistSortMode.releaseDate => 'Release Date',
  };

  IconData get icon => switch (this) {
    WatchlistSortMode.recentActivity => Icons.history,
    WatchlistSortMode.alphabetical => Icons.sort_by_alpha,
    WatchlistSortMode.popularity => Icons.trending_up,
    WatchlistSortMode.minutesRemaining => Icons.timer,
    WatchlistSortMode.releaseDate => Icons.calendar_today,
  };
}

/// Status filter for watchlist items.
enum WatchlistStatusFilter {
  all,
  notStarted,
  inProgress,
  completed;

  String get displayName => switch (this) {
    WatchlistStatusFilter.all => 'All',
    WatchlistStatusFilter.notStarted => 'Not Started',
    WatchlistStatusFilter.inProgress => 'In Progress',
    WatchlistStatusFilter.completed => 'Completed',
  };

  IconData get icon => switch (this) {
    WatchlistStatusFilter.all => Icons.list,
    WatchlistStatusFilter.notStarted => Icons.radio_button_unchecked,
    WatchlistStatusFilter.inProgress => Icons.play_circle_outline,
    WatchlistStatusFilter.completed => Icons.check_circle_outline,
  };
}
