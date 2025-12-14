import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/app_notification.dart';

/// Notification service for managing in-app notifications
class NotificationService extends StateNotifier<List<AppNotification>> {
  NotificationService() : super([]) {
    _addWelcomeNotification();
  }

  final _uuid = const Uuid();

  /// Add a new notification
  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  /// Add a simple info notification
  void addInfo(String title, String message, {String? actionRoute}) {
    addNotification(AppNotification.info(
      id: _uuid.v4(),
      title: title,
      message: message,
      actionRoute: actionRoute,
    ));
  }

  /// Add a success notification
  void addSuccess(String title, String message, {String? actionRoute}) {
    addNotification(AppNotification.success(
      id: _uuid.v4(),
      title: title,
      message: message,
      actionRoute: actionRoute,
    ));
  }

  /// Add a warning notification
  void addWarning(String title, String message, {String? actionRoute}) {
    addNotification(AppNotification.warning(
      id: _uuid.v4(),
      title: title,
      message: message,
      actionRoute: actionRoute,
    ));
  }

  /// Add an error notification
  void addError(String title, String message, {String? actionRoute}) {
    addNotification(AppNotification.error(
      id: _uuid.v4(),
      title: title,
      message: message,
      actionRoute: actionRoute,
    ));
  }

  /// Mark notification as read
  void markAsRead(String id) {
    state = state.map((notification) {
      if (notification.id == id) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    state = state.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();
  }

  /// Remove a notification
  void removeNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
  }

  /// Clear all notifications
  void clearAll() {
    state = [];
  }

  /// Get unread count
  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Get notifications grouped by date
  Map<String, List<AppNotification>> getGroupedNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final notification in state) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (notificationDate == today) {
        grouped['Today']!.add(notification);
      } else if (notificationDate == yesterday) {
        grouped['Yesterday']!.add(notification);
      } else {
        grouped['Earlier']!.add(notification);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  /// Add welcome notification on first launch
  void _addWelcomeNotification() {
    addInfo(
      'Welcome to Timeline Biography!',
      'Start creating your life story by adding events, photos, and memories.',
    );
  }
}
