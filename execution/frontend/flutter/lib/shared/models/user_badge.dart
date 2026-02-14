import 'badge.dart';

/// UserBadge model linking a user to an earned badge.
class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final Badge? badge;

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    Badge? badge;
    if (json['badges'] != null) {
      badge = Badge.fromJson(json['badges'] as Map<String, dynamic>);
    }

    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      badge: badge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  UserBadge copyWith({
    String? id,
    String? userId,
    String? badgeId,
    DateTime? earnedAt,
    Badge? badge,
  }) {
    return UserBadge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      badge: badge ?? this.badge,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
