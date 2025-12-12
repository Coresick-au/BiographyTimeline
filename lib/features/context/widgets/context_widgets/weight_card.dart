import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Weight tracking card for pet contexts
class WeightCard extends StatelessWidget {
  final TimelineTheme theme;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const WeightCard({
    Key? key,
    required this.theme,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentWeight = data['currentWeight'] as double? ?? 0.0;
    final previousWeight = data['previousWeight'] as double?;
    final targetWeight = data['targetWeight'] as double?;
    final lastUpdated = data['lastUpdated'] as DateTime?;

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
                      Icons.monitor_weight,
                      color: theme.getColor('primary'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Weight Tracker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Weight',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${currentWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.getColor('primary'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (previousWeight != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getWeightChangeColor(currentWeight, previousWeight).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getWeightChangeIcon(currentWeight, previousWeight),
                            size: 14,
                            color: _getWeightChangeColor(currentWeight, previousWeight),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${(currentWeight - previousWeight).abs().toStringAsFixed(1)}kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getWeightChangeColor(currentWeight, previousWeight),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (targetWeight != null) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${targetWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_calculateProgress(currentWeight, targetWeight)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.getColor('secondary'),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _calculateProgress(currentWeight, targetWeight) / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(theme.getColor('secondary')),
                    ),
                  ],
                ),
              ],
              if (lastUpdated != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${_formatDate(lastUpdated)}',
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

  Color _getWeightChangeColor(double current, double previous) {
    if (current > previous) {
      return Colors.green;
    } else if (current < previous) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  IconData _getWeightChangeIcon(double current, double previous) {
    if (current > previous) {
      return Icons.trending_up;
    } else if (current < previous) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  int _calculateProgress(double current, double target) {
    if (target == 0) return 0;
    return ((current / target) * 100).clamp(0, 100).toInt();
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