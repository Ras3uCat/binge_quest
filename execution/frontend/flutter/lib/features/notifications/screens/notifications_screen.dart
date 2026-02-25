import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_controller.dart';
import '../widgets/social_notification_card.dart';
import '../widgets/talent_notification_card.dart';
import '../widgets/watch_party_notification_card.dart';
import '../../../../core/constants/e_colors.dart';
import '../../../../shared/models/app_notification.dart';
import '../../../../shared/models/watchlist_item.dart';
import '../../../../shared/repositories/watchlist_repository.dart';
import '../../../../shared/widgets/e_confirm_dialog.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../../search/screens/person_detail_screen.dart';

class NotificationsScreen extends GetView<NotificationController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            if (controller.notifications.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: _confirmClearAll,
              child: const Text(
                'Clear All',
                style: TextStyle(color: EColors.error),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => controller.markAllAsRead(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadNotifications(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              final Widget card;

              if (notification.type == NotificationType.talentReleases) {
                card = TalentNotificationCard(notification: notification);
              } else if (notification.type == NotificationType.social) {
                card = SocialNotificationCard(notification: notification);
              } else if (notification.type.isWatchParty) {
                card = WatchPartyNotificationCard(notification: notification);
              } else {
                card = _buildDefaultCard(notification);
              }

              return _buildDismissible(notification, card);
            },
          ),
        );
      }),
    );
  }

  Widget _buildDismissible(AppNotification notification, Widget child) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.removeNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: EColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: EColors.error),
      ),
      child: child,
    );
  }

  void _confirmClearAll() {
    final count = controller.notifications.length;
    EConfirmDialog.show(
      title: 'Clear all notifications?',
      message:
          'This will permanently remove all $count notification${count == 1 ? '' : 's'}.',
      confirmLabel: 'Clear All',
      isDestructive: true,
      onConfirm: () => controller.clearAllNotifications(),
    );
  }

  Widget _buildDefaultCard(AppNotification notification) {
    return Card(
      color: notification.isRead
          ? EColors.cardBackground
          : EColors.primary.withOpacity(0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : const BorderSide(color: EColors.primary, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          notification.title,
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(notification.createdAt),
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!notification.isRead) {
            await controller.markAsRead(notification.id);
          }
          _handleDeepLink(notification);
        },
      ),
    );
  }

  Future<void> _handleDeepLink(AppNotification notification) async {
    if (!notification.hasDeepLink) return;

    final data = notification.data!;
    final tmdbId = int.tryParse(data['tmdb_id']?.toString() ?? '');
    final mediaType = data['media_type'] as String?;
    final personId = int.tryParse(data['person_id']?.toString() ?? '');

    if (tmdbId != null && mediaType != null) {
      final item = await WatchlistRepository.getItemByTmdbId(
        tmdbId: tmdbId,
        mediaType: mediaType == 'movie' ? MediaType.movie : MediaType.tv,
      );
      if (item != null) {
        Get.to(() => ItemDetailScreen(item: item));
        return;
      }
    }

    if (personId != null) {
      Get.to(() => PersonDetailScreen(personId: personId));
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
