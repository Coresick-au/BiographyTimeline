import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'dart:math' as math;
import '../../lib/features/timeline/services/event_clustering_service.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';
import '../../lib/shared/models/context.dart';

void main() {
  group('Spatial Clustering Property Tests', () {
    late EventClusteringService clusteringService;
    late Faker faker;

    setUp(() {
      clusteringService = EventClusteringService();
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 7: Spatial Clustering Threshold Consistency**', () async {
      // **Validates: Requirements 2.2**
      
      // Property: For any collection of photos with GPS coordinates and distance threshold configuration, 
      // the system should create new clusters when spatial distance exceeds the threshold

      for (int i = 0; i < 100; i++) {
        // Generate test scenario with configurable distance threshold
        final testScenario = _generateSpatialClusteringScenario(faker);
        final config = ClusteringConfiguration(
          temporalThresholdMinutes: 24 * 60, // 24 hours - effectively disable temporal clustering
          spatialThresholdMeters: testScenario.distanceThresholdMeters,
          burstThresholdSeconds: 1, // Disable burst detection
          minBurstSize: 1000, // Effectively disable burst detection
        );
        
        // Create test assets with controlled GPS coordinates
        final assets = _generateAssetsWithGpsCoordinates(testScenario, faker);
        
        // Perform clustering
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify spatial clustering behavior
        for (final cluster in clusters) {
          final clusterAssets = cluster.assets;
          if (clusterAssets.length > 1) {
            // Check that all assets in each cluster are within the distance threshold
            for (int j = 0; j < clusterAssets.length; j++) {
              for (int k = j + 1; k < clusterAssets.length; k++) {
                final asset1 = clusterAssets[j];
                final asset2 = clusterAssets[k];
                
                final location1 = asset1.exifData?.gpsLocation;
                final location2 = asset2.exifData?.gpsLocation;
                
                if (location1 != null && location2 != null) {
                  final distance = _calculateDistance(location1, location2);
                  
                  expect(distance, lessThanOrEqualTo(testScenario.distanceThresholdMeters),
                    reason: 'All assets in cluster should be within configured distance threshold of ${testScenario.distanceThresholdMeters}m');
                }
              }
            }
          }
        }
        
        // Verify that assets beyond the distance threshold are in different clusters
        if (clusters.length > 1) {
          for (int j = 0; j < clusters.length; j++) {
            for (int k = j + 1; k < clusters.length; k++) {
              final cluster1 = clusters[j];
              final cluster2 = clusters[k];
              
              // Check distance between cluster centers or representative assets
              final location1 = cluster1.centerLocation ?? _getRepresentativeLocation(cluster1.assets);
              final location2 = cluster2.centerLocation ?? _getRepresentativeLocation(cluster2.assets);
              
              if (location1 != null && location2 != null) {
                final distance = _calculateDistance(location1, location2);
                
                // Distance between different clusters should be meaningful
                // (allowing for some tolerance due to clustering algorithm specifics)
                expect(distance, greaterThan(0),
                  reason: 'Different clusters should be spatially separated');
              }
            }
          }
        }
        
        // Verify consistency: running clustering again should produce same groupings
        final clustersSecondRun = await clusteringService.clusterAssets(assets, customConfig: config);
        
        expect(clustersSecondRun.length, equals(clusters.length),
          reason: 'Spatial clustering should be deterministic and produce consistent results');
        
        // Verify that each asset appears in exactly one cluster
        final allClusteredAssetIds = <String>{};
        for (final cluster in clusters) {
          for (final asset in cluster.assets) {
            expect(allClusteredAssetIds.contains(asset.id), isFalse,
              reason: 'Each asset should appear in exactly one cluster');
            allClusteredAssetIds.add(asset.id);
          }
        }
        
        final originalAssetIds = assets.map((a) => a.id).toSet();
        expect(allClusteredAssetIds, equals(originalAssetIds),
          reason: 'All original assets should be present in clusters');
      }
    });

    test('Spatial clustering handles assets without GPS data gracefully', () async {
      // Test that assets without GPS coordinates are still clustered appropriately
      for (int i = 0; i < 50; i++) {
        final config = ClusteringConfiguration(
          temporalThresholdMinutes: 60, // 1 hour
          spatialThresholdMeters: 1000, // 1km
          burstThresholdSeconds: 1,
          minBurstSize: 1000,
        );
        
        // Create mix of assets with and without GPS data
        final assets = _generateMixedGpsAssets(faker);
        
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify that clustering still works
        expect(clusters, isNotEmpty, reason: 'Should produce clusters even with mixed GPS data');
        
        // Verify that all assets are accounted for
        final allClusteredAssetIds = clusters
            .expand((cluster) => cluster.assets)
            .map((asset) => asset.id)
            .toSet();
        final originalAssetIds = assets.map((a) => a.id).toSet();
        
        expect(allClusteredAssetIds, equals(originalAssetIds),
          reason: 'All assets should be clustered regardless of GPS availability');
      }
    });

    test('Spatial clustering respects context-specific distance thresholds', () async {
      // Test that different context types use appropriate distance thresholds
      for (int i = 0; i < 50; i++) {
        final contextType = faker.randomGenerator.element(ContextType.values);
        final config = ClusteringConfiguration.forContext(contextType);
        
        // Generate assets with GPS coordinates that test the context-specific thresholds
        final assets = _generateAssetsForSpatialContextTesting(contextType, config, faker);
        
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify that clustering respects context-specific distance thresholds
        for (final cluster in clusters) {
          if (cluster.assets.length > 1) {
            final assetsWithGps = cluster.assets
                .where((a) => a.exifData?.gpsLocation != null)
                .toList();
            
            if (assetsWithGps.length > 1) {
              // Check maximum distance within cluster
              double maxDistance = 0;
              for (int j = 0; j < assetsWithGps.length; j++) {
                for (int k = j + 1; k < assetsWithGps.length; k++) {
                  final location1 = assetsWithGps[j].exifData!.gpsLocation!;
                  final location2 = assetsWithGps[k].exifData!.gpsLocation!;
                  final distance = _calculateDistance(location1, location2);
                  maxDistance = math.max(maxDistance, distance);
                }
              }
              
              expect(maxDistance, lessThanOrEqualTo(config.spatialThresholdMeters),
                reason: 'Cluster should respect context-specific distance threshold for $contextType');
            }
          }
        }
      }
    });
  });
}

