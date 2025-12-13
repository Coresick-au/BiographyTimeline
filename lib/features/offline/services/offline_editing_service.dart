import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'offline_sync_service.dart';
import 'offline_database_service.dart';
import '../models/offline_models.dart';

/// Provider for offline editing service
final offlineEditingServiceProvider = Provider((ref) => OfflineEditingService(
  syncService: ref.read(offlineSyncServiceProvider),
  databaseService: ref.read(offlineDatabaseServiceProvider),
));

/// Offline editing service for handling timeline edits without connectivity
class OfflineEditingService {
  final OfflineSyncService _syncService;
  final OfflineDatabaseService _databaseService;
  
  final Map<String, Timer> _editTimers = {};
  final Map<String, Map<String, dynamic>> _pendingEdits = {};

  OfflineEditingService({
    required OfflineSyncService syncService,
    required OfflineDatabaseService databaseService,
  }) : _syncService = syncService,
       _databaseService = databaseService;

  /// Create a new timeline event offline
  Future<String> createTimelineEvent(Map<String, dynamic> eventData) async {
    final eventId = const Uuid().v4();
    final now = DateTime.now();
    
    final completeEventData = {
      'id': eventId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'sync_status': SyncStatus.offlineOnly.name,
      ...eventData,
    };

    // Save to local database
    await _saveLocalEvent(completeEventData);

    // Queue for sync
    await _syncService.saveForSync(
      'timeline_events',
      eventId,
      completeEventData,
      OfflineOperation.create,
    );

    return eventId;
  }

  /// Update an existing timeline event offline
  Future<void> updateTimelineEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    // Get existing event
    final existingEvent = await _getLocalEvent(eventId);
    if (existingEvent == null) {
      throw Exception('Event not found: $eventId');
    }

    // Apply updates
    final updatedEvent = Map<String, dynamic>.from(existingEvent);
    updatedEvent.addAll(updates);
    updatedEvent['updated_at'] = DateTime.now().toIso8601String();

    // Save to local database
    await _saveLocalEvent(updatedEvent);

    // Queue for sync
    await _syncService.updateForSync(
      'timeline_events',
      eventId,
      updatedEvent,
    );

