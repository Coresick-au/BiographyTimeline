import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Interface for timeline renderers
abstract class ITimelineRenderer {
  /// Build the timeline widget
  Widget build({
    required List<TimelineEvent> events,
    required List<Context> contexts,
    required Function(TimelineEvent) onEventTap,
    required Function(TimelineEvent) onEventLongPress,
    required Function(DateTime) onDateTap,
    required Function(Context) onContextTap,
    ScrollController? scrollController,
  });
  
  /// Initialize the renderer with configuration
  Future<void> initialize(dynamic config);
  
  /// Dispose resources
  void dispose();
}
