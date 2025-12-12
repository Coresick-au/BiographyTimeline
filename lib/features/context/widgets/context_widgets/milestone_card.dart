import 'package:flutter/material.dart';
import '../../../../shared/models/context.dart';
import '../../../../shared/models/timeline_theme.dart';

/// Universal milestone card that adapts to different contexts
class MilestoneCard extends StatelessWidget {
  final ContextType contextType;
  final TimelineTheme theme;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const MilestoneCard({
    Key? key,
    required this.contextType,
    required this.theme,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = theme.getColor('primary');
    final milestoneTitle = data['title'] ?? _getDefaultTitle();
    final milestoneDate = data['date'] as DateTime?;
    final milestoneDescription = data['description'] ?? '';

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
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getContextIcon(),
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      milestoneTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (milestoneDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  milestoneDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (milestoneDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDate(milestoneDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              _buildContextSpecificContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextSpecificContent() {
    switch (contextType) {
      case ContextType.person:
        return _buildPersonalContent();
      case ContextType.pet:
        return _buildPetContent();
      case ContextType.project:
        return _buildProjectContent();
      case ContextType.business:
        return _buildBusinessContent();
    }
  }

  Widget _buildPersonalContent() {
    final age = data['age'];
    if (age != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              Icons.cake,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Age $age',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPetContent() {
    final weight = data['weight'];
    if (weight != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              Icons.monitor_weight,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${weight}kg',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProjectContent() {
    final progress = data['progress'] as double?;
    if (progress != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
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
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBusinessContent() {
    final revenue = data['revenue'];
    if (revenue != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 14,
              color: Colors.green[600],
            ),
            const SizedBox(width: 4),
            Text(
              '\$${_formatNumber(revenue)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  IconData _getContextIcon() {
    switch (contextType) {
      case ContextType.person:
        return Icons.flag;
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.construction;
      case ContextType.business:
        return Icons.business;
    }
  }

  String _getDefaultTitle() {
    switch (contextType) {
      case ContextType.person:
        return 'Personal Milestone';
      case ContextType.pet:
        return 'Pet Milestone';
      case ContextType.project:
        return 'Project Milestone';
      case ContextType.business:
        return 'Business Milestone';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
}