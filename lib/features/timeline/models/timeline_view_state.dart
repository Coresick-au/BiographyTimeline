import 'package:freezed_annotation/freezed_annotation.dart';

part 'timeline_view_state.freezed.dart';

/// Timeline orientation (axis direction)
enum TimelineOrientation {
  vertical,   // Time flows top → bottom
  horizontal, // Time flows left → right
}

/// Display density mode
enum TimelineDisplayMode {
  minimal, // Icon-only markers, no cards unless selected
  maximal, // Full event cards with images, text, tags
}

/// Semantic zoom tier (determines aggregation level)
enum ZoomTier {
  year,  // One marker per year
  month, // Aggregated month markers
  week,  // Compact week markers
  day,   // Individual events visible
  focus, // Selected event emphasized
}

/// Unified timeline view state
/// 
/// Manages orientation, display mode, zoom level, viewport position,
/// and selection state for the timeline renderer.
@freezed
class TimelineViewState with _$TimelineViewState {
  const factory TimelineViewState({
    /// Timeline axis orientation
    @Default(TimelineOrientation.vertical) TimelineOrientation orientation,
    
    /// Display density mode
    @Default(TimelineDisplayMode.maximal) TimelineDisplayMode displayMode,
    
    /// Zoom level (0.0 = zoomed out, 1.0 = zoomed in)
    @Default(0.5) double zoomLevel,
    
    /// Current zoom tier (derived from zoomLevel)
    @Default(ZoomTier.day) ZoomTier zoomTier,
    
    /// Viewport start position in pixels (primary axis)
    @Default(0.0) double viewportStartPx,
    
    /// Pixels per day (derived from zoomLevel)
    /// Range: 0.2 (zoomed out) to 60.0 (zoomed in)
    @Default(10.0) double pixelsPerDay,
    
    /// Date currently focused/centered
    DateTime? focusedDate,
    
    /// Currently selected event ID
    String? selectedEventId,
    
    /// Expanded cluster IDs (for progressive disclosure)
    @Default({}) Set<String> expandedClusterIds,
  }) = _TimelineViewState;
  
  const TimelineViewState._();
  
  /// Calculate zoom tier from zoom level
  ZoomTier calculateZoomTier() {
    if (zoomLevel < 0.20) return ZoomTier.year;
    if (zoomLevel < 0.40) return ZoomTier.month;
    if (zoomLevel < 0.60) return ZoomTier.week;
    if (zoomLevel < 0.85) return ZoomTier.day;
    return ZoomTier.focus;
  }
  
  /// Calculate pixels per day from zoom level
  /// Uses linear interpolation: lerp(0.2, 60.0, zoomLevel)
  double calculatePixelsPerDay() {
    return 0.2 + (60.0 - 0.2) * zoomLevel;
  }
  
  /// Convert date to primary axis position
  double dateToPosition(DateTime date, DateTime minDate) {
    final dayIndex = date.difference(minDate).inDays;
    return dayIndex * pixelsPerDay;
  }
  
  /// Convert primary axis position to date
  DateTime positionToDate(double position, DateTime minDate) {
    final dayIndex = (position / pixelsPerDay).floor();
    return minDate.add(Duration(days: dayIndex));
  }
}
