import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/view_state.dart';
import '../services/timeline_renderer_interface.dart';

/// Manages view state preservation across timeline view mode transitions.
/// 
/// This service stores and restores view-specific state (scroll position,
/// filters, zoom level) when users switch between different timeline views
/// (Life Stream, Map, Grid, etc.).
class ViewStateManager extends StateNotifier<Map<TimelineViewMode, ViewState>> {
  ViewStateManager() : super({});

  /// Save the current state for a specific view mode
  void saveViewState(TimelineViewMode mode, ViewState viewState) {
    state = {...state, mode: viewState};
  }

  /// Retrieve saved state for a specific view mode
  ViewState? getViewState(TimelineViewMode mode) {
    return state[mode];
  }

  /// Restore view state to a renderer
  /// 
  /// This method applies saved state (scroll position, zoom, focused event)
  /// to the renderer after a view transition.
  Future<void> restoreViewState(
    TimelineViewMode mode,
    ITimelineRenderer renderer,
  ) async {
    final savedState = state[mode];
    if (savedState == null) return;

    // Restore focused event (which may trigger scroll)
    if (savedState.focusedEventId != null) {
      await renderer.navigateToEvent(savedState.focusedEventId!);
    }

    // Restore zoom level
    if (savedState.zoomLevel != 1.0) {
      await renderer.setZoomLevel(savedState.zoomLevel);
    }

    // Note: Scroll position restoration is handled implicitly by navigateToEvent
    // or can be implemented via renderer-specific APIs if needed
  }

  /// Clear saved state for a specific view mode
  void clearViewState(TimelineViewMode mode) {
    final newState = Map<TimelineViewMode, ViewState>.from(state);
    newState.remove(mode);
    state = newState;
  }

  /// Clear all saved view states
  void clearAllViewStates() {
    state = {};
  }
}

/// Provider for ViewStateManager
final viewStateManagerProvider = StateNotifierProvider<ViewStateManager, Map<TimelineViewMode, ViewState>>((ref) {
  return ViewStateManager();
});
