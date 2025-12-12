import 'package:flutter/material.dart';
import '../../../../shared/models/context.dart';

/// Card widget for displaying a context in the management interface
class ContextCard extends StatelessWidget {
  final Context context;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContextCard({
    Key? key,
    required this.context,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contextColor = _getContextColor(this.context.type);
    
    return Card(
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: contextColor, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: contextColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getContextIcon(this.context.type),
                      color: contextColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          this.context.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getContextTypeDisplayName(this.context.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: contextColor,
                      size: 20,
                    ),
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
              ),
              if (this.context.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  this.context.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildFeatureChips(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${_formatDate(this.context.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    final enabledFeatures = context.moduleConfiguration.entries
        .where((entry) => entry.value == true)
        .take(3) // Show only first 3 features to avoid overflow
        .map((entry) => _getFeatureDisplayName(entry.key))
        .toList();

    if (enabledFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...enabledFeatures.map((feature) => Chip(
              label: Text(
                feature,
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: _getContextColor(context.type).withOpacity(0.1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
        if (context.moduleConfiguration.entries.where((e) => e.value == true).length > 3)
          Chip(
            label: Text(
              '+${context.moduleConfiguration.entries.where((e) => e.value == true).length - 3}',
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: Colors.grey.withOpacity(0.1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Color _getContextColor(ContextType type) {
    switch (type) {
      case ContextType.person:
        return Colors.blue;
      case ContextType.pet:
        return Colors.green;
      case ContextType.project:
        return Colors.orange;
      case ContextType.business:
        return Colors.indigo;
    }
  }

  IconData _getContextIcon(ContextType type) {
    switch (type) {
      case ContextType.person:
        return Icons.person;
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.construction;
      case ContextType.business:
        return Icons.business;
    }
  }

  String _getContextTypeDisplayName(ContextType type) {
    switch (type) {
      case ContextType.person:
        return 'Personal Life';
      case ContextType.pet:
        return 'Pet Timeline';
      case ContextType.project:
        return 'Project Progress';
      case ContextType.business:
        return 'Business Journey';
    }
  }

  String _getFeatureDisplayName(String featureKey) {
    switch (featureKey) {
      case 'enableGhostCamera':
        return 'Ghost Camera';
      case 'enableBudgetTracking':
        return 'Budget';
      case 'enableProgressComparison':
        return 'Progress';
      case 'enableMilestoneTracking':
        return 'Milestones';
      case 'enableLocationTracking':
        return 'Location';
      case 'enableFaceDetection':
        return 'Faces';
      case 'enableWeightTracking':
        return 'Weight';
      case 'enableVetVisitTracking':
        return 'Vet Visits';
      case 'enableTaskTracking':
        return 'Tasks';
      case 'enableTeamTracking':
        return 'Team';
      case 'enableRevenueTracking':
        return 'Revenue';
      default:
        return featureKey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}