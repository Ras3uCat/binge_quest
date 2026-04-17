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
  final bool shareWatchingActivity;

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
    this.shareWatchingActivity = true,
  });

  /// Display-friendly name: username > displayName (if real) > 'Apple User' > 'User'.
  /// Suppresses Apple "Hide My Email" relay addresses from surfacing as display names.
  String get displayLabel {
    if (username != null) return '@$username';
    if (email?.contains('@privaterelay.appleid.com') == true) {
      if (displayName != null && displayName!.contains(' ')) return displayName!;
      return 'Apple User';
    }
    return displayName ?? 'User';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      primaryArchetype: json['primary_archetype'] as String?,
      secondaryArchetype: json['secondary_archetype'] as String?,
      shareWatchingActivity: json['share_watching_activity'] as bool? ?? true,
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
