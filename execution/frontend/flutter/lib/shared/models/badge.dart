/// Badge category types matching database schema.
enum BadgeCategory {
  completion,
  milestone,
  genre,
  streak,
  activity;

  static BadgeCategory fromString(String value) {
    return BadgeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BadgeCategory.completion,
    );
  }
}

/// Badge criteria types for determining unlock conditions.
enum BadgeCriteriaType {
  itemsCompleted,
  moviesCompleted,
  showsCompleted,
  hoursWatched,
  genreWatched,
  weekendCompletions,
  lateNightWatches,
  earlyWatches,
  // Efficiency badge types
  efficiencyScore,
  staleItems,
  staleCleared,
  allActiveDays,
  sameDayStarts;

  static BadgeCriteriaType fromString(String value) {
    switch (value) {
      case 'items_completed':
        return BadgeCriteriaType.itemsCompleted;
      case 'movies_completed':
        return BadgeCriteriaType.moviesCompleted;
      case 'shows_completed':
        return BadgeCriteriaType.showsCompleted;
      case 'hours_watched':
        return BadgeCriteriaType.hoursWatched;
      case 'genre_watched':
        return BadgeCriteriaType.genreWatched;
      case 'weekend_completions':
        return BadgeCriteriaType.weekendCompletions;
      case 'late_night_watches':
        return BadgeCriteriaType.lateNightWatches;
      case 'early_watches':
        return BadgeCriteriaType.earlyWatches;
      case 'efficiency_score':
        return BadgeCriteriaType.efficiencyScore;
      case 'stale_items':
        return BadgeCriteriaType.staleItems;
      case 'stale_cleared':
        return BadgeCriteriaType.staleCleared;
      case 'all_active_days':
        return BadgeCriteriaType.allActiveDays;
      case 'same_day_starts':
        return BadgeCriteriaType.sameDayStarts;
      default:
        return BadgeCriteriaType.itemsCompleted;
    }
  }
}

/// Badge criteria containing unlock requirements.
class BadgeCriteria {
  final BadgeCriteriaType type;
  final int value;
  final int? genreId;

  const BadgeCriteria({
    required this.type,
    required this.value,
    this.genreId,
  });

  factory BadgeCriteria.fromJson(Map<String, dynamic> json) {
    return BadgeCriteria(
      type: BadgeCriteriaType.fromString(json['type'] as String? ?? ''),
      value: json['value'] as int? ?? 0,
      genreId: json['genre_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
      if (genreId != null) 'genre_id': genreId,
    };
  }
}

/// Badge model representing an achievement users can earn.
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeCategory category;
  final BadgeCriteria criteria;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.category,
    required this.criteria,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    final criteriaJson = json['criteria_json'];
    final criteria = criteriaJson is Map<String, dynamic>
        ? BadgeCriteria.fromJson(criteriaJson)
        : BadgeCriteria.fromJson({});

    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['icon_path'] as String? ?? '',
      category: BadgeCategory.fromString(json['category'] as String? ?? ''),
      criteria: criteria,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_path': iconPath,
      'category': category.name,
      'criteria_json': criteria.toJson(),
    };
  }

  /// Get the emoji from the icon path (format: "emoji:X").
  String get emoji {
    if (iconPath.startsWith('emoji:')) {
      return iconPath.substring(6);
    }
    return '🏆';
  }

  /// Check if this badge is earned based on user stats.
  bool isEarned(Map<String, dynamic> stats) {
    switch (criteria.type) {
      case BadgeCriteriaType.itemsCompleted:
        return (stats['items_completed'] as int? ?? 0) >= criteria.value;
      case BadgeCriteriaType.moviesCompleted:
        return (stats['movies_completed'] as int? ?? 0) >= criteria.value;
      case BadgeCriteriaType.showsCompleted:
        return (stats['shows_completed'] as int? ?? 0) >= criteria.value;
      case BadgeCriteriaType.hoursWatched:
        final minutes = stats['minutes_watched'] as int? ?? 0;
        return (minutes / 60) >= criteria.value;
      case BadgeCriteriaType.genreWatched:
        final genreStats = stats['genre_stats'] as Map<int, int>? ?? {};
        return (genreStats[criteria.genreId] ?? 0) >= criteria.value;
      case BadgeCriteriaType.weekendCompletions:
      case BadgeCriteriaType.lateNightWatches:
      case BadgeCriteriaType.earlyWatches:
        // Streak badges require special tracking
        return false;
      // Efficiency badges
      case BadgeCriteriaType.efficiencyScore:
        return (stats['efficiency_score'] as int? ?? 0) >= criteria.value;
      case BadgeCriteriaType.staleItems:
        // For "No Backlog" badge, check if stale items equals the required value (0)
        final staleItems = stats['stale_items'] as int? ?? 999;
        return staleItems == criteria.value && (stats['items_completed'] as int? ?? 0) > 0;
      case BadgeCriteriaType.staleCleared:
      case BadgeCriteriaType.allActiveDays:
      case BadgeCriteriaType.sameDayStarts:
        // These require special tracking over time
        return false;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Badge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
