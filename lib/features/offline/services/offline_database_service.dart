import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_models.dart';

/// Provider for offline database service
final offlineDatabaseServiceProvider = Provider((ref) => OfflineDatabaseService());

/// Offline database service for local SQLite operations
class OfflineDatabaseService {
  static Database? _database;
  static const String _dbName = 'timeline_offline.db';
  static const int _dbVersion = 1;

  final OfflineStorageConfig _config;

  OfflineDatabaseService({OfflineStorageConfig? config}) 
      : _config = config ?? const OfflineStorageConfig();

  /// Initialize the offline database
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with all required tables
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    // Create offline data records table
    await db.execute('''
      CREATE TABLE offline_data_records (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        operation TEXT,
        created_at INTEGER NOT NULL,
        last_modified INTEGER NOT NULL,
        last_sync_attempt INTEGER,
        error_message TEXT,
        retry_count INTEGER DEFAULT 0,
        metadata TEXT,
        UNIQUE(table_name, record_id)
      )
    ''');

    // Create sync conflicts table
    await db.execute('''
      CREATE TABLE sync_conflicts (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        base_data TEXT NOT NULL,
        conflicting_fields TEXT NOT NULL,
        detected_at INTEGER NOT NULL,
        description TEXT,
        resolution_strategy TEXT,
        resolved_at INTEGER,
        resolved_data TEXT
      )
    ''');

    // Create sync sessions table
    await db.execute('''
      CREATE TABLE sync_sessions (
        id TEXT PRIMARY KEY,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        status TEXT NOT NULL,
        records_processed INTEGER DEFAULT 0,
        records_total INTEGER DEFAULT 0,
        conflicts_detected INTEGER DEFAULT 0,
        errors_encountered INTEGER DEFAULT 0,
        error_messages TEXT,
        metadata TEXT
      )
    ''');

    // Create media cache table
    await db.execute('''
      CREATE TABLE media_cache (
        id TEXT PRIMARY KEY,
        original_url TEXT NOT NULL UNIQUE,
        local_path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        access_count INTEGER DEFAULT 0,
        is_temporary INTEGER DEFAULT 0,
        expires_at INTEGER,
        metadata TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_offline_records_sync_status ON offline_data_records(sync_status)');
    await db.execute('CREATE INDEX idx_offline_records_table ON offline_data_records(table_name)');
    await db.execute('CREATE INDEX idx_conflicts_table ON sync_conflicts(table_name)');
    await db.execute('CREATE INDEX idx_media_cache_url ON media_cache(original_url)');
    await db.execute('CREATE INDEX idx_media_cache_expires ON media_cache(expires_at)');

    // Create timeline events table (offline version)
    await db.execute('''
      CREATE TABLE timeline_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        location_lat REAL,
        location_lng REAL,
        location_name TEXT,
        media_urls TEXT,
        context_id TEXT,
        cluster_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Create stories table (offline version)
    await db.execute('''
      CREATE TABLE stories (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        event_ids TEXT,
        context_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_published INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Create contexts table (offline version)
    await db.execute('''
      CREATE TABLE contexts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        theme_data TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');
  }

  /// Upgrade database schema
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades in future versions
    if (oldVersion < newVersion) {
      // Add migration logic here
    }
  }

  /// Save or update an offline data record
  Future<void> saveOfflineRecord(OfflineDataRecord record) async {
    final db = await database;
    
    await db.insert(
      'offline_data_records',
      {
        'id': record.id,
        'table_name': record.tableName,
        'record_id': record.recordId,
        'data': json.encode(record.data),
        'sync_status': record.syncStatus.name,
        'operation': record.operation?.name,
        'created_at': record.createdAt.millisecondsSinceEpoch,
        'last_modified': record.lastModified.millisecondsSinceEpoch,
        'last_sync_attempt': record.lastSyncAttempt?.millisecondsSinceEpoch,
        'error_message': record.errorMessage,
        'retry_count': record.retryCount,
        'metadata': record.metadata != null ? json.encode(record.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get offline records that need syncing
  Future<List<OfflineDataRecord>> getPendingSyncRecords() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_data_records',
      where: 'sync_status IN (?, ?, ?, ?)',
      whereArgs: [
        SyncStatus.pendingUpload.name,
        SyncStatus.pendingDownload.name,
        SyncStatus.conflict.name,
        SyncStatus.failed.name,
      ],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToOfflineRecord(map)).toList();
  }

  /// Get all offline records for a specific table
  Future<List<OfflineDataRecord>> getRecordsForTable(String tableName) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_data_records',
      where: 'table_name = ?',
      whereArgs: [tableName],
      orderBy: 'last_modified DESC',
    );

    return maps.map((map) => _mapToOfflineRecord(map)).toList();
  }

