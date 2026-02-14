import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/app_notification.dart';
import '../../social/controllers/friend_controller.dart';
import '../../social/screens/friend_list_screen.dart';
import '../../watchlist/controllers/watchlist_member_controller.dart';
import '../controllers/notification_controller.dart';

/// Notification card for social events (friend requests, co-curator invites, etc).
class SocialNotificationCard extends StatelessWidget {
  final AppNotification notification;

  const SocialNotificationCard({super.key, required this.notification});

  String get _socialType => notification.data?['type'] as String? ?? 'unknown';

  bool get _isFriendRequest => _socialType == 'friend_request';
  bool get _isCoOwnerInvite => _socialType == 'co_owner_invite';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? EColors.cardBackground
          : EColors.tertiary.withValues(alpha: 0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        side: notification.isRead
            ? BorderSide.none
            : const BorderSide(color: EColors.tertiary, width: 1),
      ),
      child: InkWell(
        onTap: () => _handleTap(),
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(ESizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(),
              const SizedBox(height: ESizes.sm),
              _buildTitle(),
              const SizedBox(height: ESizes.xs),
              _buildBody(),
              const SizedBox(height: ESizes.sm),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        const Icon(Icons.people, size: 16, color: EColors.tertiary),
        const SizedBox(width: ESizes.xs),
        Text(
          _isFriendRequest
              ? 'Friend Request'
              : _isCoOwnerInvite
              ? 'Co-Curator Invite'
              : 'Social',
          style: const TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.tertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      notification.title,
      style: TextStyle(
        fontSize: ESizes.fontMd,
        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        color: EColors.textPrimary,
      ),
    );
  }

  Widget _buildBody() {
    return Text(
      notification.body,
      style: TextStyle(
        fontSize: ESizes.fontSm,
        color: EColors.textSecondary.withValues(alpha: 0.8),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Text(
          _formatDate(notification.createdAt),
          style: const TextStyle(
            fontSize: ESizes.fontXs,
            color: EColors.textTertiary,
          ),
        ),
        const Spacer(),
        if (_isFriendRequest && !notification.isRead) _buildViewButton(),
        if (_isCoOwnerInvite) _buildInviteActions(),
      ],
    );
  }

  Widget _buildViewButton() {
    return GestureDetector(
      onTap: () => Get.to(() => const FriendListScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.sm,
          vertical: ESizes.xs,
        ),
        decoration: BoxDecoration(
          color: EColors.tertiary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add, size: 14, color: EColors.tertiary),
            SizedBox(width: ESizes.xs),
            Text(
              'View Requests',
              style: TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteActions() {
    return Obx(() {
      final ctrl = WatchlistMemberController.to;
      final invite = ctrl.pendingInvites
          .where((i) => i.watchlistId == notification.data?['watchlist_id'])
          .firstOrNull;

      if (invite == null) {
        return const Text(
          'Responded',
          style: TextStyle(
            fontSize: ESizes.fontXs,
            color: EColors.textTertiary,
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              ctrl.acceptInvite(invite);
              Get.find<NotificationController>().markAsRead(notification.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.sm,
                vertical: ESizes.xs,
              ),
              decoration: BoxDecoration(
                color: EColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: ESizes.fontXs,
                  color: EColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          GestureDetector(
            onTap: () {
              ctrl.declineInvite(invite);
              Get.find<NotificationController>().markAsRead(notification.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.sm,
                vertical: ESizes.xs,
              ),
              decoration: BoxDecoration(
                color: EColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(ESizes.radiusSm),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(
                  fontSize: ESizes.fontXs,
                  color: EColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _handleTap() {
    if (!notification.isRead) {
      Get.find<NotificationController>().markAsRead(notification.id);
    }
    if (_isFriendRequest) {
      if (Get.isRegistered<FriendController>()) {
        FriendController.to.refresh();
      }
      Get.to(() => const FriendListScreen());
    } else if (_isCoOwnerInvite) {
      WatchlistMemberController.to.refresh();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays < 1) {
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat.yMMMd().format(date);
  }
}
