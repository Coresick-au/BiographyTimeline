import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';
import '../services/timeline_renderer_interface.dart';
import '../../social/services/privacy_settings_service.dart';
import 'package:flutter/foundation.dart';

/// Timeline data service for managing events, contexts, and data operations
class TimelineDataService {
  final List<TimelineEvent> _events = [];
  final List<Context> _contexts = [];
  final Map<String, List<TimelineEvent>> _clusteredEvents = {};
  final PrivacySettingsService _privacyService = PrivacySettingsService();
  
  // Stream controllers for reactive updates
  final _eventsController = StreamController<List<TimelineEvent>>.broadcast();
  final _contextsController = StreamController<List<Context>>.broadcast();
  final _clustersController = StreamController<Map<String, List<TimelineEvent>>>.broadcast();
  
  // Settings and filters
  bool _showPrivateEvents = true;
  String? _activeContextId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _eventFilter = 'all'; // all, photos, milestones, text
  String? _currentViewerId; // ID of user viewing the timeline
  String? _timelineOwnerId; // ID of user who owns the timeline

  // Getters
  List<TimelineEvent> get events => _getFilteredEvents();
  List<Context> get contexts => _getPrivacyFilteredContexts(_contexts);
  Map<String, List<TimelineEvent>> get clusteredEvents => Map.unmodifiable(_clusteredEvents);
  
  // Streams
  Stream<List<TimelineEvent>> get eventsStream => _eventsController.stream;
  Stream<List<Context>> get contextsStream => _contextsController.stream;
  Stream<Map<String, List<TimelineEvent>>> get clustersStream => _clustersController.stream;

  // Settings getters
  bool get showPrivateEvents => _showPrivateEvents;
  String? get activeContextId => _activeContextId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get eventFilter => _eventFilter;

  /// Initialize the data service with sample data
  Future<void> initialize() async {
    if (_events.isEmpty) {
      _createSampleData();
      _updateStreams();
    }
  }

