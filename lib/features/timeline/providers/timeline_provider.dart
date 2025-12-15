import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timeline_service.dart';
import '../services/timeline_view_switch_service.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../models/view_state.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Provider for the TimelineService
final timelineServiceProvider = Provider<TimelineService>((ref) {
  return TimelineService();
});

/// Provider for current timeline configuration (now uses view switch service)
final timelineConfigProvider = Provider<TimelineRenderConfig>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return service.currentConfig;
});

/// Provider for timeline render data
final timelineRenderDataProvider = FutureProvider<TimelineRenderData>((ref) async {
  final service = ref.watch(timelineServiceProvider);
  return TimelineRenderData(
    events: service.events,
    contexts: service.contexts,
    earliestDate: service.events.isEmpty ? DateTime.now() : 
                 service.events.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
    latestDate: service.events.isEmpty ? DateTime.now() : 
               service.events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
    clusteredEvents: service.getClusteredEvents(),
  );
});

/// Provider for active renderer (now uses view switch service)
final activeRendererProvider = Provider<ITimelineRenderer?>((ref) {
  final viewSwitchService = ref.watch(timelineViewSwitchServiceProvider);
  return viewSwitchService.currentRenderer;
});

/// Provider for timeline statistics
final timelineStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return service.getStatistics();
});

/// Provider for available view modes (now uses view switch service)
final availableViewModesProvider = Provider<Map<TimelineViewMode, String>>((ref) {
  final viewSwitchService = ref.watch(timelineViewSwitchServiceProvider);
  return viewSwitchService.getAvailableViews();
});

/// Provider to handle timeline actions
class TimelineActions {
  final Ref ref;

  TimelineActions(this.ref);

  /// Load events from the service
  Future<void> loadEvents() async {
    final service = ref.read(timelineServiceProvider);
    await service.loadEvents();
    // Force the UI to rebuild with new data
    ref.invalidate(timelineRenderDataProvider);
  }

  /// Update timeline configuration
  Future<void> updateConfig(TimelineRenderConfig config) async {
    final service = ref.read(timelineServiceProvider);
    await service.updateConfig(config);
    ref.invalidate(timelineConfigProvider);
    ref.invalidate(timelineRenderDataProvider);
  }

  /// Add events to timeline
  Future<void> addEvents(List<TimelineEvent> events) async {
    final service = ref.read(timelineServiceProvider);
    await service.addEvents(events);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }

  /// Remove events from timeline
  Future<void> removeEvents(List<String> eventIds) async {
    final service = ref.read(timelineServiceProvider);
    await service.removeEvents(eventIds);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }

  /// Update an event
  Future<void> updateEvent(TimelineEvent event) async {
    final service = ref.read(timelineServiceProvider);
    await service.updateEvent(event);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }

  /// Add contexts
  Future<void> addContexts(List<Context> contexts) async {
    final service = ref.read(timelineServiceProvider);
    await service.addContexts(contexts);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }

  /// Remove contexts
  Future<void> removeContexts(List<String> contextIds) async {
    final service = ref.read(timelineServiceProvider);
    await service.removeContexts(contextIds);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }

  /// Update a context
  Future<void> updateContext(Context context) async {
    final service = ref.read(timelineServiceProvider);
    await service.updateContext(context);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }

  /// Navigate to specific date
  Future<void> navigateToDate(DateTime date) async {
    final renderer = ref.read(activeRendererProvider);
    if (renderer != null) {
      await renderer.navigateToDate(date);
    }
  }

  /// Navigate to specific event
  Future<void> navigateToEvent(String eventId) async {
    final renderer = ref.read(activeRendererProvider);
    if (renderer != null) {
      await renderer.navigateToEvent(eventId);
    }
  }

  /// Switch view mode (now uses view switch service)
  Future<void> switchViewMode(TimelineViewMode viewMode) async {
    final viewSwitchService = ref.read(timelineViewSwitchServiceProvider);
    await viewSwitchService.switchToView(viewMode);
  }

  /// Search events
  List<TimelineEvent> searchEvents(String query) {
    final service = ref.read(timelineServiceProvider);
    return service.searchEvents(query);
  }

  /// Get events in date range
  List<TimelineEvent> getEventsInRange(DateTime start, DateTime end) {
    final service = ref.read(timelineServiceProvider);
    return service.getEventsInRange(start, end);
  }

  /// Get events for context
  List<TimelineEvent> getEventsForContext(String contextId) {
    final service = ref.read(timelineServiceProvider);
    return service.getEventsForContext(contextId);
  }

  /// Export timeline data
  Map<String, dynamic> exportData() {
    final service = ref.read(timelineServiceProvider);
    return service.exportData();
  }

  /// Import timeline data
  Future<void> importData(Map<String, dynamic> data) async {
    final service = ref.read(timelineServiceProvider);
    await service.importData(data);
    ref.invalidate(timelineRenderDataProvider); // Refresh UI
  }
}

/// Provider for timeline actions
final timelineActionsProvider = Provider<TimelineActions>((ref) {
  return TimelineActions(ref);
});

/// Provider for current view state
final currentViewStateProvider = Provider<ViewState>((ref) {
  final viewSwitchService = ref.watch(timelineViewSwitchServiceProvider);
  return viewSwitchService.viewState;
});
