import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_sync_service.dart';
import 'powersync_adapter.dart';
import '../models/offline_models.dart';

/// Provider for hybrid sync service that can use either manual sync or PowerSync
final hybridSyncServiceProvider = Provider((ref) => HybridSyncService(
  manualSyncService: ref.read(offlineSyncServiceProvider),
  powersyncAdapter: ref.read(powersyncAdapterProvider),
));

/// Hybrid sync service that can switch between manual sync and PowerSync
class HybridSyncService {
  final OfflineSyncService _manualSyncService;
  final PowerSyncAdapter _powersyncAdapter;
  SyncEngine _currentEngine = SyncEngine.manual;
  
  HybridSyncService({
    required OfflineSyncService manualSyncService,
    required PowerSyncAdapter powersyncAdapter,
  }) : _manualSyncService = manualSyncService,
       _powersyncAdapter = powersyncAdapter;

  /// Initialize the sync service
  Future<void> initialize({SyncEngine engine = SyncEngine.manual}) async {
    _currentEngine = engine;
    
    if (engine == SyncEngine.powersync) {
      await _powersyncAdapter.initialize();
    } else {
      await _manualSyncService.initialize();
    }
  }

  /// Switch sync engine
  Future<void> switchEngine(SyncEngine engine) async {
    if (_currentEngine == engine) return;
    
    // Dispose current engine
    if (_currentEngine == SyncEngine.powersync) {
      await _powersyncAdapter.dispose();
    } else {
      _manualSyncService.dispose();
    }
    
    // Initialize new engine
    await initialize(engine: engine);
  }

  /// Get current sync engine
  SyncEngine get currentEngine => _currentEngine;

  /// Start sync process using current engine
  Future<SyncSession> syncNow() async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        return await _manualSyncService.syncNow();
      case SyncEngine.powersync:
        return await _powersyncAdapter.syncNow();
    }
  }

  /// Save a record for sync
  Future<void> saveForSync(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
    OfflineOperation operation,
  ) async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        await _manualSyncService.saveForSync(tableName, recordId, data, operation);
        break;
      case SyncEngine.powersync:
        await _powersyncAdapter.saveForSync(tableName, recordId, data, operation);
        break;
    }
  }

  /// Update a record for sync
  Future<void> updateForSync(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        await _manualSyncService.updateForSync(tableName, recordId, data);
        break;
      case SyncEngine.powersync:
        await _powersyncAdapter.saveForSync(
          tableName, 
          recordId, 
          data, 
          OfflineOperation.update,
        );
        break;
    }
  }

  /// Delete a record for sync
  Future<void> deleteForSync(
    String tableName,
    String recordId,
  ) async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        await _manualSyncService.deleteForSync(tableName, recordId);
        break;
      case SyncEngine.powersync:
        await _powersyncAdapter.saveForSync(
          tableName, 
          recordId, 
          {'id': recordId}, 
          OfflineOperation.delete,
        );
        break;
    }
  }

  /// Get current sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        final status = await _manualSyncService.getSyncStatus();
        return {
          ...status,
          'engine': 'manual',
        };
      case SyncEngine.powersync:
        final status = await _powersyncAdapter.getSyncStatus();
        return {
          ...status,
          'engine': 'powersync',
        };
    }
  }

  /// Get sync history from current engine
  Future<List<SyncSession>> getSyncHistory({int limit = 10}) async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        return await _manualSyncService.getSyncHistory(limit: limit);
      case SyncEngine.powersync:
        return await _powersyncAdapter.getSyncHistory(limit: limit);
    }
  }

  /// Retry failed sync operations
  Future<void> retryFailedSyncs() async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        await _manualSyncService.retryFailedSyncs();
        break;
      case SyncEngine.powersync:
        // PowerSync handles retries automatically
        await _powersyncAdapter.refreshFromServer();
        break;
    }
  }

  /// Enable/disable auto sync
  Future<void> setAutoSync(bool enabled) async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        await _manualSyncService.setAutoSync(enabled);
        break;
      case SyncEngine.powersync:
        await _powersyncAdapter.setAutoSync(enabled);
        break;
    }
  }

  /// Force refresh from server
  Future<void> refreshFromServer() async {
    switch (_currentEngine) {
      case SyncEngine.manual:
        await _manualSyncService.refreshFromServer();
        break;
      case SyncEngine.powersync:
        await _powersyncAdapter.refreshFromServer();
        break;
    }
  }

  /// Dispose the sync service
  Future<void> dispose() async {
    if (_currentEngine == SyncEngine.powersync) {
      await _powersyncAdapter.dispose();
    } else {
      _manualSyncService.dispose();
    }
  }

  /// Get PowerSync database if available
  dynamic getPowerSyncDatabase() {
    if (_currentEngine == SyncEngine.powersync) {
      return _powersyncAdapter.powersync;
    }
    return null;
  }

  /// Check if PowerSync is available
  bool get isPowerSyncAvailable => _currentEngine == SyncEngine.powersync;
}

/// Sync engine options
enum SyncEngine {
  manual,
  powersync,
}
