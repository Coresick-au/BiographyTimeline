import 'package:flutter/material.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';

class ContextCard extends StatelessWidget {
  final Context context;
  final TimelineTheme theme;

  const ContextCard({
    super.key,
    required this.context,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.getColor('primary').withOpacity(0.1),
              theme.getColor('secondary').withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.getColor('primary'),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getContextIcon(this.context.type),
                      color: Colors.white,
                      size: 24,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getContextTypeLabel(this.context.type),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.getColor('primary'),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (this.context.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  this.context.description!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Theme and Configuration Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Theme',
                      theme.name,
                      theme.getColor('secondary'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Created',
                      _formatDate(this.context.createdAt),
                      Colors.grey[600]!,
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

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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

  String _getContextTypeLabel(ContextType type) {
    switch (type) {
      case ContextType.person:
        return 'Personal Timeline';
      case ContextType.pet:
        return 'Pet Timeline';
      case ContextType.project:
        return 'Project Timeline';
      case ContextType.business:
        return 'Business Timeline';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}