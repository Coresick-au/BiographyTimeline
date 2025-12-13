import 'dart:async';
import 'dart:math' as math;
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import 'timeline_renderer_interface.dart';

/// Service for managing timeline data and rendering coordination
class TimelineService {
  final List<ITimelineRenderer> _renderers = [];
  final List<TimelineEvent> _events = [];
  final List<Context> _contexts = [];
  TimelineRenderConfig _currentConfig;
  
  final _configController = StreamController<TimelineRenderConfig>.broadcast();
  final _dataController = StreamController<TimelineRenderData>.broadcast();
  
  TimelineService() : _currentConfig = const TimelineRenderConfig(
    viewMode: TimelineViewMode.lifeStream,
  );

  /// Stream of configuration changes
  Stream<TimelineRenderConfig> get configStream => _configController.stream;
  
  /// Stream of data changes
  Stream<TimelineRenderData> get dataStream => _dataController.stream;
  
  /// Current configuration
  TimelineRenderConfig get currentConfig => _currentConfig;
  
  /// All timeline events
  List<TimelineEvent> get events => List.unmodifiable(_events);
  
  /// All contexts
  List<Context> get contexts => List.unmodifiable(_contexts);

  /// Initialize the service with sample data if needed
  Future<void> initialize() async {
    // If we have no events, load some sample data for testing
    if (_events.isEmpty) {
      // Basic sample event
      final sampleEvent = TimelineEvent.create(
        id: 'sample-1',
        contextId: 'personal-1',
        ownerId: 'user-1',
        timestamp: DateTime.now(),
        eventType: 'text',
        title: 'Welcome to your Timeline',
        description: 'This is a sample event to get you started.',
      );
      
      // Create a default context if needed
      if (_contexts.isEmpty) {
        _contexts.add(Context(
          id: 'personal-1',
          ownerId: 'user-1',
          type: ContextType.person,
          name: 'Personal',
          theme: TimelineTheme.standard(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          moduleConfiguration: {},
        ));
      }

      await addEvents([sampleEvent]);
    }
  }

  /// Register a new renderer
  void registerRenderer(ITimelineRenderer renderer) {
    _renderers.add(renderer);
  }

  /// Unregister a renderer
  void unregisterRenderer(ITimelineRenderer renderer) {
    _renderers.remove(renderer);
    renderer.dispose();
  }

  /// Get renderer for specific view mode
  ITimelineRenderer? getRenderer(TimelineViewMode viewMode) {
    return _renderers.where((r) => r.config.viewMode == viewMode).firstOrNull;
  }

  /// Update timeline configuration
  Future<void> updateConfig(TimelineRenderConfig config) async {
    _currentConfig = config;
    _configController.add(config);
    
    // Update all renderers
    for (final renderer in _renderers) {
      await renderer.updateConfig(config);
    }
  }

  /// Add timeline events
  Future<void> addEvents(List<TimelineEvent> events) async {
    _events.addAll(events);
    _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _notifyDataChanged();
  }

  /// Remove timeline events
  Future<void> removeEvents(List<String> eventIds) async {
    _events.removeWhere((event) => eventIds.contains(event.id));
    await _notifyDataChanged();
  }

  /// Update a specific event
  Future<void> updateEvent(TimelineEvent updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await _notifyDataChanged();
    }
  }

  /// Add contexts
  Future<void> addContexts(List<Context> contexts) async {
    _contexts.addAll(contexts);
    await _notifyDataChanged();
  }

  /// Remove contexts
  Future<void> removeContexts(List<String> contextIds) async {
    _contexts.removeWhere((context) => contextIds.contains(context.id));
    await _notifyDataChanged();
  }

  /// Update a specific context
  Future<void> updateContext(Context updatedContext) async {
    final index = _contexts.indexWhere((c) => c.id == updatedContext.id);
    if (index != -1) {
      _contexts[index] = updatedContext;
      await _notifyDataChanged();
    }
  }

  /// Get events for a specific date range
  List<TimelineEvent> getEventsInRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return event.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             event.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get events for a specific context
  List<TimelineEvent> getEventsForContext(String contextId) {
    return _events.where((event) => event.contextId == contextId).toList();
  }

