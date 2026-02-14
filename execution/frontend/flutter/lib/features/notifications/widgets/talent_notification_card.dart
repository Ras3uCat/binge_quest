import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/repositories/watchlist_repository.dart';
import '../../search/widgets/content_detail_sheet.dart';
import '../../watchlist/screens/item_detail_screen.dart';
import '../controllers/notification_controller.dart';
import '../helpers/quick_add_helper.dart';

/// Specialized notification card for talent release notifications.
/// Shows person name, content title, media type badge, and quick-add option.
class TalentNotificationCard extends StatelessWidget {
  final AppNotification notification;

  const TalentNotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification.data ?? {};
    final personName = data['person_name'] as String? ?? '';
    final mediaType = data['media_type'] as String? ?? 'movie';

    return Card(
      color: notification.isRead
          ? EColors.cardBackground
          : EColors.secondary.withValues(alpha: 0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        side: notification.isRead
            ? BorderSide.none
            : const BorderSide(color: EColors.secondary, width: 1),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(ESizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(ESizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(personName, mediaType),
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

  Widget _buildTopRow(String personName, String mediaType) {
    return Row(
      children: [
        const Icon(Icons.person, size: 16, color: EColors.secondary),
        const SizedBox(width: ESizes.xs),
        Expanded(
          child: Text(
            personName,
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              color: EColors.secondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildMediaTypeBadge(mediaType),
      ],
    );
  }

  Widget _buildMediaTypeBadge(String mediaType) {
    final isMovie = mediaType == 'movie';
    final color = isMovie ? EColors.accent : EColors.primary;
    final label = isMovie ? 'Movie' : 'TV';
    final icon = isMovie ? Icons.movie : Icons.tv;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ESizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: ESizes.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: ESizes.fontXs,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      notification.title,
      style: TextStyle(
        fontSize: ESizes.fontMd,
        fontWeight:
            notification.isRead ? FontWeight.normal : FontWeight.bold,
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
        _buildQuickAddButton(),
      ],
    );
  }

  Widget _buildQuickAddButton() {
    final data = notification.data ?? {};
    final tmdbId = int.tryParse(data['tmdb_id']?.toString() ?? '');
    if (tmdbId == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _handleQuickAdd(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.sm,
          vertical: ESizes.xs,
        ),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(ESizes.radiusSm),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: EColors.primary),
            SizedBox(width: ESizes.xs),
            Text(
              'Add to Watchlist',
              style: TextStyle(
                fontSize: ESizes.fontXs,
                color: EColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (!notification.isRead) {
      final controller = Get.find<NotificationController>();
      await controller.markAsRead(notification.id);
    }
    _navigateToContent();
  }

  Future<void> _navigateToContent() async {
    final data = notification.data ?? {};
    final tmdbId = int.tryParse(data['tmdb_id']?.toString() ?? '');
    final mediaType = data['media_type'] as String?;

    if (tmdbId == null || mediaType == null) return;

    final mType = mediaType == 'movie' ? MediaType.movie : MediaType.tv;

    // If item is in a watchlist, navigate to its detail screen
    final item = await WatchlistRepository.getItemByTmdbId(
      tmdbId: tmdbId,
      mediaType: mType,
    );

    if (item != null) {
      Get.to(() => ItemDetailScreen(item: item));
    } else {
      // Show content detail sheet (includes add-to-watchlist button)
      final result = TmdbSearchResult(
        id: tmdbId,
        titleField: notification.data?['content_title'] as String?,
        mediaTypeString: mediaType,
        voteAverage: 0,
      );
      Get.bottomSheet(
        ContentDetailSheet(result: result),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  /// Quick-add button handler: delegates to QuickAddHelper.
  Future<void> _handleQuickAdd() async {
    final data = notification.data ?? {};
    final tmdbId = int.tryParse(data['tmdb_id']?.toString() ?? '');
    final mediaType = data['media_type'] as String?;
    final contentTitle = data['content_title'] as String? ?? notification.title;

    if (tmdbId == null || mediaType == null) return;

    await QuickAddHelper.quickAddToWatchlist(
      tmdbId: tmdbId,
      mediaType: mediaType,
      contentTitle: contentTitle,
    );
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
