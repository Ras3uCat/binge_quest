/// Represents a user's public profile from the `users` table.
/// Used for friend search results, friend cards, and co-owner display.
class UserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? username;
  final bool isPremium;
  final DateTime? createdAt;
  final String? primaryArchetype;
  final String? secondaryArchetype;

  const UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.username,
    this.isPremium = false,
    this.createdAt,
    this.primaryArchetype,
    this.secondaryArchetype,
  });

  /// Display-friendly name: username > displayName > 'User'.
  String get displayLabel =>
      username != null ? '@$username' : (displayName ?? 'User');

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      primaryArchetype: json['primary_archetype'] as String?,
      secondaryArchetype: json['secondary_archetype'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'username': username,
        'is_premium': isPremium,
      };
}
