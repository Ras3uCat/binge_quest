/// Represents a content event detected for a followed talent.
/// Created by the backend when new movies/shows featuring followed talent
/// are detected on TMDB.
class TalentContentEvent {
  final String id;
  final int tmdbPersonId;
  final int tmdbContentId;
  final String mediaType;
  final String contentTitle;
  final DateTime detectedAt;
  final int notifiedUserCount;

  const TalentContentEvent({
    required this.id,
    required this.tmdbPersonId,
    required this.tmdbContentId,
    required this.mediaType,
    required this.contentTitle,
    required this.detectedAt,
    this.notifiedUserCount = 0,
  });

  bool get isMovie => mediaType == 'movie';
  bool get isTv => mediaType == 'tv';

  factory TalentContentEvent.fromJson(Map<String, dynamic> json) {
    return TalentContentEvent(
      id: json['id'] as String,
      tmdbPersonId: json['tmdb_person_id'] as int,
      tmdbContentId: json['tmdb_content_id'] as int,
      mediaType: json['media_type'] as String? ?? 'movie',
      contentTitle: json['content_title'] as String,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      notifiedUserCount: json['notified_user_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tmdb_person_id': tmdbPersonId,
        'tmdb_content_id': tmdbContentId,
        'media_type': mediaType,
        'content_title': contentTitle,
        'detected_at': detectedAt.toIso8601String(),
        'notified_user_count': notifiedUserCount,
      };
}
