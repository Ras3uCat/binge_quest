import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/e_colors.dart';
import '../../core/constants/e_sizes.dart';
import '../models/friend_watching.dart';

class FriendsWatchingRow extends StatelessWidget {
  final List<FriendWatching> friends;
  final double avatarSize;
  final double overlapOffset;

  const FriendsWatchingRow({
    super.key,
    required this.friends,
    this.avatarSize = 20.0,
    this.overlapOffset = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayFriends = friends.take(3).toList();

    return Row(
      children: [
        _buildAvatarStack(displayFriends),
        const SizedBox(width: ESizes.sm),
        Expanded(
          child: Text(
            _getLabelText(friends),
            style: const TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSm,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStack(List<FriendWatching> displayFriends) {
    return SizedBox(
      width: avatarSize + (displayFriends.length - 1) * overlapOffset,
      height: avatarSize,
      child: Stack(
        children: List.generate(displayFriends.length, (index) {
          final friend = displayFriends[index];
          return Positioned(
            left: index * overlapOffset,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EColors
                      .background, // Match background to create "cutout" effect
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: friend.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: friend.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildPlaceholder(),
                        placeholder: (context, url) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: EColors.surfaceLight,
      child: const Icon(
        Icons.person,
        size: 12, // Scaled down for small avatar
        color: EColors.textSecondary,
      ),
    );
  }

  String _getLabelText(List<FriendWatching> allFriends) {
    if (allFriends.isEmpty) return '';

    final firstFriend = allFriends[0];

    if (allFriends.length == 1) {
      return '${firstFriend.displayLabel} is also watching';
    } else if (allFriends.length == 2) {
      final secondFriend = allFriends[1];
      return '${firstFriend.displayLabel} & ${secondFriend.displayLabel} are watching';
    } else {
      return '${firstFriend.displayLabel} & ${allFriends.length - 1} more friends watching';
    }
  }
}
