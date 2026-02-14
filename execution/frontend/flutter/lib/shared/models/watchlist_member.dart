import 'user_profile.dart';

/// Represents a co-owner membership on a watchlist.
/// The [user] field is populated by the repository after a profile lookup.
class WatchlistMember {
  final String id;
  final String watchlistId;
  final String userId;
  final String role;
  final String invitedBy;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final UserProfile? user;

  const WatchlistMember({
    required this.id,
    required this.watchlistId,
    required this.userId,
    required this.role,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.user,
  });

  /// Wraps [isOwner] with new terminology.
  bool get isCurator => role == 'owner';

  /// Wraps [isCoOwner] with new terminology.
  bool get isCoCurator => role == 'co_owner';

  @Deprecated('Use isCurator instead')
  bool get isOwner => role == 'owner';

  @Deprecated('Use isCoCurator instead')
  bool get isCoOwner => role == 'co_owner';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory WatchlistMember.fromJson(
    Map<String, dynamic> json, {
    UserProfile? user,
  }) {
    return WatchlistMember(
      id: json['id'] as String,
      watchlistId: json['watchlist_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      invitedBy: json['invited_by'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      user: user,
    );
  }
}
