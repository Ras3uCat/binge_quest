import 'user_profile.dart';

/// Represents a user block. The [blockedUser] field is populated
/// by the repository after a profile lookup.
class UserBlock {
  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;
  final UserProfile? blockedUser;

  const UserBlock({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
    this.blockedUser,
  });

  factory UserBlock.fromJson(
    Map<String, dynamic> json, {
    UserProfile? blockedUser,
  }) {
    return UserBlock(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedId: json['blocked_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      blockedUser: blockedUser,
    );
  }
}
