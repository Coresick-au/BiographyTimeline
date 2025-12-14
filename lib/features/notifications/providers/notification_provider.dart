import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../../shared/models/app_notification.dart';

/// Provider for notification service
final notificationServiceProvider =
    StateNotifierProvider<NotificationService, List<AppNotification>>((ref) {
  return NotificationService();
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationServiceProvider);
  return notifications.where((n) => !n.isRead).length;
});

/// Provider for grouped notifications
final groupedNotificationsProvider =
    Provider<Map<String, List<AppNotification>>>((ref) {
  final service = ref.read(notificationServiceProvider.notifier);
  return service.getGroupedNotifications();
});
