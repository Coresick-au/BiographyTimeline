import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Revenue tracking card for business contexts
class RevenueCard extends StatelessWidget {
  final TimelineTheme theme;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const RevenueCard({
    Key? key,
    required this.theme,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentRevenue = data['currentRevenue'] as double? ?? 0.0;
    final previousRevenue = data['previousRevenue'] as double?;
    final target = data['target'] as double?;
    final period = data['period'] as String? ?? 'This Month';

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
                      Icons.trending_up,
                      color: theme.getColor('primary'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Revenue Tracker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${_formatNumber(currentRevenue)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.getColor('primary'),
                          ),
                        ),
                      ),
                      if (previousRevenue != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getGrowthColor(currentRevenue, previousRevenue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getGrowthIcon(currentRevenue, previousRevenue),
                                size: 14,
                                color: _getGrowthColor(currentRevenue, previousRevenue),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${_calculateGrowthPercentage(currentRevenue, previousRevenue)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getGrowthColor(currentRevenue, previousRevenue),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (target != null) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: \$${_formatNumber(target)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_calculateTargetProgress(currentRevenue, target)}%',
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
                      value: (currentRevenue / target).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(theme.getColor('secondary')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricChip(
                    'Growth',
                    previousRevenue != null 
                        ? '${_calculateGrowthPercentage(currentRevenue, previousRevenue)}%'
                        : 'N/A',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    'Status',
                    target != null && currentRevenue >= target ? 'On Track' : 'In Progress',
                    Icons.flag,
                    target != null && currentRevenue >= target ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Color _getGrowthColor(double current, double previous) {
    if (current > previous) {
      return Colors.green;
    } else if (current < previous) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  IconData _getGrowthIcon(double current, double previous) {
    if (current > previous) {
      return Icons.trending_up;
    } else if (current < previous) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  int _calculateGrowthPercentage(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return (((current - previous) / previous) * 100).toInt();
  }

  int _calculateTargetProgress(double current, double target) {
    if (target == 0) return 0;
    return ((current / target) * 100).clamp(0, 100).toInt();
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
}