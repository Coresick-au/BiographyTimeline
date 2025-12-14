/// Notification types
enum NotificationType {
  info,
  success,
  warning,
  error,
}

/// App notification model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? actionData;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.actionData,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionData: actionData ?? this.actionData,
    );
  }

  /// Helper constructors for common notification types
  factory AppNotification.info({
    required String id,
    required String title,
    required String message,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: NotificationType.info,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionData: actionData,
    );
  }

  factory AppNotification.success({
    required String id,
    required String title,
    required String message,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: NotificationType.success,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionData: actionData,
    );
  }

  factory AppNotification.warning({
    required String id,
    required String title,
    required String message,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: NotificationType.warning,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionData: actionData,
    );
  }

  factory AppNotification.error({
    required String id,
    required String title,
    required String message,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: NotificationType.error,
      timestamp: DateTime.now(),
      actionRoute: actionRoute,
      actionData: actionData,
    );
  }
}
