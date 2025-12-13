import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';

/// Bento Grid timeline renderer with visual life overview dashboard
class BentoGridTimelineRenderer extends BaseTimelineRenderer {
  // Grid configuration
  static const int _gridColumns = 4;
  static const int _gridRows = 3;
  final List<GridItem> _gridItems = [];
  
  // Data
  List<TimelineEvent> _sortedEvents = [];
  Map<String, List<TimelineEvent>> _eventsByCategory = {};
  
  // Statistics
  Map<String, int> _eventTypeStats = {};
  Map<String, int> _locationStats = {};
  Map<String, int> _monthlyStats = {};
  int _totalEvents = 0;
  int _totalLocations = 0;
  DateTime? _earliestDate;
  DateTime? _latestDate;
  
  BentoGridTimelineRenderer(
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) : super(config, data) {
    _initializeGrid();
    _calculateStatistics();
  }

  void _initializeGrid() {
    _gridItems.clear();
    _gridItems.addAll([
      GridItem(
        id: 'total_events',
        title: 'Total Events',
        type: GridItemType.stat,
        rowSpan: 1,
        colSpan: 1,
        position: const GridPosition(0, 0),
      ),
      GridItem(
        id: 'timeline_span',
        title: 'Timeline Span',
        type: GridItemType.stat,
        rowSpan: 1,
        colSpan: 1,
        position: const GridPosition(0, 1),
      ),
      GridItem(
        id: 'unique_locations',
        title: 'Locations',
        type: GridItemType.stat,
        rowSpan: 1,
        colSpan: 1,
        position: const GridPosition(0, 2),
      ),
      GridItem(
        id: 'event_types',
        title: 'Event Types',
        type: GridItemType.chart,
        rowSpan: 1,
        colSpan: 1,
        position: const GridPosition(0, 3),
      ),
      GridItem(
        id: 'recent_events',
        title: 'Recent Activity',
        type: GridItemType.list,
        rowSpan: 2,
        colSpan: 2,
        position: const GridPosition(1, 0),
      ),
      GridItem(
        id: 'monthly_activity',
        title: 'Monthly Activity',
        type: GridItemType.chart,
        rowSpan: 2,
        colSpan: 2,
        position: const GridPosition(1, 2),
      ),
      GridItem(
        id: 'top_locations',
        title: 'Top Locations',
        type: GridItemType.list,
        rowSpan: 1,
        colSpan: 2,
        position: const GridPosition(2, 0),
      ),
      GridItem(
        id: 'life_highlights',
        title: 'Life Highlights',
        type: GridItemType.highlights,
        rowSpan: 1,
        colSpan: 2,
        position: const GridPosition(2, 2),
      ),
    ]);
  }


  
  @override
  void dispose() {
    _gridItems.clear();
    _sortedEvents.clear();
    _eventsByCategory.clear();
    _eventTypeStats.clear();
    _locationStats.clear();
    _monthlyStats.clear();
    super.dispose();
  }
  
  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return Builder(
      builder: (context) {
        if (data.events.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildBentoGrid(context, onEventTap, onEventLongPress),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Life Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add events to see your life statistics dashboard',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.grid_view,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life Overview Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Visual summary of your timeline data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _calculateStatistics();
            },
            tooltip: 'Refresh Statistics',
          ),
        ],
      ),
    );
  }
  
  Widget _buildBentoGrid(BuildContext context, TimelineEventCallback? onEventTap, TimelineEventCallback? onEventLongPress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistics Cards Row
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Total Events', _totalEvents.toString(), Icons.event)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(context, 'Timeline Span', _getTimelineSpan(), Icons.date_range)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(context, 'Locations', _totalLocations.toString(), Icons.location_on)),
              const SizedBox(width: 8),
              Expanded(child: _buildEventTypeChart(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main Content Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentEventsCard(context, onEventTap, onEventLongPress),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildMonthlyActivityChart(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bottom Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTopLocationsCard(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildLifeHighlightsCard(context, onEventTap),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventTypeChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Event Types',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _eventTypeStats.isEmpty
                ? Center(
                    child: Text(
                      'No data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _eventTypeStats.entries.map((entry) {
                      final percentage = _totalEvents > 0 
                          ? (entry.value / _totalEvents * 100).round()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              _getEventTypeIcon(entry.key),
                              size: 16,
                              color: _getEventTypeColor(entry.key),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _totalEvents > 0 ? entry.value / _totalEvents : 0,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getEventTypeColor(entry.key),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentEventsCard(BuildContext context, TimelineEventCallback? onEventTap, TimelineEventCallback? onEventLongPress) {
    final recentEvents = _sortedEvents.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: recentEvents.isEmpty
                ? Center(
                    child: Text(
                      'No recent events',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: recentEvents.length,
                    itemBuilder: (context, index) {
                      final event = recentEvents[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getEventTypeIcon(event.eventType),
                          color: _getEventTypeColor(event.eventType),
                          size: 20,
                        ),
                        title: Text(
                          event.title ?? 'Untitled Event',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        subtitle: Text(
                          _formatDate(event.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        onTap: () => onEventTap?.call(event),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlyActivityChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Activity',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _monthlyStats.isEmpty
                ? Center(
                    child: Text(
                      'No data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _monthlyStats.entries.map((entry) {
                        final maxValue = _monthlyStats.values.reduce(math.max);
                        final height = maxValue > 0 ? entry.value / maxValue : 0;
                        return Container(
                          width: 30,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 100.0 * height,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${entry.value}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopLocationsCard(BuildContext context) {
    final topLocations = _locationStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(5);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Locations',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: topLocations.isEmpty
                ? Center(
                    child: Text(
                      'No location data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: topLocations.length,
                    itemBuilder: (context, index) {
                      final entry = topLocations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '${entry.value} events',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLifeHighlightsCard(BuildContext context, TimelineEventCallback? onEventTap) {
    final highlights = _sortedEvents.where((e) => e.eventType == 'milestone').take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Life Highlights',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: highlights.isEmpty
                ? Center(
                    child: Text(
                      'No milestones yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: highlights.length,
                    itemBuilder: (context, index) {
                      final event = highlights[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          title: Text(
                            event.title ?? 'Milestone',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(event.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => onEventTap?.call(event),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  void _calculateStatistics() {
    if (data.events.isEmpty) {
      _resetStatistics();
      return;
    }
    
    _sortedEvents = List<TimelineEvent>.from(data.events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    _totalEvents = _sortedEvents.length;
    _earliestDate = _sortedEvents.last.timestamp;
    _latestDate = _sortedEvents.first.timestamp;
    
    // Calculate event type statistics
    _eventTypeStats.clear();
    for (final event in _sortedEvents) {
      _eventTypeStats[event.eventType] = (_eventTypeStats[event.eventType] ?? 0) + 1;
    }
    
    // Calculate location statistics
    _locationStats.clear();
    final uniqueLocations = <String>{};
    for (final event in _sortedEvents) {
      if (event.location != null) {
        final location = event.location!.locationName ?? 'Unknown';
        _locationStats[location] = (_locationStats[location] ?? 0) + 1;
        uniqueLocations.add(location);
      }
    }
    _totalLocations = uniqueLocations.length;
    
    // Calculate monthly statistics
    _monthlyStats.clear();
    for (final event in _sortedEvents) {
      final monthKey = '${_getMonthAbbreviation(event.timestamp)} ${event.timestamp.year}';
      _monthlyStats[monthKey] = (_monthlyStats[monthKey] ?? 0) + 1;
    }
  }
  
  void _resetStatistics() {
    _totalEvents = 0;
    _totalLocations = 0;
    _earliestDate = null;
    _latestDate = null;
    _eventTypeStats.clear();
    _locationStats.clear();
    _monthlyStats.clear();
    _sortedEvents.clear();
  }
  
  String _getTimelineSpan() {
    if (_earliestDate == null || _latestDate == null) return '0 days';
    
    final days = _latestDate!.difference(_earliestDate!).inDays;
    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()} years';
  }
  
  String _getMonthAbbreviation(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
  
  // Interface implementations
  @override
  List<TimelineEvent> getVisibleEvents() {
    return List.unmodifiable(_sortedEvents);
  }
  
  @override
  DateTimeRange? getVisibleDateRange() {
    if (_earliestDate == null || _latestDate == null) return null;
    
    return DateTimeRange(start: _earliestDate!, end: _latestDate!);
  }
  
  @override
  Future<void> onDataUpdated() async {
    _calculateStatistics();
    await super.onDataUpdated();
  }
  
  @override
  Future<void> onConfigUpdated() async {
    await super.onConfigUpdated();
  }
  
  @override
  Future<void> navigateToDate(DateTime date) async {
    // Bento grid doesn't support date navigation
  }
  
  @override
  Future<void> navigateToEvent(String eventId) async {
    // Bento grid doesn't support event navigation
  }
  
  @override
  Future<void> setZoomLevel(double level) async {
    // Bento grid doesn't support zoom
  }
  
  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation would capture grid as image
    return null;
  }
}

/// Grid item configuration for bento layout
class GridItem {
  final String id;
  final String title;
  final GridItemType type;
  final int rowSpan;
  final int colSpan;
  final GridPosition position;
  
  const GridItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rowSpan,
    required this.colSpan,
    required this.position,
  });
}

/// Types of grid items
enum GridItemType {
  stat,
  chart,
  list,
  highlights,
}

/// Grid position
class GridPosition {
  final int row;
  final int col;
  
  const GridPosition(this.row, this.col);
}
