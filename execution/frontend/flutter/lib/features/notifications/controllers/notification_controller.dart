import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/models/notification_preferences.dart';
import '../../../shared/repositories/notification_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository = NotificationRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  final Rxn<NotificationPreferences> preferences =
      Rxn<NotificationPreferences>();
  final RxBool isUpdatingPreferences = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen to foreground messages from service
    // We use lazy retrieval or ensure service is init
    final notificationService = Get.find<NotificationService>();
    ever(notificationService.foregroundMessage, (_) => loadNotifications());

    // Load notifications and preferences when user changes or on init if user exists
    ever(_authController.userRx, (user) {
      if (user != null) {
        loadNotifications();
        loadPreferences();
      } else {
        notifications.clear();
        preferences.value = null;
        unreadCount.value = 0;
      }
    });

    if (_authController.userRx.value != null) {
      loadNotifications();
      loadPreferences();
    }
  }

  Future<void> loadPreferences() async {
    final userId = _authController.userRx.value?.id;
    if (userId == null) return;

    try {
      final fetchedPreferences = await _repository.getPreferences(userId);
      preferences.value = fetchedPreferences;
    } catch (e) {
      // ignore
    }
  }

  Future<void> updatePreferences(NotificationPreferences newPreferences) async {
    isUpdatingPreferences.value = true;
    try {
      await _repository.updatePreferences(newPreferences);
      preferences.value = newPreferences;
    } catch (e) {
      // Revert or show error
      Get.snackbar('Error', 'Failed to update preferences');
    } finally {
      isUpdatingPreferences.value = false;
    }
  }

  Future<void> loadNotifications() async {
    final userId = _authController.userRx.value?.id;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final fetchedNotifications = await _repository.getNotifications(
        userId: userId,
      );
      notifications.assignAll(fetchedNotifications);

      final count = await _repository.getUnreadCount(userId);
      unreadCount.value = count;
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      // Update local state optimistic
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = notifications[index];
        if (!notification.isRead) {
          notifications[index] = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
        }
      }
    } catch (e) {
      // Revert if needed, or just reload
      loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _authController.userRx.value?.id;
    if (userId == null) return;

    try {
      await _repository.markAllAsRead(userId);

      // Update local state
      for (var i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      unreadCount.value = 0;
    } catch (e) {
      loadNotifications();
    }
  }

  Future<void> sendTestNotification() async {
    try {
      final service = Get.find<NotificationService>();
      await service.sendTestNotification();
    } catch (e) {
      Get.snackbar('Error', 'Failed to invoke test notification: $e');
    }
  }
}
