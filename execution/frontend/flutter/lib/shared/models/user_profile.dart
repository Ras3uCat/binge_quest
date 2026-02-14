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

  const UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.username,
    this.isPremium = false,
    this.createdAt,
  });

  /// Display-friendly name: displayName > username > 'User'.
  String get displayLabel =>
      displayName ?? (username != null ? '@$username' : 'User');

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
