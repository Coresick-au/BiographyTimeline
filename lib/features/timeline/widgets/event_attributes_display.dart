import 'package:flutter/material.dart';
import '../../../shared/models/context.dart';

/// Widget for displaying custom attributes of an event
class EventAttributesDisplay extends StatelessWidget {
  final Map<String, dynamic> attributes;
  final String eventType;
  final ContextType contextType;

  const EventAttributesDisplay({
    super.key,
    required this.attributes,
    required this.eventType,
    required this.contextType,
  });

  @override
  Widget build(BuildContext context) {
    if (attributes.isEmpty) {
      return Text(
        'No additional details',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    return Column(
      children: attributes.entries.map((entry) {
        return _buildAttributeRow(context, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildAttributeRow(BuildContext context, String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              _formatAttributeName(key),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              _formatAttributeValue(value),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAttributeName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatAttributeValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is double) value.toStringAsFixed(2);
    if (value is List) return value.join(', ');
    if (value is Map) {
      final entries = value.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return entries.isEmpty ? 'Empty' : entries;
    }
    return value.toString();
  }
}
