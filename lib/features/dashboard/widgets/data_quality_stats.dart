import 'package:flutter/material.dart';

class DataQualityStats extends StatelessWidget {
  final int totalEvents;
  final int withLocation;
  final int withTags;
  final int withPhotos;

  const DataQualityStats({
    super.key,
    required this.totalEvents,
    required this.withLocation,
    required this.withTags,
    required this.withPhotos,
  });

  @override
  Widget build(BuildContext context) {
    if (totalEvents == 0) return const Center(child: Text('No events'));

    return Column(
      children: [
        _buildStatRow(context, 'Location', withLocation, Icons.location_on),
        const SizedBox(height: 12),
        _buildStatRow(context, 'Tags', withTags, Icons.label),
        const SizedBox(height: 12),
        _buildStatRow(context, 'Photos', withPhotos, Icons.photo),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int count, IconData icon) {
    final percentage = (count / totalEvents);
    final color = _getColorForPercentage(percentage);

    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}
