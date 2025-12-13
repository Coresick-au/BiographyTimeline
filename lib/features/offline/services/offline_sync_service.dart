import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'offline_database_service.dart';
import '../models/offline_models.dart';

/// Provider for offline sync service
final offlineSyncServiceProvider = Provider((ref) => OfflineSyncService(
  databaseService: ref.read(offlineDatabaseServiceProvider),
));

/// Offline sync service for handling data synchronization
class OfflineSyncService {
  final OfflineDatabaseService _databaseService;
  final OfflineStorageConfig _config;
  
  SyncSession? _currentSession;
  Timer? _syncTimer;
  bool _isSyncing = false;

  OfflineSyncService({
    required OfflineDatabaseService databaseService,
    OfflineStorageConfig? config,
  }) : _databaseService = databaseService,
       _config = config ?? const OfflineStorageConfig();

  /// Initialize the sync service
  Future<void> initialize() async {
    // Clean up expired cache entries
    await _databaseService.cleanupExpiredCache();
    
    // Start background sync if enabled
    if (_config.enableBackgroundSync) {
      _startBackgroundSync();
    }
  }

  /// Start manual sync process
  Future<SyncSession> syncNow() async {
    if (_isSyncing) {
      return _currentSession!;
    }

    _isSyncing = true;
    
    var session = SyncSession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      status: SyncStatus.syncing,
    );

    _currentSession = session;
    await _databaseService.createSyncSession(session);

    try {
      // Get pending records
      final pendingRecords = await _databaseService.getPendingSyncRecords();
      session = session.copyWith(recordsTotal: pendingRecords.length);

      // Process each record
      for (final record in pendingRecords) {
        await _syncRecord(record);
        session = session.copyWith(recordsProcessed: session.recordsProcessed + 1);
        
        // Update session progress
        await _databaseService.updateSyncSession(session);
      }

      // Handle conflicts
      await _resolveConflicts();

      // Mark session as completed
      session = session.copyWith(
        completedAt: DateTime.now(),
        status: SyncStatus.synced,
      );
      
    } catch (e) {
      final errorMessages = List<String>.from(session.errorMessages);
      errorMessages.add(e.toString());
      session = session.copyWith(
        status: SyncStatus.failed,
        errorMessages: errorMessages,
        errorsEncountered: session.errorsEncountered + 1,
      );
    } finally {
      await _databaseService.updateSyncSession(session);
      _isSyncing = false;
      _currentSession = null;
    }

