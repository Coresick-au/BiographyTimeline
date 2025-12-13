import '../services/timeline_renderer_interface.dart';
import '../renderers/chronological_timeline_renderer.dart';
import '../renderers/clustered_timeline_renderer.dart';
import '../renderers/map_timeline_renderer.dart';
import '../renderers/enhanced_map_timeline_renderer.dart';
import '../renderers/story_timeline_renderer.dart';
import '../renderers/life_stream_timeline_renderer.dart';
import '../renderers/bento_grid_timeline_renderer.dart';
import '../renderers/river_timeline_renderer.dart';

/// Factory for creating timeline renderers
class TimelineRendererFactory {
  /// Create a renderer for the specified view mode
  static ITimelineRenderer createRenderer(
    TimelineViewMode viewMode,
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) {
    switch (viewMode) {
      case TimelineViewMode.chronological:
        return ChronologicalTimelineRenderer(config, data);
      case TimelineViewMode.clustered:
        return ClusteredTimelineRenderer(config, data);
      case TimelineViewMode.mapView:
        final renderer = EnhancedMapTimelineRenderer();
        renderer.initialize(config);
        renderer.updateData(data);
        return renderer;
      case TimelineViewMode.story:
        return StoryTimelineRenderer(config, data);
      case TimelineViewMode.lifeStream:
        return LifeStreamTimelineRenderer(config, data);
      case TimelineViewMode.bentoGrid:
        return BentoGridTimelineRenderer(config, data);
      case TimelineViewMode.river:
        final renderer = RiverTimelineRenderer();
        renderer.initialize(config);
        renderer.updateData(data);
        return renderer;
      default:
        throw ArgumentError('Unsupported view mode: $viewMode');
    }
  }

  /// Get all available view modes
  static List<TimelineViewMode> getAvailableViewModes() {
    return TimelineViewMode.values;
  }

  /// Check if a view mode is supported
  static bool isViewModeSupported(TimelineViewMode viewMode) {
    return TimelineViewMode.values.contains(viewMode);
  }

  /// Get display name for a view mode
  static String getViewModeDisplayName(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.chronological:
        return 'Chronological';
      case TimelineViewMode.clustered:
        return 'Clustered';
      case TimelineViewMode.mapView:
        return 'Enhanced Map';
      case TimelineViewMode.story:
        return 'Story View';
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.bentoGrid:
        return 'Grid View';
      case TimelineViewMode.river:
        return 'River View';
      default:
        return 'Unknown';
    }
  }

  /// Get description for a view mode
  static String getViewModeDescription(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.chronological:
        return 'Traditional timeline with infinite scroll';
      case TimelineViewMode.clustered:
        return 'Events grouped by time periods and themes';
      case TimelineViewMode.mapView:
        return 'Geographic visualization with location clustering';
      case TimelineViewMode.story:
        return 'Narrative flow with scrollytelling';
      case TimelineViewMode.lifeStream:
        return 'Chronological timeline with infinite scroll';
      case TimelineViewMode.bentoGrid:
        return 'Life overview with density patterns';
      case TimelineViewMode.river:
        return 'Sankey-style visualization of merged timelines';
      default:
        return 'Unknown view mode';
    }
  }

  /// Get icon for a view mode
  static String getViewModeIcon(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.chronological:
        return 'timeline';
      case TimelineViewMode.clustered:
        return 'category';
      case TimelineViewMode.mapView:
        return 'map';
      case TimelineViewMode.story:
        return 'auto_stories';
      case TimelineViewMode.lifeStream:
        return 'timeline';
      case TimelineViewMode.bentoGrid:
        return 'grid_view';
      case TimelineViewMode.river:
        return 'water';
      default:
        return 'help_outline';
    }
  }
}
