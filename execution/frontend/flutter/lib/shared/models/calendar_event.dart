import 'watchlist_item.dart';

enum CalendarEventType { episode, movieRelease }

class CalendarEvent {
  final DateTime date; // normalized: DateTime(y, m, d), local time
  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final CalendarEventType type;
  final String? episodeCode; // "S01E05" — TV only
  final int? seasonNumber;
  final int? episodeNumber;
  final String watchlistId;
  final String watchlistName;

  const CalendarEvent({
    required this.date,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    required this.type,
    this.episodeCode,
    this.seasonNumber,
    this.episodeNumber,
    required this.watchlistId,
    required this.watchlistName,
  });
}