  /// Get clustered events for timeline rendering
  Map<String, List<TimelineEvent>> getClusteredEvents({
    Duration timeThreshold = const Duration(hours: 24),
    double distanceThresholdKm = 10.0,
  }) {
    final clusters = <String, List<TimelineEvent>>{};
    final processedEvents = <String>{};
    
    for (int i = 0; i < _events.length; i++) {
      final event = _events[i];
      
      if (processedEvents.contains(event.id)) continue;
      
      // Find nearby events
      final cluster = <TimelineEvent>[event];
      processedEvents.add(event.id);
      
      for (int j = i + 1; j < _events.length; j++) {
        final otherEvent = _events[j];
        
        if (processedEvents.contains(otherEvent.id)) continue;
        
        // Check temporal proximity
        final timeDiff = otherEvent.timestamp.difference(event.timestamp).abs();
        if (timeDiff > timeThreshold) continue;
        
        // Check spatial proximity (if both have coordinates)
        if (event.location != null && otherEvent.location != null) {
          final distance = _calculateDistance(
            event.location!.toJson().cast<String, double>(),
            otherEvent.location!.toJson().cast<String, double>(),
          );
          if (distance > distanceThresholdKm) continue;
        }
        
        cluster.add(otherEvent);
        processedEvents.add(otherEvent.id);
      }
      
      if (cluster.isNotEmpty) {
        final clusterId = cluster.first.id;
        clusters[clusterId] = cluster;
      }
    }
    
    return clusters;
  }

  /// Get timeline statistics
  Map<String, dynamic> getStatistics() {
    if (_events.isEmpty) return {};
    
    final dates = _events.map((e) => e.timestamp).toList();
    dates.sort();
    
    final contextCounts = <String, int>{};
    for (final event in _events) {
      contextCounts[event.contextId] = (contextCounts[event.contextId] ?? 0) + 1;
    }
    
    return {
      'totalEvents': _events.length,
      'totalContexts': _contexts.length,
      'dateRange': {
        'start': dates.first,
        'end': dates.last,
        'span': dates.last.difference(dates.first).inDays,
      },
      'eventsPerContext': contextCounts,
      'eventsPerYear': _getEventsPerYear(),
    };
  }

  /// Search events by text content
  List<TimelineEvent> searchEvents(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _events.where((event) {
      // Search in title
      if (event.title?.toLowerCase().contains(lowerQuery) ?? false) return true;
      
      // Search in description
      if (event.description?.toLowerCase().contains(lowerQuery) ?? false) return true;
      
      // Search in custom attributes
      for (final value in event.customAttributes.values) {
        if (value.toString().toLowerCase().contains(lowerQuery)) return true;
      }
      
      return false;
    }).toList();
  }

  /// Export timeline data
  Map<String, dynamic> exportData() {
    return {
      'events': _events.map((e) => e.toJson()).toList(),
      'contexts': _contexts.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import timeline data
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Import contexts first
      if (data['contexts'] != null) {
        final contextList = (data['contexts'] as List)
            .map((json) => Context.fromJson(json))
            .toList();
        await addContexts(contextList);
      }
      
      // Then import events
      if (data['events'] != null) {
        final eventList = (data['events'] as List)
            .map((json) => TimelineEvent.fromJson(json))
            .toList();
        await addEvents(eventList);
      }
    } catch (e) {
      throw Exception('Failed to import timeline data: $e');
    }
  }

  /// Notify all renderers of data changes
  Future<void> _notifyDataChanged() async {
    final renderData = TimelineRenderData(
      events: _events,
      contexts: _contexts,
      earliestDate: _events.isEmpty ? DateTime.now() : 
                   _events.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
      latestDate: _events.isEmpty ? DateTime.now() : 
                 _events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
      clusteredEvents: getClusteredEvents(),
    );
    
    _dataController.add(renderData);
    
    // Update all renderers
    for (final renderer in _renderers) {
      await renderer.updateData(renderData);
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double _calculateDistance(Map<String, double> coord1, Map<String, double> coord2) {
    final lat1 = coord1['latitude']!;
    final lon1 = coord1['longitude']!;
    final lat2 = coord2['latitude']!;
    final lon2 = coord2['longitude']!;
    
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.toRadians().cos() * lat2.toRadians().cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Get events per year statistics
  Map<int, int> _getEventsPerYear() {
    final eventsPerYear = <int, int>{};
    
    for (final event in _events) {
      final year = event.timestamp.year;
      eventsPerYear[year] = (eventsPerYear[year] ?? 0) + 1;
    }
    
    return eventsPerYear;
  }

  /// Dispose resources
  void dispose() {
    for (final renderer in _renderers) {
      renderer.dispose();
    }
    _renderers.clear();
    
    _configController.close();
    _dataController.close();
  }
}

/// Extension methods for math operations
extension on double {
  double toRadians() => this * (3.14159265359 / 180);
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
}

