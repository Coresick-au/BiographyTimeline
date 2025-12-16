import 'dart:math' as math;
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/context.dart';

/// Configuration for event clustering algorithms
class ClusteringConfiguration {
  /// Maximum time difference between photos to be in the same cluster (in minutes)
  final int temporalThresholdMinutes;
  
  /// Maximum distance between photos to be in the same cluster (in meters)
  final double spatialThresholdMeters;
  
  /// Minimum time between photos to be considered a burst (in seconds)
  final int burstThresholdSeconds;
  
  /// Minimum number of photos to be considered a burst
  final int minBurstSize;
  
  /// Maximum number of photos in a burst before splitting
  final int maxBurstSize;

  const ClusteringConfiguration({
    this.temporalThresholdMinutes = 60, // 1 hour default
    this.spatialThresholdMeters = 1000, // 1km default
    this.burstThresholdSeconds = 30, // 30 seconds default
    this.minBurstSize = 3,
    this.maxBurstSize = 50,
  });

  /// Creates context-specific clustering configuration
  factory ClusteringConfiguration.forContext(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return const ClusteringConfiguration(
          temporalThresholdMinutes: 120, // 2 hours for personal events
          spatialThresholdMeters: 500, // 500m for personal activities
          burstThresholdSeconds: 60, // 1 minute for personal photos
        );
      case ContextType.pet:
        return const ClusteringConfiguration(
          temporalThresholdMinutes: 30, // 30 minutes for pet activities
          spatialThresholdMeters: 100, // 100m for pet activities (home/yard)
          burstThresholdSeconds: 15, // 15 seconds for pet bursts
        );
      case ContextType.project:
        return const ClusteringConfiguration(
          temporalThresholdMinutes: 240, // 4 hours for project work
          spatialThresholdMeters: 50, // 50m for project site
          burstThresholdSeconds: 30, // 30 seconds for progress photos
        );
      case ContextType.business:
        return const ClusteringConfiguration(
          temporalThresholdMinutes: 480, // 8 hours for business events
          spatialThresholdMeters: 1000, // 1km for business activities
          burstThresholdSeconds: 120, // 2 minutes for business photos
        );
    }
  }
}

/// Represents a cluster of media assets that will become a timeline event
class MediaCluster {
  final List<MediaAsset> assets;
  final DateTime startTime;
  final DateTime endTime;
  final GeoLocation? centerLocation;
  final MediaAsset keyAsset;
  final bool isBurst;

  MediaCluster({
    required this.assets,
    required this.startTime,
    required this.endTime,
    this.centerLocation,
    required this.keyAsset,
    this.isBurst = false,
  });

  /// Gets the duration of this cluster in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Gets the number of assets in this cluster
  int get assetCount => assets.length;
}

/// Service responsible for clustering media assets into timeline events
class EventClusteringService {
  final ClusteringConfiguration _config;

  EventClusteringService({ClusteringConfiguration? config})
      : _config = config ?? const ClusteringConfiguration();

  /// Clusters a list of media assets into timeline events
  Future<List<MediaCluster>> clusterAssets(
    List<MediaAsset> assets, {
    ClusteringConfiguration? customConfig,
  }) async {
    final config = customConfig ?? _config;
    
    if (assets.isEmpty) return [];

    // Sort assets by timestamp
    final sortedAssets = List<MediaAsset>.from(assets)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // First pass: detect bursts
    final List<MediaCluster> burstClusters = _detectBursts(sortedAssets, config);
    
    // Second pass: cluster remaining assets by temporal and spatial proximity
    final List<MediaAsset> nonBurstAssets = _getRemainingAssets(sortedAssets, burstClusters);
    final List<MediaCluster> proximityClusters = _clusterByProximity(nonBurstAssets, config);

    // Combine and sort all clusters
    final allClusters = [...burstClusters, ...proximityClusters]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return allClusters;
  }

  /// Detects rapid photo bursts in the asset list
  List<MediaCluster> _detectBursts(List<MediaAsset> assets, ClusteringConfiguration config) {
    final List<MediaCluster> bursts = [];
    final List<MediaAsset> currentBurst = [];
    
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      
      if (currentBurst.isEmpty) {
        currentBurst.add(asset);
        continue;
      }
      
      final lastAsset = currentBurst.last;
      final timeDifference = asset.createdAt.difference(lastAsset.createdAt).inSeconds;
      
      if (timeDifference <= config.burstThresholdSeconds) {
        // Continue the burst
        currentBurst.add(asset);
        
        // Check if burst is getting too large
        if (currentBurst.length >= config.maxBurstSize) {
          bursts.add(_createBurstCluster(List.from(currentBurst), config));
          currentBurst.clear();
        }
      } else {
        // End current burst if it meets minimum size
        if (currentBurst.length >= config.minBurstSize) {
          bursts.add(_createBurstCluster(List.from(currentBurst), config));
        }
        currentBurst.clear();
        currentBurst.add(asset);
      }
    }
    
    // Handle final burst
    if (currentBurst.length >= config.minBurstSize) {
      bursts.add(_createBurstCluster(currentBurst, config));
    }
    
