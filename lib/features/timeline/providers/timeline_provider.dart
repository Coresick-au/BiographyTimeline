import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timeline_service.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Provider for the TimelineService
final timelineServiceProvider = Provider<TimelineService>((ref) {
  return TimelineService();
});

/// Provider for current timeline configuration
final timelineConfigProvider = StateProvider<TimelineRenderConfig>((ref) {
  return const TimelineRenderConfig(
    viewMode: TimelineViewMode.chronological,
    showPrivateEvents: true,
  );
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

/// Provider for active renderer
final activeRendererProvider = Provider<ITimelineRenderer?>((ref) {
  final service = ref.watch(timelineServiceProvider);
  final config = ref.watch(timelineConfigProvider);
  final renderData = ref.watch(timelineRenderDataProvider);
  
  // Only create renderer when data is available
  if (renderData is AsyncData<TimelineRenderData>) {
    return TimelineRendererFactory.createRenderer(
      config.viewMode,
      config,
      renderData.value,
    );
  }
  
  return null;
});

/// Provider for timeline statistics
final timelineStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return service.getStatistics();
});

/// Provider for available view modes
final availableViewModesProvider = Provider<List<TimelineViewMode>>((ref) {
  return TimelineRendererFactory.getAvailableViewModes();
});

/// Provider to handle timeline actions
class TimelineActions {
  final Ref ref;

  TimelineActions(this.ref);

  /// Update timeline configuration
  Future<void> updateConfig(TimelineRenderConfig config) async {
    final service = ref.read(timelineServiceProvider);
    await service.updateConfig(config);
    ref.read(timelineConfigProvider.notifier).state = config;
  }

  /// Add events to timeline
  Future<void> addEvents(List<TimelineEvent> events) async {
    final service = ref.read(timelineServiceProvider);
    await service.addEvents(events);
  }

  /// Remove events from timeline
  Future<void> removeEvents(List<String> eventIds) async {
    final service = ref.read(timelineServiceProvider);
    await service.removeEvents(eventIds);
  }

  /// Update an event
  Future<void> updateEvent(TimelineEvent event) async {
    final service = ref.read(timelineServiceProvider);
    await service.updateEvent(event);
  }

  /// Add contexts
  Future<void> addContexts(List<Context> contexts) async {
    final service = ref.read(timelineServiceProvider);
    await service.addContexts(contexts);
  }

  /// Remove contexts
  Future<void> removeContexts(List<String> contextIds) async {
    final service = ref.read(timelineServiceProvider);
    await service.removeContexts(contextIds);
  }

  /// Update a context
  Future<void> updateContext(Context context) async {
    final service = ref.read(timelineServiceProvider);
    await service.updateContext(context);
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

  /// Switch view mode
  Future<void> switchViewMode(TimelineViewMode viewMode) async {
    final currentConfig = ref.read(timelineConfigProvider);
    final newConfig = currentConfig.copyWith(viewMode: viewMode);
    await updateConfig(newConfig);
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
  }
}

/// Provider for timeline actions
final timelineActionsProvider = Provider<TimelineActions>((ref) {
  return TimelineActions(ref);
});

/// Notifier for managing timeline state
class TimelineNotifier extends StateNotifier<TimelineState> {
  final TimelineActions _actions;

  TimelineNotifier(this._actions) : super(const TimelineState());

  Future<void> initializeWithDemoData() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: Load demo data
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> switchViewMode(TimelineViewMode viewMode) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _actions.switchViewMode(viewMode);
      state = state.copyWith(
        isLoading: false,
        currentViewMode: viewMode,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// State for timeline
class TimelineState {
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final TimelineViewMode? currentViewMode;

  const TimelineState({
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.currentViewMode,
  });

  TimelineState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? error,
    TimelineViewMode? currentViewMode,
  }) {
    return TimelineState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      currentViewMode: currentViewMode ?? this.currentViewMode,
    );
  }
}

/// Provider for timeline notifier
final timelineNotifierProvider = StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  final actions = ref.watch(timelineActionsProvider);
  return TimelineNotifier(actions);
});
