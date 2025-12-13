import 'package:equatable/equatable.dart';

/// Sync status for offline data
enum SyncStatus {
  synced,
  pendingUpload,
  pendingDownload,
  conflict,
  offlineOnly,
  syncing,
  failed,
}

/// Offline operation for tracking changes
enum OfflineOperation {
  create,
  update,
  delete,
}

/// Offline data record for tracking sync state
class OfflineDataRecord extends Equatable {
  final String id;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> data;
  final SyncStatus syncStatus;
  final OfflineOperation? operation;
  final DateTime createdAt;
  final DateTime lastModified;
  final DateTime? lastSyncAttempt;
  final String? errorMessage;
  final int retryCount;
  final Map<String, dynamic>? metadata;

  const OfflineDataRecord({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.data,
    required this.syncStatus,
    this.operation,
    required this.createdAt,
    required this.lastModified,
    this.lastSyncAttempt,
    this.errorMessage,
    this.retryCount = 0,
    this.metadata,
  });

  factory OfflineDataRecord.fromJson(Map<String, dynamic> json) {
    return OfflineDataRecord(
      id: json['id'],
      tableName: json['table_name'],
      recordId: json['record_id'],
      data: json['data'],
      syncStatus: SyncStatus.values.firstWhere((e) => e.name == json['sync_status']),
      operation: json['operation'] != null ? 
        OfflineOperation.values.firstWhere((e) => e.name == json['operation']) : null,
      createdAt: DateTime.parse(json['created_at']),
      lastModified: DateTime.parse(json['last_modified']),
      lastSyncAttempt: json['last_sync_attempt'] != null ? 
        DateTime.parse(json['last_sync_attempt']) : null,
      errorMessage: json['error_message'],
      retryCount: json['retry_count'] ?? 0,
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'data': data,
      'sync_status': syncStatus.name,
      'operation': operation?.name,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'last_sync_attempt': lastSyncAttempt?.toIso8601String(),
      'error_message': errorMessage,
      'retry_count': retryCount,
      'metadata': metadata,
    };
  }