  /// Create sample data for testing
  void _createSampleData() {
    final now = DateTime.now();
    
    // Create sample contexts
    _contexts.addAll([
      Context(
        id: 'context-1',
        ownerId: 'user-1',
        type: ContextType.person,
        name: 'Personal Timeline',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now,
      ),
      Context(
        id: 'context-2',
        ownerId: 'user-1',
        type: ContextType.person,
        name: 'Career Journey',
        moduleConfiguration: {},
        themeId: 'career',
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ),
    ]);

    // Create sample events
    _events.addAll([
      TimelineEvent.create(
        id: 'event-1',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 30)),
        eventType: 'photo',
        title: 'Summer Vacation',
        description: 'Beautiful sunset at the beach with friends and family. Amazing memories created during this wonderful trip.',
        location: GeoLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          locationName: 'San Francisco, CA',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 20)),
        eventType: 'milestone',
        title: 'Started New Job',
        description: 'First day at the new company. Excited about this new opportunity and the challenges ahead.',
      ),
      TimelineEvent.create(
        id: 'event-3',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 15)),
        eventType: 'photo',
        title: 'Weekend Adventure',
        description: 'Hiking in the mountains. The views were breathtaking and the weather was perfect.',
        location: GeoLocation(
          latitude: 37.8651,
          longitude: -119.5383,
          locationName: 'Yosemite National Park',
        ),
      ),
      TimelineEvent.create(
        id: 'event-4',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 10)),
        eventType: 'text',
        title: 'Project Milestone',
        description: 'Successfully completed the first phase of the major project. Team celebration followed.',
      ),
      TimelineEvent.create(
        id: 'event-5',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 5)),
        eventType: 'photo',
        title: 'Family Gathering',
        description: 'Wonderful reunion with extended family. So great to see everyone together again.',
        location: GeoLocation(
          latitude: 34.0522,
          longitude: -118.2437,
          locationName: 'Los Angeles, CA',
        ),
      ),
      TimelineEvent.create(
        id: 'event-6',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 3)),
        eventType: 'milestone',
        title: 'Promotion!',
        description: 'Well-deserved promotion after months of hard work and dedication to the team.',
      ),
      TimelineEvent.create(
        id: 'event-7',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 1)),
        eventType: 'text',
        title: 'Weekend Reflection',
        description: 'Time to pause and reflect on the journey so far. Grateful for all the experiences and people in my life.',
      ),
    ]);

    // Create some clusters for demonstration
    _clusteredEvents['Recent'] = _events.where((e) => 
      e.timestamp.isAfter(now.subtract(const Duration(days: 7)))
    ).toList();
    
    _clusteredEvents['This Month'] = _events.where((e) => 
      e.timestamp.isAfter(now.subtract(const Duration(days: 30)))
    ).toList();
    
    _clusteredEvents['Career'] = _events.where((e) => 
      e.contextId == 'context-2'
    ).toList();
    
    _clusteredEvents['Personal'] = _events.where((e) => 
      e.contextId == 'context-1'
    ).toList();
  }

  /// Load sample data (will be replaced with real data loading)
  Future<void> _loadSampleData() async {
    final now = DateTime.now();
    
    // Sample contexts
    _contexts.addAll([
      Context(
        id: 'context-1',
        ownerId: 'user-1',
        type: ContextType.person,
        name: 'Personal Timeline',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now,
      ),
      Context(
        id: 'context-2',
        ownerId: 'user-1',
        type: ContextType.person,
        name: 'Adventures',
        moduleConfiguration: {},
        themeId: 'adventure',
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ),
      Context(
        id: 'context-3',
        ownerId: 'user-1',
        type: ContextType.pet,
        name: 'Pet Journey',
        moduleConfiguration: {},
        themeId: 'pets',
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now,
      ),
    ]);

    // Sample events
    _events.addAll([
      TimelineEvent.create(
        id: 'event-1',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 30)),
        eventType: 'photo',
        title: 'Summer Vacation',
        description: 'Beautiful sunset at the beach',
        location: GeoLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          locationName: 'San Francisco, CA',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 20)),
        eventType: 'milestone',
        title: 'Started New Job',
        description: 'First day at the new company',
      ),
      TimelineEvent.create(
        id: 'event-3',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 15)),
        eventType: 'photo',
        title: 'Mountain Hiking',
        description: 'Reached the summit after a long hike',
        location: GeoLocation(
          latitude: 37.8651,
          longitude: -119.5383,
          locationName: 'Yosemite National Park',
        ),
      ),
      TimelineEvent.create(
        id: 'event-4',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 10)),
        eventType: 'text',
        title: 'Pet Birthday',
        description: 'Celebrated my pet\'s 5th birthday',
      ),
      TimelineEvent.create(
        id: 'event-5',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 5)),
        eventType: 'photo',
        title: 'Weekend Adventure',
        description: 'Exploring new trails',
        location: GeoLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          locationName: 'San Francisco, CA',
        ),
      ),
    ]);

    // Generate clusters
    _generateClusters();
  }

  /// Get filtered events based on current settings
  List<TimelineEvent> _getFilteredEvents() {
    var filteredEvents = List<TimelineEvent>.from(_events);

    // Apply privacy filtering first
    filteredEvents = _getPrivacyFilteredEvents(filteredEvents);

    // Filter by private events
    if (!_showPrivateEvents) {
      filteredEvents = filteredEvents.where((event) => 
        event.privacyLevel != PrivacyLevel.private).toList();
    }

    // Filter by active context
    if (_activeContextId != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.contextId == _activeContextId).toList();
    }

    // Filter by date range
    if (_startDate != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.timestamp.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.timestamp.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }

    // Filter by event type
    switch (_eventFilter) {
      case 'photos':
        filteredEvents = filteredEvents.where((event) => 
          event.eventType == 'photo').toList();
        break;
      case 'milestones':
        filteredEvents = filteredEvents.where((event) => 
          event.eventType == 'milestone').toList();
        break;
      case 'text':
        filteredEvents = filteredEvents.where((event) => 
          event.eventType == 'text').toList();
        break;
    }

    return filteredEvents;
  }

  /// Generate event clusters
  void _generateClusters() {
    _clusteredEvents.clear();
    
    // Cluster by month
    final eventsByMonth = <String, List<TimelineEvent>>{};
    for (final event in _getFilteredEvents()) {
      final monthKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}';
      eventsByMonth.putIfAbsent(monthKey, () => []).add(event);
    }
    
    _clusteredEvents.addAll(eventsByMonth);
  }

  /// Update all streams
  void _updateStreams() {
    _eventsController.add(events);
    _contextsController.add(contexts);
    _clustersController.add(clusteredEvents);
  }

  /// Add new event
  Future<void> addEvent(TimelineEvent event) async {
    _events.add(event);
    _generateClusters();
    _updateStreams();
  }

  /// Add multiple events
  Future<void> addEvents(List<TimelineEvent> events) async {
    _events.addAll(events);
    _generateClusters();
    _updateStreams();
  }

  /// Update existing event
  Future<void> updateEvent(TimelineEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      _generateClusters();
      _updateStreams();
    }
  }

  /// Remove event
  Future<void> removeEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
    _generateClusters();
    _updateStreams();
  }

  /// Add new context
  Future<void> addContext(Context context) async {
    _contexts.add(context);
    _updateStreams();
  }

  /// Update existing context
  Future<void> updateContext(Context context) async {
    final index = _contexts.indexWhere((c) => c.id == context.id);
    if (index != -1) {
      _contexts[index] = context;
      _updateStreams();
    }
  }

  /// Remove context
  Future<void> removeContext(String contextId) async {
    _contexts.removeWhere((context) => context.id == contextId);
    // Also remove events from this context
    _events.removeWhere((event) => event.contextId == contextId);
    _generateClusters();
    _updateStreams();
  }

  /// Update settings
  void updateSettings({
    bool? showPrivateEvents,
    String? activeContextId,
    DateTime? startDate,
    DateTime? endDate,
    String? eventFilter,
  }) {
    if (showPrivateEvents != null) _showPrivateEvents = showPrivateEvents;
    if (activeContextId != null) _activeContextId = activeContextId;
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    if (eventFilter != null) _eventFilter = eventFilter;
    
    _generateClusters();
    _updateStreams();
  }

  /// Get events for specific context
  List<TimelineEvent> getEventsForContext(String contextId) {
    return _events.where((event) => event.contextId == contextId).toList();
  }

  /// Get events in date range
  List<TimelineEvent> getEventsInRange(DateTime start, DateTime end) {
    return _events.where((event) => 
      event.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
      event.timestamp.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  /// Search events
  List<TimelineEvent> searchEvents(String query) {
    if (query.isEmpty) return events;
    
    final lowerQuery = query.toLowerCase();
    return events.where((event) => 
      (event.title?.toLowerCase().contains(lowerQuery) ?? false) ||
      (event.description?.toLowerCase().contains(lowerQuery) ?? false) ||
      (event.location?.locationName?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Get timeline statistics
  Map<String, dynamic> getStatistics() {
    final filteredEvents = events;
    final eventsByType = <String, int>{};
    final eventsByContext = <String, int>{};
    
    for (final event in filteredEvents) {
      // Count by type
      eventsByType[event.eventType] = (eventsByType[event.eventType] ?? 0) + 1;
      
      // Count by context
      eventsByContext[event.contextId] = (eventsByContext[event.contextId] ?? 0) + 1;
    }
    
    return {
      'totalEvents': filteredEvents.length,
      'totalContexts': _contexts.length,
      'eventsByType': eventsByType,
      'eventsByContext': eventsByContext,
      'earliestDate': filteredEvents.isEmpty ? null : filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
      'latestDate': filteredEvents.isEmpty ? null : filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
      'hasLocations': filteredEvents.where((e) => e.location != null).length,
    };
  }

  /// Export data
  Map<String, dynamic> exportData() {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'contexts': _contexts.map((c) => c.toJson()).toList(),
      'settings': {
        'showPrivateEvents': _showPrivateEvents,
        'activeContextId': _activeContextId,
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'eventFilter': _eventFilter,
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import data
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      _events.clear();
      _contexts.clear();
      
      // Import contexts
      if (data['contexts'] != null) {
        for (final contextData in data['contexts']) {
          final context = Context.fromJson(contextData);
          _contexts.add(context);
        }
      }
      
      // Import events
      if (data['events'] != null) {
        for (final eventData in data['events']) {
          final event = TimelineEvent.fromJson(eventData);
          _events.add(event);
        }
      }
      
      // Import settings
      if (data['settings'] != null) {
        final settings = data['settings'];
        _showPrivateEvents = settings['showPrivateEvents'] ?? true;
        _activeContextId = settings['activeContextId'];
        _startDate = settings['startDate'] != null ? DateTime.parse(settings['startDate']) : null;
        _endDate = settings['endDate'] != null ? DateTime.parse(settings['endDate']) : null;
        _eventFilter = settings['eventFilter'] ?? 'all';
      }
      
      _generateClusters();
      _updateStreams();
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _eventsController.close();
    _contextsController.close();
    _clustersController.close();
  }
}

/// Provider for timeline data service
final timelineDataProvider = Provider<TimelineDataService>((ref) {
  final service = TimelineDataService();
  // Initialize the service
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.initialize();
  });
  return service;
});

/// Provider for events stream
final timelineEventsStreamProvider = StreamProvider<List<TimelineEvent>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.eventsStream;
});

/// Provider for contexts stream
final timelineContextsStreamProvider = StreamProvider<List<Context>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.contextsStream;
});

