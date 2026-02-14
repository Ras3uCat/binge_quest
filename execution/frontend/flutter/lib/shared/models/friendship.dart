import 'user_profile.dart';

/// Represents a friendship row (symmetric, single-row per relationship).
/// The [friend] field is populated by the repository after a profile lookup.
class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? friend;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.friend,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  /// Whether the current user sent this request.
  bool isSentBy(String userId) => requesterId == userId;

  /// Whether the current user received this request.
  bool isReceivedBy(String userId) => addresseeId == userId;

  /// Get the other user's ID given the current user's ID.
  String friendId(String currentUserId) =>
      requesterId == currentUserId ? addresseeId : requesterId;

  factory Friendship.fromJson(
    Map<String, dynamic> json, {
    UserProfile? friend,
  }) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      friend: friend,
    );
  }
}
