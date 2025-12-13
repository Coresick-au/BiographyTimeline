import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/timeline_data_service.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Main integration service that coordinates all timeline features
class TimelineIntegrationService {
  final TimelineDataService _dataService;
  final Map<String, ITimelineRenderer> _rendererCache = {};
  
  // Stream controllers for integration events
  final _integrationEventsController = StreamController<TimelineIntegrationEvent>.broadcast();
  
  TimelineIntegrationService(this._dataService);
  
  Stream<TimelineIntegrationEvent> get integrationEvents => _integrationEventsController.stream;

  /// Initialize all timeline features
  Future<void> initialize() async {
    try {
      // Initialize data service
      await _dataService.initialize();
      
      // Emit initialization complete event
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.initializationComplete,
          data: {'message': 'Timeline features initialized successfully'},
        ),
      );
      
      // Set up data service listeners for reactive updates
      _setupDataServiceListeners();
      
    } catch (e) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.error,
          data: {'error': e.toString()},
        ),
      );
      rethrow;
    }
  }

  /// Set up listeners for data service changes
  void _setupDataServiceListeners() {
    // Listen to events stream
    _dataService.eventsStream.listen((events) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.eventsUpdated,
          data: {'count': events.length},
        ),
      );
    });

    // Listen to contexts stream
    _dataService.contextsStream.listen((contexts) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.contextsUpdated,
          data: {'count': contexts.length},
        ),
      );
    });
  }

  /// Get or create a renderer with caching
  ITimelineRenderer getOrCreateRenderer(
    TimelineViewMode viewMode,
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) {
    final cacheKey = '${viewMode.name}_${config.hashCode}_${data.hashCode}';
    
    if (_rendererCache.containsKey(cacheKey)) {
      return _rendererCache[cacheKey]!;
    }

    final renderer = TimelineRendererFactory.createRenderer(viewMode, config, data);
    if (renderer != null) {
      _rendererCache[cacheKey] = renderer;
      
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.rendererCreated,
          data: {'viewMode': viewMode.name, 'cacheKey': cacheKey},
        ),
      );
    }
    
    return renderer!;
  }

  /// Clear renderer cache
  void clearRendererCache() {
    final count = _rendererCache.length;
    _rendererCache.clear();
    
    _integrationEventsController.add(
      TimelineIntegrationEvent(
        type: TimelineIntegrationEventType.rendererCacheCleared,
        data: {'clearedCount': count},
      ),
    );
  }

  /// Add event with integration hooks
  Future<void> addEventWithIntegration(TimelineEvent event) async {
    try {
      await _dataService.addEvent(event);
      
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.eventAdded,
          data: {'eventId': event.id, 'title': event.title},
        ),
      );
    } catch (e) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.error,
          data: {'error': 'Failed to add event: ${e.toString()}'},
        ),
      );
      rethrow;
    }
  }

  /// Update event with integration hooks
  Future<void> updateEventWithIntegration(TimelineEvent event) async {
    try {
      await _dataService.updateEvent(event);
      
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.eventUpdated,
          data: {'eventId': event.id, 'title': event.title},
        ),
      );
    } catch (e) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.error,
          data: {'error': 'Failed to update event: ${e.toString()}'},
        ),
      );
      rethrow;
    }
  }

  /// Remove event with integration hooks
  Future<void> removeEventWithIntegration(String eventId) async {
    try {
      await _dataService.removeEvent(eventId);
      
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.eventRemoved,
          data: {'eventId': eventId},
        ),
      );
    } catch (e) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.error,
          data: {'error': 'Failed to remove event: ${e.toString()}'},
        ),
      );
      rethrow;
    }
  }

  /// Export timeline with all features
  Future<Map<String, dynamic>> exportTimelineWithFeatures() async {
    try {
      final data = _dataService.exportData();
      
      // Add integration metadata
      data['integration'] = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'features': [
          'timeline_renderers',
          'data_service',
          'state_management',
          'navigation',
        ],
        'rendererCacheSize': _rendererCache.length,
      };
      
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.exportCompleted,
          data: {'eventCount': data['events'].length},
        ),
      );
      
      return data;
    } catch (e) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.error,
          data: {'error': 'Export failed: ${e.toString()}'},
        ),
      );
      rethrow;
    }
  }

  /// Import timeline with all features
  Future<void> importTimelineWithFeatures(Map<String, dynamic> data) async {
    try {
      await _dataService.importData(data);
      
      // Clear renderer cache after import to force refresh
      clearRendererCache();
      
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.importCompleted,
          data: {'eventCount': data['events']?.length ?? 0},
        ),
      );
    } catch (e) {
      _integrationEventsController.add(
        TimelineIntegrationEvent(
          type: TimelineIntegrationEventType.error,
          data: {'error': 'Import failed: ${e.toString()}'},
        ),
      );
      rethrow;
    }
  }

  /// Get integration status
  Map<String, dynamic> getIntegrationStatus() {
    return {
      'dataServiceInitialized': _dataService.events.isNotEmpty,
      'rendererCacheSize': _rendererCache.length,
      'availableViewModes': TimelineViewMode.values.length,
      'totalEvents': _dataService.events.length,
      'totalContexts': _dataService.contexts.length,
      'features': [
        'timeline_renderers',
        'data_service',
        'state_management',
        'navigation',
        'configuration_controls',
        'error_handling',
      ],
    };
  }

  /// Dispose resources
  void dispose() {
    _integrationEventsController.close();
    
    // Dispose all cached renderers
    for (final renderer in _rendererCache.values) {
      renderer.dispose();
    }
    _rendererCache.clear();
  }
}

/// Integration event types
enum TimelineIntegrationEventType {
  initializationComplete,
  eventsUpdated,
  contextsUpdated,
  rendererCreated,
  rendererCacheCleared,
  eventAdded,
  eventUpdated,
  eventRemoved,
  exportCompleted,
  importCompleted,
  error,
}

/// Integration event
class TimelineIntegrationEvent {
  final TimelineIntegrationEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  TimelineIntegrationEvent({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();
}

/// Provider for integration service
final timelineIntegrationServiceProvider = Provider<TimelineIntegrationService>((ref) {
  final dataService = ref.watch(timelineServiceProvider);
  return TimelineIntegrationService(dataService);
});

/// Provider for integration events stream
final timelineIntegrationEventsProvider = StreamProvider<TimelineIntegrationEvent>((ref) {
  final integrationService = ref.watch(timelineIntegrationServiceProvider);
  return integrationService.integrationEvents;
});

/// Provider for integration status
final timelineIntegrationStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final integrationService = ref.watch(timelineIntegrationServiceProvider);
  return integrationService.getIntegrationStatus();
});

/// Notifier for integration operations
class TimelineIntegrationNotifier extends StateNotifier<AsyncValue<void>> {
  final TimelineIntegrationService _service;

  TimelineIntegrationNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      await _service.initialize();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _service.addEventWithIntegration(event);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateEventWithIntegration(event);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeEventWithIntegration(eventId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> exportTimeline() async {
    state = const AsyncValue.loading();
    try {
      await _service.exportTimelineWithFeatures();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> importTimeline(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _service.importTimelineWithFeatures(data);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearRendererCache() {
    _service.clearRendererCache();
  }
}

/// Provider for integration notifier
final timelineIntegrationNotifierProvider = StateNotifierProvider<TimelineIntegrationNotifier, AsyncValue<void>>((ref) {
  final integrationService = ref.watch(timelineIntegrationServiceProvider);
  return TimelineIntegrationNotifier(integrationService);
});