/// Provider for clusters stream
final timelineClustersStreamProvider = StreamProvider<Map<String, List<TimelineEvent>>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.clustersStream;
});

/// Provider for timeline statistics
final timelineStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.getStatistics();
});

/// Notifier for timeline data operations
class TimelineDataNotifier extends StateNotifier<AsyncValue<void>> {
  final TimelineDataService _service;

  TimelineDataNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _service.addEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeEvent(eventId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addContext(Context context) async {
    state = const AsyncValue.loading();
    try {
      await _service.addContext(context);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateContext(Context context) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateContext(context);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Set the current viewer and timeline owner for privacy filtering
  void setPrivacyContext(String viewerId, String ownerId) {
    _currentViewerId = viewerId;
    _timelineOwnerId = ownerId;
    _notifyDataChanged();
  }

  /// Check if a viewer can access the timeline
  bool canAccessTimeline() {
    if (_currentViewerId == null || _timelineOwnerId == null) return true;
    if (_currentViewerId == _timelineOwnerId) return true;
    
    return _privacyService.canAccessTimeline(_currentViewerId!, _timelineOwnerId!);
  }

  /// Get events filtered by privacy settings
  List<TimelineEvent> _getPrivacyFilteredEvents(List<TimelineEvent> events) {
    if (_currentViewerId == null || _timelineOwnerId == null) return events;
    if (_currentViewerId == _timelineOwnerId) return events;
    
    if (!canAccessTimeline()) return [];
    
    final accessibleEventIds = _privacyService.getAccessibleEvents(
      _currentViewerId!, 
      _timelineOwnerId!
    );
    
    if (accessibleEventIds.isEmpty) return events;
    
    return events.where((event) => accessibleEventIds.contains(event.id)).toList();
  }

  /// Get contexts filtered by privacy settings
  List<Context> _getPrivacyFilteredContexts(List<Context> contexts) {
    if (_currentViewerId == null || _timelineOwnerId == null) return contexts;
    if (_currentViewerId == _timelineOwnerId) return contexts;
    
    if (!canAccessTimeline()) return [];
    
    final accessibleContextIds = _privacyService.getAccessibleContexts(
      _currentViewerId!, 
      _timelineOwnerId!
    );
    
    if (accessibleContextIds.isEmpty) return contexts;
    
    return contexts.where((context) => accessibleContextIds.contains(context.id)).toList();
  }

  Future<void> removeContext(String contextId) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeContext(contextId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _service.importData(data);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for timeline data operations
final timelineDataProvider = StateNotifierProvider<TimelineDataNotifier, AsyncValue<void>>((ref) {
  final service = TimelineDataService();
  return TimelineDataNotifier(service);
});

/// Provider for events stream
final timelineEventsStreamProvider = StreamProvider<List<TimelineEvent>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.eventsStream;
});

/// Provider for contexts stream
final timelineContextsStreamProvider = StreamProvider<List<Context>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.contextsStream;
});

/// Provider for clusters stream
final timelineClustersStreamProvider = StreamProvider<Map<String, List<TimelineEvent>>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.clustersStream;
});