  /// Save a conflict record
  Future<void> saveConflict(SyncConflict conflict) async {
    final db = await database;
    
    await db.insert(
      'sync_conflicts',
      {
        'id': conflict.id,
        'table_name': conflict.tableName,
        'record_id': conflict.recordId,
        'local_data': json.encode(conflict.localData),
        'remote_data': json.encode(conflict.remoteData),
        'base_data': json.encode(conflict.baseData),
        'conflicting_fields': json.encode(conflict.conflictingFields),
        'detected_at': conflict.detectedAt.toIso8601String(),
        'description': conflict.description,
        'resolution_strategy': conflict.resolutionStrategy?.name,
        'resolved_at': conflict.resolvedAt?.toIso8601String(),
        'resolved_data': conflict.resolvedData != null 
            ? json.encode(conflict.resolvedData) 
            : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_conflicts',
      where: 'resolved_at IS NULL',
      orderBy: 'detected_at DESC',
    );

    return maps.map((map) => _mapToSyncConflict(map)).toList();
  }

  /// Get conflicts for a specific table
  Future<List<SyncConflict>> getConflictsForTable(String tableName) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_conflicts',
      where: 'table_name = ?',
      whereArgs: [tableName],
      orderBy: 'detected_at DESC',
    );

    return maps.map((map) => _mapToSyncConflict(map)).toList();
  }

  /// Update a record with resolved data
  Future<void> updateRecord(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    
    await db.update(
      tableName,
      {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  /// Mark conflict as applied
  Future<void> markConflictApplied(String conflictId) async {
    final db = await database;
    
    await db.update(
      'sync_conflicts',
      {'applied_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conflictId],
    );
  }

  /// Update sync status for a record
  Future<void> updateRecordSyncStatus(
    String recordId, 
    SyncStatus status, {
    String? errorMessage,
    int? retryCount,
  }) async {
    final db = await database;
    
    await db.update(
      'offline_data_records',
      {
        'sync_status': status.name,
        'last_sync_attempt': DateTime.now().millisecondsSinceEpoch,
        'error_message': errorMessage,
        'retry_count': retryCount,
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  /// Delete an offline record
  Future<void> deleteOfflineRecord(String recordId) async {
    final db = await database;
    
    await db.delete(
      'offline_data_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  /// Save a sync conflict
  Future<void> saveSyncConflict(SyncConflict conflict) async {
    final db = await database;
    
    await db.insert(
      'sync_conflicts',
      {
        'id': conflict.id,
        'table_name': conflict.tableName,
        'record_id': conflict.recordId,
        'local_data': json.encode(conflict.localData),
        'remote_data': json.encode(conflict.remoteData),
        'base_data': json.encode(conflict.baseData),
        'conflicting_fields': json.encode(conflict.conflictingFields),
        'detected_at': conflict.detectedAt.millisecondsSinceEpoch,
        'description': conflict.description,
        'resolution_strategy': conflict.resolutionStrategy?.name,
        'resolved_at': conflict.resolvedAt?.millisecondsSinceEpoch,
        'resolved_data': conflict.resolvedData != null ? json.encode(conflict.resolvedData) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  
  /// Resolve a sync conflict
  Future<void> resolveConflict(
    String conflictId, 
    ConflictResolutionStrategy strategy,
    Map<String, dynamic> resolvedData,
  ) async {
    final db = await database;
    
    await db.update(
      'sync_conflicts',
      {
        'resolution_strategy': strategy.name,
        'resolved_at': DateTime.now().millisecondsSinceEpoch,
        'resolved_data': json.encode(resolvedData),
      },
      where: 'id = ?',
      whereArgs: [conflictId],
    );
  }

  /// Create a new sync session
  Future<void> createSyncSession(SyncSession session) async {
    final db = await database;
    
    await db.insert(
      'sync_sessions',
      {
        'id': session.id,
        'started_at': session.startedAt.millisecondsSinceEpoch,
        'completed_at': session.completedAt?.millisecondsSinceEpoch,
        'status': session.status.name,
        'records_processed': session.recordsProcessed,
        'records_total': session.recordsTotal,
        'conflicts_detected': session.conflictsDetected,
        'errors_encountered': session.errorsEncountered,
        'error_messages': session.errorMessages.isNotEmpty ? json.encode(session.errorMessages) : null,
        'metadata': session.metadata != null ? json.encode(session.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update sync session progress
  Future<void> updateSyncSession(SyncSession session) async {
    final db = await database;
    
    await db.update(
      'sync_sessions',
      {
        'completed_at': session.completedAt?.millisecondsSinceEpoch,
        'status': session.status.name,
        'records_processed': session.recordsProcessed,
        'records_total': session.recordsTotal,
        'conflicts_detected': session.conflictsDetected,
        'errors_encountered': session.errorsEncountered,
        'error_messages': session.errorMessages.isNotEmpty ? json.encode(session.errorMessages) : null,
      },
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Get recent sync sessions
  Future<List<SyncSession>> getRecentSyncSessions({int limit = 10}) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return maps.map((map) => _mapToSyncSession(map)).toList();
  }

  /// Save media cache entry
  Future<void> saveMediaCacheEntry(MediaCacheEntry entry) async {
    final db = await database;
    
    await db.insert(
      'media_cache',
      {
        'id': entry.id,
        'original_url': entry.originalUrl,
        'local_path': entry.localPath,
        'mime_type': entry.mimeType,
        'file_size': entry.fileSize,
        'cached_at': entry.cachedAt.millisecondsSinceEpoch,
        'last_accessed': entry.lastAccessed.millisecondsSinceEpoch,
        'access_count': entry.accessCount,
        'is_temporary': entry.isTemporary ? 1 : 0,
        'expires_at': entry.expiresAt?.millisecondsSinceEpoch,
        'metadata': entry.metadata != null ? json.encode(entry.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get media cache entry by URL
  Future<MediaCacheEntry?> getMediaCacheEntry(String originalUrl) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      where: 'original_url = ?',
      whereArgs: [originalUrl],
    );

    if (maps.isEmpty) return null;
    
    final entry = _mapToMediaCacheEntry(maps.first);
    
    // Update access statistics
    await db.update(
      'media_cache',
      {
        'last_accessed': DateTime.now().millisecondsSinceEpoch,
        'access_count': entry.accessCount + 1,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    
    return entry;
  }

  /// Clean up expired media cache entries
  Future<void> cleanupExpiredCache() async {
    final db = await database;
    
    await db.delete(
      'media_cache',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final recordCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM offline_data_records')
    ) ?? 0;
    
    final pendingSyncCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM offline_data_records WHERE sync_status IN (?, ?, ?, ?)', 
        [SyncStatus.pendingUpload.name, SyncStatus.pendingDownload.name, SyncStatus.conflict.name, SyncStatus.failed.name])
    ) ?? 0;
    
    final conflictCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_conflicts WHERE resolved_at IS NULL')
    ) ?? 0;
    
    final mediaCacheCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media_cache')
    ) ?? 0;
    
    final mediaCacheSize = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(file_size) FROM media_cache')
    ) ?? 0;

    return {
      'totalRecords': recordCount,
      'pendingSync': pendingSyncCount,
      'conflicts': conflictCount,
      'mediaCacheCount': mediaCacheCount,
      'mediaCacheSizeBytes': mediaCacheSize,
      'mediaCacheSizeMB': (mediaCacheSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Helper methods for mapping database rows to models

  OfflineDataRecord _mapToOfflineRecord(Map<String, dynamic> map) {
    return OfflineDataRecord(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      data: json.decode(map['data']),
      syncStatus: SyncStatus.values.byName(map['sync_status']),
      operation: OfflineOperation.values.byName(map['operation']),
      createdAt: DateTime.parse(map['created_at']),
      lastModified: DateTime.parse(map['last_modified']),
      lastSyncAttempt: map['last_sync_attempt'] != null
          ? DateTime.parse(map['last_sync_attempt'])
          : null,
      errorMessage: map['error_message'],
      retryCount: map['retry_count'],
      metadata: map['metadata'] != null
          ? json.decode(map['metadata'])
          : null,
    );
  }

  SyncConflict _mapToSyncConflict(Map<String, dynamic> map) {
    return SyncConflict(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      localData: json.decode(map['local_data']),
      remoteData: json.decode(map['remote_data']),
      baseData: json.decode(map['base_data']),
      conflictingFields: List<String>.from(json.decode(map['conflicting_fields'])),
      detectedAt: DateTime.fromMillisecondsSinceEpoch(map['detected_at']),
      description: map['description'],
      resolutionStrategy: map['resolution_strategy'] != null ?
        ConflictResolutionStrategy.values.firstWhere((e) => e.name == map['resolution_strategy']) : null,
      resolvedAt: map['resolved_at'] != null ? 
        DateTime.fromMillisecondsSinceEpoch(map['resolved_at']) : null,
      resolvedData: map['resolved_data'] != null ? json.decode(map['resolved_data']) : null,
    );
  }

  SyncSession _mapToSyncSession(Map<String, dynamic> map) {
    return SyncSession(
      id: map['id'],
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at']),
      completedAt: map['completed_at'] != null ? 
        DateTime.fromMillisecondsSinceEpoch(map['completed_at']) : null,
      status: SyncStatus.values.firstWhere((e) => e.name == map['status']),
      recordsProcessed: map['records_processed'] ?? 0,
      recordsTotal: map['records_total'] ?? 0,
      conflictsDetected: map['conflicts_detected'] ?? 0,
      errorsEncountered: map['errors_encountered'] ?? 0,
      errorMessages: map['error_messages'] != null ? 
        List<String>.from(json.decode(map['error_messages'])) : [],
      metadata: map['metadata'] != null ? json.decode(map['metadata']) : null,
    );
  }

  MediaCacheEntry _mapToMediaCacheEntry(Map<String, dynamic> map) {
    return MediaCacheEntry(
      id: map['id'],
      originalUrl: map['original_url'],
      localPath: map['local_path'],
      mimeType: map['mime_type'],
      fileSize: map['file_size'],
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at']),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['last_accessed']),
      accessCount: map['access_count'] ?? 0,
      isTemporary: (map['is_temporary'] ?? 0) == 1,
      expiresAt: map['expires_at'] != null ? 
        DateTime.fromMillisecondsSinceEpoch(map['expires_at']) : null,
      metadata: map['metadata'] != null ? json.decode(map['metadata']) : null,
    );
  }
}
