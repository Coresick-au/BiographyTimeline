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

  // Setters
  void setActiveContext(String? contextId) {
    _activeContextId = contextId;
    _notifyChanges();
  }
  
  // Notify listeners of changes
  void _notifyChanges() {
    _eventsController.add(_getFilteredEvents());
    _contextsController.add(_getPrivacyFilteredContexts(_contexts));
    _clustersController.add(Map.unmodifiable(_clusteredEvents));
  }

  TimelineDataService() {
    _initializeSampleData();
  }

  /// Initialize sample data for testing
  void _initializeSampleData() {
    final now = DateTime.now();

    // Sample contexts
    _contexts.addAll([
      Context(
        id: 'context-1',
        ownerId: 'user-1',
        type: ContextType.person,
        name: 'Personal Journey',
        moduleConfiguration: {},
        themeId: 'personal',
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

    // Sample events spanning 2-3 years
    _events.addAll([
      // 2022 Events
      TimelineEvent.create(
        id: 'event-2022-1',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 2, 1, 15),
        eventType: 'milestone',
        title: 'New Year Resolution',
        description: 'Started my journey towards a healthier lifestyle',
      ),
      TimelineEvent.create(
        id: 'event-2022-2',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 2, 3, 20),
        eventType: 'photo',
        title: 'Spring Adventure',
        description: 'First hike of the season',
        location: GeoLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          locationName: 'New York, NY',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2022-3',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 2, 6, 10),
        eventType: 'milestone',
        title: 'Graduation Day',
        description: 'Completed my degree!',
      ),
      TimelineEvent.create(
        id: 'event-2022-4',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 2, 8, 5),
        eventType: 'photo',
        title: 'Summer Road Trip',
        description: 'Epic cross-country adventure',
        location: GeoLocation(
          latitude: 36.1699,
          longitude: -115.1398,
          locationName: 'Las Vegas, NV',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2022-5',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 2, 9, 12),
        eventType: 'milestone',
        title: 'Adopted Max',
        description: 'Welcomed our new furry family member',
      ),
      
      // 2023 Events
      TimelineEvent.create(
        id: 'event-2023-1',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 1, 1, 8),
        eventType: 'milestone',
        title: 'Started New Job',
        description: 'First day at the new company',
      ),
      TimelineEvent.create(
        id: 'event-2023-2',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 1, 4, 15),
        eventType: 'photo',
        title: 'Cherry Blossoms',
        description: 'Beautiful spring day in the park',
        location: GeoLocation(
          latitude: 38.9072,
          longitude: -77.0369,
          locationName: 'Washington, DC',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2023-3',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 1, 7, 4),
        eventType: 'photo',
        title: 'Independence Day BBQ',
        description: 'Great time with friends and family',
      ),
      TimelineEvent.create(
        id: 'event-2023-4',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 1, 9, 12),
        eventType: 'milestone',
        title: 'Max\'s First Birthday',
        description: 'Celebrating one year with our best friend',
      ),
      TimelineEvent.create(
        id: 'event-2023-5',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 1, 10, 31),
        eventType: 'photo',
        title: 'Halloween Party',
        description: 'Best costume contest winner!',
      ),
      TimelineEvent.create(
        id: 'event-2023-6',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year - 1, 12, 25),
        eventType: 'photo',
        title: 'Christmas Celebration',
        description: 'Family gathering for the holidays',
      ),
      
      // 2024 Events (Recent)
      TimelineEvent.create(
        id: 'event-2024-1',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 1, 1),
        eventType: 'milestone',
        title: 'New Year 2024',
        description: 'Fresh start, new goals',
      ),
      TimelineEvent.create(
        id: 'event-2024-2',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 2, 14),
        eventType: 'photo',
        title: 'Valentine\'s Day',
        description: 'Romantic dinner downtown',
        location: GeoLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          locationName: 'San Francisco, CA',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-3',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 5, 20),
        eventType: 'milestone',
        title: 'Promotion',
        description: 'Got promoted to senior position!',
      ),
      TimelineEvent.create(
        id: 'event-2024-4',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 7, 15),
        eventType: 'photo',
        title: 'Summer Vacation',
        description: 'Beautiful sunset at the beach',
        location: GeoLocation(
          latitude: 21.3099,
          longitude: -157.8581,
          locationName: 'Honolulu, HI',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-5',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 9, 10),
        eventType: 'photo',
        title: 'Mountain Hiking',
        description: 'Reached the summit after a long hike',
        location: GeoLocation(
          latitude: 39.7392,
          longitude: -104.9903,
          locationName: 'Denver, CO',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-6',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 10, 15),
        eventType: 'milestone',
        title: 'Pet Birthday',
        description: 'Celebrating our furry friend\'s special day',
      ),
      TimelineEvent.create(
        id: 'event-2024-7',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 30)),
        eventType: 'text',
        title: 'Reflection',
        description: 'Thinking about the journey so far',
        privacyLevel: PrivacyLevel.private,
      ),
      TimelineEvent.create(
        id: 'event-2024-8',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 7)),
        eventType: 'photo',
        title: 'Weekend Getaway',
        description: 'Quick trip to recharge',
      ),
      
      // Additional diverse events for better filter testing
      TimelineEvent.create(
        id: 'event-2024-9',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 3, 10),
        eventType: 'video',
        title: 'Skiing Adventure',
        description: 'First time skiing down the slopes',
        location: GeoLocation(
          latitude: 39.6403,
          longitude: -106.3742,
          locationName: 'Vail, CO',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-10',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 4, 5),
        eventType: 'location',
        title: 'New Office Location',
        description: 'Company moved to a new building',
        location: GeoLocation(
          latitude: 40.7589,
          longitude: -73.9851,
          locationName: 'New York, NY',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-11',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 6, 1),
        eventType: 'video',
        title: 'Max Learning Tricks',
        description: 'Teaching Max to fetch and roll over',
      ),
      TimelineEvent.create(
        id: 'event-2024-12',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 6, 20),
        eventType: 'general',
        title: 'Concert Night',
        description: 'Amazing live music performance',
        location: GeoLocation(
          latitude: 34.0522,
          longitude: -118.2437,
          locationName: 'Los Angeles, CA',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-13',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 8, 1),
        eventType: 'text',
        title: 'Career Goals',
        description: 'Setting new professional development goals',
      ),
      TimelineEvent.create(
        id: 'event-2024-14',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 8, 15),
        eventType: 'video',
        title: 'Scuba Diving',
        description: 'First time diving in the ocean',
        location: GeoLocation(
          latitude: 18.4655,
          longitude: -66.1057,
          locationName: 'San Juan, Puerto Rico',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-15',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 9, 1),
        eventType: 'general',
        title: 'Vet Checkup',
        description: 'Annual health checkup for Max',
      ),
      TimelineEvent.create(
        id: 'event-2024-16',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 11, 1),
        eventType: 'milestone',
        title: 'Completed Certification',
        description: 'Finished professional certification program',
      ),
      TimelineEvent.create(
        id: 'event-2024-17',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: DateTime(now.year, 11, 15),
        eventType: 'photo',
        title: 'Thanksgiving Dinner',
        description: 'Family gathering for Thanksgiving',
      ),
      TimelineEvent.create(
        id: 'event-2024-18',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 14)),
        eventType: 'general',
        title: 'Team Building Event',
        description: 'Company retreat and team activities',
      ),
      TimelineEvent.create(
        id: 'event-2024-19',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 10)),
        eventType: 'location',
        title: 'New Favorite Cafe',
        description: 'Discovered an amazing coffee shop',
        location: GeoLocation(
          latitude: 47.6062,
          longitude: -122.3321,
          locationName: 'Seattle, WA',
        ),
      ),
      TimelineEvent.create(
        id: 'event-2024-20',
        contextId: 'context-3',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 5)),
        eventType: 'photo',
        title: 'Max at the Park',
        description: 'Playing fetch on a beautiful day',
      ),
      TimelineEvent.create(
        id: 'event-2024-21',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 3)),
        eventType: 'video',
        title: 'Presentation Success',
        description: 'Recorded my successful project presentation',
      ),
      TimelineEvent.create(
        id: 'event-2024-22',
        contextId: 'context-2',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 2)),
        eventType: 'general',
        title: 'Movie Marathon',
        description: 'Relaxing weekend watching favorite films',
      ),
      TimelineEvent.create(
        id: 'event-2024-23',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 1)),
        eventType: 'text',
        title: 'Daily Reflection',
        description: 'Grateful for all the progress this year',
        privacyLevel: PrivacyLevel.private,
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
      case 'all':
      default:
        // No filtering
        break;
    }

    return filteredEvents;
  }

  /// Generate event clusters based on time proximity
  void _generateClusters() {
    _clusteredEvents.clear();
    
    final filteredEvents = _getFilteredEvents();
    if (filteredEvents.isEmpty) return;

    // Sort events by timestamp
    final sortedEvents = List<TimelineEvent>.from(filteredEvents)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Group events into clusters based on time proximity (within 7 days)
    List<TimelineEvent> currentCluster = [sortedEvents.first];
    
    for (int i = 1; i < sortedEvents.length; i++) {
      final currentEvent = sortedEvents[i];
      final previousEvent = sortedEvents[i - 1];
      
      final timeDifference = currentEvent.timestamp.difference(previousEvent.timestamp);
      
      if (timeDifference.inDays <= 7) {
        currentCluster.add(currentEvent);
      } else {
        // Save current cluster and start a new one
        if (currentCluster.isNotEmpty) {
          _clusteredEvents['cluster-${_clusteredEvents.length}'] = List.from(currentCluster);
        }
        currentCluster = [currentEvent];
      }
    }
    
    // Save the last cluster
    if (currentCluster.isNotEmpty) {
      _clusteredEvents['cluster-${_clusteredEvents.length}'] = List.from(currentCluster);
    }
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
    
    _notifyDataChanged();
  }

  /// Notify listeners of data changes
  void _notifyDataChanged() {
    _generateClusters();
    _eventsController.add(_getFilteredEvents());
    _contextsController.add(_getPrivacyFilteredContexts(_contexts));
    _clustersController.add(Map.unmodifiable(_clusteredEvents));
  }

  // CRUD operations
  Future<void> addEvent(TimelineEvent event) async {
    _events.add(event);
    _notifyDataChanged();
  }

  Future<void> updateEvent(TimelineEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      _notifyDataChanged();
    }
  }

  Future<void> removeEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
    _notifyDataChanged();
  }

  Future<void> addContext(Context context) async {
    _contexts.add(context);
    _notifyDataChanged();
  }

  Future<void> updateContext(Context context) async {
    final index = _contexts.indexWhere((c) => c.id == context.id);
    if (index != -1) {
      _contexts[index] = context;
      _notifyDataChanged();
    }
  }

  Future<void> removeContext(String contextId) async {
    _contexts.removeWhere((context) => context.id == contextId);
    _events.removeWhere((event) => event.contextId == contextId);
    _notifyDataChanged();
  }

  /// Import data from external source
  Future<void> importData(Map<String, dynamic> data) async {
    // Implementation for importing data
    // This would parse the data and add events/contexts
    _notifyDataChanged();
  }

  /// Get statistics about the timeline
  Map<String, dynamic> getStatistics() {
    final filteredEvents = _getFilteredEvents();
    
    return {
      'totalEvents': filteredEvents.length,
      'totalContexts': _getPrivacyFilteredContexts(_contexts).length,
      'photoEvents': filteredEvents.where((e) => e.eventType == 'photo').length,
      'milestoneEvents': filteredEvents.where((e) => e.eventType == 'milestone').length,
      'textEvents': filteredEvents.where((e) => e.eventType == 'text').length,
      'privateEvents': filteredEvents.where((e) => e.privacyLevel == PrivacyLevel.private).length,
      'publicEvents': filteredEvents.where((e) => e.privacyLevel == PrivacyLevel.public).length,
      'clusters': _clusteredEvents.length,
      'dateRange': filteredEvents.isNotEmpty 
        ? {
            'start': filteredEvents.first.timestamp.toIso8601String(),
            'end': filteredEvents.last.timestamp.toIso8601String(),
          }
        : null,
    };
  }

  /// Initialize the service with data
  Future<void> initialize() async {
    // Load data from persistent storage if needed
    _notifyDataChanged();
  }

  /// Dispose resources
  void dispose() {
    _eventsController.close();
    _contextsController.close();
    _clustersController.close();
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

  /// Request access to specific events
  Future<bool> requestEventAccess(String eventId) async {
    if (_currentViewerId == null || _timelineOwnerId == null) return false;
    
    final settings = _privacyService.getSettings(_timelineOwnerId!);
    if (!settings.allowEventRequests) return false;
    
    // In a real implementation, this would send a notification to the timeline owner
    // For now, return true to indicate the request was sent
    return true;
  }

  /// Request access to specific contexts
  Future<bool> requestContextAccess(String contextId) async {
    if (_currentViewerId == null || _timelineOwnerId == null) return false;
    
    final settings = _privacyService.getSettings(_timelineOwnerId!);
    if (!settings.allowContextRequests) return false;
    
    // In a real implementation, this would send a notification to the timeline owner
    // For now, return true to indicate the request was sent
    return true;
  }

  /// Export timeline data
  Map<String, dynamic> exportData() {
    return {
      'events': _events.map((e) => {
        'id': e.id,
        'contextId': e.contextId,
        'ownerId': e.ownerId,
        'timestamp': e.timestamp.toIso8601String(),
        'eventType': e.eventType,
        'title': e.title,
        'description': e.description,
        'privacyLevel': e.privacyLevel.toString(),
      }).toList(),
      'contexts': _contexts.map((c) => {
        'id': c.id,
        'ownerId': c.ownerId,
        'type': c.type.toString(),
        'name': c.name,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      }).toList(),
      'clusters': _clusteredEvents.map((key, value) => 
        MapEntry(key, value.map((e) => e.id).toList())),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
}

/// Provider for TimelineDataService instance
final timelineServiceProvider = Provider<TimelineDataService>((ref) {
  return TimelineDataService();
});

/// Provider for timeline data operations
final timelineDataProvider = StateNotifierProvider<TimelineDataNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return TimelineDataNotifier(service);
});

/// Provider for events stream
final timelineEventsStreamProvider = StreamProvider<List<TimelineEvent>>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return service.eventsStream;
});

/// Provider for contexts stream
final timelineContextsStreamProvider = StreamProvider<List<Context>>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return service.contextsStream;
});

/// Provider for clusters stream
final timelineClustersStreamProvider = StreamProvider<Map<String, List<TimelineEvent>>>((ref) {
  final service = ref.watch(timelineServiceProvider);
  return service.clustersStream;
});

/// Provider for timeline statistics
final timelineStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(timelineServiceProvider);
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
  final service = ref.watch(timelineServiceProvider);
  return TimelineDataNotifier(service);
});
