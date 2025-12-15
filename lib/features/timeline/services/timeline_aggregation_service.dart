import '../../../shared/models/timeline_event.dart';
import '../models/render_node.dart';
import '../models/timeline_view_state.dart';

/// Service for aggregating timeline events into render nodes
/// 
/// Precomputes buckets (year/month/week/day) and generates clusters
/// based on zoom tier and density thresholds.
class TimelineAggregationService {
  /// Cluster thresholds per tier
  static const int yearThreshold = 20;
  static const int monthThreshold = 30;
  static const int weekThreshold = 15;
  static const int dayThreshold = 8;
  
  /// Build render nodes from events
  /// 
  /// Returns a list of EventNodes or ClusterNodes based on the current
  /// zoom tier and visible date range.
  List<RenderNode> buildNodes({
    required List<TimelineEvent> events,
    required ZoomTier tier,
    required DateTime visibleStart,
    required DateTime visibleEnd,
    required Set<String> expandedClusterIds,
  }) {
    if (events.isEmpty) return [];
    
    // Filter to visible range
    final visibleEvents = events.where((e) {
      return e.timestamp.isAfter(visibleStart) && 
             e.timestamp.isBefore(visibleEnd);
    }).toList();
    
    if (visibleEvents.isEmpty) return [];
    
    // Aggregate based on tier
    switch (tier) {
      case ZoomTier.year:
        return _aggregateByYear(visibleEvents, expandedClusterIds);
      case ZoomTier.month:
        return _aggregateByMonth(visibleEvents, expandedClusterIds);
      case ZoomTier.week:
        return _aggregateByWeek(visibleEvents, expandedClusterIds);
      case ZoomTier.day:
        return _aggregateByDay(visibleEvents, expandedClusterIds);
      case ZoomTier.focus:
        // Show all individual events at focus level
        return visibleEvents.map((e) => EventNode.fromEvent(e)).toList();
    }
  }
  
  /// Aggregate events by year
  List<RenderNode> _aggregateByYear(
    List<TimelineEvent> events,
    Set<String> expandedClusterIds,
  ) {
    final buckets = <int, List<TimelineEvent>>{};
    
    for (final event in events) {
      final year = event.timestamp.year;
      buckets.putIfAbsent(year, () => []).add(event);
    }
    
    final nodes = <RenderNode>[];
    
    buckets.forEach((year, yearEvents) {
      final clusterId = 'year_$year';
      
      // Always cluster at year level unless very few total events
      if (yearEvents.length <= yearThreshold || 
          expandedClusterIds.contains(clusterId)) {
        // Show individual events
        nodes.addAll(yearEvents.map((e) => EventNode.fromEvent(e)));
      } else {
        // Create cluster
        nodes.add(ClusterNode.fromEvents(
          id: clusterId,
          events: yearEvents,
        ));
      }
    });
    
    return nodes;
  }
  
  /// Aggregate events by month
  List<RenderNode> _aggregateByMonth(
    List<TimelineEvent> events,
    Set<String> expandedClusterIds,
  ) {
    final buckets = <String, List<TimelineEvent>>{};
    
    for (final event in events) {
      final key = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(key, () => []).add(event);
    }
    
    final nodes = <RenderNode>[];
    
    buckets.forEach((monthKey, monthEvents) {
      final clusterId = 'month_$monthKey';
      
      if (monthEvents.length <= monthThreshold || 
          expandedClusterIds.contains(clusterId)) {
        nodes.addAll(monthEvents.map((e) => EventNode.fromEvent(e)));
      } else {
        nodes.add(ClusterNode.fromEvents(
          id: clusterId,
          events: monthEvents,
        ));
      }
    });
    
    return nodes;
  }
  
  /// Aggregate events by week
  List<RenderNode> _aggregateByWeek(
    List<TimelineEvent> events,
    Set<String> expandedClusterIds,
  ) {
    final buckets = <String, List<TimelineEvent>>{};
    
    for (final event in events) {
      final weekKey = _getISOWeekKey(event.timestamp);
      buckets.putIfAbsent(weekKey, () => []).add(event);
    }
    
    final nodes = <RenderNode>[];
    
    buckets.forEach((weekKey, weekEvents) {
      final clusterId = 'week_$weekKey';
      
      if (weekEvents.length <= weekThreshold || 
          expandedClusterIds.contains(clusterId)) {
        nodes.addAll(weekEvents.map((e) => EventNode.fromEvent(e)));
      } else {
        nodes.add(ClusterNode.fromEvents(
          id: clusterId,
          events: weekEvents,
        ));
      }
    });
    
    return nodes;
  }
  
  /// Aggregate events by day
  List<RenderNode> _aggregateByDay(
    List<TimelineEvent> events,
    Set<String> expandedClusterIds,
  ) {
    final buckets = <String, List<TimelineEvent>>{};
    
    for (final event in events) {
      final dayKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}-${event.timestamp.day.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(dayKey, () => []).add(event);
    }
    
    final nodes = <RenderNode>[];
    
    buckets.forEach((dayKey, dayEvents) {
      final clusterId = 'day_$dayKey';
      
      if (dayEvents.length <= dayThreshold || 
          expandedClusterIds.contains(clusterId)) {
        nodes.addAll(dayEvents.map((e) => EventNode.fromEvent(e)));
      } else {
        nodes.add(ClusterNode.fromEvents(
          id: clusterId,
          events: dayEvents,
        ));
      }
    });
    
    return nodes;
  }
  
  /// Get ISO week key (year-week format)
  String _getISOWeekKey(DateTime date) {
    // Simple week calculation (Monday-based)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final weekNumber = ((dayOfYear + DateTime(date.year, 1, 1).weekday - 1) / 7).floor() + 1;
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
