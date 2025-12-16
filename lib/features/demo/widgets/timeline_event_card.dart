import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/timeline_theme.dart';

class TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineTheme theme;

  const TimelineEventCard({
    super.key,
    required this.event,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with event type and timestamp
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.getColor('primary').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.getColor('primary').withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _formatEventType(event.eventType),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.getColor('primary'),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(event.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Title
            if (event.title != null) ...[
              Text(
                event.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Description
            if (event.description != null) ...[
              Text(
                event.description!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Custom Attributes (if any)
            if (event.customAttributes.isNotEmpty) ...[
              const Text(
                'Details:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: event.customAttributes.entries
                    .where((entry) => entry.value != null && entry.value != '')
                    .map((entry) => _buildAttributeChip(entry.key, entry.value))
                    .toList(),
              ),
            ],
            
            // Assets info
            if (event.assets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.attachment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.assets.length} ${event.assets.length == 1 ? 'asset' : 'assets'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeChip(String key, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.getColor('secondary').withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_formatAttributeName(key)}: ${_formatAttributeValue(value)}',
        style: TextStyle(
          fontSize: 12,
          color: theme.getColor('secondary'),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'photo':
        return 'Photo';
      case 'text':
        return 'Note';
      case 'mixed':
        return 'Mixed';
      case 'milestone':
        return 'Milestone';
      case 'pet_milestone':
        return 'Pet Milestone';
      case 'renovation_progress':
        return 'Renovation';
      case 'business_milestone':
        return 'Business Milestone';
      default:
        return eventType.toUpperCase();
    }
  }

  String _formatAttributeName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatAttributeValue(dynamic value) {
    if (value is double) {
      if (value == value.toInt()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
