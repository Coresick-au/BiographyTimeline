import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';
import '../views/bubble_overview_view.dart';

/// Renderer for the Bubble Overview mode
class BubbleTimelineRenderer extends BaseTimelineRenderer {
  BubbleTimelineRenderer(
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) : super(config, data);

  @override
  Widget build({
    BuildContext? context,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return BubbleOverviewView(
      events: data.events,
      onBubbleTap: (start, end) {
        // When a bubble is tapped, navigate to that date and switch to chronological/maximal view
        // effectively "zooming in"
        
        // This logic needs to be handled by the parent or via a callback that exposes more control.
        // For now, we can use the passed onDateTap if available, or just log.
        // Ideally, we want to perform a view switch here.
        
        if (onDateTap != null) {
          onDateTap(start);
        }
      },
    );
  }

  // Bubble view handles its own navigation/interaction for now
  // We can implement methods if we want to drive it externally
}
