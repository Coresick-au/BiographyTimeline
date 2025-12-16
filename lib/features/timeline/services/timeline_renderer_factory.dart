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

  /// Get the display name for a view mode
  static String getViewModeDisplayName(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return 'Chronological';
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.bentoGrid:
        return 'Grid View';
      case TimelineViewMode.story:
        return 'Story View';
      case TimelineViewMode.mapView:
        return 'Enhanced Map';
      case TimelineViewMode.cluster:
        return 'Clustered';
      case TimelineViewMode.bubble:
        return 'Bubble View';
      case TimelineViewMode.swimlanes:
        return 'Swimlanes';
      case TimelineViewMode.river:
        return 'River Flow';
      default:
        return 'Timeline';
    }
  }

  /// Get the description for a view mode
  static String getViewModeDescription(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return 'Traditional timeline view ordered by date';
      case TimelineViewMode.lifeStream:
        return 'A continuous stream of life events';
      case TimelineViewMode.bentoGrid:
        return 'Bento box style grid layout';
      case TimelineViewMode.story:
        return 'Narrative flow through key moments';
      case TimelineViewMode.mapView:
        return 'Geographic visualization of your journey';
      case TimelineViewMode.cluster:
        return 'Events grouped by time periods or themes';
      case TimelineViewMode.bubble:
        return 'Interactive bubble visualization';
      case TimelineViewMode.swimlanes:
        return 'Parallel timelines for different contexts';
      case TimelineViewMode.river:
        return 'Flowing river of memories';
      default:
        return 'Standard timeline view';
    }
  }

  /// Get the icon name for a view mode
  static String getViewModeIcon(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return 'timeline';
      case TimelineViewMode.lifeStream:
        return 'stream';
      case TimelineViewMode.bentoGrid:
        return 'grid_view';
      case TimelineViewMode.story:
        return 'auto_stories';
      case TimelineViewMode.mapView:
        return 'map';
      case TimelineViewMode.cluster:
        return 'category';
      case TimelineViewMode.bubble:
        return 'bubble_chart';
      case TimelineViewMode.swimlanes:
        return 'view_week';
      case TimelineViewMode.river:
        return 'landscape';
      default:
        return 'timeline';
    }
  }
}
