import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timeline_renderer_interface.dart';

/// Provider for the current timeline view mode
/// This allows the navigation to reset the view when the Timeline tab is tapped
final timelineViewProvider = StateNotifierProvider<TimelineViewNotifier, TimelineViewMode>((ref) {
  return TimelineViewNotifier();
});

/// Notifier for managing timeline view mode state
class TimelineViewNotifier extends StateNotifier<TimelineViewMode> {
  TimelineViewNotifier() : super(TimelineViewMode.chronological);

  /// Set the current view mode
  void setViewMode(TimelineViewMode mode) {
    state = mode;
  }

  /// Reset to chronological view (default)
  void resetToDefault() {
    state = TimelineViewMode.chronological;
  }
}
