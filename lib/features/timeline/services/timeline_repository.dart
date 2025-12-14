import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';
import '../../../core/database/database.dart';
import '../../../shared/error_handling/error_service.dart';
import '../../../shared/loading/loading_service.dart';

/// Repository for accessing and modifying timeline data.
/// 
/// This class provides database-backed storage for timeline events and contexts.
class TimelineRepository {
  final Database _database;
  final ErrorService _errorService;
  final LoadingService _loadingService;
  
  TimelineRepository(this._database, [ErrorService? errorService, LoadingService? loadingService]) 
      : _errorService = errorService ?? ErrorService.instance,
        _loadingService = loadingService ?? LoadingService();

  /// Get all events
  Future<List<TimelineEvent>> getEvents() async {
    try {
      final maps = await _database.query('timeline_events');
      return maps.map(_mapToTimelineEvent).toList();
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to get timeline events',
        metadata: {'operation': 'getEvents'},
      );
      rethrow;
    }
  }

  /// Get all contexts
  Future<List<Context>> getContexts() async {
    try {
      final maps = await _database.query('contexts');
      return maps.map(_mapToContext).toList();
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to get contexts',
        metadata: {'operation': 'getContexts'},
      );
      rethrow;
    }
  }

  /// Get events for a specific context
  Future<List<TimelineEvent>> getEventsForContext(String contextId) async {
    final maps = await _database.query(
      'timeline_events',
      where: 'context_id = ?',
      whereArgs: [contextId],
      orderBy: 'timestamp DESC',
    );
    return maps.map(_mapToTimelineEvent).toList();
  }

  /// Get events in a date range
  Future<List<TimelineEvent>> getEventsInRange(DateTime start, DateTime end) async {
    final maps = await _database.query(
      'timeline_events',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );
    return maps.map(_mapToTimelineEvent).toList();
  }

  /// Add a new event
  Future<void> addEvent(TimelineEvent event) async {
    final loadingId = _loadingService.startSave(item: 'timeline event');
    try {
      await _database.insert(
        'timeline_events',
        _timelineEventToMap(event),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to add timeline event',
        metadata: {
          'operation': 'addEvent',
          'eventId': event.id,
          'contextId': event.contextId,
        },
        showToUser: true,
      );
      rethrow;
    } finally {
      _loadingService.stopLoading(loadingId);
    }
  }

  /// Update an existing event
  Future<void> updateEvent(TimelineEvent event) async {
    final loadingId = _loadingService.startSave(item: 'timeline event');
    try {
      await _database.update(
        'timeline_events',
        _timelineEventToMap(event),
        where: 'id = ?',
        whereArgs: [event.id],
      );
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to update timeline event',
        metadata: {
          'operation': 'updateEvent',
          'eventId': event.id,
        },
        showToUser: true,
      );
      rethrow;
    } finally {
      _loadingService.stopLoading(loadingId);
    }
  }

  /// Remove an event by ID
  Future<void> removeEvent(String eventId) async {
    final loadingId = _loadingService.startDelete(item: 'timeline event');
    try {
      await _database.delete(
        'timeline_events',
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to remove timeline event',
        metadata: {
          'operation': 'removeEvent',
          'eventId': eventId,
        },
        showToUser: true,
      );
      rethrow;
    } finally {
      _loadingService.stopLoading(loadingId);
    }
  }

  /// Add a new context
  Future<void> addContext(Context context) async {
    try {
      await _database.insert(
        'contexts',
        _contextToMap(context),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to add context',
        metadata: {
          'operation': 'addContext',
          'contextId': context.id,
        },
        showToUser: true,
      );
      rethrow;
    }
  }

  /// Update an existing context
  Future<void> updateContext(Context context) async {
    try {
      await _database.update(
        'contexts',
        _contextToMap(context),
        where: 'id = ?',
        whereArgs: [context.id],
      );
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to update context',
        metadata: {
          'operation': 'updateContext',
          'contextId': context.id,
        },
        showToUser: true,
      );
      rethrow;
    }
  }

  /// Remove a context by ID
  Future<void> removeContext(String contextId) async {
    try {
      await _database.delete(
        'contexts',
        where: 'id = ?',
        whereArgs: [contextId],
      );
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to remove context',
        metadata: {
          'operation': 'removeContext',
          'contextId': contextId,
        },
        showToUser: true,
      );
      rethrow;
    }
  }

  /// Search events by text content
  Future<List<TimelineEvent>> searchEvents(String query) async {
    try {
      final maps = await _database.query(
        'timeline_events',
        where: 'title LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'timestamp DESC',
      );
      return maps.map(_mapToTimelineEvent).toList();
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to search timeline events',
        metadata: {
          'operation': 'searchEvents',
          'query': query,
        },
      );
      rethrow;
    }
  }

  /// Get events count per context
  Future<Map<String, int>> getEventCountPerContext() async {
    final maps = await _database.rawQuery('''
      SELECT context_id, COUNT(*) as count
      FROM timeline_events
      GROUP BY context_id
    ''');
    
    final result = <String, int>{};
    for (final map in maps) {
      result[map['context_id'] as String] = map['count'] as int;
    }
    return result;
  }

  /// Get timeline statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final eventCount = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM timeline_events')
    ) ?? 0;
    
    final contextCount = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM contexts')
    ) ?? 0;
    
    final earliestDateMap = await _database.rawQuery(
      'SELECT MIN(timestamp) as min_timestamp FROM timeline_events'
    );
    final earliestTimestamp = earliestDateMap.first['min_timestamp'] as int?;
    
    final latestDateMap = await _database.rawQuery(
      'SELECT MAX(timestamp) as max_timestamp FROM timeline_events'
    );
    final latestTimestamp = latestDateMap.first['max_timestamp'] as int?;
    
    return {
      'totalEvents': eventCount,
      'totalContexts': contextCount,
      'earliestDate': earliestTimestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(earliestTimestamp)
          : null,
      'latestDate': latestTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(latestTimestamp)
          : null,
    };
  }

  /// Maps a database row to a TimelineEvent
  TimelineEvent _mapToTimelineEvent(Map<String, dynamic> map) {
    return TimelineEvent(
      id: map['id'] as String,
      contextId: map['context_id'] as String,
      ownerId: map['owner_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      eventType: map['event_type'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      customAttributes: DatabaseJsonHelper.jsonToMap(map['custom_attributes'] as String),
      location: map['location'] != null
          ? GeoLocation.fromJson(DatabaseJsonHelper.jsonToMap(map['location'] as String))
          : null,
      participantIds: DatabaseJsonHelper.jsonToStringList(map['participant_ids'] as String),
      privacyLevel: _parsePrivacyLevel(map['privacy_level'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      assets: [], // TODO: Load assets from media_assets table when needed
    );
  }

  /// Maps a TimelineEvent to a database row
  Map<String, dynamic> _timelineEventToMap(TimelineEvent event) {
    return {
      'id': event.id,
      'context_id': event.contextId,
      'owner_id': event.ownerId,
      'timestamp': event.timestamp.millisecondsSinceEpoch,
      'event_type': event.eventType,
      'title': event.title,
      'description': event.description,
      'custom_attributes': DatabaseJsonHelper.mapToJson(event.customAttributes),
      'location': event.location != null
          ? DatabaseJsonHelper.mapToJson(event.location!.toJson())
          : null,
      'participant_ids': DatabaseJsonHelper.stringListToJson(event.participantIds),
      'privacy_level': event.privacyLevel.name,
      'created_at': event.createdAt.millisecondsSinceEpoch,
      'updated_at': event.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Maps a database row to a Context
  Context _mapToContext(Map<String, dynamic> map) {
    return Context(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      type: ContextType.values.firstWhere(
        (type) => type.name == map['type'] as String,
        orElse: () => ContextType.person,
      ),
      name: map['name'] as String,
      description: map['description'] as String?,
      moduleConfiguration: DatabaseJsonHelper.jsonToMap(map['module_configuration'] as String),
      themeId: map['theme_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Maps a Context to a database row
  Map<String, dynamic> _contextToMap(Context context) {
    return {
      'id': context.id,
      'owner_id': context.ownerId,
      'type': context.type.name,
      'name': context.name,
      'description': context.description,
      'module_configuration': DatabaseJsonHelper.mapToJson(context.moduleConfiguration),
      'theme_id': context.themeId,
      'created_at': context.createdAt.millisecondsSinceEpoch,
      'updated_at': context.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Parse privacy level from string
  PrivacyLevel _parsePrivacyLevel(String value) {
    return PrivacyLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => PrivacyLevel.public,
    );
  }
}

/// Provider for the Timeline Repository
final timelineRepositoryProvider = Provider((ref) {
  // Use a lazy async pattern
  return LazyTimelineRepository();
});

/// Lazy initialization wrapper for TimelineRepository
class LazyTimelineRepository {
  TimelineRepository? _inner;
  
  TimelineRepository get _repo {
    return _inner ??= throw Exception('Repository not initialized - call initialize() first');
  }

  Future<void> initialize() async {
    if (_inner == null) {
      final database = await AppDatabase.database;
      _inner = TimelineRepository(database, ErrorService.instance, LoadingService());
    }
  }

  Future<List<TimelineEvent>> getEvents() async {
    await initialize();
    return _repo.getEvents();
  }

  Future<List<Context>> getContexts() async {
    await initialize();
    return _repo.getContexts();
  }

  Future<List<TimelineEvent>> getEventsForContext(String contextId) async {
    await initialize();
    return _repo.getEventsForContext(contextId);
  }

  Future<List<TimelineEvent>> getEventsInRange(DateTime start, DateTime end) async {
    await initialize();
    return _repo.getEventsInRange(start, end);
  }

  Future<void> addEvent(TimelineEvent event) async {
    await initialize();
    return _repo.addEvent(event);
  }

  Future<void> updateEvent(TimelineEvent event) async {
    await initialize();
    return _repo.updateEvent(event);
  }

  Future<void> removeEvent(String eventId) async {
    await initialize();
    return _repo.removeEvent(eventId);
  }

  Future<void> addContext(Context context) async {
    await initialize();
    return _repo.addContext(context);
  }

  Future<void> updateContext(Context context) async {
    await initialize();
    return _repo.updateContext(context);
  }

  Future<void> removeContext(String contextId) async {
    await initialize();
    return _repo.removeContext(contextId);
  }

  Future<List<TimelineEvent>> searchEvents(String query) async {
    await initialize();
    return _repo.searchEvents(query);
  }

  Future<Map<String, int>> getEventCountPerContext() async {
    await initialize();
    return _repo.getEventCountPerContext();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    await initialize();
    return _repo.getStatistics();
  }
}
