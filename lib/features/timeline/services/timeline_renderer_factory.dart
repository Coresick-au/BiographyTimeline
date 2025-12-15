import '../services/timeline_renderer_interface.dart';
import '../renderers/vertical_timeline_renderer.dart';
import '../renderers/centered_vertical_timeline_renderer.dart';
import '../renderers/life_stream_timeline_renderer.dart';
import '../renderers/grid_timeline_renderer.dart';
import '../renderers/enhanced_vertical_timeline_renderer.dart';
import '../renderers/story_timeline_renderer.dart';
import '../renderers/river_timeline_renderer.dart';
import '../renderers/map_timeline_renderer.dart';
import '../renderers/clustered_timeline_renderer.dart';
import '../renderers/bubble_timeline_renderer.dart';
import '../renderers/swimlanes_timeline_renderer.dart';
import '../renderers/flow_timeline_renderer.dart';

/// Factory for creating timeline renderers based on view mode.
class TimelineRendererFactory {
  static ITimelineRenderer createRenderer(
    TimelineViewMode mode,
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return CenteredVerticalTimelineRenderer(config, data);
      case TimelineViewMode.lifeStream:
        return LifeStreamTimelineRenderer(config, data);
      case TimelineViewMode.bentoGrid:
        return GridTimelineRenderer(config, data);
      case TimelineViewMode.story:
        return StoryTimelineRenderer(config, data);
      case TimelineViewMode.mapView:
        return MapTimelineRenderer(config, data);
      case TimelineViewMode.cluster:
        return ClusteredTimelineRenderer(config, data);
      case TimelineViewMode.bubble:
        return BubbleTimelineRenderer(config, data);
      case TimelineViewMode.swimlanes:
        return SwimlanesTimelineRenderer(config, data);
      case TimelineViewMode.river:
        return FlowTimelineRenderer(config, data);
      default:
        // Fallback to vertical if unknown
        return VerticalTimelineRenderer(config, data);
    }
  }
}
