import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart'; // Add this import
import '../models/timeline_render_data.dart';
import '../models/view_state.dart';
import '../services/timeline_service.dart';
import '../services/timeline_renderer_interface.dart';
import '../renderers/enhanced_vertical_timeline_renderer.dart';
import '../renderers/life_stream_timeline_renderer.dart';
import '../renderers/clustered_timeline_renderer.dart';
import '../renderers/grid_timeline_renderer.dart';
import '../renderers/map_timeline_renderer.dart';
import '../renderers/story_timeline_renderer.dart';

/// Service for managing timeline view switching and state
class TimelineViewSwitchService {
  final TimelineService _timelineService;
  final Map<TimelineViewMode, ITimelineRenderer> _renderers = {};
  
  TimelineViewMode _currentViewMode = TimelineViewMode.lifeStream;
  ViewState _viewState = const ViewState(viewMode: TimelineViewMode.lifeStream);
  String? _errorMessage;
  
  TimelineViewSwitchService(this._timelineService) {
    _initializeRenderers();
  }
  
  /// Current view mode
  TimelineViewMode get currentViewMode => _currentViewMode;
  
  /// Current view state
  ViewState get viewState => _viewState;
  
  /// Error message if any
  String? get errorMessage => _errorMessage;
  
  /// Get renderer for current view mode
  ITimelineRenderer? get currentRenderer => _renderers[_currentViewMode];
  
  /// Initialize all available renderers
  void _initializeRenderers() {
    // simplified initial config/data
    final initialConfig = _timelineService.currentConfig;
    final initialData = TimelineRenderData(
      events: _timelineService.events,
      contexts: _timelineService.contexts,
      earliestDate: DateTime.now(), // approximation
      latestDate: DateTime.now(),
      clusteredEvents: {},
    );

    _renderers[TimelineViewMode.chronological] = EnhancedVerticalTimelineRenderer(initialConfig, initialData);
    _renderers[TimelineViewMode.lifeStream] = LifeStreamTimelineRenderer(initialConfig, initialData);
    _renderers[TimelineViewMode.cluster] = ClusteredTimelineRenderer(initialConfig, initialData);
    _renderers[TimelineViewMode.bentoGrid] = GridTimelineRenderer(initialConfig, initialData);
    _renderers[TimelineViewMode.mapView] = MapTimelineRenderer(initialConfig, initialData);
    _renderers[TimelineViewMode.story] = StoryTimelineRenderer(initialConfig, initialData);
    
    // Register all renderers with the timeline service
    for (final renderer in _renderers.values) {
      _timelineService.registerRenderer(renderer);
    }
  }
  
  /// Switch to a different view mode
  Future<bool> switchToView(TimelineViewMode viewMode) async {
    try {
      // _viewState = ViewState.loading; // ViewState is freezed class now
      _errorMessage = null;
      
      // Check if renderer exists
      if (!_renderers.containsKey(viewMode)) {
        throw Exception('Renderer not available for view mode: $viewMode');
      }
      
      // Update configuration for the new view mode
      final newConfig = TimelineRenderConfig(
        viewMode: viewMode,
        startDate: _timelineService.currentConfig.startDate,
        endDate: _timelineService.currentConfig.endDate,
        selectedEventIds: _timelineService.currentConfig.selectedEventIds,
        showPrivateEvents: _timelineService.currentConfig.showPrivateEvents,
        zoomLevel: _timelineService.currentConfig.zoomLevel,
        customSettings: _timelineService.currentConfig.customSettings,
      );
      
      await _timelineService.updateConfig(newConfig);
      
      _currentViewMode = viewMode;
      // _viewState = ViewState.ready;
      _viewState = ViewState(viewMode: viewMode);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      // _viewState = ViewState.error;
      _viewState = ViewState(viewMode: viewMode);
      return false;
    }
  }
  
  /// Switch to next view mode in cycle
  Future<bool> switchToNextView() async {
    final allModes = TimelineViewMode.values;
    final currentIndex = allModes.indexOf(_currentViewMode);
    final nextIndex = (currentIndex + 1) % allModes.length;
    return await switchToView(allModes[nextIndex]);
  }
  
  /// Switch to previous view mode in cycle
  Future<bool> switchToPreviousView() async {
    final allModes = TimelineViewMode.values;
    final currentIndex = allModes.indexOf(_currentViewMode);
    final previousIndex = (currentIndex - 1 + allModes.length) % allModes.length;
    return await switchToView(allModes[previousIndex]);
  }
  
  /// Update view configuration
  Future<bool> updateViewConfig({
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? selectedEventIds,
    bool? showPrivateEvents,
    double? zoomLevel,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      // _viewState = ViewState.loading;
      _errorMessage = null;
      
      final newConfig = TimelineRenderConfig(
        viewMode: _currentViewMode,
        startDate: startDate ?? _timelineService.currentConfig.startDate,
        endDate: endDate ?? _timelineService.currentConfig.endDate,
        selectedEventIds: selectedEventIds ?? _timelineService.currentConfig.selectedEventIds,
        showPrivateEvents: showPrivateEvents ?? _timelineService.currentConfig.showPrivateEvents,
        zoomLevel: zoomLevel ?? _timelineService.currentConfig.zoomLevel,
        customSettings: customSettings ?? _timelineService.currentConfig.customSettings,
      );
      
      await _timelineService.updateConfig(newConfig);
      // _viewState = ViewState.ready;
      _viewState = ViewState(viewMode: _currentViewMode);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      // _viewState = ViewState.error;
      _viewState = ViewState(viewMode: _currentViewMode);
      return false;
    }
  }
  
  /// Get available view modes with their display names
  Map<TimelineViewMode, String> getAvailableViews() {
    return {
      TimelineViewMode.chronological: 'Vertical Timeline',
      TimelineViewMode.lifeStream: 'Life Stream',
      TimelineViewMode.cluster: 'Clustered View',
      TimelineViewMode.bentoGrid: 'Grid View',
      TimelineViewMode.mapView: 'Map View',
      TimelineViewMode.story: 'Story View',
    };
  }
  
  /// Check if a view mode is available
  bool isViewAvailable(TimelineViewMode viewMode) {
    return _renderers.containsKey(viewMode);
  }
  
  /// Reset view to default state
  Future<void> resetView() async {
    await switchToView(TimelineViewMode.lifeStream);
    await updateViewConfig(
      startDate: null,
      endDate: null,
      selectedEventIds: <String>{},
      showPrivateEvents: false,
      zoomLevel: 1.0,
      customSettings: <String, dynamic>{},
    );
  }
  
  /// Dispose resources
  void dispose() {
    for (final renderer in _renderers.values) {
      _timelineService.unregisterRenderer(renderer);
    }
    _renderers.clear();
  }
}

/// Provider for the timeline view switch service
final timelineViewSwitchServiceProvider = Provider<TimelineViewSwitchService>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  return TimelineViewSwitchService(timelineService);
});

/// Provider for current view mode
final currentViewModeProvider = Provider<TimelineViewMode>((ref) {
  final viewSwitchService = ref.watch(timelineViewSwitchServiceProvider);
  return viewSwitchService.currentViewMode;
});

/// Provider for current view state
final currentViewStateProvider = Provider<ViewState>((ref) {
  final viewSwitchService = ref.watch(timelineViewSwitchServiceProvider);
  return viewSwitchService.viewState;
});

/// Provider for current renderer
final currentRendererProvider = Provider<ITimelineRenderer?>((ref) {
  final viewSwitchService = ref.watch(timelineViewSwitchServiceProvider);
  return viewSwitchService.currentRenderer;
});
