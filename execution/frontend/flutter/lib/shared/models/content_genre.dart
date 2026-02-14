import 'package:flutter/material.dart';

/// Standard content genres from TMDB.
class ContentGenre {
  final int id;
  final String name;
  final IconData? icon;

  const ContentGenre({
    required this.id,
    required this.name,
    this.icon,
  });

  /// All known genres (movie + TV combined, deduplicated by ID)
  static const List<ContentGenre> allGenres = [
    ContentGenre(id: 28, name: 'Action', icon: Icons.sports_mma),
    ContentGenre(id: 10759, name: 'Action & Adventure', icon: Icons.sports_mma),
    ContentGenre(id: 12, name: 'Adventure', icon: Icons.explore),
    ContentGenre(id: 16, name: 'Animation', icon: Icons.animation),
    ContentGenre(id: 35, name: 'Comedy', icon: Icons.sentiment_very_satisfied),
    ContentGenre(id: 80, name: 'Crime', icon: Icons.gavel),
    ContentGenre(id: 99, name: 'Documentary', icon: Icons.videocam),
    ContentGenre(id: 18, name: 'Drama', icon: Icons.theater_comedy),
    ContentGenre(id: 10751, name: 'Family', icon: Icons.family_restroom),
    ContentGenre(id: 14, name: 'Fantasy', icon: Icons.auto_awesome),
    ContentGenre(id: 36, name: 'History', icon: Icons.history_edu),
    ContentGenre(id: 27, name: 'Horror', icon: Icons.nights_stay),
    ContentGenre(id: 10402, name: 'Music', icon: Icons.music_note),
    ContentGenre(id: 9648, name: 'Mystery', icon: Icons.help_outline),
    ContentGenre(id: 10749, name: 'Romance', icon: Icons.favorite),
    ContentGenre(id: 878, name: 'Science Fiction', icon: Icons.rocket),
    ContentGenre(id: 10765, name: 'Sci-Fi & Fantasy', icon: Icons.rocket),
    ContentGenre(id: 53, name: 'Thriller', icon: Icons.flash_on),
    ContentGenre(id: 10752, name: 'War', icon: Icons.military_tech),
    ContentGenre(id: 10768, name: 'War & Politics', icon: Icons.military_tech),
    ContentGenre(id: 37, name: 'Western', icon: Icons.landscape),
  ];

  /// Get genre by ID
  static ContentGenre? getById(int id) {
    try {
      return allGenres.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get display name for genre ID
  static String getNameById(int id) {
    return getById(id)?.name ?? 'Unknown';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentGenre &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
