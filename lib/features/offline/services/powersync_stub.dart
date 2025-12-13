import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_database_service.dart';
import 'offline_sync_service.dart';
import '../models/offline_models.dart';

/// Provider for PowerSync stub (simulated PowerSync for testing)
final powersyncStubProvider = Provider((ref) => PowerSyncStub(
  databaseService: ref.read(offlineDatabaseServiceProvider),
  manualSyncService: ref.read(offlineSyncServiceProvider),
));

/// PowerSync stub that simulates PowerSync behavior using manual sync
class PowerSyncStub {
  final OfflineDatabaseService _databaseService;
  final OfflineSyncService _manualSyncService;
  bool _isInitialized = false;
  bool _isConnected = false;

  PowerSyncStub({
    required OfflineDatabaseService databaseService,
    required OfflineSyncService manualSyncService,
  }) : _databaseService = databaseService,
       _manualSyncService = manualSyncService;

  /// Initialize PowerSync stub
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize the underlying manual sync service
    await _manualSyncService.initialize();
    _isInitialized = true;
  }

  /// Connect to simulated PowerSync backend
  Future<void> connect() async {
    if (!_isInitialized) {
      await initialize();
    }
    _isConnected = true;
  }

  /// Disconnect from simulated PowerSync backend
  Future<void> disconnect() async {
    _isConnected = false;
  }

  /// Close PowerSync stub
  Future<void> close() async {
    _isConnected = false;
    _isInitialized = false;
  }

  /// Get sync status
  PowerSyncStatus get currentStatus => PowerSyncStatus(
    isConnected: _isConnected,
    isSyncing: false,
    lastSyncedAt: DateTime.now(),
    hasErrors: false,
  );

  /// Execute a query (simulated)
  Future<List<Map<String, dynamic>>> execute(String sql, [List<dynamic>? args]) async {
    // This would normally use PowerSync's query engine
    // For now, return empty results
    return [];
  }

  /// Watch for changes (simulated)
  Stream<List<Map<String, dynamic>>> watch(String sql, [List<dynamic>? args]) async* {
    // Simulate watching by returning empty stream
    yield [];
  }

  /// Save a record using PowerSync (simulated)
  Future<void> saveForSync(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
    OfflineOperation operation,
  ) async {
    // Use manual sync service under the hood
    await _manualSyncService.saveForSync(tableName, recordId, data, operation);
  }

  /// Get sync history
  Future<List<SyncSession>> getSyncHistory({int limit = 10}) async {
    return await _manualSyncService.getSyncHistory(limit: limit);
  }
}

/// PowerSync status model
class PowerSyncStatus {
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final bool hasErrors;

  PowerSyncStatus({
    required this.isConnected,
    required this.isSyncing,
    this.lastSyncedAt,
    required this.hasErrors,
  });
}
