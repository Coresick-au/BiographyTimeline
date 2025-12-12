import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_event.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Event card widget for personal context events
class PersonalEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PersonalEventCard({
    Key? key,
    required this.event,
    required this.theme,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildContent(),
              if (event.customAttributes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildCustomAttributes(),
              ],
              if (event.assets.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMediaPreview(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.getColor('primary').withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _getEventIcon(),
            color: theme.getColor('primary'),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.title != null)
                Text(
                  event.title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                _formatTimestamp(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null || onDelete != null)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (event.description != null && event.description!.isNotEmpty) {
      return Text(
        event.description!,
        style: const TextStyle(fontSize: 14),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCustomAttributes() {
    final attributes = event.customAttributes;
    if (attributes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.eventType == 'milestone' && attributes['milestone_type'] != null)
          _buildAttributeChip(
            'Milestone',
            attributes['milestone_type'],
            Icons.flag,
          ),
        if (event.eventType == 'travel' && attributes['destination'] != null)
          _buildAttributeChip(
            'Destination',
            attributes['destination'],
            Icons.flight,
          ),
      ],
    );
  }

  Widget _buildAttributeChip(String label, dynamic value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.getColor('secondary').withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.getColor('secondary')),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: theme.getColor('secondary'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final photoCount = event.assets.length;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_library,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon() {
    switch (event.eventType) {
      case 'milestone':
        return Icons.flag;
      case 'travel':
        return Icons.flight;
      case 'celebration':
        return Icons.celebration;
      case 'photo':
        return Icons.photo;
      case 'text':
        return Icons.text_fields;
      default:
        return Icons.event;
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(event.timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}';
    }
  }
}