import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_event.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Event card widget for business context events
class BusinessEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BusinessEventCard({
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
        if (_shouldShowMetricIndicator())
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 12,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 2),
                Text(
                  'Growth',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
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
        if (event.eventType == 'revenue_update' && attributes['revenue'] != null)
          _buildMetricCard(
            'Revenue',
            '\$${_formatNumber(attributes['revenue'])}',
            Icons.trending_up,
            Colors.green,
          ),
        if (event.eventType == 'team_update') ...[
          Row(
            children: [
              if (attributes['team_size'] != null)
                Expanded(
                  child: _buildAttributeChip(
                    'Team Size',
                    '${attributes['team_size']} people',
                    Icons.group,
                    Colors.blue,
                  ),
                ),
              if (attributes['new_hires'] != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'New Hires',
                    attributes['new_hires'],
                    Icons.person_add,
                    Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (event.eventType == 'business_milestone' && attributes['milestone'] != null)
          _buildMetricCard(
            'Milestone',
            attributes['milestone'],
            Icons.flag,
            Colors.orange,
          ),
        if (event.eventType == 'launch' && attributes['product_name'] != null)
          _buildMetricCard(
            'Product Launch',
            attributes['product_name'],
            Icons.rocket_launch,
            Colors.red,
          ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          if (event.eventType == 'revenue_update' || event.eventType == 'team_update') ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.indigo[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowMetricIndicator() {
    return event.eventType == 'revenue_update' || 
           event.eventType == 'team_update' ||
           event.eventType == 'business_milestone';
  }

  IconData _getEventIcon() {
    switch (event.eventType) {
      case 'business_milestone':
        return Icons.business;
      case 'revenue_update':
        return Icons.trending_up;
      case 'team_update':
        return Icons.group;
      case 'launch':
        return Icons.rocket_launch;
      case 'photo':
        return Icons.photo;
      case 'text':
        return Icons.text_fields;
      default:
        return Icons.business;
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    if (number is int) return number.toString();
    if (number is double) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      } else {
        return number.toStringAsFixed(0);
      }
    }
    return number.toString();
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