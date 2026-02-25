import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/app_notification.dart';
import '../../social/controllers/watch_party_controller.dart';
import '../../social/screens/friend_list_screen.dart';
import '../controllers/notification_controller.dart';

/// Notification card for Watch Party events.
/// Handles: watch_party_invite (Accept/Decline), plus info cards for
/// watch_party_join, watch_party_progress, watch_party_deleted.
class WatchPartyNotificationCard extends StatelessWidget {
  final AppNotification notification;

  const WatchPartyNotificationCard({super.key, required this.notification});

  bool get _isInvite =>
      notification.type == NotificationType.watchPartyInvite;

  String get _partyId =>
      notification.data?['party_id']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? EColors.cardBackground
          : EColors.primary.withValues(alpha: 0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        side: notification.isRead
            ? BorderSide.none
            : const BorderSide(color: EColors.primary, width: 1),
      ),
      child: InkWell(
        onTap: _handleTap,
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
        const Icon(Icons.groups, size: 16, color: EColors.primary),
        const SizedBox(width: ESizes.xs),
        Text(
          _typeLabel,
          style: const TextStyle(
            fontSize: ESizes.fontSm,
            color: EColors.primary,
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
        if (_isInvite && _partyId.isNotEmpty)
          _buildInviteActions(),
      ],
    );
  }

  Widget _buildInviteActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _onAccept,
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
          onTap: _onDecline,
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
  }

  Future<void> _onAccept() async {
    final notifCtrl = Get.find<NotificationController>();
    await WatchPartyController.to.acceptInvite(_partyId);
    await notifCtrl.markAsRead(notification.id);
    await notifCtrl.loadNotifications();
  }

  Future<void> _onDecline() async {
    final notifCtrl = Get.find<NotificationController>();
    await WatchPartyController.to.declineInvite(_partyId);
    await notifCtrl.markAsRead(notification.id);
    await notifCtrl.loadNotifications();
  }

  void _handleTap() {
    if (!notification.isRead) {
      Get.find<NotificationController>().markAsRead(notification.id);
    }
    if (_isInvite) {
      Get.to(() => const FriendListScreen(initialTab: 1));
    }
  }

  String get _typeLabel {
    switch (notification.type) {
      case NotificationType.watchPartyInvite:
        return 'Watch Party Invite';
      case NotificationType.watchPartyJoin:
        return 'Watch Party';
      case NotificationType.watchPartyProgress:
        return 'Watch Party Update';
      case NotificationType.watchPartyDeleted:
        return 'Watch Party Ended';
      default:
        return 'Watch Party';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) {
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat.yMMMd().format(date);
  }
}
