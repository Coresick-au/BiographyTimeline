import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../models/timeline_state.dart';
import 'timeline_repository.dart';
import 'timeline_filter_service.dart';
import 'timeline_clustering_service.dart';

/// Timeline data service managing the state of the timeline.
/// 
/// Migrated to Riverpod 2.4+ AsyncNotifier pattern.
class TimelineDataService extends AsyncNotifier<TimelineState> {
  late final LazyTimelineRepository _repository;
  late final TimelineFilterService _filterService;
  late final TimelineClusteringService _clusteringService;

  @override
  FutureOr<TimelineState> build() async {
    _repository = ref.watch(timelineRepositoryProvider);
    _filterService = ref.watch(timelineFilterServiceProvider);
    _clusteringService = ref.watch(timelineClusteringServiceProvider);

    // Initialize the repository
    await _repository.initialize();

    // Initial load
    return _loadData();
  }

  /// Load initial data from repository
  Future<TimelineState> _loadData() async {
    final events = await _repository.getEvents();
    final contexts = await _repository.getContexts();

    // Create initial state with default settings
    final initialState = TimelineState(
      allEvents: events,
      contexts: contexts,
    );

    // Apply initial processing
    return _processState(initialState);
  }

  /// Process the state (filter and cluster) based on current settings
  TimelineState _processState(TimelineState currentState) {
    // 1. Filter events
    final filtered = _filterService.filterEvents(
      events: currentState.allEvents,
      showPrivateEvents: currentState.showPrivateEvents,
      activeContextId: currentState.activeContextId,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
      eventFilter: currentState.eventFilter,
      currentViewerId: currentState.currentViewerId,
      timelineOwnerId: currentState.timelineOwnerId,
    );

    // 2. Filter contexts (if needed for privacy)
    final filteredContexts = _filterService.filterContexts(
      contexts: currentState.contexts,
      currentViewerId: currentState.currentViewerId,
      timelineOwnerId: currentState.timelineOwnerId,
    );

    // 3. Cluster events
    final clusters = _clusteringService.generateClusters(filtered);

    return currentState.copyWith(
      filteredEvents: filtered,
      contexts: filteredContexts, // Technically typically we might want to keep allContexts separately from visibleContexts, but for now this matches legacy behavior
      clusteredEvents: clusters,
    );
  }

  // --- Actions ---

  /// Refresh data from repository
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData());
  }

  /// Update settings and re-process state
  void updateSettings({
    bool? showPrivateEvents,
    String? activeContextId,
    DateTime? startDate,
    DateTime? endDate,
    String? eventFilter,
  }) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    final newState = currentState.copyWith(
      showPrivateEvents: showPrivateEvents ?? currentState.showPrivateEvents,
      activeContextId: activeContextId ?? currentState.activeContextId,
      startDate: startDate ?? currentState.startDate,
      endDate: endDate ?? currentState.endDate,
      eventFilter: eventFilter ?? currentState.eventFilter,
    );

    state = AsyncValue.data(_processState(newState));
  }
  
  void setActiveContext(String? contextId) {
    updateSettings(activeContextId: contextId);
  }

  /// Set privacy context
  void setPrivacyContext(String viewerId, String ownerId) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    final newState = currentState.copyWith(
      currentViewerId: viewerId,
      timelineOwnerId: ownerId,
    );

    state = AsyncValue.data(_processState(newState));
  }

  // --- CRUD Operations ---

  Future<void> addEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    await _repository.addEvent(event);
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> updateEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    await _repository.updateEvent(event);
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> removeEvent(String eventId) async {
    state = const AsyncValue.loading();
    await _repository.removeEvent(eventId);
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> addContext(Context context) async {
    state = const AsyncValue.loading();
    await _repository.addContext(context);
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> updateContext(Context context) async {
    state = const AsyncValue.loading();
    await _repository.updateContext(context);
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> removeContext(String contextId) async {
    state = const AsyncValue.loading();
    await _repository.removeContext(contextId);
    state = await AsyncValue.guard(() => _loadData());
  }
  
  /// Import data (Delegates to repository, then reloads)
  Future<void> importData(Map<String, dynamic> data) async {
     // TODO: Implement import in repository
     // await _repository.importData(data);
     state = await AsyncValue.guard(() => _loadData());
  }
}

/// Main Provider
final timelineDataProvider = AsyncNotifierProvider<TimelineDataService, TimelineState>(() {
  return TimelineDataService();
});
