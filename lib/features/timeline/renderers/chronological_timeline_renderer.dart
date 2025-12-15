import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/design_system/design_system.dart';

/// Chronological timeline renderer with infinite scroll and modern styling
class ChronologicalTimelineRenderer extends BaseTimelineRenderer {
  final ScrollController _scrollController = ScrollController();
  
  // Performance optimization variables
  final Map<String, Widget> _eventCardCache = {};
  final List<TimelineEvent> _visibleEvents = [];
  DateTime? _currentViewportStart;
  DateTime? _currentViewportEnd;
  
  ChronologicalTimelineRenderer(
    super.config, 
    super.data,
  );

  @override
  Widget build({
    BuildContext? context,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return StreamBuilder<List<TimelineEvent>>(
      stream: _getFilteredEventsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!;
        if (events.isEmpty) {
          return _buildEmptyState();
        }

        return _buildTimelineView(
          events,
          onEventTap: onEventTap,
          onEventLongPress: onEventLongPress,
          onDateTap: onDateTap,
          onContextTap: onContextTap,
          scrollController: scrollController,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events to display',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding events to see your timeline',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView(
    List<TimelineEvent> events, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    // If no scroll controller provided, return just the slivers for parent CustomScrollView
    if (scrollController == null) {
      return Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildTimelineHeader(events),
                _buildTimelineEvents(
                  events,
                  onEventTap: onEventTap,
                  onEventLongPress: onEventLongPress,
                  onDateTap: onDateTap,
                  onContextTap: onContextTap,
                ),
                _buildTimelineFooter(),
              ],
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        _buildTimelineHeader(events),
        _buildTimelineEvents(
          events,
          onEventTap: onEventTap,
          onEventLongPress: onEventLongPress,
          onDateTap: onDateTap,
          onContextTap: onContextTap,
        ),
        _buildTimelineFooter(),
      ],
    );
  }

  Widget _buildTimelineHeader(List<TimelineEvent> events) {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) => ModernCard(
          margin: EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignTokens.space2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                    ),
                    child: Icon(
                      Icons.timeline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timeline',
                          style: DesignTokens.titleLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${events.length} events • ${_formatDateRange(events)}',
                          style: DesignTokens.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFilterButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) {
        // Handle filtering
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'all',
          child: Text('All Events'),
        ),
        const PopupMenuItem(
          value: 'photos',
          child: Text('Photos Only'),
        ),
        const PopupMenuItem(
          value: 'milestones',
          child: Text('Milestones Only'),
        ),
      ],
    );
  }

  Widget _buildTimelineEvents(
    List<TimelineEvent> events, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  }) {
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    // Sort events by timestamp
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = sortedEvents[index];
          return Column(
            children: [
              if (index == 0 || !_isSameDay(sortedEvents[index - 1].timestamp, event.timestamp))
                _buildDateSeparator(event.timestamp),
              _buildEventCard(
                event,
                onEventTap: onEventTap,
                onEventLongPress: onEventLongPress,
                onContextTap: onContextTap,
              ),
            ],
          );
        },
        childCount: sortedEvents.length,
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Text(
                  _formatDate(date),
                  style: DesignTokens.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    TimelineEvent event, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    // Use cached card if available
    if (_eventCardCache.containsKey(event.id)) {
      return _eventCardCache[event.id]!;
    }

    final card = Builder(
      builder: (context) => TimelineEventCard(
        title: event.title ?? 'Untitled Event',
        description: event.description,
        timestamp: event.timestamp,
        eventIcon: _getEventTypeIcon(event.eventType),
        eventColor: _getEventTypeColor(event.eventType),
        location: event.location?.locationName,
        mediaCount: event.assets.length,
        onTap: () => onEventTap?.call(event),
        onLongPress: () => onEventLongPress?.call(event),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _handleEditEvent(event);
                break;
              case 'delete':
                _handleDeleteEvent(event);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Cache the card for performance
    _eventCardCache[event.id] = card;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space1,
      ),
      child: card,
    );
  }

  Widget _buildTimelineFooter() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'End of timeline',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<TimelineEvent>> _getFilteredEventsStream() {
    // Simulate real-time updates with a stream
    return Stream.value(filterEvents(data.events));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateRange(List<TimelineEvent> events) {
    if (events.isEmpty) return 'No dates';
    
    final dates = events.map((e) => e.timestamp).toList();
    dates.sort();
    
    final start = dates.first;
    final end = dates.last;
    
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${start.day} - ${end.day} ${_monthName(start.month)} ${start.year}';
      } else {
        return '${start.day} ${_monthName(start.month)} - ${end.day} ${_monthName(end.month)} ${start.year}';
      }
    } else {
      return '${start.day} ${_monthName(start.month)} ${start.year} - ${end.day} ${_monthName(end.month)} ${end.year}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _handleEditEvent(TimelineEvent event) {
    // Handle event editing
    debugPrint('Edit event: ${event.id}');
  }

  void _handleDeleteEvent(TimelineEvent event) {
    // Handle event deletion
    debugPrint('Delete event: ${event.id}');
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

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Scroll to the specified date
    final targetEvent = data.events
        .where((e) => e.timestamp.isAfter(date.subtract(const Duration(days: 1))))
        .firstOrNull;
    
    if (targetEvent != null && _scrollController.hasClients) {
      // Calculate scroll position and animate
      final index = data.events.indexOf(targetEvent);
      final estimatedPosition = index * 200.0; // Estimated item height
      
      await _scrollController.animateTo(
        estimatedPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    
    await super.navigateToDate(date);
  }

  @override
  List<TimelineEvent> getVisibleEvents() {
    return filterEvents(data.events);
  }

  @override
  DateTimeRange? getVisibleDateRange() {
    if (_currentViewportStart != null && _currentViewportEnd != null) {
      return DateTimeRange(
        start: _currentViewportStart!,
        end: _currentViewportEnd!,
      );
    }
    return super.getVisibleDateRange();
  }

  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation for timeline export
    // This would use RepaintBoundary to capture the timeline as an image
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _eventCardCache.clear();
    super.dispose();
  }
}