    return bursts;
  }

  /// Creates a burst cluster from a list of assets
  MediaCluster _createBurstCluster(List<MediaAsset> assets, ClusteringConfiguration config) {
    final keyAsset = _selectKeyAsset(assets);
    final centerLocation = _calculateCenterLocation(assets);
    
    // Update assets to mark the key asset
    final updatedAssets = assets.map((asset) {
      return asset.copyWith(isKeyAsset: asset.id == keyAsset.id);
    }).toList();
    
    // Find the updated key asset
    final updatedKeyAsset = updatedAssets.firstWhere((asset) => asset.isKeyAsset);
    
    return MediaCluster(
      assets: updatedAssets,
      startTime: assets.first.createdAt,
      endTime: assets.last.createdAt,
      centerLocation: centerLocation,
      keyAsset: updatedKeyAsset,
      isBurst: true,
    );
  }

  /// Gets assets that are not part of any burst cluster
  List<MediaAsset> _getRemainingAssets(List<MediaAsset> allAssets, List<MediaCluster> burstClusters) {
    final Set<String> burstAssetIds = {};
    for (final cluster in burstClusters) {
      burstAssetIds.addAll(cluster.assets.map((a) => a.id));
    }
    
    return allAssets.where((asset) => !burstAssetIds.contains(asset.id)).toList();
  }

  /// Clusters assets by temporal and spatial proximity
  List<MediaCluster> _clusterByProximity(List<MediaAsset> assets, ClusteringConfiguration config) {
    if (assets.isEmpty) return [];
    
    final List<MediaCluster> clusters = [];
    final List<MediaAsset> currentCluster = [];
    
    for (final asset in assets) {
      if (currentCluster.isEmpty) {
        currentCluster.add(asset);
        continue;
      }
      
      final shouldAddToCluster = _shouldAddToCluster(currentCluster, asset, config);
      
      if (shouldAddToCluster) {
        currentCluster.add(asset);
      } else {
        // Finalize current cluster
        clusters.add(_createProximityCluster(List.from(currentCluster)));
        currentCluster.clear();
        currentCluster.add(asset);
      }
    }
    
    // Handle final cluster
    if (currentCluster.isNotEmpty) {
      clusters.add(_createProximityCluster(currentCluster));
    }
    
    return clusters;
  }

  /// Determines if an asset should be added to the current cluster
  bool _shouldAddToCluster(List<MediaAsset> currentCluster, MediaAsset newAsset, ClusteringConfiguration config) {
    if (currentCluster.isEmpty) return true;
    
    // Check temporal proximity with the last asset
    final lastAsset = currentCluster.last;
    final timeDifference = newAsset.createdAt.difference(lastAsset.createdAt).inMinutes;
    if (timeDifference > config.temporalThresholdMinutes) {
      return false;
    }
    
    // Check that adding this asset won't exceed the total time window
    final firstAsset = currentCluster.first;
    final totalDuration = newAsset.createdAt.difference(firstAsset.createdAt).inMinutes;
    if (totalDuration > config.temporalThresholdMinutes) {
      return false;
    }
    
    // Check spatial proximity if both have location data
    final newAssetLocation = newAsset.exifData?.gpsLocation;
    
    if (newAssetLocation != null) {
      // Check distance to the last asset
      final lastAssetLocation = lastAsset.exifData?.gpsLocation;
      if (lastAssetLocation != null) {
        final distanceToLast = _calculateDistance(lastAssetLocation, newAssetLocation);
        if (distanceToLast > config.spatialThresholdMeters) {
          return false;
        }
      }
      
      // Check that adding this asset won't violate the spatial constraint for the entire cluster
      for (final clusterAsset in currentCluster) {
        final clusterAssetLocation = clusterAsset.exifData?.gpsLocation;
        if (clusterAssetLocation != null) {
          final distance = _calculateDistance(clusterAssetLocation, newAssetLocation);
          if (distance > config.spatialThresholdMeters) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  /// Creates a proximity-based cluster from a list of assets
  MediaCluster _createProximityCluster(List<MediaAsset> assets) {
    final keyAsset = _selectKeyAsset(assets);
    final centerLocation = _calculateCenterLocation(assets);
    
    // Update assets to mark the key asset
    final updatedAssets = assets.map((asset) {
      return asset.copyWith(isKeyAsset: asset.id == keyAsset.id);
    }).toList();
    
    // Find the updated key asset
    final updatedKeyAsset = updatedAssets.firstWhere((asset) => asset.isKeyAsset);
    
    return MediaCluster(
      assets: updatedAssets,
      startTime: assets.first.createdAt,
      endTime: assets.last.createdAt,
      centerLocation: centerLocation,
      keyAsset: updatedKeyAsset,
      isBurst: false,
    );
  }

  /// Selects the key asset from a cluster based on various criteria
  MediaAsset _selectKeyAsset(List<MediaAsset> assets) {
    if (assets.isEmpty) throw ArgumentError('Cannot select key asset from empty list');
    if (assets.length == 1) return assets.first;
    
    // Prioritize assets with complete EXIF data
    final assetsWithExif = assets.where((a) => a.exifData?.isComplete == true).toList();
    if (assetsWithExif.isNotEmpty) {
      // From assets with EXIF, prefer those with GPS data
      final assetsWithGps = assetsWithExif.where((a) => a.exifData?.gpsLocation != null).toList();
      if (assetsWithGps.isNotEmpty) {
        // Select the one closest to the temporal center
        return _selectTemporalCenter(assetsWithGps);
      }
      return _selectTemporalCenter(assetsWithExif);
    }
    
    // Fallback to temporal center selection
    return _selectTemporalCenter(assets);
  }

  /// Selects the asset closest to the temporal center of the cluster
  MediaAsset _selectTemporalCenter(List<MediaAsset> assets) {
    if (assets.isEmpty) throw ArgumentError('Cannot select from empty list');
    if (assets.length == 1) return assets.first;
    
    final startTime = assets.first.createdAt;
    final endTime = assets.last.createdAt;
    final centerTime = DateTime.fromMillisecondsSinceEpoch(
      (startTime.millisecondsSinceEpoch + endTime.millisecondsSinceEpoch) ~/ 2
    );
    
    MediaAsset closest = assets.first;
    int minDifference = (assets.first.createdAt.difference(centerTime)).abs().inMilliseconds;
    
    for (final asset in assets) {
      final difference = (asset.createdAt.difference(centerTime)).abs().inMilliseconds;
      if (difference < minDifference) {
        minDifference = difference;
        closest = asset;
      }
    }
    
    return closest;
  }

  /// Calculates the center location of a cluster of assets
  GeoLocation? _calculateCenterLocation(List<MediaAsset> assets) {
    final locationsWithGps = assets
        .where((a) => a.exifData?.gpsLocation != null)
        .map((a) => a.exifData!.gpsLocation!)
        .toList();
    
    if (locationsWithGps.isEmpty) return null;
    if (locationsWithGps.length == 1) return locationsWithGps.first;
    
    // Calculate centroid
    double totalLat = 0;
    double totalLng = 0;
    
    for (final location in locationsWithGps) {
      totalLat += location.latitude;
      totalLng += location.longitude;
    }
    
    final centerLat = totalLat / locationsWithGps.length;
    final centerLng = totalLng / locationsWithGps.length;
    
    return GeoLocation(
      latitude: centerLat,
      longitude: centerLng,
      altitude: null, // Don't calculate average altitude
      locationName: null, // Will be geocoded separately if needed
    );
  }

  /// Calculates the distance between two geographic locations in meters
  double _calculateDistance(GeoLocation location1, GeoLocation location2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = location1.latitude * (math.pi / 180);
    final double lat2Rad = location2.latitude * (math.pi / 180);
    final double deltaLatRad = (location2.latitude - location1.latitude) * (math.pi / 180);
    final double deltaLngRad = (location2.longitude - location1.longitude) * (math.pi / 180);
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Converts media clusters to timeline events
  Future<List<TimelineEvent>> createTimelineEvents(
    List<MediaCluster> clusters, {
    required String contextId,
    required String ownerId,
  }) async {
    final List<TimelineEvent> events = [];
    
    for (final cluster in clusters) {
      // Determine event type based on cluster characteristics
      String eventType = 'photo';
      if (cluster.isBurst) {
        eventType = 'photo_burst';
      } else if (cluster.assetCount > 10) {
        eventType = 'photo_collection';
      }
      
      // Update assets with event ID and key asset flag
      final String eventId = _generateEventId();
      final updatedAssets = cluster.assets.map((asset) {
        return asset.copyWith(
          eventId: eventId,
          isKeyAsset: asset.id == cluster.keyAsset.id,
        );
      }).toList();
      
      // Create timeline event
      final event = TimelineEvent.create(
        id: eventId,
        ownerId: ownerId,
        timestamp: cluster.startTime,
        location: cluster.centerLocation,
        eventType: eventType,
        assets: updatedAssets,
        title: _generateEventTitle(cluster),
        description: _generateEventDescription(cluster),
      );
      
      events.add(event);
    }
    
    return events;
  }

  /// Generates a unique event ID
  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  /// Generates a title for an event based on its cluster
  String? _generateEventTitle(MediaCluster cluster) {
    if (cluster.isBurst) {
      return 'Photo Burst (${cluster.assetCount} photos)';
    } else if (cluster.assetCount > 1) {
      return '${cluster.assetCount} Photos';
    }
    return null; // Single photo events don't need auto-generated titles
  }

  /// Generates a description for an event based on its cluster
  String? _generateEventDescription(MediaCluster cluster) {
    final buffer = StringBuffer();
    
    if (cluster.durationMinutes > 0) {
      buffer.write('Duration: ${cluster.durationMinutes} minutes');
    }
    
    if (cluster.centerLocation?.locationName != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('Location: ${cluster.centerLocation!.locationName}');
    }
    
    return buffer.isEmpty ? null : buffer.toString();
  }
}