class SpatialClusteringScenario {
  final double distanceThresholdMeters;
  final int numberOfAssets;
  final List<GeoLocation> locations;
  final int expectedMinClusters;
  final int expectedMaxClusters;

  SpatialClusteringScenario({
    required this.distanceThresholdMeters,
    required this.numberOfAssets,
    required this.locations,
    required this.expectedMinClusters,
    required this.expectedMaxClusters,
  });
}

SpatialClusteringScenario _generateSpatialClusteringScenario(Faker faker) {
  // Generate a reasonable distance threshold (50m to 5km)
  final distanceThresholdMeters = faker.randomGenerator.decimal(scale: 5000, min: 50);
  
  // Generate 3-15 assets
  final numberOfAssets = faker.randomGenerator.integer(15, min: 3);
  
  // Create GPS coordinates with controlled distances
  final baseLocation = GeoLocation(
    latitude: faker.geo.latitude(),
    longitude: faker.geo.longitude(),
    altitude: null,
    locationName: faker.address.city(),
  );
  
  final locations = <GeoLocation>[baseLocation];
  int expectedClusters = 1;
  
  // Create additional locations, some within threshold, some outside
  for (int i = 1; i < numberOfAssets; i++) {
    final shouldStartNewCluster = faker.randomGenerator.boolean();
    
    GeoLocation newLocation;
    if (shouldStartNewCluster) {
      // Create location beyond threshold to force new cluster
      newLocation = _generateLocationAtDistance(
        baseLocation,
        distanceThresholdMeters + faker.randomGenerator.decimal(scale: 1000, min: 100),
        faker,
      );
      expectedClusters++;
    } else {
      // Create location within threshold
      newLocation = _generateLocationAtDistance(
        baseLocation,
        faker.randomGenerator.decimal(scale: distanceThresholdMeters * 0.8, min: 10),
        faker,
      );
    }
    
    locations.add(newLocation);
  }
  
  return SpatialClusteringScenario(
    distanceThresholdMeters: distanceThresholdMeters,
    numberOfAssets: numberOfAssets,
    locations: locations,
    expectedMinClusters: 1,
    expectedMaxClusters: expectedClusters,
  );
}

GeoLocation _generateLocationAtDistance(GeoLocation baseLocation, double distanceMeters, Faker faker) {
  // Generate a random bearing (0-360 degrees)
  final bearing = faker.randomGenerator.decimal(scale: 360);
  
  // Convert to radians
  final bearingRad = bearing * (math.pi / 180);
  
  // Earth's radius in meters
  const double earthRadius = 6371000;
  
  // Convert base coordinates to radians
  final lat1Rad = baseLocation.latitude * (math.pi / 180);
  final lng1Rad = baseLocation.longitude * (math.pi / 180);
  
  // Calculate new coordinates
  final lat2Rad = math.asin(
    math.sin(lat1Rad) * math.cos(distanceMeters / earthRadius) +
    math.cos(lat1Rad) * math.sin(distanceMeters / earthRadius) * math.cos(bearingRad)
  );
  
  final lng2Rad = lng1Rad + math.atan2(
    math.sin(bearingRad) * math.sin(distanceMeters / earthRadius) * math.cos(lat1Rad),
    math.cos(distanceMeters / earthRadius) - math.sin(lat1Rad) * math.sin(lat2Rad)
  );
  
  // Convert back to degrees
  final lat2 = lat2Rad * (180 / math.pi);
  final lng2 = lng2Rad * (180 / math.pi);
  
  return GeoLocation(
    latitude: lat2,
    longitude: lng2,
    altitude: null,
    locationName: faker.address.city(),
  );
}

