import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Cost tracking card for project contexts
class CostCard extends StatelessWidget {
  final TimelineTheme theme;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const CostCard({
    Key? key,
    required this.theme,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalSpent = data['totalSpent'] as double? ?? 0.0;
    final budget = data['budget'] as double?;
    final recentExpense = data['recentExpense'] as double?;
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
                      Icons.attach_money,
                      color: theme.getColor('primary'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Budget Tracker',
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
                          'Total Spent',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${_formatNumber(totalSpent)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.getColor('primary'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recentExpense != null && recentExpense > 0) ...[
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
                            Icons.add,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '\$${_formatNumber(recentExpense)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (budget != null) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget: \$${_formatNumber(budget)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_calculateBudgetUsage(totalSpent, budget)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getBudgetUsageColor(totalSpent, budget),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (totalSpent / budget).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getBudgetUsageColor(totalSpent, budget),
                      ),
                    ),
                    if (totalSpent > budget) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 12,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Over budget by \$${_formatNumber(totalSpent - budget)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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

  Color _getBudgetUsageColor(double spent, double budget) {
    final usage = spent / budget;
    if (usage >= 1.0) {
      return Colors.red;
    } else if (usage >= 0.8) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  int _calculateBudgetUsage(double spent, double budget) {
    if (budget == 0) return 0;
    return ((spent / budget) * 100).toInt();
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