    return session;
  }

  /// Sync a single record
  Future<void> _syncRecord(OfflineDataRecord record) async {
    try {
      switch (record.operation) {
        case OfflineOperation.create:
          await _createRemoteRecord(record);
          break;
        case OfflineOperation.update:
          await _updateRemoteRecord(record);
          break;
        case OfflineOperation.delete:
          await _deleteRemoteRecord(record);
          break;
        case null:
          // No operation to perform
          break;
      }

      // Update record as synced
      await _databaseService.updateRecordSyncStatus(
        record.id,
        SyncStatus.synced,
      );

    } catch (e) {
      // Mark record as failed
      await _databaseService.updateRecordSyncStatus(
        record.id,
        SyncStatus.failed,
        errorMessage: e.toString(),
        retryCount: record.retryCount + 1,
      );
      
      rethrow;
    }
  }

  /// Create a record on the remote server
  Future<void> _createRemoteRecord(OfflineDataRecord record) async {
    // This would integrate with your actual API
    // For now, simulate the operation
    final response = await _makeApiRequest(
      'POST',
      '/api/${record.tableName}',
      record.data,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success - update local record with remote ID if needed
      final responseData = json.decode(response.body);
      if (responseData['id'] != null) {
        record.data['id'] = responseData['id'];
        await _databaseService.saveOfflineRecord(record);
      }
    } else {
      throw Exception('Failed to create remote record: ${response.statusCode}');
    }
  }

  /// Update a record on the remote server
  Future<void> _updateRemoteRecord(OfflineDataRecord record) async {
    final response = await _makeApiRequest(
      'PUT',
      '/api/${record.tableName}/${record.recordId}',
      record.data,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update remote record: ${response.statusCode}');
    }
  }

  /// Delete a record on the remote server
  Future<void> _deleteRemoteRecord(OfflineDataRecord record) async {
    final response = await _makeApiRequest(
      'DELETE',
      '/api/${record.tableName}/${record.recordId}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete remote record: ${response.statusCode}');
    }

    // Remove local record after successful remote deletion
    await _databaseService.deleteOfflineRecord(record.id);
  }

  /// Resolve sync conflicts
  Future<void> _resolveConflicts() async {
    final conflicts = await _databaseService.getUnresolvedConflicts();
    
    for (final conflict in conflicts) {
      // For now, use automatic merge strategy
      // In a real app, this might prompt the user
      await _autoResolveConflict(conflict);
    }
  }

  /// Automatically resolve a conflict
  Future<void> _autoResolveConflict(SyncConflict conflict) async {
    final resolvedData = Map<String, dynamic>.from(conflict.baseData);
    
    // Simple merge strategy: prefer local data for modified fields
    for (final field in conflict.conflictingFields) {
      if (conflict.localData.containsKey(field)) {
        resolvedData[field] = conflict.localData[field];
      }
    }

    await _databaseService.resolveConflict(
      conflict.id,
      ConflictResolutionStrategy.automaticMerge,
      resolvedData,
    );
  }

  /// Save a record for offline sync
  Future<void> saveForSync(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
    OfflineOperation operation,
  ) async {
    final record = OfflineDataRecord(
      id: const Uuid().v4(),
      tableName: tableName,
      recordId: recordId,
      data: data,
      syncStatus: SyncStatus.pendingUpload,
      operation: operation,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await _databaseService.saveOfflineRecord(record);

    // Trigger auto-sync if enabled
    if (_config.enableAutoSync) {
      _scheduleAutoSync();
    }
  }

  /// Update a record for offline sync
  Future<void> updateForSync(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final records = await _databaseService.getRecordsForTable(tableName);
    final existingRecord = records.firstWhere(
      (r) => r.recordId == recordId,
      orElse: () => throw Exception('Record not found: $recordId'),
    );

    final updatedRecord = existingRecord.copyWith(
      data: data,
      lastModified: DateTime.now(),
      syncStatus: SyncStatus.pendingUpload,
      operation: OfflineOperation.update,
    );

    await _databaseService.saveOfflineRecord(updatedRecord);

    if (_config.enableAutoSync) {
      _scheduleAutoSync();
    }
  }

  /// Delete a record for offline sync
  Future<void> deleteForSync(
    String tableName,
    String recordId,
  ) async {
    final records = await _databaseService.getRecordsForTable(tableName);
    final existingRecord = records.firstWhere(
      (r) => r.recordId == recordId,
      orElse: () => throw Exception('Record not found: $recordId'),
    );

    if (existingRecord != null) {
      final deletedRecord = existingRecord.copyWith(
        lastModified: DateTime.now(),
        syncStatus: SyncStatus.pendingUpload,
        operation: OfflineOperation.delete,
      );

      await _databaseService.saveOfflineRecord(deletedRecord);
    } else {
      // Record doesn't exist locally, create a delete-only record
      final record = OfflineDataRecord(
        id: const Uuid().v4(),
        tableName: tableName,
        recordId: recordId,
        data: {'id': recordId},
        syncStatus: SyncStatus.pendingUpload,
        operation: OfflineOperation.delete,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      await _databaseService.saveOfflineRecord(record);
    }

    if (_config.enableAutoSync) {
      _scheduleAutoSync();
    }
  }

  /// Get current sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final stats = await _databaseService.getDatabaseStats();
    final recentSessions = await _databaseService.getRecentSyncSessions(limit: 1);
    
    return {
      'isSyncing': _isSyncing,
      'currentSession': _currentSession?.toJson(),
      'lastSyncSession': recentSessions.isNotEmpty ? recentSessions.first.toJson() : null,
      'pendingRecords': stats['pendingSync'],
      'conflicts': stats['conflicts'],
      'totalRecords': stats['totalRecords'],
    };
  }

  /// Get sync history
  Future<List<SyncSession>> getSyncHistory({int limit = 10}) async {
    return await _databaseService.getRecentSyncSessions(limit: limit);
  }

  /// Retry failed sync operations
  Future<void> retryFailedSyncs() async {
    final db = await _databaseService.database;
    
    // Reset failed records to pending
    await db.update(
      'offline_data_records',
      {
        'sync_status': SyncStatus.pendingUpload.name,
        'error_message': null,
        'retry_count': 0,
      },
      where: 'sync_status = ? AND retry_count < ?',
      whereArgs: [SyncStatus.failed.name, _config.maxSyncRetries],
    );

    // Trigger sync
    await syncNow();
  }

  /// Start background sync timer
  void _startBackgroundSync() {
    _syncTimer = Timer.periodic(_config.syncRetryInterval, (_) {
      if (_config.enableAutoSync && !_isSyncing) {
        syncNow();
      }
    });
  }

  /// Schedule auto-sync with delay
  void _scheduleAutoSync() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_config.enableAutoSync && !_isSyncing) {
        syncNow();
      }
    });
  }

  /// Make API request to remote server
  Future<http.Response> _makeApiRequest(
    String method,
    String endpoint, [
    Map<String, dynamic>? data,
  ]) async {
    // This would connect to your actual API endpoint
    // For now, simulate successful responses
    await Future.delayed(const Duration(milliseconds: 500));
    
    switch (method) {
      case 'POST':
        return http.Response(
          json.encode({'id': const Uuid().v4(), ...?data}),
          201,
        );
      case 'PUT':
        return http.Response(json.encode(data ?? {}), 200);
      case 'DELETE':
        return http.Response('', 204);
      default:
        throw Exception('Unsupported method: $method');
    }
  }

  /// Dispose the sync service
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Enable/disable auto sync
  Future<void> setAutoSync(bool enabled) async {
    // This would update the config in storage
    if (enabled && !_config.enableAutoSync) {
      _scheduleAutoSync();
    }
  }

  /// Force refresh data from server
  Future<void> refreshFromServer() async {
    // This would download fresh data from the server
    // and update local cache
    var session = SyncSession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      status: SyncStatus.syncing,
    );

    await _databaseService.createSyncSession(session);

    try {
      // Simulate server refresh
      await Future.delayed(const Duration(seconds: 2));
      
      session = session.copyWith(
        completedAt: DateTime.now(),
        status: SyncStatus.synced,
      );
    } catch (e) {
      final errorMessages = List<String>.from(session.errorMessages);
      errorMessages.add(e.toString());
      session = session.copyWith(
        status: SyncStatus.failed,
        errorMessages: errorMessages,
      );
    } finally {
      await _databaseService.updateSyncSession(session);
    }
  }
}