/// Provider for timeline statistics
final timelineStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return service.getStatistics();
});

/// Notifier for timeline data operations
class TimelineDataNotifier extends StateNotifier<AsyncValue<void>> {
  final TimelineDataService _service;

  TimelineDataNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _service.addEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateEvent(TimelineEvent event) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeEvent(eventId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addContext(Context context) async {
    state = const AsyncValue.loading();
    try {
      await _service.addContext(context);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateContext(Context context) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateContext(context);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeContext(String contextId) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeContext(contextId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _service.importData(data);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void updateSettings({
    bool? showPrivateEvents,
    String? activeContextId,
    DateTime? startDate,
    DateTime? endDate,
    String? eventFilter,
  }) {
    _service.updateSettings(
      showPrivateEvents: showPrivateEvents,
      activeContextId: activeContextId,
      startDate: startDate,
      endDate: endDate,
      eventFilter: eventFilter,
    );
  }

  void setPrivacyContext(String viewerId, String ownerId) {
    _service.setPrivacyContext(viewerId, ownerId);
  }

  bool canAccessTimeline() {
    return _service.canAccessTimeline();
  }

  Future<bool> requestEventAccess(String eventId) async {
    return _service.requestEventAccess(eventId);
  }

  Future<bool> requestContextAccess(String contextId) async {
    return _service.requestContextAccess(contextId);
  }
}

/// Provider for timeline data notifier
final timelineDataNotifierProvider = StateNotifierProvider<TimelineDataNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(timelineDataProvider);
  return TimelineDataNotifier(service);
});
