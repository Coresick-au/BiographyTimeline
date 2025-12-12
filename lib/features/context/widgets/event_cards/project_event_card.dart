import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_event.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Event card widget for project context events
class ProjectEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectEventCard({
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
        if (_shouldShowProgressIndicator())
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 12,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 2),
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
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
        if (event.eventType == 'renovation_progress') ...[
          Row(
            children: [
              if (attributes['room'] != null)
                Expanded(
                  child: _buildAttributeChip(
                    'Room',
                    attributes['room'],
                    Icons.home,
                    Colors.blue,
                  ),
                ),
              if (attributes['phase'] != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'Phase',
                    attributes['phase'],
                    Icons.construction,
                    Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (event.eventType == 'budget_update') ...[
          Row(
            children: [
              if (attributes['cost'] != null)
                Expanded(
                  child: _buildAttributeChip(
                    'Cost',
                    '\$${attributes['cost']}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              if (attributes['contractor'] != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'Contractor',
                    attributes['contractor'],
                    Icons.person,
                    Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (event.eventType == 'milestone' && attributes['milestone_type'] != null)
          _buildAttributeChip(
            'Milestone',
            attributes['milestone_type'],
            Icons.flag,
            Colors.red,
          ),
      ],
    );
  }

  Widget _buildAttributeChip(String label, dynamic value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
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
        color: theme.getColor('primary').withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.getColor('primary').withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_library,
            size: 16,
            color: theme.getColor('primary'),
          ),
          const SizedBox(width: 4),
          Text(
            '$photoCount ${photoCount == 1 ? 'photo' : 'photos'}',
            style: TextStyle(
              fontSize: 12,
              color: theme.getColor('primary'),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (event.eventType == 'renovation_progress') ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Before/After',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowProgressIndicator() {
    return event.eventType == 'renovation_progress' || 
           event.eventType == 'milestone' ||
           event.eventType == 'completion';
  }

  IconData _getEventIcon() {
    switch (event.eventType) {
      case 'renovation_progress':
        return Icons.construction;
      case 'budget_update':
        return Icons.attach_money;
      case 'milestone':
        return Icons.flag;
      case 'completion':
        return Icons.check_circle;
      case 'photo':
        return Icons.photo_camera;
      case 'text':
        return Icons.text_fields;
      default:
        return Icons.construction;
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