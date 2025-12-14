import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timeline_render_data.dart';
import '../models/view_state.dart';
import '../services/timeline_service.dart';
import '../renderers/timeline_renderer_interface.dart';
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
  ViewState _viewState = ViewState.loading;
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
    _renderers[TimelineViewMode.vertical] = EnhancedVerticalTimelineRenderer();
    _renderers[TimelineViewMode.lifeStream] = LifeStreamTimelineRenderer();
    _renderers[TimelineViewMode.clustered] = ClusteredTimelineRenderer();
    _renderers[TimelineViewMode.grid] = GridTimelineRenderer();
    _renderers[TimelineViewMode.map] = MapTimelineRenderer();
    _renderers[TimelineViewMode.story] = StoryTimelineRenderer();
    
    // Register all renderers with the timeline service
    for (final renderer in _renderers.values) {
      _timelineService.registerRenderer(renderer);
    }
  }
  
  /// Switch to a different view mode
  Future<bool> switchToView(TimelineViewMode viewMode) async {
    try {
      _viewState = ViewState.loading;
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
        activeContext: _timelineService.currentConfig.activeContext,
        selectedEventIds: _timelineService.currentConfig.selectedEventIds,
        showPrivateEvents: _timelineService.currentConfig.showPrivateEvents,
        zoomLevel: _timelineService.currentConfig.zoomLevel,
        customSettings: _timelineService.currentConfig.customSettings,
      );
      
      await _timelineService.updateConfig(newConfig);
      
      _currentViewMode = viewMode;
      _viewState = ViewState.ready;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _viewState = ViewState.error;
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
    String? activeContext,
    Set<String>? selectedEventIds,
    bool? showPrivateEvents,
    double? zoomLevel,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      _viewState = ViewState.loading;
      _errorMessage = null;
      
      final newConfig = TimelineRenderConfig(
        viewMode: _currentViewMode,
        startDate: startDate ?? _timelineService.currentConfig.startDate,
        endDate: endDate ?? _timelineService.currentConfig.endDate,
        activeContext: activeContext ?? _timelineService.currentConfig.activeContext,
        selectedEventIds: selectedEventIds ?? _timelineService.currentConfig.selectedEventIds,
        showPrivateEvents: showPrivateEvents ?? _timelineService.currentConfig.showPrivateEvents,
        zoomLevel: zoomLevel ?? _timelineService.currentConfig.zoomLevel,
        customSettings: customSettings ?? _timelineService.currentConfig.customSettings,
      );
      
      await _timelineService.updateConfig(newConfig);
      _viewState = ViewState.ready;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _viewState = ViewState.error;
      return false;
    }
  }
  
  /// Get available view modes with their display names
  Map<TimelineViewMode, String> getAvailableViews() {
    return {
      TimelineViewMode.vertical: 'Vertical Timeline',
      TimelineViewMode.lifeStream: 'Life Stream',
      TimelineViewMode.clustered: 'Clustered View',
      TimelineViewMode.grid: 'Grid View',
      TimelineViewMode.map: 'Map View',
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
      activeContext: null,
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
