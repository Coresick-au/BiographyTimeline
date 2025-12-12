import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';

/// Result of a manual clustering operation
class ClusteringOperationResult {
  final bool success;
  final String? errorMessage;
  final List<TimelineEvent>? updatedEvents;

  ClusteringOperationResult({
    required this.success,
    this.errorMessage,
    this.updatedEvents,
  });

  factory ClusteringOperationResult.success(List<TimelineEvent> events) {
    return ClusteringOperationResult(
      success: true,
      updatedEvents: events,
    );
  }

  factory ClusteringOperationResult.failure(String message) {
    return ClusteringOperationResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service responsible for manual event clustering operations
class EventManagementService {
  
  /// Splits a timeline event into multiple events
  /// Each asset becomes its own event, preserving all custom attributes
  Future<ClusteringOperationResult> splitEvent(
    TimelineEvent event,
    List<List<MediaAsset>> assetGroups,
  ) async {
    try {
      // Validation
      final validationResult = _validateSplitOperation(event, assetGroups);
      if (!validationResult.success) {
        return validationResult;
      }

      final List<TimelineEvent> newEvents = [];
      
      for (int i = 0; i < assetGroups.length; i++) {
        final assetGroup = assetGroups[i];
        if (assetGroup.isEmpty) continue;
        
        // Generate new event ID for each split
        final newEventId = _generateEventId();
        
        // Update assets with new event ID and determine key asset
        final updatedAssets = assetGroup.map((asset) {
          return asset.copyWith(
            eventId: newEventId,
            isKeyAsset: asset.id == _selectKeyAsset(assetGroup).id,
          );
        }).toList();
        
        // Create new event with preserved attributes
        final newEvent = event.copyWith(
          id: newEventId,
          timestamp: assetGroup.first.createdAt,
          assets: updatedAssets,
          title: i == 0 ? event.title : null, // Keep original title for first split
          description: i == 0 ? event.description : null,
          updatedAt: DateTime.now(),
        );
        
        newEvents.add(newEvent);
      }
      
      return ClusteringOperationResult.success(newEvents);
    } catch (e) {
      return ClusteringOperationResult.failure('Failed to split event: $e');
    }
  }

  /// Merges multiple timeline events into a single event
  /// Combines all assets and preserves custom attributes from the primary event
  Future<ClusteringOperationResult> mergeEvents(
    List<TimelineEvent> events, {
    TimelineEvent? primaryEvent,
  }) async {
    try {
      // Validation
      final validationResult = _validateMergeOperation(events);
      if (!validationResult.success) {
        return validationResult;
      }

      // Determine primary event (earliest by default, or specified)
      final primary = primaryEvent ?? events.reduce((a, b) => 
        a.timestamp.isBefore(b.timestamp) ? a : b
      );
      
      // Collect all assets from all events
      final List<MediaAsset> allAssets = [];
      for (final event in events) {
        allAssets.addAll(event.assets);
      }
      
      // Generate new event ID
      final mergedEventId = _generateEventId();
      
      // Update all assets with the new event ID and determine key asset
      final keyAsset = _selectKeyAsset(allAssets);
      final updatedAssets = allAssets.map((asset) {
        return asset.copyWith(
          eventId: mergedEventId,
          isKeyAsset: asset.id == keyAsset.id,
        );
      }).toList();
      
      // Sort assets by timestamp
      updatedAssets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Create merged event
      final mergedEvent = primary.copyWith(
        id: mergedEventId,
        timestamp: updatedAssets.first.createdAt,
        assets: updatedAssets,
        title: _generateMergedTitle(events),
        description: _generateMergedDescription(events),
        participantIds: _mergeParticipantIds(events),
        updatedAt: DateTime.now(),
      );
      
      return ClusteringOperationResult.success([mergedEvent]);
    } catch (e) {
      return ClusteringOperationResult.failure('Failed to merge events: $e');
    }
  }

  /// Moves assets from one event to another
  Future<ClusteringOperationResult> moveAssets(
    List<MediaAsset> assetsToMove,
    TimelineEvent sourceEvent,
    TimelineEvent targetEvent,
  ) async {
    try {
      // Validation
      final validationResult = _validateMoveOperation(assetsToMove, sourceEvent, targetEvent);
      if (!validationResult.success) {
        return validationResult;
      }

      final assetIdsToMove = assetsToMove.map((a) => a.id).toSet();
      
      // Update source event (remove assets)
      final remainingSourceAssets = sourceEvent.assets
          .where((asset) => !assetIdsToMove.contains(asset.id))
          .toList();
      
      // Update target event (add assets)
      final updatedAssetsToMove = assetsToMove.map((asset) {
        return asset.copyWith(
          eventId: targetEvent.id,
          isKeyAsset: false, // Will be recalculated
        );
      }).toList();
      
      final allTargetAssets = [...targetEvent.assets, ...updatedAssetsToMove];
      allTargetAssets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Recalculate key assets for both events
      final List<TimelineEvent> updatedEvents = [];
      
      // Update source event if it still has assets
      if (remainingSourceAssets.isNotEmpty) {
        final sourceKeyAsset = _selectKeyAsset(remainingSourceAssets);
        final updatedSourceAssets = remainingSourceAssets.map((asset) {
          return asset.copyWith(isKeyAsset: asset.id == sourceKeyAsset.id);
        }).toList();
        
        final updatedSourceEvent = sourceEvent.copyWith(
          assets: updatedSourceAssets,
          timestamp: updatedSourceAssets.first.createdAt,
          updatedAt: DateTime.now(),
        );
        updatedEvents.add(updatedSourceEvent);
      }
      
      // Update target event
      final targetKeyAsset = _selectKeyAsset(allTargetAssets);
      final finalTargetAssets = allTargetAssets.map((asset) {
        return asset.copyWith(isKeyAsset: asset.id == targetKeyAsset.id);
      }).toList();
      
      final updatedTargetEvent = targetEvent.copyWith(
        assets: finalTargetAssets,
        timestamp: finalTargetAssets.first.createdAt,
        updatedAt: DateTime.now(),
      );
      updatedEvents.add(updatedTargetEvent);
      
      return ClusteringOperationResult.success(updatedEvents);
    } catch (e) {
      return ClusteringOperationResult.failure('Failed to move assets: $e');
    }
  }

  /// Updates the key asset for an event
  Future<ClusteringOperationResult> updateKeyAsset(
    TimelineEvent event,
    MediaAsset newKeyAsset,
  ) async {
    try {
      // Validation
      if (!event.assets.any((asset) => asset.id == newKeyAsset.id)) {
        return ClusteringOperationResult.failure('Asset is not part of this event');
      }

      // Update all assets to reflect new key asset
      final updatedAssets = event.assets.map((asset) {
        return asset.copyWith(isKeyAsset: asset.id == newKeyAsset.id);
      }).toList();
      
      final updatedEvent = event.copyWith(
        assets: updatedAssets,
        updatedAt: DateTime.now(),
      );
      
      return ClusteringOperationResult.success([updatedEvent]);
    } catch (e) {
      return ClusteringOperationResult.failure('Failed to update key asset: $e');
    }
  }

  /// Validates a split operation
  ClusteringOperationResult _validateSplitOperation(
    TimelineEvent event,
    List<List<MediaAsset>> assetGroups,
  ) {
    // Check if event has enough assets to split
    if (event.assets.length < 2) {
      return ClusteringOperationResult.failure('Cannot split event with less than 2 assets');
    }
    
    // Check if asset groups are valid
    if (assetGroups.isEmpty || assetGroups.length < 2) {
      return ClusteringOperationResult.failure('Must specify at least 2 asset groups for splitting');
    }
    
    // Check if all assets are accounted for
    final allGroupAssets = assetGroups.expand((group) => group).toList();
    final originalAssetIds = event.assets.map((a) => a.id).toSet();
    final groupAssetIds = allGroupAssets.map((a) => a.id).toSet();
    
    if (!originalAssetIds.containsAll(groupAssetIds) || 
        !groupAssetIds.containsAll(originalAssetIds)) {
      return ClusteringOperationResult.failure('Asset groups must contain all original assets exactly once');
    }
    
    // Check for empty groups
    if (assetGroups.any((group) => group.isEmpty)) {
      return ClusteringOperationResult.failure('Asset groups cannot be empty');
    }
    
    return ClusteringOperationResult.success([]);
  }

  /// Validates a merge operation
  ClusteringOperationResult _validateMergeOperation(List<TimelineEvent> events) {
    if (events.length < 2) {
      return ClusteringOperationResult.failure('Must specify at least 2 events to merge');
    }
    
    // Check if all events belong to the same context
    final contextId = events.first.contextId;
    if (!events.every((event) => event.contextId == contextId)) {
      return ClusteringOperationResult.failure('Cannot merge events from different contexts');
    }
    
    // Check if all events belong to the same owner
    final ownerId = events.first.ownerId;
    if (!events.every((event) => event.ownerId == ownerId)) {
      return ClusteringOperationResult.failure('Cannot merge events from different owners');
    }
    
    return ClusteringOperationResult.success([]);
  }

  /// Validates a move operation
  ClusteringOperationResult _validateMoveOperation(
    List<MediaAsset> assetsToMove,
    TimelineEvent sourceEvent,
    TimelineEvent targetEvent,
  ) {
    if (assetsToMove.isEmpty) {
      return ClusteringOperationResult.failure('Must specify assets to move');
    }
    
    // Check if source and target are different events
    if (sourceEvent.id == targetEvent.id) {
      return ClusteringOperationResult.failure('Source and target events must be different');
    }
    
    // Check if all assets belong to source event
    final sourceAssetIds = sourceEvent.assets.map((a) => a.id).toSet();
    final moveAssetIds = assetsToMove.map((a) => a.id).toSet();
    
    if (!sourceAssetIds.containsAll(moveAssetIds)) {
      return ClusteringOperationResult.failure('All assets to move must belong to source event');
    }
    
    // Check if source event would be left empty
    if (sourceEvent.assets.length == assetsToMove.length) {
      return ClusteringOperationResult.failure('Cannot move all assets from source event (would leave it empty)');
    }
    
    // Check if events belong to same context
    if (sourceEvent.contextId != targetEvent.contextId) {
      return ClusteringOperationResult.failure('Cannot move assets between different contexts');
    }
    
    return ClusteringOperationResult.success([]);
  }

  /// Selects the best key asset from a list of assets
  MediaAsset _selectKeyAsset(List<MediaAsset> assets) {
    if (assets.isEmpty) throw ArgumentError('Cannot select key asset from empty list');
    if (assets.length == 1) return assets.first;
    
    // Prioritize assets with complete EXIF data
    final assetsWithExif = assets.where((a) => a.exifData?.isComplete == true).toList();
    if (assetsWithExif.isNotEmpty) {
      // From assets with EXIF, prefer those with GPS data
      final assetsWithGps = assetsWithExif.where((a) => a.exifData?.gpsLocation != null).toList();
      if (assetsWithGps.isNotEmpty) {
        return _selectTemporalCenter(assetsWithGps);
      }
      return _selectTemporalCenter(assetsWithExif);
    }
    
    // Fallback to temporal center selection
    return _selectTemporalCenter(assets);
  }

  /// Selects the asset closest to the temporal center
  MediaAsset _selectTemporalCenter(List<MediaAsset> assets) {
    if (assets.isEmpty) throw ArgumentError('Cannot select from empty list');
    if (assets.length == 1) return assets.first;
    
    final sortedAssets = List<MediaAsset>.from(assets)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    final startTime = sortedAssets.first.createdAt;
    final endTime = sortedAssets.last.createdAt;
    final centerTime = DateTime.fromMillisecondsSinceEpoch(
      (startTime.millisecondsSinceEpoch + endTime.millisecondsSinceEpoch) ~/ 2
    );
    
    MediaAsset closest = sortedAssets.first;
    int minDifference = (sortedAssets.first.createdAt.difference(centerTime)).abs().inMilliseconds;
    
    for (final asset in sortedAssets) {
      final difference = (asset.createdAt.difference(centerTime)).abs().inMilliseconds;
      if (difference < minDifference) {
        minDifference = difference;
        closest = asset;
      }
    }
    
    return closest;
  }

  /// Generates a unique event ID
  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Generates a title for merged events
  String? _generateMergedTitle(List<TimelineEvent> events) {
    final titlesWithContent = events
        .where((e) => e.title != null && e.title!.isNotEmpty)
        .map((e) => e.title!)
        .toList();
    
    if (titlesWithContent.isEmpty) {
      final totalAssets = events.fold<int>(0, (sum, event) => sum + event.assets.length);
      return 'Merged Event ($totalAssets photos)';
    }
    
    if (titlesWithContent.length == 1) {
      return titlesWithContent.first;
    }
    
    // Combine unique titles
    final uniqueTitles = titlesWithContent.toSet().toList();
    if (uniqueTitles.length <= 2) {
      return uniqueTitles.join(' & ');
    }
    
    return 'Merged Event (${events.length} events)';
  }

  /// Generates a description for merged events
  String? _generateMergedDescription(List<TimelineEvent> events) {
    final descriptions = events
        .where((e) => e.description != null && e.description!.isNotEmpty)
        .map((e) => e.description!)
        .toList();
    
    if (descriptions.isEmpty) return null;
    if (descriptions.length == 1) return descriptions.first;
    
    // Combine descriptions with separator
    return descriptions.join(' • ');
  }

  /// Merges participant IDs from multiple events
  List<String> _mergeParticipantIds(List<TimelineEvent> events) {
    final allParticipants = <String>{};
    for (final event in events) {
      allParticipants.addAll(event.participantIds);
    }
    return allParticipants.toList();
  }
}