    // Track for batch editing
    _trackEdit('timeline_events', eventId, updatedEvent);
  }

  /// Delete a timeline event offline
  Future<void> deleteTimelineEvent(String eventId) async {
    // Remove from local database
    await _deleteLocalEvent(eventId);

    // Queue for sync
    await _syncService.deleteForSync('timeline_events', eventId);

    // Clear from tracking
    _clearEditTracking('timeline_events', eventId);
  }

  /// Create a new story offline
  Future<String> createStory(Map<String, dynamic> storyData) async {
    final storyId = const Uuid().v4();
    final now = DateTime.now();
    
    final completeStoryData = {
      'id': storyId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'sync_status': SyncStatus.offlineOnly.name,
      'is_published': false,
      ...storyData,
    };

    // Save to local database
    await _saveLocalStory(completeStoryData);

    // Queue for sync
    await _syncService.saveForSync(
      'stories',
      storyId,
      completeStoryData,
      OfflineOperation.create,
    );

    return storyId;
  }

  /// Update a story offline
  Future<void> updateStory(
    String storyId,
    Map<String, dynamic> updates,
  ) async {
    final existingStory = await _getLocalStory(storyId);
    if (existingStory == null) {
      throw Exception('Story not found: $storyId');
    }

    final updatedStory = Map<String, dynamic>.from(existingStory);
    updatedStory.addAll(updates);
    updatedStory['updated_at'] = DateTime.now().toIso8601String();

    await _saveLocalStory(updatedStory);

    await _syncService.updateForSync('stories', storyId, updatedStory);

    _trackEdit('stories', storyId, updatedStory);
  }

  /// Delete a story offline
  Future<void> deleteStory(String storyId) async {
    await _deleteLocalStory(storyId);
    await _syncService.deleteForSync('stories', storyId);
    _clearEditTracking('stories', storyId);
  }

  /// Batch update multiple events
  Future<void> batchUpdateEvents(
    List<String> eventIds,
    Map<String, dynamic> updates,
  ) async {
    for (final eventId in eventIds) {
      try {
        await updateTimelineEvent(eventId, updates);
      } catch (e) {
        // Log error but continue with other events
        print('Failed to update event $eventId: $e');
      }
    }
  }

  /// Move events to a different cluster
  Future<void> moveEventsToCluster(
    List<String> eventIds,
    String newClusterId,
  ) async {
    await batchUpdateEvents(eventIds, {'cluster_id': newClusterId});
  }

  /// Update event context
  Future<void> updateEventContext(
    String eventId,
    String newContextId,
  ) async {
    await updateTimelineEvent(eventId, {'context_id': newContextId});
  }

  /// Get offline editing statistics
  Future<Map<String, dynamic>> getEditingStats() async {
    final stats = await _databaseService.getDatabaseStats();
    
    return {
      'pendingEdits': _pendingEdits.length,
      'activeEditTimers': _editTimers.length,
      'unsavedChanges': _pendingEdits.values.length,
      'offlineEvents': stats['totalRecords'],
      'pendingSync': stats['pendingSync'],
    };
  }

  /// Get all pending edits for a table
  List<Map<String, dynamic>> getPendingEditsForTable(String tableName) {
    return _pendingEdits.values
        .where((edit) => edit['table_name'] == tableName)
        .toList();
  }

  /// Flush pending edits immediately
  Future<void> flushPendingEdits() async {
    for (final entry in _pendingEdits.entries) {
      final key = entry.key;
      final edit = entry.value;
      
      try {
        await _syncService.updateForSync(
          edit['table_name'],
          edit['record_id'],
          edit['data'],
        );
      } catch (e) {
        print('Failed to flush edit $key: $e');
      }
    }
    
    _pendingEdits.clear();
    _clearAllEditTimers();
  }

  /// Discard pending edits
  void discardPendingEdits({String? tableName}) {
    if (tableName != null) {
      _pendingEdits.removeWhere((key, edit) => edit['table_name'] == tableName);
    } else {
      _pendingEdits.clear();
    }
    _clearAllEditTimers();
  }

  /// Auto-save functionality for rich text editing
  Future<void> autoSaveStoryContent(
    String storyId,
    String content,
  ) async {
    final editKey = 'story_content_$storyId';
    
    // Store in pending edits
    _pendingEdits[editKey] = {
      'table_name': 'stories',
      'record_id': storyId,
      'data': {'content': content},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Cancel existing timer
    _editTimers[editKey]?.cancel();

    // Set new timer for auto-save
    _editTimers[editKey] = Timer(const Duration(seconds: 2), () async {
      try {
        await updateStory(storyId, {'content': content});
        _pendingEdits.remove(editKey);
        _editTimers.remove(editKey);
      } catch (e) {
        print('Auto-save failed for story $storyId: $e');
      }
    });
  }

  /// Auto-save functionality for event editing
  Future<void> autoSaveEventData(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    final editKey = 'event_data_$eventId';
    
    _pendingEdits[editKey] = {
      'table_name': 'timeline_events',
      'record_id': eventId,
      'data': eventData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _editTimers[editKey]?.cancel();

    _editTimers[editKey] = Timer(const Duration(seconds: 2), () async {
      try {
        await updateTimelineEvent(eventId, eventData);
        _pendingEdits.remove(editKey);
        _editTimers.remove(editKey);
      } catch (e) {
        print('Auto-save failed for event $eventId: $e');
      }
    });
  }

  /// Get local events for offline viewing
  Future<List<Map<String, dynamic>>> getLocalEvents({
    String? contextId,
    String? clusterId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (contextId != null) {
      whereClause += ' AND context_id = ?';
      whereArgs.add(contextId);
    }
    
    if (clusterId != null) {
      whereClause += ' AND cluster_id = ?';
      whereArgs.add(clusterId);
    }
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'timeline_events',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _convertEventFromDb(map)).toList();
  }

  /// Get local stories for offline viewing
  Future<List<Map<String, dynamic>>> getLocalStories({
    String? contextId,
    bool? published,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (contextId != null) {
      whereClause += ' AND context_id = ?';
      whereArgs.add(contextId);
    }
    
    if (published != null) {
      whereClause += ' AND is_published = ?';
      whereArgs.add(published ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _convertStoryFromDb(map)).toList();
  }

  // Private helper methods

  Future<void> _saveLocalEvent(Map<String, dynamic> eventData) async {
    final db = await _databaseService.database;
    
    await db.insert(
      'timeline_events',
      _convertEventToDb(eventData),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> _getLocalEvent(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'timeline_events',
      where: 'id = ?',
      whereArgs: [eventId],
    );

    if (maps.isEmpty) return null;
    return _convertEventFromDb(maps.first);
  }

  Future<void> _deleteLocalEvent(String eventId) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'timeline_events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> _saveLocalStory(Map<String, dynamic> storyData) async {
    final db = await _databaseService.database;
    
    await db.insert(
      'stories',
      _convertStoryToDb(storyData),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> _getLocalStory(String storyId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'id = ?',
      whereArgs: [storyId],
    );

    if (maps.isEmpty) return null;
    return _convertStoryFromDb(maps.first);
  }

  Future<void> _deleteLocalStory(String storyId) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'stories',
      where: 'id = ?',
      whereArgs: [storyId],
    );
  }

  void _trackEdit(String tableName, String recordId, Map<String, dynamic> data) {
    final editKey = '${tableName}_$recordId';
    _pendingEdits[editKey] = {
      'table_name': tableName,
      'record_id': recordId,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  void _clearEditTracking(String tableName, String recordId) {
    final editKey = '${tableName}_$recordId';
    _pendingEdits.remove(editKey);
    _editTimers[editKey]?.cancel();
    _editTimers.remove(editKey);
  }

  void _clearAllEditTimers() {
    for (final timer in _editTimers.values) {
      timer.cancel();
    }
    _editTimers.clear();
  }

  Map<String, dynamic> _convertEventToDb(Map<String, dynamic> event) {
    return {
      'id': event['id'],
      'title': event['title'],
      'description': event['description'],
      'date': DateTime.parse(event['date']).millisecondsSinceEpoch,
      'location_lat': event['location_lat'],
      'location_lng': event['location_lng'],
      'location_name': event['location_name'],
      'media_urls': event['media_urls'] != null ? json.encode(event['media_urls']) : null,
      'context_id': event['context_id'],
      'cluster_id': event['cluster_id'],
      'created_at': DateTime.parse(event['created_at']).millisecondsSinceEpoch,
      'updated_at': DateTime.parse(event['updated_at']).millisecondsSinceEpoch,
      'sync_status': event['sync_status'] ?? 'synced',
    };
  }

  Map<String, dynamic> _convertEventFromDb(Map<String, dynamic> event) {
    return {
      'id': event['id'],
      'title': event['title'],
      'description': event['description'],
      'date': DateTime.fromMillisecondsSinceEpoch(event['date']).toIso8601String(),
      'location_lat': event['location_lat'],
      'location_lng': event['location_lng'],
      'location_name': event['location_name'],
      'media_urls': event['media_urls'] != null ? json.decode(event['media_urls']) : null,
      'context_id': event['context_id'],
      'cluster_id': event['cluster_id'],
      'created_at': DateTime.fromMillisecondsSinceEpoch(event['created_at']).toIso8601String(),
      'updated_at': DateTime.fromMillisecondsSinceEpoch(event['updated_at']).toIso8601String(),
      'sync_status': event['sync_status'],
    };
  }

  Map<String, dynamic> _convertStoryToDb(Map<String, dynamic> story) {
    return {
      'id': story['id'],
      'title': story['title'],
      'content': story['content'],
      'event_ids': story['event_ids'] != null ? json.encode(story['event_ids']) : null,
      'context_id': story['context_id'],
      'created_at': DateTime.parse(story['created_at']).millisecondsSinceEpoch,
      'updated_at': DateTime.parse(story['updated_at']).millisecondsSinceEpoch,
      'is_published': story['is_published'] == true ? 1 : 0,
      'sync_status': story['sync_status'] ?? 'synced',
    };
  }

  Map<String, dynamic> _convertStoryFromDb(Map<String, dynamic> story) {
    return {
      'id': story['id'],
      'title': story['title'],
      'content': story['content'],
      'event_ids': story['event_ids'] != null ? json.decode(story['event_ids']) : null,
      'context_id': story['context_id'],
      'created_at': DateTime.fromMillisecondsSinceEpoch(story['created_at']).toIso8601String(),
      'updated_at': DateTime.fromMillisecondsSinceEpoch(story['updated_at']).toIso8601String(),
      'is_published': (story['is_published'] ?? 0) == 1,
      'sync_status': story['sync_status'],
    };
  }

  /// Dispose the editing service
  void dispose() {
    _clearAllEditTimers();
  }
}
