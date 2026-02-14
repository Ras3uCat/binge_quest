import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';

/// Mood tags for content filtering.
enum MoodTag {
  comfort,
  thriller,
  lighthearted,
  intense,
  emotional,
  escapism;

  String get displayName {
    switch (this) {
      case MoodTag.comfort:
        return 'Comfort';
      case MoodTag.thriller:
        return 'Thriller';
      case MoodTag.lighthearted:
        return 'Lighthearted';
      case MoodTag.intense:
        return 'Intense';
      case MoodTag.emotional:
        return 'Emotional';
      case MoodTag.escapism:
        return 'Escapism';
    }
  }

  String get description {
    switch (this) {
      case MoodTag.comfort:
        return 'Feel-good & familiar';
      case MoodTag.thriller:
        return 'Edge of your seat';
      case MoodTag.lighthearted:
        return 'Fun & easy watch';
      case MoodTag.intense:
        return 'Action-packed';
      case MoodTag.emotional:
        return 'Deep & moving';
      case MoodTag.escapism:
        return 'Fantasy & sci-fi';
    }
  }

  IconData get icon {
    switch (this) {
      case MoodTag.comfort:
        return Icons.favorite;
      case MoodTag.thriller:
        return Icons.psychology;
      case MoodTag.lighthearted:
        return Icons.sentiment_satisfied;
      case MoodTag.intense:
        return Icons.local_fire_department;
      case MoodTag.emotional:
        return Icons.water_drop;
      case MoodTag.escapism:
        return Icons.rocket_launch;
    }
  }

  Color get color {
    switch (this) {
      case MoodTag.comfort:
        return EColors.success;
      case MoodTag.thriller:
        return EColors.error;
      case MoodTag.lighthearted:
        return EColors.accent;
      case MoodTag.intense:
        return EColors.secondary;
      case MoodTag.emotional:
        return EColors.info;
      case MoodTag.escapism:
        return EColors.tertiary;
    }
  }

  /// Returns TMDB genre IDs associated with this mood.
  List<int> get genreIds {
    switch (this) {
      case MoodTag.comfort:
        return [35, 10751, 16]; // Comedy, Family, Animation
      case MoodTag.thriller:
        return [53, 27, 80, 9648]; // Thriller, Horror, Crime, Mystery
      case MoodTag.lighthearted:
        return [35, 10749, 16]; // Comedy, Romance, Animation
      case MoodTag.intense:
        return [28, 10759, 53]; // Action, Action & Adventure, Thriller
      case MoodTag.emotional:
        return [18, 10749]; // Drama, Romance
      case MoodTag.escapism:
        return [14, 878, 10765, 12]; // Fantasy, Sci-Fi, Sci-Fi & Fantasy, Adventure
    }
  }
}
