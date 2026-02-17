class FriendWatching {
  final String userId;
  final String displayName;
  final String username;
  final String? avatarUrl;

  /// Prefer username, fall back to displayName.
  String get displayLabel =>
      username.isNotEmpty ? '@$username' : displayName;

  FriendWatching({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
  });

  factory FriendWatching.fromJson(Map<String, dynamic> json) {
    return FriendWatching(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Unknown',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
