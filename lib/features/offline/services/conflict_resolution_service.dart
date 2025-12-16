import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'offline_database_service.dart';
import '../models/offline_models.dart';

/// Provider for conflict resolution service
final conflictResolutionServiceProvider = Provider((ref) => ConflictResolutionService(
  databaseService: ref.read(offlineDatabaseServiceProvider),
));

/// Service for detecting and resolving conflicts in offline synchronization
class ConflictResolutionService {
  final OfflineDatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  final Future<Map<String, dynamic>?> Function(String tableName, String recordId)? _baseRecordFetcher;

  ConflictResolutionService({
    required OfflineDatabaseService databaseService,
    Future<Map<String, dynamic>?> Function(String tableName, String recordId)? baseRecordFetcher,
  }) : _databaseService = databaseService,
       _baseRecordFetcher = baseRecordFetcher;

  /// Detect conflicts between local and remote data
  Future<List<SyncConflict>> detectConflicts(
    String tableName,
    List<Map<String, dynamic>> localRecords,
    List<Map<String, dynamic>> remoteRecords,
  ) async {
    final conflicts = <SyncConflict>[];
    
    // Create lookup maps for efficient comparison
    final localMap = {for (var r in localRecords) r['id'] as String: r};
    final remoteMap = {for (var r in remoteRecords) r['id'] as String: r};
    
    // Find all record IDs that exist in both local and remote
    final commonIds = localMap.keys.where(remoteMap.containsKey);
    
    for (final id in commonIds) {
      final local = localMap[id]!;
      final remote = remoteMap[id]!;
      
      // Get the base version if available
      final baseRecord = await _getBaseRecord(tableName, id);
      
      // Compare versions
      final localVersion = local['version'] as int? ?? 0;
      final remoteVersion = remote['version'] as int? ?? 0;
      
      // If versions differ, check for conflicts
      if (localVersion != remoteVersion) {
        final conflict = await _analyzeRecordConflict(
          tableName,
          id,
          local,
          remote,
          baseRecord,
        );
        
        if (conflict != null) {
          conflicts.add(conflict);
        }
      }
    }
    
    return conflicts;
  }

  /// Analyze a single record for conflicts
  Future<SyncConflict?> _analyzeRecordConflict(
    String tableName,
    String recordId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    Map<String, dynamic>? baseData,
  ) async {
    // Extract data payloads (remove metadata)
    final localPayload = _extractDataPayload(localData);
    final remotePayload = _extractDataPayload(remoteData);
    final basePayload = baseData != null ? _extractDataPayload(baseData) : <String, dynamic>{};
    
    // Find conflicting fields
    final conflictingFields = <String>[];
    final mergedData = <String, dynamic>{};
    
    // Check each field for conflicts
    final allFields = {...localPayload.keys, ...remotePayload.keys, ...basePayload.keys};
    
    for (final field in allFields) {
      final localValue = localPayload[field];
      final remoteValue = remotePayload[field];
      final baseValue = basePayload[field];
      
      if (localValue != remoteValue) {
        // Both sides changed the same field - potential conflict
        if (localValue != baseValue && remoteValue != baseValue) {
          conflictingFields.add(field);
        } else if (localValue != baseValue) {
          // Only local changed
          mergedData[field] = localValue;
        } else if (remoteValue != baseValue) {
          // Only remote changed
          mergedData[field] = remoteValue;
        } else {
          // Both changed to same value
          mergedData[field] = localValue;
        }
      } else {
        // Both have same value
        mergedData[field] = localValue;
      }
    }
    
    // If there are conflicting fields, create a conflict record
    if (conflictingFields.isNotEmpty) {
      return SyncConflict(
        id: _uuid.v4(),
        tableName: tableName,
        recordId: recordId,
        localData: localPayload,
        remoteData: remotePayload,
        baseData: basePayload,
        conflictingFields: conflictingFields,
        detectedAt: DateTime.now(),
        description: 'Conflict detected in ${conflictingFields.join(', ')}',
      );
    }
    
    // No conflicts - return null
    return null;
  }

  /// Extract data payload from record (remove metadata fields)
  Map<String, dynamic> _extractDataPayload(Map<String, dynamic> record) {
    final payload = Map<String, dynamic>.from(record);
    
    // Remove metadata fields
    payload.remove('id');
    payload.remove('version');
    payload.remove('created_at');
    payload.remove('updated_at');
    payload.remove('sync_status');
    payload.remove('synced_at');
    
    return payload;
  }

  /// Get base record for 3-way merge
  Future<Map<String, dynamic>?> _getBaseRecord(String tableName, String recordId) async {
    if (_baseRecordFetcher != null) {
      return _baseRecordFetcher!(tableName, recordId);
    }
    // In a real implementation, this would fetch the last common ancestor
    // For now, we'll return null (base case)
    return null;
  }

