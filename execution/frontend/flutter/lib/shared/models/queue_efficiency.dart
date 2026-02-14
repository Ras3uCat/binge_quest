/// Queue efficiency metrics for a user's watchlist.
/// Tracks how efficiently a user is managing their queue.
class QueueEfficiency {
  final int totalItems;
  final int completedItems;
  final int activeItems;
  final int idleItems;
  final int staleItems;
  final double completionRate;
  final int efficiencyScore;
  final int recentCompletions;
  final int excludedItems;

  const QueueEfficiency({
    required this.totalItems,
    required this.completedItems,
    required this.activeItems,
    required this.idleItems,
    required this.staleItems,
    required this.completionRate,
    required this.efficiencyScore,
    required this.recentCompletions,
    this.excludedItems = 0,
  });

  factory QueueEfficiency.fromJson(Map<String, dynamic> json) {
    return QueueEfficiency(
      totalItems: json['total_items'] as int? ?? 0,
      completedItems: json['completed_items'] as int? ?? 0,
      activeItems: json['active_items'] as int? ?? 0,
      idleItems: json['idle_items'] as int? ?? 0,
      staleItems: json['stale_items'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      efficiencyScore: json['efficiency_score'] as int? ?? 0,
      recentCompletions: json['recent_completions'] as int? ?? 0,
      excludedItems: json['excluded_items'] as int? ??
          json['excluded_count'] as int? ?? 0,
    );
  }

  /// Empty/default efficiency for new users or when no items.
  factory QueueEfficiency.empty() {
    return const QueueEfficiency(
      totalItems: 0,
      completedItems: 0,
      activeItems: 0,
      idleItems: 0,
      staleItems: 0,
      completionRate: 0.0,
      efficiencyScore: 0,
      recentCompletions: 0,
      excludedItems: 0,
    );
  }

  /// Calculate efficiency locally from items (fallback if DB function unavailable).
  factory QueueEfficiency.calculate({
    required int total,
    required int completed,
    required int active,
    required int idle,
    required int stale,
    required int recentCompletions,
    int excluded = 0,
  }) {
    // Calculate completion rate
    final completionRate = total > 0
        ? (completed / total) * 100
        : 0.0;

    // Calculate efficiency score (0-100)
    // Base: completion rate
    // Penalty: -2 points per stale item
    // Bonus: +5 points per recent completion (max 25 points)
    final score = (completionRate - (stale * 2) + (recentCompletions * 5).clamp(0, 25))
        .clamp(0, 100)
        .round();

    return QueueEfficiency(
      totalItems: total,
      completedItems: completed,
      activeItems: active,
      idleItems: idle,
      staleItems: stale,
      completionRate: completionRate,
      efficiencyScore: score,
      recentCompletions: recentCompletions,
      excludedItems: excluded,
    );
  }

  /// Efficiency rating based on score.
  EfficiencyRating get rating {
    if (efficiencyScore >= 80) return EfficiencyRating.excellent;
    if (efficiencyScore >= 60) return EfficiencyRating.good;
    if (efficiencyScore >= 40) return EfficiencyRating.fair;
    if (efficiencyScore >= 20) return EfficiencyRating.needsWork;
    return EfficiencyRating.poor;
  }

  /// Number of in-progress (non-completed) items.
  int get inProgressItems => totalItems - completedItems;

  /// Percentage of items that are stale.
  double get stalePercentage => inProgressItems > 0
      ? (staleItems / inProgressItems) * 100
      : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'completed_items': completedItems,
      'active_items': activeItems,
      'idle_items': idleItems,
      'stale_items': staleItems,
      'completion_rate': completionRate,
      'efficiency_score': efficiencyScore,
      'recent_completions': recentCompletions,
      'excluded_items': excludedItems,
    };
  }

  @override
  String toString() {
    return 'QueueEfficiency(score: $efficiencyScore, rating: ${rating.label}, '
        'total: $totalItems, completed: $completedItems, stale: $staleItems)';
  }
}

/// Efficiency rating levels.
enum EfficiencyRating {
  excellent,
  good,
  fair,
  needsWork,
  poor;

  String get label => switch (this) {
    EfficiencyRating.excellent => 'Excellent',
    EfficiencyRating.good => 'Good',
    EfficiencyRating.fair => 'Fair',
    EfficiencyRating.needsWork => 'Needs Work',
    EfficiencyRating.poor => 'Poor',
  };

  String get emoji => switch (this) {
    EfficiencyRating.excellent => '🌟',
    EfficiencyRating.good => '👍',
    EfficiencyRating.fair => '📊',
    EfficiencyRating.needsWork => '⚠️',
    EfficiencyRating.poor => '🔴',
  };

  String get message => switch (this) {
    EfficiencyRating.excellent => 'You\'re crushing it! Keep up the momentum.',
    EfficiencyRating.good => 'Solid progress! You\'re staying on track.',
    EfficiencyRating.fair => 'Room for improvement. Try finishing some items.',
    EfficiencyRating.needsWork => 'Your queue is getting stale. Time to binge!',
    EfficiencyRating.poor => 'Queue backlog alert! Start with quick wins.',
  };
}
