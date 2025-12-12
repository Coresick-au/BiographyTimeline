import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../services/timeline_renderer_interface.dart';
import '../widgets/timeline_event_card.dart';

/// Renderer for Life Stream view - infinite scroll chronological timeline
class LifeStreamRenderer extends BaseTimelineRenderer {
  final ScrollController _scrollController = ScrollController();
  final List<TimelineEvent> _visibleEvents = [];
  final Map<String, List<TimelineEvent>> _eventsByMonth = {};
  DateTime? _currentEarliestVisible;
  DateTime? _currentLatestVisible;
  bool _isLoadingMore = false;
  static const int _batchSize = 50;

  LifeStreamRenderer(super.config, super.data) {
    _scrollController.addListener(_onScroll);
    _organizeEventsByMonth();
    _loadInitialEvents();
  }

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return CustomScrollView(
      controller: scrollController ?? _scrollController,
      slivers: [
        _buildHeader(),
        ..._buildMonthSections(onEventTap, onEventLongPress),
        if (_isLoadingMore) _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: Text('Life Stream'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: _scrollToToday,
        ),
        IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: _showFilterOptions,
        ),
      ],
    );
  }

  List<Widget> _buildMonthSections(
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
  ) {
    final sections = <Widget>[];
    final sortedMonths = _eventsByMonth.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    for (final monthKey in sortedMonths) {
      final events = _eventsByMonth[monthKey]!;
      if (events.isEmpty) continue;

      final monthDate = DateTime.parse(monthKey);
      
      sections.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _MonthHeaderDelegate(
            monthDate: monthDate,
            eventCount: events.length,
          ),
        ),
      );

      sections.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final event = events[index];
              return TimelineEventCard(
                event: event,
                onTap: () => onEventTap?.call(event),
                onLongPress: () => onEventLongPress?.call(event),
              );
            },
            childCount: events.length,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildLoadingIndicator() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _organizeEventsByMonth() {
    _eventsByMonth.clear();
    
    final filteredEvents = filterEvents(data.events);
    
    for (final event in filteredEvents) {
      final monthKey = _getMonthKey(event.timestamp);
      _eventsByMonth.putIfAbsent(monthKey, () => []).add(event);
    }

    // Sort events within each month
    for (final events in _eventsByMonth.values) {
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
  }

  String _getMonthKey(DateTime date) {
    return DateTime(date.year, date.month, 1).toIso8601String();
  }

  void _loadInitialEvents() {
    final allEvents = filterEvents(data.events);
    if (allEvents.isEmpty) return;

    // Load first batch
    final sortedEvents = List<TimelineEvent>.from(allEvents)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final batchSize = _batchSize.clamp(0, sortedEvents.length);
    _visibleEvents.addAll(sortedEvents.take(batchSize));
    
    if (_visibleEvents.isNotEmpty) {
      _currentEarliestVisible = _visibleEvents.first.timestamp;
      _currentLatestVisible = _visibleEvents.last.timestamp;
    }
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));

      final allEvents = filterEvents(data.events);
      final remainingEvents = allEvents.where((event) {
        return !_visibleEvents.any((visible) => visible.id == event.id);
      }).toList();

      if (remainingEvents.isNotEmpty) {
        remainingEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        final nextBatch = remainingEvents.take(_batchSize).toList();
        _visibleEvents.addAll(nextBatch);
        
        _organizeEventsByMonth(); // Reorganize with new events
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _scrollToToday() async {
    final now = DateTime.now();
    final todayEvents = filterEvents(data.events).where((event) {
      return event.timestamp.year == now.year &&
             event.timestamp.month == now.month &&
             event.timestamp.day == now.day;
    }).toList();

    if (todayEvents.isNotEmpty) {
      final firstTodayEvent = todayEvents.first;
      await navigateToEvent(firstTodayEvent.id);
    } else {
      // Find closest event to today
      final allEvents = filterEvents(data.events);
      if (allEvents.isNotEmpty) {
        final closestEvent = allEvents.reduce((a, b) {
          final aDiff = (a.timestamp.difference(now).inMilliseconds).abs();
          final bDiff = (b.timestamp.difference(now).inMilliseconds).abs();
          return aDiff < bDiff ? a : b;
        });
        await navigateToEvent(closestEvent.id);
      }
    }
  }

  void _showFilterOptions() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options coming soon')),
    );
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    final targetMonthKey = _getMonthKey(date);
    
    // Find the scroll offset for the target month
    double targetOffset = 0.0;
    bool found = false;
    
    final sortedMonths = _eventsByMonth.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (final monthKey in sortedMonths) {
      if (monthKey == targetMonthKey) {
        found = true;
        break;
      }
      
      // Estimate offset based on events in previous months
      final events = _eventsByMonth[monthKey]!;
      targetOffset += events.length * 120.0; // Approximate card height
      targetOffset += 60.0; // Header height
    }
    
    if (found) {
      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Future<void> navigateToEvent(String eventId) async {
    final event = data.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Event not found: $eventId'),
    );

    // Find which month contains this event
    final monthKey = _getMonthKey(event.timestamp);
    await navigateToDate(event.timestamp);

    // After scrolling to month, find and highlight the specific event
    await Future.delayed(const Duration(milliseconds: 400));
    
    // TODO: Implement event highlighting
  }

  @override
  List<TimelineEvent> getVisibleEvents() {
    return List.unmodifiable(_visibleEvents);
  }

  @override
  DateTimeRange? getVisibleDateRange() {
    if (_visibleEvents.isEmpty) return null;
    
    final dates = _visibleEvents.map((e) => e.timestamp).toList();
    dates.sort();
    
    return DateTimeRange(
      start: dates.first,
      end: dates.last,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Delegate for sticky month headers
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime monthDate;
  final int eventCount;

  const _MonthHeaderDelegate({
    required this.monthDate,
    required this.eventCount,
  });

  @override
  double get minExtent => 60.0;

  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                _formatMonth(monthDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$eventCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.calendar_month,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonth(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  bool shouldRebuild(_MonthHeaderDelegate oldDelegate) {
    return oldDelegate.monthDate != monthDate || 
           oldDelegate.eventCount != eventCount;
  }
}
