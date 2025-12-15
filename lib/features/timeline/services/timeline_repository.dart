import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';
import '../../../core/database/database.dart';
import '../../../shared/error_handling/error_service.dart';
import '../../../shared/loading/loading_service.dart';
import 'mock_timeline_repository.dart';

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
      if (maps.isEmpty) {
        return []; // Return empty list instead of trying to map nothing
      }
      return maps.map(_mapToTimelineEvent).toList();
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to get timeline events',
        metadata: {'operation': 'getEvents'},
      );
      // Return empty list instead of rethrowing to allow app to show empty state
      return [];
    }
  }

  /// Get all contexts
  Future<List<Context>> getContexts() async {
    try {
      final maps = await _database.query('contexts');
      if (maps.isEmpty) {
        return []; // Return empty list instead of trying to map nothing
      }
      return maps.map(_mapToContext).toList();
    } catch (e, stackTrace) {
      await _errorService.logError(
        e,
        stackTrace,
        context: 'Failed to get contexts',
        metadata: {'operation': 'getContexts'},
      );
      // Return empty list instead of rethrowing to allow app to show empty state
      return [];
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
          'tags': event.tags.join(', '),
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
    try {
      return TimelineEvent(
        id: map['id'] as String,
        tags: map['tags'] != null 
            ? DatabaseJsonHelper.jsonToStringList(map['tags'] as String)
            : ['Family'],
        ownerId: map['owner_id'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        eventType: map['event_type'] as String,
        title: map['title'] as String?,
        description: map['description'] as String?,
        customAttributes: map['custom_attributes'] != null
            ? DatabaseJsonHelper.jsonToMap(map['custom_attributes'] as String)
            : {},
        location: map['location'] != null
            ? GeoLocation.fromJson(DatabaseJsonHelper.jsonToMap(map['location'] as String))
            : null,
        participantIds: map['participant_ids'] != null
            ? DatabaseJsonHelper.jsonToStringList(map['participant_ids'] as String)
            : [],
        isPrivate: map['is_private'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        assets: [], // TODO: Load assets from media_assets table when needed
      );
    } catch (e) {
      // Log the error but don't crash - return a minimal valid event
      print('Error mapping timeline event: $e');
      print('Map data: $map');
      rethrow; // Rethrow to be caught by the calling function
    }
  }

  /// Maps a TimelineEvent to a database row
  Map<String, dynamic> _timelineEventToMap(TimelineEvent event) {
    return {
      'id': event.id,
      'tags': DatabaseJsonHelper.stringListToJson(event.tags),
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
      'is_private': event.isPrivate ? 1 : 0,
      'created_at': event.createdAt.millisecondsSinceEpoch,
      'updated_at': event.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Maps a database row to a Context
  Context _mapToContext(Map<String, dynamic> map) {
    try {
      return Context(
        id: map['id'] as String,
        ownerId: map['owner_id'] as String,
        type: ContextType.values.firstWhere(
          (e) => e.toString() == 'ContextType.${map['type']}',
          orElse: () => ContextType.person,
        ),
        name: map['name'] as String,
        description: map['description'] as String?,
        moduleConfiguration: map['module_configuration'] != null
            ? DatabaseJsonHelper.jsonToMap(map['module_configuration'] as String)
            : {},
        themeId: map['theme_id'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
    } catch (e) {
      print('Error mapping context: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  /// Maps a Context to a database row
  Map<String, dynamic> _contextToMap(Context context) {
    return {
      'id': context.id,
      'owner_id': context.ownerId,
      'type': context.type.toString().split('.').last,
      'name': context.name,
      'description': context.description,
      'module_configuration': DatabaseJsonHelper.mapToJson(context.moduleConfiguration),
      'theme_id': context.themeId,
      'created_at': context.createdAt.millisecondsSinceEpoch,
      'updated_at': context.updatedAt.millisecondsSinceEpoch,
    };
  }
}

/// Provider for the Timeline Repository
/// Uses MockTimelineRepository on web to bypass SQLite web issues
final timelineRepositoryProvider = FutureProvider<dynamic>((ref) async {
  // On web, use mock repository to bypass SQLite issues
  if (kIsWeb) {
    print('DEBUG: Using MockTimelineRepository for web');
    return MockTimelineRepository();
  }
  
  // On native platforms, use real database
  final database = await AppDatabase.database;
  return TimelineRepository(database, ErrorService.instance, LoadingService());
});

