import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification types supported by the app
enum NotificationType {
  info,
  success,
  warning,
  error,
  storySaved,
  eventCreated,
  mediaProcessed,
  faceDetected,
  timelineUpdate,
}

/// Notification data model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String? message;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    required this.createdAt,
    this.data,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'data': data,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'] as String,
      ),
      title: json['title'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// Service for managing app notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationController = 
      StreamController<List<AppNotification>>.broadcast();
  
  SharedPreferences? _prefs;
  static const String _notificationsKey = 'app_notifications';
  static const int _maxNotifications = 100;

  /// Initialize the notification service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNotifications();
  }

  /// Stream of notifications
  Stream<List<AppNotification>> get notificationsStream => 
      _notificationController.stream;

  /// Get all notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Get unread notifications count
  int get unreadCount => 
      _notifications.where((n) => !n.isRead).length;

  /// Add a new notification
  void addNotification({
    required NotificationType type,
    required String title,
    String? message,
    Map<String, dynamic>? data,
  }) {
    final notification = AppNotification(
      id: _generateId(),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, notification);
    
    // Limit the number of notifications
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(_maxNotifications, _notifications.length);
    }

    _saveNotifications();
    _notificationController.add(List.from(_notifications));

    // Log notification for debugging
    if (kDebugMode) {
      print('Notification added: ${notification.title}');
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _saveNotifications();
      _notificationController.add(List.from(_notifications));
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _saveNotifications();
    _notificationController.add(List.from(_notifications));
  }

  /// Delete a notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    _notificationController.add(List.from(_notifications));
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    _notificationController.add([]);
  }

  /// Show success notification
  void showSuccess(String title, [String? message]) {
    addNotification(
      type: NotificationType.success,
      title: title,
      message: message,
    );
  }

  /// Show error notification
  void showError(String title, [String? message]) {
    addNotification(
      type: NotificationType.error,
      title: title,
      message: message,
    );
  }

  /// Show info notification
  void showInfo(String title, [String? message]) {
    addNotification(
      type: NotificationType.info,
      title: title,
      message: message,
    );
  }

  /// Show warning notification
  void showWarning(String title, [String? message]) {
    addNotification(
      type: NotificationType.warning,
      title: title,
      message: message,
    );
  }

  /// Show story saved notification
  void showStorySaved(String storyTitle) {
    addNotification(
      type: NotificationType.storySaved,
      title: 'Story Saved',
      message: 'Your story "$storyTitle" has been saved successfully.',
    );
  }

  /// Show event created notification
  void showEventCreated(String eventTitle) {
    addNotification(
      type: NotificationType.eventCreated,
      title: 'Event Created',
      message: 'New event "$eventTitle" has been added to your timeline.',
    );
  }

  /// Show media processed notification
  void showMediaProcessed(int count) {
    addNotification(
      type: NotificationType.mediaProcessed,
      title: 'Media Processed',
      message: '$count media files have been processed successfully.',
    );
  }

  /// Show face detected notification
  void showFaceDetected(int faceCount, String eventName) {
    addNotification(
      type: NotificationType.faceDetected,
      title: 'Faces Detected',
      message: '$faceCount faces detected in event "$eventName".',
    );
  }

  /// Show timeline update notification
  void showTimelineUpdate(String updateType) {
    addNotification(
      type: NotificationType.timelineUpdate,
      title: 'Timeline Updated',
      message: 'Your timeline has been updated with new $updateType.',
    );
  }

  /// Load notifications from storage
  Future<void> _loadNotifications() async {
    if (_prefs == null) return;

    final notificationsJson = _prefs!.getStringList(_notificationsKey) ?? [];
    _notifications = notificationsJson
        .map((json) => AppNotification.fromJson(
              Map<String, dynamic>.from(
                // Simple JSON decode - in production use proper JSON parsing
                Map<String, String>.fromEntries(
                  json.split(',').map((e) => e.split(':')),
                ),
              ),
            ))
        .toList();
    
    _notificationController.add(List.from(_notifications));
  }

  /// Save notifications to storage
  Future<void> _saveNotifications() async {
    if (_prefs == null) return;

    final notificationsJson = _notifications
        .map((n) => n.toString())
        .toList();
    
    await _prefs!.setStringList(_notificationsKey, notificationsJson);
  }

  /// Generate unique notification ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}

/// Error handling utilities
class ErrorHandler {
  static final NotificationService _notificationService = NotificationService();

  /// Handle and log errors
  static void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = true,
  }) {
    // Log error for debugging
    if (kDebugMode) {
      print('Error${context != null ? ' in $context' : ''}: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    // Show user-friendly notification
    if (showToUser) {
      _notificationService.showError(
        'Something went wrong',
        _getUserFriendlyMessage(error),
      );
    }

    // Report to analytics/crashlytics in production
    // TODO: Implement error reporting service
  }

  /// Handle network errors
  static void handleNetworkError(dynamic error, {String? operation}) {
    final context = operation ?? 'network request';
    ErrorHandler.handleError(
      error,
      context: context,
      showToUser: true,
    );
  }

  /// Handle database errors
  static void handleDatabaseError(dynamic error, {String? operation}) {
    final context = operation ?? 'database operation';
    ErrorHandler.handleError(
      error,
      context: context,
      showToUser: true,
    );
  }

  /// Handle media processing errors
  static void handleMediaError(dynamic error, {String? mediaType}) {
    final context = 'media processing${mediaType != null ? ' for $mediaType' : ''}';
    ErrorHandler.handleError(
      error,
      context: context,
      showToUser: false, // Don't show every media error to user
    );
  }

  /// Convert technical errors to user-friendly messages
  static String _getUserFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'Please check your internet connection and try again.';
    }
    
    if (error is TimeoutException) {
      return 'The operation timed out. Please try again.';
    }
    
    if (error.toString().contains('permission')) {
      return 'Permission denied. Please check your app settings.';
    }
    
    if (error.toString().contains('storage')) {
      return 'Storage error. Please free up some space and try again.';
    }
    
    // Default message
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Mixin for error handling in widgets and services
mixin ErrorHandlingMixin {
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    ErrorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
    );
  }
}
