/// Represents a talent (actor/director) followed by the user.
class FollowedTalent {
  final String id;
  final String userId;
  final int tmdbPersonId;
  final String personName;
  final String personType;
  final String? profilePath;
  final DateTime createdAt;

  const FollowedTalent({
    required this.id,
    required this.userId,
    required this.tmdbPersonId,
    required this.personName,
    required this.personType,
    this.profilePath,
    required this.createdAt,
  });

  bool get isActor => personType == 'actor';
  bool get isDirector => personType == 'director';

  factory FollowedTalent.fromJson(Map<String, dynamic> json) {
    return FollowedTalent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tmdbPersonId: json['tmdb_person_id'] as int,
      personName: json['person_name'] as String,
      personType: json['person_type'] as String? ?? 'actor',
      profilePath: json['profile_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'tmdb_person_id': tmdbPersonId,
        'person_name': personName,
        'person_type': personType,
        'profile_path': profilePath,
        'created_at': createdAt.toIso8601String(),
      };
}
