import '../services/timeline_renderer_interface.dart';
import '../renderers/life_stream_renderer.dart';
import '../renderers/map_view_renderer.dart';
import '../renderers/bento_grid_renderer.dart';

/// Factory for creating timeline renderers
class TimelineRendererFactory {
  /// Create a renderer for the specified view mode
  static ITimelineRenderer createRenderer(
    TimelineViewMode viewMode,
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) {
    switch (viewMode) {
      case TimelineViewMode.lifeStream:
        return LifeStreamRenderer(config, data);
      case TimelineViewMode.mapView:
        return MapViewRenderer(config, data);
      case TimelineViewMode.bentoGrid:
        return BentoGridRenderer(config, data);
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
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.mapView:
        return 'Map View';
      case TimelineViewMode.bentoGrid:
        return 'Grid View';
      default:
        return 'Unknown';
    }
  }

  /// Get description for a view mode
  static String getViewModeDescription(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.lifeStream:
        return 'Chronological timeline with infinite scroll';
      case TimelineViewMode.mapView:
        return 'Animated playback with location clustering';
      case TimelineViewMode.bentoGrid:
        return 'Life overview with density patterns';
      default:
        return 'Unknown view mode';
    }
  }

  /// Get icon for a view mode
  static String getViewModeIcon(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.lifeStream:
        return 'timeline';
      case TimelineViewMode.mapView:
        return 'map';
      case TimelineViewMode.bentoGrid:
        return 'grid_view';
      default:
        return 'help_outline';
    }
  }
}
