import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';

/// Repository for accessing and modifying timeline data.
/// 
/// This class abstracts the data source (in-memory, database, api)
/// from the application logic.
class TimelineRepository {
  // Simulating persistent storage for now
  final List<TimelineEvent> _events = [];
  final List<Context> _contexts = [];

  TimelineRepository() {
    _initializeSampleData();
  }

  /// Get all events
  Future<List<TimelineEvent>> getEvents() async {
    // Simulate network/db latency
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_events);
  }

  /// Get all contexts
  Future<List<Context>> getContexts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_contexts);
  }

  /// Add a new event
  Future<void> addEvent(TimelineEvent event) async {
    _events.add(event);
  }

  /// Update an existing event
  Future<void> updateEvent(TimelineEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    } else {
      throw Exception('Event not found: ${event.id}');
    }
  }

  /// Remove an event by ID
  Future<void> removeEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
  }

  /// Add a new context
  Future<void> addContext(Context context) async {
    _contexts.add(context);
  }

  /// Update an existing context
  Future<void> updateContext(Context context) async {
    final index = _contexts.indexWhere((c) => c.id == context.id);
    if (index != -1) {
      _contexts[index] = context;
    } else {
      throw Exception('Context not found: ${context.id}');
    }
  }

  /// Remove a context by ID
  Future<void> removeContext(String contextId) async {
    _contexts.removeWhere((c) => c.id == contextId);
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
      // ... (Rest of user events would go here, simplified for brevity but kept in structure)
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
  }
}

/// Provider for the Timeline Repository
final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository();
});
