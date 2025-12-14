import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

/// Notifications screen showing all app notifications
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedNotifications = ref.watch(groupedNotificationsProvider);
    final notificationService = ref.read(notificationServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (groupedNotifications.isNotEmpty)
            TextButton(
              onPressed: () => notificationService.markAllAsRead(),
              child: const Text('Mark All Read'),
            ),
          if (groupedNotifications.isNotEmpty)
            IconButton(
              onPressed: () {
                _showClearConfirmation(context, notificationService);
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: groupedNotifications.isEmpty
          ? _buildEmptyState(context)
          : _buildNotificationList(context, ref, groupedNotifications),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<dynamic>> groupedNotifications,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _getTotalItemCount(groupedNotifications),
      itemBuilder: (context, index) {
        return _buildItem(context, ref, groupedNotifications, index);
      },
    );
  }

  int _getTotalItemCount(Map<String, List<dynamic>> grouped) {
    int count = 0;
    for (final group in grouped.entries) {
      count++; // Header
      count += group.value.length; // Notifications
    }
    return count;
  }

  Widget _buildItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<dynamic>> grouped,
    int index,
  ) {
    int currentIndex = 0;

    for (final group in grouped.entries) {
      // Check if this is the header
      if (currentIndex == index) {
        return _buildGroupHeader(context, group.key);
      }
      currentIndex++;

      // Check if this is one of the notifications in this group
      final groupEndIndex = currentIndex + group.value.length;
      if (index < groupEndIndex) {
        final notificationIndex = index - currentIndex;
        return NotificationCard(
          notification: group.value[notificationIndex],
          onTap: () {
            final notification = group.value[notificationIndex];
            ref
                .read(notificationServiceProvider.notifier)
                .markAsRead(notification.id);
          },
          onDismiss: () {
            final notification = group.value[notificationIndex];
            ref
                .read(notificationServiceProvider.notifier)
                .removeNotification(notification.id);
          },
        );
      }
      currentIndex = groupEndIndex;
    }

    return const SizedBox.shrink();
  }

  Widget _buildGroupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showClearConfirmation(
    BuildContext context,
    dynamic service,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.clearAll();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
