import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';

/// Recommendation modes for sorting watchlist items.
enum RecommendationMode {
  recent,
  finishFast,
  freshFirst,
  viralHits;

  String get displayName {
    switch (this) {
      case RecommendationMode.recent:
        return 'Recent Progress';
      case RecommendationMode.finishFast:
        return 'Finish Fast';
      case RecommendationMode.freshFirst:
        return 'Fresh First';
      case RecommendationMode.viralHits:
        return 'Viral Hits';
    }
  }

  String get description {
    switch (this) {
      case RecommendationMode.recent:
        return 'Continue watching';
      case RecommendationMode.finishFast:
        return 'Least time remaining';
      case RecommendationMode.freshFirst:
        return 'Newest releases first';
      case RecommendationMode.viralHits:
        return 'Most popular first';
    }
  }

  IconData get icon {
    switch (this) {
      case RecommendationMode.recent:
        return Icons.play_circle_outline;
      case RecommendationMode.finishFast:
        return Icons.timer;
      case RecommendationMode.freshFirst:
        return Icons.new_releases;
      case RecommendationMode.viralHits:
        return Icons.trending_up;
    }
  }

  Color get color {
    switch (this) {
      case RecommendationMode.recent:
        return EColors.tertiary;
      case RecommendationMode.finishFast:
        return EColors.accent;
      case RecommendationMode.freshFirst:
        return EColors.primary;
      case RecommendationMode.viralHits:
        return EColors.secondary;
    }
  }
}
