import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timeline_view_state.dart';
import '../models/render_node.dart';
import '../services/timeline_aggregation_service.dart';
import '../services/timeline_data_service.dart';
import 'timeline_provider.dart';

/// Provider for timeline view state
final timelineViewStateProvider = StateNotifierProvider<TimelineViewStateNotifier, TimelineViewState>((ref) {
  return TimelineViewStateNotifier();
});

/// Notifier for managing timeline view state
class TimelineViewStateNotifier extends StateNotifier<TimelineViewState> {
  TimelineViewStateNotifier() : super(const TimelineViewState());
  
  /// Set orientation
  void setOrientation(TimelineOrientation orientation) {
    state = state.copyWith(orientation: orientation);
  }
  
  /// Set display mode
  void setDisplayMode(TimelineDisplayMode mode) {
    state = state.copyWith(displayMode: mode);
  }
  
  /// Set zoom level (0.0-1.0)
  void setZoomLevel(double level) {
    final clamped = level.clamp(0.0, 1.0);
    final tier = _calculateZoomTier(clamped);
    final pixelsPerDay = _calculatePixelsPerDay(clamped);
    
    state = state.copyWith(
      zoomLevel: clamped,
      zoomTier: tier,
      pixelsPerDay: pixelsPerDay,
    );
  }
  
  /// Zoom in
  void zoomIn() {
    setZoomLevel(state.zoomLevel + 0.15);
  }
  
  /// Zoom out
  void zoomOut() {
    setZoomLevel(state.zoomLevel - 0.15);
  }
  
  /// Set viewport position
  void setViewportPosition(double position) {
    state = state.copyWith(viewportStartPx: position);
  }
  
  /// Pan viewport by delta
  void pan(double delta) {
    state = state.copyWith(
      viewportStartPx: (state.viewportStartPx + delta).clamp(0.0, double.infinity),
    );
  }
  
  /// Set focused date
  void setFocusedDate(DateTime? date) {
    state = state.copyWith(focusedDate: date);
  }
  
  /// Select event
  void selectEvent(String? eventId) {
    state = state.copyWith(selectedEventId: eventId);
  }
  
  /// Toggle cluster expansion
  void toggleCluster(String clusterId) {
    final expanded = Set<String>.from(state.expandedClusterIds);
    if (expanded.contains(clusterId)) {
      expanded.remove(clusterId);
    } else {
      expanded.add(clusterId);
      // Also zoom in slightly when expanding
      zoomIn();
    }
    state = state.copyWith(expandedClusterIds: expanded);
  }
  
  ZoomTier _calculateZoomTier(double zoomLevel) {
    if (zoomLevel < 0.20) return ZoomTier.year;
    if (zoomLevel < 0.40) return ZoomTier.month;
    if (zoomLevel < 0.60) return ZoomTier.week;
    if (zoomLevel < 0.85) return ZoomTier.day;
    return ZoomTier.focus;
  }
  
  double _calculatePixelsPerDay(double zoomLevel) {
    return 0.2 + (60.0 - 0.2) * zoomLevel;
  }
}

/// Provider for aggregation service
final aggregationServiceProvider = Provider<TimelineAggregationService>((ref) {
  return TimelineAggregationService();
});

/// Provider for render nodes (memoized)
final renderNodesProvider = Provider<List<RenderNode>>((ref) {
  final viewState = ref.watch(timelineViewStateProvider);
  final timelineState = ref.watch(timelineDataProvider);
  final aggregationService = ref.watch(aggregationServiceProvider);
  
  return timelineState.when(
    data: (state) {
      if (state.filteredEvents.isEmpty) return [];
      
      // Calculate visible date range
      final minDate = state.filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
      final maxDate = state.filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
      
      // For now, show all events (viewport filtering will be added later)
      final visibleStart = minDate.subtract(const Duration(days: 30));
      final visibleEnd = maxDate.add(const Duration(days: 30));
      
      return aggregationService.buildNodes(
        events: state.filteredEvents,
        tier: viewState.zoomTier,
        visibleStart: visibleStart,
        visibleEnd: visibleEnd,
        expandedClusterIds: viewState.expandedClusterIds,
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