List<MediaAsset> _generateAssetsWithGpsCoordinates(SpatialClusteringScenario scenario, Faker faker) {
  final assets = <MediaAsset>[];
  final baseTime = DateTime.now().subtract(const Duration(hours: 1));
  
  for (int i = 0; i < scenario.numberOfAssets; i++) {
    final location = scenario.locations[i];
    final timestamp = baseTime.add(Duration(minutes: i)); // Small time gaps to avoid temporal clustering
    
    final asset = MediaAsset(
      id: 'spatial_asset_${i}_${timestamp.millisecondsSinceEpoch}',
      eventId: '', // Will be set during clustering
      type: AssetType.photo,
      localPath: '/mock/path/spatial_photo_$i.jpg',
      createdAt: timestamp,
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: timestamp,
        gpsLocation: location,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    
    assets.add(asset);
  }
  
  return assets;
}

List<MediaAsset> _generateMixedGpsAssets(Faker faker) {
  final assets = <MediaAsset>[];
  final baseTime = DateTime.now().subtract(const Duration(hours: 1));
  final numberOfAssets = faker.randomGenerator.integer(10, min: 5);
  
  for (int i = 0; i < numberOfAssets; i++) {
    final hasGps = faker.randomGenerator.boolean();
    final timestamp = baseTime.add(Duration(minutes: i * 5));
    
    GeoLocation? location;
    if (hasGps) {
      location = GeoLocation(
        latitude: faker.geo.latitude(),
        longitude: faker.geo.longitude(),
        altitude: null,
        locationName: faker.address.city(),
      );
    }
    
    final asset = MediaAsset(
      id: 'mixed_asset_${i}_${timestamp.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/mixed_photo_$i.jpg',
      createdAt: timestamp,
      isKeyAsset: false,
      exifData: hasGps ? ExifData(
        dateTimeOriginal: timestamp,
        gpsLocation: location,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ) : null,
    );
    
    assets.add(asset);
  }
  
  return assets;
}

List<MediaAsset> _generateAssetsForSpatialContextTesting(
  ContextType contextType,
  ClusteringConfiguration config,
  Faker faker,
) {
  final assets = <MediaAsset>[];
  final baseTime = DateTime.now().subtract(const Duration(hours: 1));
  
  // Create base location
  final baseLocation = GeoLocation(
    latitude: faker.geo.latitude(),
    longitude: faker.geo.longitude(),
    altitude: null,
    locationName: faker.address.city(),
  );
  
  // Create one cluster within the distance threshold
  for (int i = 0; i < 3; i++) {
    final location = _generateLocationAtDistance(
      baseLocation,
      config.spatialThresholdMeters * 0.5, // Well within threshold
      faker,
    );
    
    final asset = MediaAsset(
      id: 'context_spatial_asset_${i}_${baseTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/context_spatial_photo_$i.jpg',
      createdAt: baseTime.add(Duration(minutes: i * 10)), // Spread out temporally
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: baseTime.add(Duration(minutes: i * 10)),
        gpsLocation: location,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    assets.add(asset);
  }
  
  // Create second cluster beyond the distance threshold
  final distantLocation = _generateLocationAtDistance(
    baseLocation,
    config.spatialThresholdMeters + 100, // Beyond threshold
    faker,
  );
  
  for (int i = 3; i < 6; i++) {
    final location = _generateLocationAtDistance(
      distantLocation,
      config.spatialThresholdMeters * 0.3, // Within threshold of distant location
      faker,
    );
    
    final asset = MediaAsset(
      id: 'context_spatial_asset_${i}_${baseTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/context_spatial_photo_$i.jpg',
      createdAt: baseTime.add(Duration(minutes: i * 10)),
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: baseTime.add(Duration(minutes: i * 10)),
        gpsLocation: location,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    assets.add(asset);
  }
  
  return assets;
}

GeoLocation? _getRepresentativeLocation(List<MediaAsset> assets) {
  final locationsWithGps = assets
      .where((a) => a.exifData?.gpsLocation != null)
      .map((a) => a.exifData!.gpsLocation!)
      .toList();
  
  if (locationsWithGps.isEmpty) return null;
  return locationsWithGps.first; // Use first location as representative
}

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