  /// Resolve conflicts using the specified strategy
  Future<SyncConflict> resolveConflict(
    SyncConflict conflict,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? userResolution,
  }) async {
    Map<String, dynamic>? resolvedData;
    
    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        resolvedData = conflict.localData;
        break;
        
      case ConflictResolutionStrategy.remoteWins:
        resolvedData = conflict.remoteData;
        break;
        
      case ConflictResolutionStrategy.automaticMerge:
        resolvedData = await _performAutomaticMerge(conflict);
        break;
        
      case ConflictResolutionStrategy.manualMerge:
        if (userResolution == null) {
          throw ArgumentError('User resolution data required for manual merge');
        }
        resolvedData = userResolution;
        break;
        
      case ConflictResolutionStrategy.defer:
        // Don't resolve now, just mark as deferred
        return conflict.copyWith(
          resolutionStrategy: ConflictResolutionStrategy.defer,
          resolvedAt: DateTime.now(),
        );
    }
    
    // Save the resolved conflict
    final resolved = conflict.copyWith(
      resolutionStrategy: strategy,
      resolvedData: resolvedData,
      resolvedAt: DateTime.now(),
    );
    
    await _databaseService.saveConflict(resolved);
    
    return resolved;
  }

  /// Perform automatic merge for non-conflicting fields
  Future<Map<String, dynamic>> _performAutomaticMerge(SyncConflict conflict) async {
    final merged = <String, dynamic>{};
    
    // Start with base data
    merged.addAll(conflict.baseData.cast<String, dynamic>());
    
    // Apply non-conflicting changes from both sides
    for (final field in conflict.conflictingFields) {
      // For conflicting fields, we need special handling
      // Try to merge intelligently based on field type
      final localValue = conflict.localData[field];
      final remoteValue = conflict.remoteData[field];
      final baseValue = conflict.baseData[field];
      
      merged[field] = _mergeFieldValues(localValue, remoteValue, baseValue, field);
    }
    
    // Add non-conflicting fields
    for (final entry in conflict.localData.entries) {
      if (!conflict.conflictingFields.contains(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }
    
    for (final entry in conflict.remoteData.entries) {
      if (!conflict.conflictingFields.contains(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }
    
    return merged;
  }

  /// Merge individual field values intelligently
  dynamic _mergeFieldValues(dynamic local, dynamic remote, dynamic base, String fieldName) {
    // Handle different field types
    if (local is List && remote is List) {
      // Merge lists
      return _mergeLists(local, remote, base as List?);
    } else if (local is Map && remote is Map) {
      // Recursively merge maps
      return _mergeMaps(local, remote, base as Map?);
    } else if (local is String && remote is String) {
      // Try to merge strings (concatenate if different)
      if (local != remote) {
        // For text fields, prefer the longer/most recent
        return local.length > remote.length ? local : remote;
      }
    } else if (local is num && remote is num) {
      // For numbers, use average or more recent
      return (local + remote) / 2;
    }
    
    // Default: prefer local
    return local;
  }

  /// Merge two lists
  List<dynamic> _mergeLists(List local, List remote, List? base) {
    final merged = <dynamic>[];
    final seen = <dynamic>{};
    
    // Add base items
    if (base != null) {
      for (final item in base) {
        if (!seen.contains(item)) {
          merged.add(item);
          seen.add(item);
        }
      }
    }
    
    // Add local items
    for (final item in local) {
      if (!seen.contains(item)) {
        merged.add(item);
        seen.add(item);
      }
    }
    
    // Add remote items
    for (final item in remote) {
      if (!seen.contains(item)) {
        merged.add(item);
        seen.add(item);
      }
    }
    
    return merged;
  }

  /// Merge two maps recursively
  Map<String, dynamic> _mergeMaps(Map local, Map remote, Map? base) {
    final merged = <String, dynamic>{};
    
    // Add all keys from base
    if (base != null) {
      merged.addAll(base.cast<String, dynamic>());
    }
    
    // Add/merge keys from local
    for (final entry in local.entries) {
      if (remote.containsKey(entry.key)) {
        // Both have this key - merge recursively
        merged[entry.key] = _mergeFieldValues(
          entry.value,
          remote[entry.key],
          base?[entry.key],
          entry.key,
        );
      } else {
        merged[entry.key] = entry.value;
      }
    }
    
    // Add keys only in remote
    for (final entry in remote.entries) {
      if (!local.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }
    
    return merged;
  }

  /// Get all unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    return await _databaseService.getUnresolvedConflicts();
  }

  /// Get conflicts for a specific table
  Future<List<SyncConflict>> getConflictsForTable(String tableName) async {
    return await _databaseService.getConflictsForTable(tableName);
  }

  /// Apply resolved data to the database
  Future<void> applyResolution(SyncConflict conflict) async {
    if (conflict.resolvedData == null || !conflict.isResolved) {
      throw StateError('Cannot apply unresolved conflict');
    }
    
    // Update the record with resolved data
    await _databaseService.updateRecord(
      conflict.tableName,
      conflict.recordId,
      conflict.resolvedData!,
    );
    
    // Mark conflict as applied
    await _databaseService.markConflictApplied(conflict.id);
  }

  /// Get conflict statistics
  Future<Map<String, dynamic>> getConflictStats() async {
    final conflicts = await getUnresolvedConflicts();
    
    final stats = <String, int>{};
    for (final conflict in conflicts) {
      final key = '${conflict.tableName}_${conflict.conflictingFields.length}';
      stats[key] = (stats[key] ?? 0) + 1;
    }
    
    return {
      'totalConflicts': conflicts.length,
      'conflictsByTableAndFieldCount': stats,
      'tablesAffected': conflicts.map((c) => c.tableName).toSet().length,
    };
  }
}
