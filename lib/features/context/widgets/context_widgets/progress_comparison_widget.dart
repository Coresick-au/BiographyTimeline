import 'package:flutter/material.dart';
import '../../../../shared/models/context.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Progress comparison widget for pet and project contexts
class ProgressComparisonWidget extends StatelessWidget {
  final ContextType contextType;
  final TimelineTheme theme;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const ProgressComparisonWidget({
    Key? key,
    required this.contextType,
    required this.theme,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final beforeImage = data['beforeImage'] as String?;
    final afterImage = data['afterImage'] as String?;
    final progressTitle = data['title'] as String? ?? _getDefaultTitle();
    final progressDate = data['date'] as DateTime?;
    final progressValue = data['progress'] as double?;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
                      color: theme.getColor('primary').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getContextIcon(),
                      color: theme.getColor('primary'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progressTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImageComparison(beforeImage, afterImage),
              if (progressValue != null) ...[
                const SizedBox(height: 12),
                _buildProgressBar(progressValue),
              ],
              const SizedBox(height: 12),
              _buildContextSpecificMetrics(),
              if (progressDate != null) ...[
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
                      _formatDate(progressDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageComparison(String? beforeImage, String? afterImage) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    beforeImage != null ? Icons.photo : Icons.add_photo_alternate,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Before',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 2,
            color: Colors.white,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    afterImage != null ? Icons.photo : Icons.add_photo_alternate,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'After',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: theme.getColor('primary'),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(theme.getColor('primary')),
        ),
      ],
    );
  }

  Widget _buildContextSpecificMetrics() {
    switch (contextType) {
      case ContextType.pet:
        return _buildPetMetrics();
      case ContextType.project:
        return _buildProjectMetrics();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPetMetrics() {
    final weight = data['weight'] as double?;
    final age = data['age'] as String?;
    
    return Row(
      children: [
        if (weight != null)
          _buildMetricChip(
            'Weight',
            '${weight.toStringAsFixed(1)}kg',
            Icons.monitor_weight,
            Colors.blue,
          ),
        if (weight != null && age != null) const SizedBox(width: 8),
        if (age != null)
          _buildMetricChip(
            'Age',
            age,
            Icons.cake,
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildProjectMetrics() {
    final cost = data['cost'] as double?;
    final phase = data['phase'] as String?;
    
    return Row(
      children: [
        if (cost != null)
          _buildMetricChip(
            'Cost',
            '\$${_formatNumber(cost)}',
            Icons.attach_money,
            Colors.orange,
          ),
        if (cost != null && phase != null) const SizedBox(width: 8),
        if (phase != null)
          _buildMetricChip(
            'Phase',
            phase,
            Icons.construction,
            Colors.purple,
          ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContextIcon() {
    switch (contextType) {
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.compare;
      default:
        return Icons.compare;
    }
  }

  String _getDefaultTitle() {
    switch (contextType) {
      case ContextType.pet:
        return 'Growth Progress';
      case ContextType.project:
        return 'Project Progress';
      default:
        return 'Progress Comparison';
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
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
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}