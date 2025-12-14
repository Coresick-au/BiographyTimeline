import '../services/timeline_renderer_interface.dart';
import '../renderers/vertical_timeline_renderer.dart';
import '../renderers/life_stream_timeline_renderer.dart';
import '../renderers/grid_timeline_renderer.dart';
import '../renderers/enhanced_vertical_timeline_renderer.dart';
import '../renderers/story_timeline_renderer.dart';
import '../renderers/river_timeline_renderer.dart';

/// Factory for creating timeline renderers based on view mode.
class TimelineRendererFactory {
  static ITimelineRenderer createRenderer(
    TimelineViewMode mode,
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return VerticalTimelineRenderer();
      case TimelineViewMode.lifeStream:
        return LifeStreamTimelineRenderer(
          config,
          data,
        );
      case TimelineViewMode.bentoGrid:
        return GridTimelineRenderer(); // Assuming constructor allows empty or refactor later
      case TimelineViewMode.story:
        return StoryTimelineRenderer(
          config,
          data,
        );
      case TimelineViewMode.mapView:
      case TimelineViewMode.clustered:
        // Default to chronological for unsupported modes
        return VerticalTimelineRenderer();
      case TimelineViewMode.river:
        return RiverTimelineRenderer(
          config,
          data,
        );
    }
  }
}
