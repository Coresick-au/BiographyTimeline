import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/offline/services/offline_database_service.dart';
import '../../features/offline/models/offline_models.dart';

/// Database service facade that wraps OfflineDatabaseService
/// 
/// This provides a clean, injectable interface for services that need
/// database access, following the Dependency Injection pattern.
class DatabaseService {
  final OfflineDatabaseService _offlineDb;

  DatabaseService(this._offlineDb);

  /// Get the underlying database instance
  Future<dynamic> get database => _offlineDb.database;

  /// Save or update a record
  Future<void> saveRecord(OfflineDataRecord record) async {
    await _offlineDb.saveOfflineRecord(record);
  }

  /// Get records for a specific table
  Future<List<OfflineDataRecord>> getRecordsForTable(String tableName) async {
    return await _offlineDb.getRecordsForTable(tableName);
  }

  /// Get pending sync records
  Future<List<OfflineDataRecord>> getPendingSyncRecords() async {
    return await _offlineDb.getPendingSyncRecords();
  }

  /// Update a record
  Future<void> updateRecord(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    await _offlineDb.updateRecord(tableName, recordId, data);
  }

  /// Delete a record
  Future<void> deleteRecord(String recordId) async {
    await _offlineDb.deleteOfflineRecord(recordId);
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    return await _offlineDb.getDatabaseStats();
  }

  /// Save media cache entry
  Future<void> saveMediaCache(MediaCacheEntry entry) async {
    await _offlineDb.saveMediaCacheEntry(entry);
  }

  /// Get media cache entry
  Future<MediaCacheEntry?> getMediaCache(String url) async {
    return await _offlineDb.getMediaCacheEntry(url);
  }

  /// Clean up expired cache
  Future<void> cleanupCache() async {
    await _offlineDb.cleanupExpiredCache();
  }

  /// Close the database
  Future<void> close() async {
    await _offlineDb.close();
  }
}

/// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final offlineDb = ref.watch(offlineDatabaseServiceProvider);
  return DatabaseService(offlineDb);
});
