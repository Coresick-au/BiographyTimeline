import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../services/timeline_renderer_interface.dart';

/// Renderer for Bento Grid view - life overview with density patterns
class BentoGridRenderer extends BaseTimelineRenderer {
  final List<TimelineEvent> _events = [];
  final Map<int, List<TimelineEvent>> _eventsByYear = {};
  final Map<String, int> _eventDensityByMonth = {};
  double _zoomLevel = 1.0;
  int _selectedYear = DateTime.now().year;

  BentoGridRenderer(super.config, super.data) {
    _initializeGridData();
  }

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildYearSelector(),
          Expanded(
            child: _buildGrid(onEventTap, onEventLongPress),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            'Life Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    if (_eventsByYear.isEmpty) {
      return const SizedBox.shrink();
    }

    final years = _eventsByYear.keys.toList()..sort();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _selectedYear;
          final eventCount = _eventsByYear[year]?.length ?? 0;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text('$year'),
              onSelected: (selected) {
                if (selected) {
                  _selectYear(year);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
  ) {
    if (_eventsByYear.isEmpty) {
      return const Center(
        child: Text('No events to display'),
      );
    }

    final yearEvents = _eventsByYear[_selectedYear] ?? [];
    if (yearEvents.isEmpty) {
      return const Center(
        child: Text('No events for selected year'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildYearSummary(_selectedYear, yearEvents),
          const SizedBox(height: 16),
          _buildMonthlyGrid(yearEvents, onEventTap, onEventLongPress),
          const SizedBox(height: 16),
          _buildEventHighlights(yearEvents, onEventTap, onEventLongPress),
        ],
      ),
    );
  }

  Widget _buildYearSummary(int year, List<TimelineEvent> events) {
    final monthsWithEvents = <int>{};
    final eventTypes = <String, int>{};
    
    for (final event in events) {
      monthsWithEvents.add(event.timestamp.month);
      eventTypes[event.eventType] = (eventTypes[event.eventType] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$year Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem('Events', '${events.length}'),
                _buildStatItem('Active Months', '${monthsWithEvents.length}'),
                _buildStatItem('Event Types', '${eventTypes.length}'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: eventTypes.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key} (${entry.value})'),
                  backgroundColor: _getEventTypeColor(entry.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGrid(
    List<TimelineEvent> events,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
  ) {
    final gridData = _generateMonthlyGridData(events);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 12.0 / 4.0, // 12 months, 4 quarters height
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 12,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: 48, // 12 months × 4 weeks
                itemBuilder: (context, index) {
                  final month = (index ~/ 4) + 1;
                  final week = index % 4;
                  final eventCount = gridData[month]?[week] ?? 0;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: _getDensityColor(eventCount),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: eventCount > 0
                        ? Center(
                            child: Text(
                              '$eventCount',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10 * _zoomLevel,
                                fontWeight: FontWeight.bold,
                                color: _getDensityTextColor(eventCount),
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHighlights(
    List<TimelineEvent> events,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
  ) {
    // Sort events by some significance metric (e.g., assets count, description length)
    final highlights = List<TimelineEvent>.from(events)
      ..sort((a, b) {
        final aScore = _calculateEventScore(a);
        final bScore = _calculateEventScore(b);
        return bScore.compareTo(aScore);
      });

    final topEvents = highlights.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Highlights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: topEvents.length,
          itemBuilder: (context, index) {
            final event = topEvents[index];
            return _buildEventCard(event, onEventTap, onEventLongPress);
          },
        ),
      ],
    );
  }

  Widget _buildEventCard(
    TimelineEvent event,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
  ) {
    return Card(
      child: InkWell(
        onTap: () => onEventTap?.call(event),
        onLongPress: () => onEventLongPress?.call(event),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title ?? 'Event',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(event.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${event.assets.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.eventType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.eventType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Activity Density: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _buildLegendItem('Low', Colors.grey.shade300),
          _buildLegendItem('Medium', Colors.blue.shade300),
          _buildLegendItem('High', Colors.blue.shade600),
          _buildLegendItem('Very High', Colors.blue.shade900),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _initializeGridData() {
    final filteredEvents = filterEvents(data.events);
    _events.clear();
    _events.addAll(filteredEvents);
    
    _eventsByYear.clear();
    for (final event in _events) {
      final year = event.timestamp.year;
      _eventsByYear.putIfAbsent(year, () => []).add(event);
    }

    // Sort events within each year
    for (final events in _eventsByYear.values) {
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    _calculateDensityData();
  }

  void _calculateDensityData() {
    _eventDensityByMonth.clear();
    
    for (final events in _eventsByYear.values) {
      for (final event in events) {
        final monthKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}';
        _eventDensityByMonth[monthKey] = (_eventDensityByMonth[monthKey] ?? 0) + 1;
      }
    }
  }

  Map<int, List<int>> _generateMonthlyGridData(List<TimelineEvent> events) {
    final gridData = <int, List<int>>{};
    
    // Initialize grid with zeros
    for (int month = 1; month <= 12; month++) {
      gridData[month] = [0, 0, 0, 0]; // 4 weeks
    }
    
    // Distribute events across weeks
    for (final event in events) {
      final month = event.timestamp.month;
      final dayOfMonth = event.timestamp.day;
      final weekOfMonth = ((dayOfMonth - 1) / 7).floor().clamp(0, 3);
      
      gridData[month]![weekOfMonth] = (gridData[month]![weekOfMonth] ?? 0) + 1;
    }
    
    return gridData;
  }

  Color _getDensityColor(int eventCount) {
    if (eventCount == 0) return Colors.grey.shade300;
    if (eventCount <= 2) return Colors.blue.shade300;
    if (eventCount <= 5) return Colors.blue.shade600;
    return Colors.blue.shade900;
  }

  Color _getDensityTextColor(int eventCount) {
    return eventCount > 5 ? Colors.white : Colors.black;
  }

  Color _getEventTypeColor(String eventType) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[eventType.hashCode % colors.length];
  }

  int _calculateEventScore(TimelineEvent event) {
    int score = 0;
    score += event.assets.length * 10;
    score += (event.description?.length ?? 0);
    score += event.customAttributes.length * 5;
    return score;
  }

  void _selectYear(int year) {
    _selectedYear = year;
    // Trigger rebuild
  }

  void _zoomIn() {
    _zoomLevel = (_zoomLevel * 1.2).clamp(0.5, 3.0);
  }

  void _zoomOut() {
    _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 3.0);
  }

  void _resetZoom() {
    _zoomLevel = 1.0;
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    _selectYear(date.year);
  }

  @override
  Future<void> navigateToEvent(String eventId) async {
    final event = _events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Event not found: $eventId'),
    );
    await navigateToDate(event.timestamp);
  }

  @override
  List<TimelineEvent> getVisibleEvents() {
    return _eventsByYear[_selectedYear] ?? [];
  }

  @override
  DateTimeRange? getVisibleDateRange() {
    final yearEvents = _eventsByYear[_selectedYear] ?? [];
    if (yearEvents.isEmpty) return null;
    
    final dates = yearEvents.map((e) => e.timestamp).toList();
    dates.sort();
    
    return DateTimeRange(
      start: dates.first,
      end: dates.last,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
