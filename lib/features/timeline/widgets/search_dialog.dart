import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Search dialog for finding and navigating to events
class SearchDialog extends StatefulWidget {
  final List<TimelineEvent> events;
  final List<Context> contexts;
  final Function(TimelineEvent) onEventSelected;

  const SearchDialog({
    super.key,
    required this.events,
    required this.contexts,
    required this.onEventSelected,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<TimelineEvent> _filteredEvents = [];
  String? _selectedEventType;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _filteredEvents = widget.events;
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    setState(() {
      _filteredEvents = widget.events.where((event) {
        // Text search
        final searchText = _searchController.text.toLowerCase();
        final matchesText = searchText.isEmpty ||
            (event.title?.toLowerCase().contains(searchText) ?? false) ||
            (event.description?.toLowerCase().contains(searchText) ?? false) ||
            (event.location?.locationName?.toLowerCase().contains(searchText) ?? false);

        // Event type filter
        final matchesType = _selectedEventType == null || event.eventType == _selectedEventType;

        // Date range filter
        final matchesDate = _dateRange == null ||
            (event.timestamp.isAfter(_dateRange!.start) &&
                event.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1))));

        return matchesText && matchesType && matchesDate;
      }).toList();

      // Sort by date (most recent first)
      _filteredEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.search, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Search Events',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by title, description, or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Event type filter
                  FilterChip(
                    label: Text(_selectedEventType ?? 'All Types'),
                    selected: _selectedEventType != null,
                    onSelected: (selected) {
                      _showEventTypeFilter();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Date range filter
                  FilterChip(
                    label: Text(_dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : 'All Dates'),
                    selected: _dateRange != null,
                    onSelected: (selected) {
                      _showDateRangeFilter();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Clear filters
                  if (_selectedEventType != null || _dateRange != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedEventType = null;
                          _dateRange = null;
                          _filterEvents();
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Results count
            Text(
              '${_filteredEvents.length} results',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            // Results list
            Expanded(
              child: _filteredEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        final contextEntity = widget.contexts.isNotEmpty 
                            ? widget.contexts.first 
                            : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getEventTypeColor(event.eventType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getEventTypeIcon(event.eventType),
                                color: _getEventTypeColor(event.eventType),
                              ),
                            ),
                            title: Text(event.title ?? 'Untitled Event'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contextEntity?.name ?? 'Family'),
                                Text(
                                  _formatDate(event.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (event.location != null)
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event.location!.locationName ?? 'Unknown',
                                          style: Theme.of(context).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => widget.onEventSelected(event),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Event Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Types'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedEventType,
                onChanged: (value) {
                  setState(() => _selectedEventType = value);
                  Navigator.of(context).pop();
                  _filterEvents();
                },
              ),
            ),
            ...['photo', 'milestone', 'text', 'location', 'video'].map((type) {
              return ListTile(
                title: Text(type[0].toUpperCase() + type.substring(1)),
                leading: Radio<String?>(
                  value: type,
                  groupValue: _selectedEventType,
                  onChanged: (value) {
                    setState(() => _selectedEventType = value);
                    Navigator.of(context).pop();
                    _filterEvents();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showDateRangeFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _filterEvents();
      });
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'photo':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'milestone':
        return Colors.green;
      case 'text':
        return Colors.purple;
      case 'location':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'photo':
        return Icons.photo;
      case 'video':
        return Icons.videocam;
      case 'milestone':
        return Icons.star;
      case 'text':
        return Icons.text_fields;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