  OfflineDataRecord copyWith({
    String? id,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? data,
    SyncStatus? syncStatus,
    OfflineOperation? operation,
    DateTime? createdAt,
    DateTime? lastModified,
    DateTime? lastSyncAttempt,
    String? errorMessage,
    int? retryCount,
    Map<String, dynamic>? metadata,
  }) {
    return OfflineDataRecord(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      data: data ?? this.data,
      syncStatus: syncStatus ?? this.syncStatus,
      operation: operation ?? this.operation,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get needsSync => syncStatus == SyncStatus.pendingUpload || 
                        syncStatus == SyncStatus.pendingDownload ||
                        syncStatus == SyncStatus.conflict ||
                        syncStatus == SyncStatus.failed;

  bool get hasError => errorMessage != null;

  @override
  List<Object?> get props => [
        id,
        tableName,
        recordId,
        data,
        syncStatus,
        operation,
        createdAt,
        lastModified,
        lastSyncAttempt,
        errorMessage,
        retryCount,
        metadata,
      ];
}

/// Sync conflict information
class SyncConflict extends Equatable {
  final String id;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final Map<String, dynamic> baseData; // Original data before conflict
  final List<String> conflictingFields;
  final DateTime detectedAt;
  final String? description;
  final ConflictResolutionStrategy? resolutionStrategy;
  final DateTime? resolvedAt;
  final Map<String, dynamic>? resolvedData;

  const SyncConflict({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.remoteData,
    required this.baseData,
    required this.conflictingFields,
    required this.detectedAt,
    this.description,
    this.resolutionStrategy,
    this.resolvedAt,
    this.resolvedData,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'],
      tableName: json['table_name'],
      recordId: json['record_id'],
      localData: json['local_data'],
      remoteData: json['remote_data'],
      baseData: json['base_data'],
      conflictingFields: List<String>.from(json['conflicting_fields']),
      detectedAt: DateTime.parse(json['detected_at']),
      description: json['description'],
      resolutionStrategy: json['resolution_strategy'] != null ?
        ConflictResolutionStrategy.values.firstWhere((e) => e.name == json['resolution_strategy']) : null,
      resolvedAt: json['resolved_at'] != null ? 
        DateTime.parse(json['resolved_at']) : null,
      resolvedData: json['resolved_data'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'local_data': localData,
      'remote_data': remoteData,
      'base_data': baseData,
      'conflicting_fields': conflictingFields,
      'detected_at': detectedAt.toIso8601String(),
      'description': description,
      'resolution_strategy': resolutionStrategy?.name,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_data': resolvedData,
    };
  }

  SyncConflict copyWith({
    String? id,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
    Map<String, dynamic>? baseData,
    List<String>? conflictingFields,
    DateTime? detectedAt,
    String? description,
    ConflictResolutionStrategy? resolutionStrategy,
    DateTime? resolvedAt,
    Map<String, dynamic>? resolvedData,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      localData: localData ?? this.localData,
      remoteData: remoteData ?? this.remoteData,
      baseData: baseData ?? this.baseData,
      conflictingFields: conflictingFields ?? this.conflictingFields,
      detectedAt: detectedAt ?? this.detectedAt,
      description: description ?? this.description,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedData: resolvedData ?? this.resolvedData,
    );
  }

  bool get isResolved => resolvedAt != null;

  @override
  List<Object?> get props => [
        id,
        tableName,
        recordId,
        localData,
        remoteData,
        baseData,
        conflictingFields,
        detectedAt,
        description,
        resolutionStrategy,
        resolvedAt,
        resolvedData,
      ];
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  localWins,
  remoteWins,
  manualMerge,
  automaticMerge,
  defer,
}

/// Sync session for tracking batch operations
class SyncSession extends Equatable {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SyncStatus status;
  final int recordsProcessed;
  final int recordsTotal;
  final int conflictsDetected;
  final int errorsEncountered;
  final List<String> errorMessages;
  final Map<String, dynamic>? metadata;

  const SyncSession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.recordsProcessed = 0,
    this.recordsTotal = 0,
    this.conflictsDetected = 0,
    this.errorsEncountered = 0,
    this.errorMessages = const [],
    this.metadata,
  });

  factory SyncSession.fromJson(Map<String, dynamic> json) {
    return SyncSession(
      id: json['id'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? 
        DateTime.parse(json['completed_at']) : null,
      status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      recordsProcessed: json['records_processed'] ?? 0,
      recordsTotal: json['records_total'] ?? 0,
      conflictsDetected: json['conflicts_detected'] ?? 0,
      errorsEncountered: json['errors_encountered'] ?? 0,
      errorMessages: json['error_messages'] != null ? 
        List<String>.from(json['error_messages']) : [],
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status.name,
      'records_processed': recordsProcessed,
      'records_total': recordsTotal,
      'conflicts_detected': conflictsDetected,
      'errors_encountered': errorsEncountered,
      'error_messages': errorMessages,
      'metadata': metadata,
    };
  }

  SyncSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncStatus? status,
    int? recordsProcessed,
    int? recordsTotal,
    int? conflictsDetected,
    int? errorsEncountered,
    List<String>? errorMessages,
    Map<String, dynamic>? metadata,
  }) {
    return SyncSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      recordsProcessed: recordsProcessed ?? this.recordsProcessed,
      recordsTotal: recordsTotal ?? this.recordsTotal,
      conflictsDetected: conflictsDetected ?? this.conflictsDetected,
      errorsEncountered: errorsEncountered ?? this.errorsEncountered,
      errorMessages: errorMessages ?? this.errorMessages,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive => status == SyncStatus.syncing;
  bool get isCompleted => status == SyncStatus.synced;
  bool get hasErrors => errorsEncountered > 0;

  double get progress => recordsTotal > 0 ? recordsProcessed / recordsTotal : 0.0;

  @override
  List<Object?> get props => [
        id,
        startedAt,
        completedAt,
        status,
        recordsProcessed,
        recordsTotal,
        conflictsDetected,
        errorsEncountered,
        errorMessages,
        metadata,
      ];
}

/// Media cache entry for offline media storage
class MediaCacheEntry extends Equatable {
  final String id;
  final String originalUrl;
  final String localPath;
  final String mimeType;
  final int fileSize;
  final DateTime cachedAt;
  final DateTime lastAccessed;
  final int accessCount;
  final bool isTemporary;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  const MediaCacheEntry({
    required this.id,
    required this.originalUrl,
    required this.localPath,
    required this.mimeType,
    required this.fileSize,
    required this.cachedAt,
    required this.lastAccessed,
    this.accessCount = 0,
    this.isTemporary = false,
    this.expiresAt,
    this.metadata,
  });

