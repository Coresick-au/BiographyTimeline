import 'package:flutter/material.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Team tracking card for business contexts
class TeamCard extends StatelessWidget {
  final TimelineTheme theme;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const TeamCard({
    Key? key,
    required this.theme,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final teamSize = data['teamSize'] as int? ?? 0;
    final newHires = data['newHires'] as int? ?? 0;
    final departments = data['departments'] as List<String>? ?? [];
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
                      Icons.group,
                      color: theme.getColor('primary'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Team Overview',
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
                          'Team Size',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$teamSize ${teamSize == 1 ? 'person' : 'people'}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.getColor('primary'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (newHires > 0) ...[
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
                            Icons.person_add,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '+$newHires',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (departments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Departments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: departments.take(3).map((dept) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.getColor('secondary').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dept,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.getColor('secondary'),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList()
                        ..addAll(departments.length > 3 ? [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${departments.length - 3}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ] : []),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricChip(
                    'Growth',
                    newHires > 0 ? '+$newHires' : 'Stable',
                    Icons.trending_up,
                    newHires > 0 ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    'Size',
                    _getTeamSizeCategory(teamSize),
                    Icons.business,
                    _getTeamSizeColor(teamSize),
                  ),
                ],
              ),
              if (lastUpdated != null) ...[
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

  String _getTeamSizeCategory(int size) {
    if (size <= 5) return 'Small';
    if (size <= 20) return 'Medium';
    if (size <= 100) return 'Large';
    return 'Enterprise';
  }

  Color _getTeamSizeColor(int size) {
    if (size <= 5) return Colors.blue;
    if (size <= 20) return Colors.green;
    if (size <= 100) return Colors.orange;
    return Colors.purple;
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