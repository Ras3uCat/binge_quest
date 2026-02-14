import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/friendship.dart';

/// Card displaying a friend request with accept/decline buttons,
/// or a sent request with a cancel option.
class FriendRequestCard extends StatelessWidget {
  final Friendship friendship;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  const FriendRequestCard({
    super.key,
    required this.friendship,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    this.onTap,
  });

  bool get _isReceived => onAccept != null;

  @override
  Widget build(BuildContext context) {
    final friend = friendship.friend;
    final name = friend?.displayName ?? 'Unknown';
    final handle = friend?.username != null ? '@${friend!.username}' : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ESizes.md),
      child: Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.md),
        ),
        child: Row(
          children: [
            _buildAvatar(friend?.avatarUrl),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: EColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: ESizes.fontMd,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      handle,
                      style: const TextStyle(
                        color: EColors.textSecondary,
                        fontSize: ESizes.fontSm,
                      ),
                    ),
                ],
              ),
            ),
            if (_isReceived) ...[
              IconButton(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle, color: EColors.success),
                tooltip: 'Accept',
              ),
              IconButton(
                onPressed: onDecline,
                icon: const Icon(Icons.cancel, color: EColors.error),
                tooltip: 'Decline',
              ),
            ] else if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: EColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: EColors.surfaceLight,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? const Icon(Icons.person, color: EColors.textSecondary)
          : null,
    );
  }
}