  factory MediaCacheEntry.fromJson(Map<String, dynamic> json) {
    return MediaCacheEntry(
      id: json['id'],
      originalUrl: json['original_url'],
      localPath: json['local_path'],
      mimeType: json['mime_type'],
      fileSize: json['file_size'],
      cachedAt: DateTime.parse(json['cached_at']),
      lastAccessed: DateTime.parse(json['last_accessed']),
      accessCount: json['access_count'] ?? 0,
      isTemporary: json['is_temporary'] ?? false,
      expiresAt: json['expires_at'] != null ? 
        DateTime.parse(json['expires_at']) : null,
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_url': originalUrl,
      'local_path': localPath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'cached_at': cachedAt.toIso8601String(),
      'last_accessed': lastAccessed.toIso8601String(),
      'access_count': accessCount,
      'is_temporary': isTemporary,
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  MediaCacheEntry copyWith({
    String? id,
    String? originalUrl,
    String? localPath,
    String? mimeType,
    int? fileSize,
    DateTime? cachedAt,
    DateTime? lastAccessed,
    int? accessCount,
    bool? isTemporary,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return MediaCacheEntry(
      id: id ?? this.id,
      originalUrl: originalUrl ?? this.originalUrl,
      localPath: localPath ?? this.localPath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      isTemporary: isTemporary ?? this.isTemporary,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
        id,
        originalUrl,
        localPath,
        mimeType,
        fileSize,
        cachedAt,
        lastAccessed,
        accessCount,
        isTemporary,
        expiresAt,
        metadata,
      ];
}

/// Offline storage configuration
class OfflineStorageConfig extends Equatable {
  final int maxCacheSizeMB;
  final int maxDatabaseSizeMB;
  final Duration cacheExpiration;
  final Duration syncRetryInterval;
  final int maxSyncRetries;
  final bool enableAutoSync;
  final bool enableBackgroundSync;
  final List<String> cachedTables;
  final Map<String, dynamic>? metadata;

  const OfflineStorageConfig({
    this.maxCacheSizeMB = 500,
    this.maxDatabaseSizeMB = 100,
    this.cacheExpiration = const Duration(days: 30),
    this.syncRetryInterval = const Duration(minutes: 5),
    this.maxSyncRetries = 3,
    this.enableAutoSync = true,
    this.enableBackgroundSync = true,
    this.cachedTables = const ['timeline_events', 'stories', 'media'],
    this.metadata,
  });

  factory OfflineStorageConfig.fromJson(Map<String, dynamic> json) {
    return OfflineStorageConfig(
      maxCacheSizeMB: json['maxCacheSizeMB'] ?? 500,
      maxDatabaseSizeMB: json['maxDatabaseSizeMB'] ?? 100,
      cacheExpiration: Duration(milliseconds: json['cacheExpiration'] ?? 2592000000), // 30 days
      syncRetryInterval: Duration(milliseconds: json['syncRetryInterval'] ?? 300000), // 5 minutes
      maxSyncRetries: json['maxSyncRetries'] ?? 3,
      enableAutoSync: json['enableAutoSync'] ?? true,
      enableBackgroundSync: json['enableBackgroundSync'] ?? true,
      cachedTables: List<String>.from(json['cachedTables'] ?? ['timeline_events', 'stories', 'media']),
      metadata: json['metadata'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'maxCacheSizeMB': maxCacheSizeMB,
      'maxDatabaseSizeMB': maxDatabaseSizeMB,
      'cacheExpiration': cacheExpiration.inMilliseconds,
      'syncRetryInterval': syncRetryInterval.inMilliseconds,
      'maxSyncRetries': maxSyncRetries,
      'enableAutoSync': enableAutoSync,
      'enableBackgroundSync': enableBackgroundSync,
      'cachedTables': cachedTables,
      'metadata': metadata,
    };
  }

  OfflineStorageConfig copyWith({
    int? maxCacheSizeMB,
    int? maxDatabaseSizeMB,
    Duration? cacheExpiration,
    Duration? syncRetryInterval,
    int? maxSyncRetries,
    bool? enableAutoSync,
    bool? enableBackgroundSync,
    List<String>? cachedTables,
    Map<String, dynamic>? metadata,
  }) {
    return OfflineStorageConfig(
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      maxDatabaseSizeMB: maxDatabaseSizeMB ?? this.maxDatabaseSizeMB,
      cacheExpiration: cacheExpiration ?? this.cacheExpiration,
      syncRetryInterval: syncRetryInterval ?? this.syncRetryInterval,
      maxSyncRetries: maxSyncRetries ?? this.maxSyncRetries,
      enableAutoSync: enableAutoSync ?? this.enableAutoSync,
      enableBackgroundSync: enableBackgroundSync ?? this.enableBackgroundSync,
      cachedTables: cachedTables ?? this.cachedTables,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        maxCacheSizeMB,
        maxDatabaseSizeMB,
        cacheExpiration,
        syncRetryInterval,
        maxSyncRetries,
        enableAutoSync,
        enableBackgroundSync,
        cachedTables,
        metadata,
      ];
}

/// Cache priority levels for intelligent media caching
enum CachePriority {
  high,
  medium,
  low,
}

/// Media file metadata for intelligent caching
class MediaFileMetadata {
  final String url;
  final String fileType;
  final int fileSize;
  final CachePriority priority;
  final DateTime lastAccessed;
  final int accessCount;
  final bool isEssential;

  MediaFileMetadata({
    required this.url,
    required this.fileType,
    required this.fileSize,
    required this.priority,
    required this.lastAccessed,
    required this.accessCount,
    this.isEssential = false,
  });

  double get priorityScore {
    double score = 0.0;
    
    // Priority level score
    switch (priority) {
      case CachePriority.high:
        score += 100;
        break;
      case CachePriority.medium:
        score += 50;
        break;
      case CachePriority.low:
        score += 10;
        break;
    }
    
    // Access frequency score
    score += accessCount * 5;
    
    // Recency score
    final daysSinceAccess = DateTime.now().difference(lastAccessed).inDays;
    score += (30 - daysSinceAccess).clamp(0, 30);
    
    // Essential files get bonus
    if (isEssential) score += 200;
    
    return score;
  }
}
