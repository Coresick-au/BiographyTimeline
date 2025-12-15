import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import 'timeline_view_state.dart';

/// Base class for timeline render nodes
/// 
/// Nodes represent either individual events or clusters of events
/// at different zoom levels.
sealed class RenderNode {
  final DateTime start;
  final DateTime end;
  final ZoomTier tier; // Zoom tier for visual hierarchy
  double primaryPx; // Computed position on primary axis (x or y)
  
  RenderNode({
    required this.start,
    required this.end,
    this.tier = ZoomTier.day,
    this.primaryPx = 0.0,
  });
  
  /// Get unique identifier for this node
  String get id;
  
  /// Get display label for this node
  String get label;
}

/// Individual event node
class EventNode extends RenderNode {
  final String eventId;
  final EventType type;
  final String title;
  final bool hasMedia;
  final List<String> tags;
  final DateTime timestamp;
  
  EventNode({
    required this.eventId,
    required this.type,
    required this.title,
    required this.hasMedia,
    required this.tags,
    required this.timestamp,
    ZoomTier tier = ZoomTier.day,
  }) : super(
    start: timestamp,
    end: timestamp,
    tier: tier,
  );
  
  @override
  String get id => eventId;
  
  @override
  String get label => title;
  
  /// Create from TimelineEvent
  factory EventNode.fromEvent(TimelineEvent event) {
    return EventNode(
      eventId: event.id,
      type: event.eventType == 'milestone' ? EventType.milestone :
            event.eventType == 'photo' ? EventType.photo :
            event.eventType == 'note' ? EventType.note :
            EventType.other,
      title: event.title ?? 'Untitled Event',
      hasMedia: event.assets.isNotEmpty,
      tags: event.tags,
      timestamp: event.timestamp,
    );
  }
}

/// Cluster of events node
class ClusterNode extends RenderNode {
  final String clusterId;
  final int count;
  final Map<EventType, int> typeCounts;
  final EventType dominantType;
  final List<String> eventIds;
  
  ClusterNode({
    required this.clusterId,
    required this.count,
    required this.typeCounts,
    required this.dominantType,
    required this.eventIds,
    required DateTime start,
    required DateTime end,
    ZoomTier tier = ZoomTier.day,
  }) : super(start: start, end: end, tier: tier);
  
  @override
  String get id => clusterId;
  
  @override
  String get label => '$count events';
  
  /// Create cluster from list of events
  factory ClusterNode.fromEvents({
    required String id,
    required List<TimelineEvent> events,
  }) {
    if (events.isEmpty) {
      throw ArgumentError('Cannot create cluster from empty event list');
    }
    
    // Count event types
    final typeCounts = <EventType, int>{};
    for (final event in events) {
      final type = event.eventType == 'milestone' ? EventType.milestone :
                   event.eventType == 'photo' ? EventType.photo :
                   event.eventType == 'note' ? EventType.note :
                   EventType.other;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    
    // Find dominant type
    EventType dominantType = EventType.other;
    int maxCount = 0;
    typeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantType = type;
      }
    });
    
    // Get date range
    final timestamps = events.map((e) => e.timestamp).toList()..sort();
    
    return ClusterNode(
      clusterId: id,
      count: events.length,
      typeCounts: typeCounts,
      dominantType: dominantType,
      eventIds: events.map((e) => e.id).toList(),
      start: timestamps.first,
      end: timestamps.last,
    );
  }
}

/// Layout node with computed visual properties
class LayoutNode {
  final RenderNode node;
  final Rect? cardRect;       // null in minimal mode
  final Offset markerCenter;  // Always present
  final bool isLabelVisible;
  
  const LayoutNode({
    required this.node,
    this.cardRect,
    required this.markerCenter,
    required this.isLabelVisible,
  });
}

/// Event type enumeration (simplified)
enum EventType {
  milestone,
  photo,
  note,
  other,
}
