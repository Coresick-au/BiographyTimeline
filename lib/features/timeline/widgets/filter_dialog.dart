import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Common event type constants
class EventTypes {
  static const String photo = 'photo';
  static const String video = 'video';
  static const String milestone = 'milestone';
  static const String text = 'text';
  static const String location = 'location';
  static const String general = 'general';
  
  static const List<String> all = [
    photo,
    video,
    milestone,
    text,
    location,
    general,
  ];
}

/// Filter dialog for timeline events
class FilterDialog extends ConsumerStatefulWidget {
  final List<TimelineEvent> events;
  final List<Context> contexts;
  final Function(FilterCriteria) onFilterApplied;
  final FilterCriteria? currentFilter;

  const FilterDialog({
    super.key,
    required this.events,
    required this.contexts,
    required this.onFilterApplied,
    this.currentFilter,
  });

  @override
  ConsumerState<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  Set<String> _selectedTypes = {};
  String? _selectedContextId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    if (widget.currentFilter != null) {
      _selectedTypes = Set.from(widget.currentFilter!.eventTypes);
      _selectedContextId = widget.currentFilter!.contextId;
      _dateRange = widget.currentFilter!.dateRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Events',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Event Type Filter
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EventTypes.all.map((type) {
                        final isSelected = _selectedTypes.contains(type);
                        return FilterChip(
                          label: Text(_getEventTypeLabel(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Context Filter
                    Text(
                      'Timeline Context',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _selectedContextId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All Contexts',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Contexts'),
                        ),
                        ...widget.contexts.map((context) {
                          return DropdownMenuItem<String?>(
                            value: context.id,
                            child: Text(context.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedContextId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Date Range Filter
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _dateRange == null
                            ? 'Select Date Range'
                            : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                      ),
                    ),
                    if (_dateRange != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _dateRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Date Range'),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTypeLabel(String type) {
    switch (type) {
      case EventTypes.photo:
        return 'Photo';
      case EventTypes.video:
        return 'Video';
      case EventTypes.milestone:
        return 'Milestone';
      case EventTypes.text:
        return 'Text';
      case EventTypes.location:
        return 'Location';
      case EventTypes.general:
        return 'General';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedContextId = null;
      _dateRange = null;
    });
  }

  void _applyFilters() {
    final filter = FilterCriteria(
      eventTypes: _selectedTypes.toList(),
      contextId: _selectedContextId,
      dateRange: _dateRange,
    );
    widget.onFilterApplied(filter);
    Navigator.of(context).pop();
  }
}

/// Filter criteria for timeline events
class FilterCriteria {
  final List<String> eventTypes;
  final String? contextId;
  final DateTimeRange? dateRange;

  const FilterCriteria({
    this.eventTypes = const [],
    this.contextId,
    this.dateRange,
  });

  bool get hasFilters =>
      eventTypes.isNotEmpty || contextId != null || dateRange != null;

  bool matches(TimelineEvent event) {
    // Check event type filter
    if (eventTypes.isNotEmpty && !eventTypes.contains(event.eventType)) {
      return false;
    }

    // Check context filter
    if (contextId != null && event.contextId != contextId) {
      return false;
    }

    // Check date range filter
    if (dateRange != null) {
      if (event.timestamp.isBefore(dateRange!.start) ||
          event.timestamp.isAfter(dateRange!.end.add(const Duration(days: 1)))) {
        return false;
      }
    }

    return true;
  }

  int get filterCount {
    int count = 0;
    if (eventTypes.isNotEmpty) count++;
    if (contextId != null) count++;
    if (dateRange != null) count++;
    return count;
  }
}
