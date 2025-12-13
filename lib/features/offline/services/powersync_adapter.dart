import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'offline_database_service.dart';
import 'offline_sync_service.dart';
import 'powersync_stub.dart';
import '../models/offline_models.dart';

/// Provider for PowerSync adapter
final powersyncAdapterProvider = Provider((ref) => PowerSyncAdapter(
  databaseService: ref.read(offlineDatabaseServiceProvider),
));

/// PowerSync adapter that implements sync interface using PowerSync stub
class PowerSyncAdapter {
  final OfflineDatabaseService _databaseService;
  late PowerSyncStub _powersync;
  bool _isInitialized = false;

  PowerSyncAdapter({
    required OfflineDatabaseService databaseService,
  }) : _databaseService = databaseService;

  /// Initialize PowerSync stub
  Future<void> initialize() async {
    if (_isInitialized) return;

    _powersync = PowerSyncStub(
      databaseService: _databaseService,
      manualSyncService: OfflineSyncService(databaseService: _databaseService),
    );

    await _powersync.initialize();
    await _powersync.connect();

    _isInitialized = true;
  }

  /// Get the PowerSync stub instance
  PowerSyncStub get powersync {
    if (!_isInitialized) {
      throw StateError('PowerSync adapter not initialized');
    }
    return _powersync;
  }

  /// Sync data using PowerSync stub
  Future<SyncSession> syncNow() async {
    if (!_isInitialized) {
      await initialize();
    }

    var session = SyncSession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      status: SyncStatus.syncing,
    );

    try {
      // Simulate sync process
      await Future.delayed(const Duration(seconds: 1));
      
      session = session.copyWith(
        completedAt: DateTime.now(),
        status: SyncStatus.synced,
      );
    } catch (e) {
      session = session.copyWith(
        completedAt: DateTime.now(),
        status: SyncStatus.failed,
        errorMessages: [e.toString()],
        errorsEncountered: 1,
      );
    }

    // Save session to our tracking database
    await _databaseService.createSyncSession(session);
    return session;
  }

  /// Save a record for sync using PowerSync stub
  Future<void> saveForSync(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
    OfflineOperation operation,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Use the stub's save method
    await _powersync.saveForSync(tableName, recordId, data, operation);

    // Also track in our offline database for compatibility
    final record = OfflineDataRecord(
      id: const Uuid().v4(),
      tableName: tableName,
      recordId: recordId,
      data: data,
      syncStatus: SyncStatus.synced, // PowerSync handles sync automatically
      operation: operation,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await _databaseService.saveOfflineRecord(record);
  }

  /// Get sync status from PowerSync stub
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (!_isInitialized) {
      await initialize();
    }

    final status = _powersync.currentStatus;
    
    return {
      'isSyncing': status.isSyncing,
      'isConnected': status.isConnected,
      'lastSync': status.lastSyncedAt?.toIso8601String(),
      'syncErrors': status.hasErrors,
    };
  }

  /// Get sync history from our tracking database
  Future<List<SyncSession>> getSyncHistory({int limit = 10}) async {
    return await _databaseService.getRecentSyncSessions(limit: limit);
  }

  /// Dispose PowerSync stub resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _powersync.disconnect();
      await _powersync.close();
      _isInitialized = false;
    }
  }

  /// Enable/disable auto sync
  Future<void> setAutoSync(bool enabled) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (enabled) {
      await _powersync.connect();
    } else {
      await _powersync.disconnect();
    }
  }

  /// Force refresh from server
  Future<void> refreshFromServer() async {
    if (!_isInitialized) {
      await initialize();
    }

    // PowerSync stub handles refresh automatically when connected
    await _powersync.connect();
  }
}
