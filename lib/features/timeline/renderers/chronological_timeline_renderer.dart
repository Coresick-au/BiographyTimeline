import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../../../core/templates/template_manager.dart';
import '../../context/widgets/event_cards/personal_event_card.dart';
import '../../context/widgets/event_cards/pet_event_card.dart';
import '../../context/widgets/event_cards/project_event_card.dart';
import '../../context/widgets/event_cards/business_event_card.dart';

/// Chronological timeline renderer with infinite scroll and context-aware rendering
class ChronologicalTimelineRenderer extends BaseTimelineRenderer {
  final ScrollController _scrollController = ScrollController();
  final TemplateManager _templateManager = TemplateManager();
  
  // Performance optimization variables
  final Map<String, Widget> _eventCardCache = {};
  final List<TimelineEvent> _visibleEvents = [];
  DateTime? _currentViewportStart;
  DateTime? _currentViewportEnd;
  
  ChronologicalTimelineRenderer(
    super.config, 
    super.data,
  ) {
    _initializeTemplateManager();
  }

  Future<void> _initializeTemplateManager() async {
    await _templateManager.initialize();
  }

  @override
  Widget build({
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
    return CustomScrollView(
      controller: scrollController ?? _scrollController,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                _buildFilterButton(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${events.length} events • ${_formatDateRange(events)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index.isEven) {
            // Date separator
            final eventIndex = index ~/ 2;
            if (eventIndex < events.length) {
              return _buildDateSeparator(events[eventIndex].timestamp);
            }
            return null;
          } else {
            // Event card
            final eventIndex = index ~/ 2;
            if (eventIndex < events.length) {
              return _buildEventCard(
                events[eventIndex],
                onEventTap: onEventTap,
                onEventLongPress: onEventLongPress,
                onContextTap: onContextTap,
              );
            }
            return null;
          }
        },
        childCount: events.length * 2,
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[300],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[300],
            ),
          ),
        ],
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

    final context = data.contexts.firstWhere(
      (ctx) => ctx.id == event.contextId,
      orElse: () => Context(
        id: 'default',
        ownerId: event.ownerId,
        type: ContextType.person,
        name: 'Default',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final theme = TimelineTheme(
      id: 'default',
      name: 'Default Theme',
      contextType: context.type,
      colorPalette: {
        'primary': Colors.blue.value,
        'background': Colors.white.value,
        'text': Colors.black.value,
        'card': Colors.grey[100]!.value,
      },
      iconSet: {'default': 'material'},
      typography: {
        'body': {'fontSize': 14.0, 'fontWeight': 'normal'},
        'header': {'fontSize': 16.0, 'fontWeight': 'bold'},
      },
      widgetFactories: {'card': true, 'list': true},
      enableGhostCamera: false,
      enableBudgetTracking: false,
      enableProgressComparison: false,
    );

    final card = _templateManager.createEventCard(
      event: event,
      context: context,
      theme: theme,
      onTap: () => onEventTap?.call(event),
      onEdit: () => _handleEditEvent(event),
      onDelete: () => _handleDeleteEvent(event),
    );

    // Cache the card for performance
    _eventCardCache[event.id] = card;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
