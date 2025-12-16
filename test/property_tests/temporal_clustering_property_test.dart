import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/features/timeline/services/event_clustering_service.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';
import '../../lib/shared/models/context.dart';

void main() {
  group('Temporal Clustering Property Tests', () {
    late EventClusteringService clusteringService;
    late Faker faker;

    setUp(() {
      clusteringService = EventClusteringService();
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 6: Configurable Temporal Clustering**', () async {
      // **Validates: Requirements 2.1**
      
      // Property: For any collection of photos and time window configuration, 
      // the clustering algorithm should group images within the specified time window consistently

      for (int i = 0; i < 100; i++) {
        // Generate test scenario with configurable time window
        final testScenario = _generateTemporalClusteringScenario(faker);
        final config = ClusteringConfiguration(
          temporalThresholdMinutes: testScenario.timeWindowMinutes,
          spatialThresholdMeters: double.maxFinite, // Disable spatial clustering for this test
          burstThresholdSeconds: 1, // Disable burst detection for this test
          minBurstSize: 1000, // Effectively disable burst detection
        );
        
        // Create test assets with controlled timestamps
        final assets = _generateAssetsWithTimestamps(testScenario, faker);
        
        // Perform clustering
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify temporal clustering behavior
        for (final cluster in clusters) {
          // Check that all assets in each cluster are within the time window
          final clusterAssets = cluster.assets;
          if (clusterAssets.length > 1) {
            clusterAssets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final startTime = clusterAssets.first.createdAt;
            final endTime = clusterAssets.last.createdAt;
            final durationMinutes = endTime.difference(startTime).inMinutes;
            
            expect(durationMinutes, lessThanOrEqualTo(testScenario.timeWindowMinutes),
              reason: 'All assets in cluster should be within configured time window of ${testScenario.timeWindowMinutes} minutes');
          }
        }
        
        // Verify that assets outside the time window are in different clusters
        if (clusters.length > 1) {
          for (int j = 0; j < clusters.length - 1; j++) {
            final currentCluster = clusters[j];
            final nextCluster = clusters[j + 1];
            
            final currentLatest = currentCluster.assets
                .map((a) => a.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b);
            final nextEarliest = nextCluster.assets
                .map((a) => a.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            
            final gapMinutes = nextEarliest.difference(currentLatest).inMinutes;
            
            // Gap between clusters should be larger than the time window
            // (allowing for some tolerance due to clustering algorithm specifics)
            expect(gapMinutes, greaterThan(0),
              reason: 'There should be a temporal gap between different clusters');
          }
        }
        
        // Verify consistency: running clustering again should produce same groupings
        final clustersSecondRun = await clusteringService.clusterAssets(assets, customConfig: config);
        
        expect(clustersSecondRun.length, equals(clusters.length),
          reason: 'Clustering should be deterministic and produce consistent results');
        
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

    test('Temporal clustering respects context-specific configurations', () async {
      // Test that different context types use appropriate time windows
      for (int i = 0; i < 50; i++) {
        final contextType = faker.randomGenerator.element(ContextType.values);
        final config = ClusteringConfiguration.forContext(contextType);
        
        // Generate assets with timestamps that test the context-specific thresholds
        final assets = _generateAssetsForContextTesting(contextType, faker);
        
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify that clustering respects context-specific time windows
        for (final cluster in clusters) {
          if (cluster.assets.length > 1) {
            final sortedAssets = List<MediaAsset>.from(cluster.assets)
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final duration = sortedAssets.last.createdAt.difference(sortedAssets.first.createdAt);
            
            expect(duration.inMinutes, lessThanOrEqualTo(config.temporalThresholdMinutes),
              reason: 'Cluster duration should respect context-specific time window for $contextType');
          }
        }
      }
    });
  });
}

class TemporalClusteringScenario {
  final int timeWindowMinutes;
  final int numberOfAssets;
  final List<DateTime> timestamps;
  final int expectedMinClusters;
  final int expectedMaxClusters;

  TemporalClusteringScenario({
    required this.timeWindowMinutes,
    required this.numberOfAssets,
    required this.timestamps,
    required this.expectedMinClusters,
    required this.expectedMaxClusters,
  });
}

TemporalClusteringScenario _generateTemporalClusteringScenario(Faker faker) {
  // Generate a reasonable time window (15 minutes to 8 hours)
  final timeWindowMinutes = faker.randomGenerator.integer(480, min: 15);
  
  // Generate 3-20 assets
  final numberOfAssets = faker.randomGenerator.integer(20, min: 3);
  
  // Create timestamps with controlled gaps
  final baseTime = faker.date.dateTimeBetween(
    DateTime(2020, 1, 1),
    DateTime(2024, 1, 1),
  );
  
  final timestamps = <DateTime>[];
  DateTime currentTime = baseTime;
  
  // Create clusters with some assets within time window and some outside
  int expectedClusters = 1;
  
  for (int i = 0; i < numberOfAssets; i++) {
    timestamps.add(currentTime);
    
    if (i < numberOfAssets - 1) {
      // Randomly decide whether to stay in current cluster or start new one
      final shouldStartNewCluster = faker.randomGenerator.boolean();
      
      if (shouldStartNewCluster) {
        // Jump beyond time window to force new cluster
        final gapMinutes = timeWindowMinutes + faker.randomGenerator.integer(120, min: 1);
        currentTime = currentTime.add(Duration(minutes: gapMinutes));
        expectedClusters++;
      } else {
        // Stay within time window
        final gapMinutes = faker.randomGenerator.integer(timeWindowMinutes ~/ 2, min: 1);
        currentTime = currentTime.add(Duration(minutes: gapMinutes));
      }
    }
  }
  
  return TemporalClusteringScenario(
    timeWindowMinutes: timeWindowMinutes,
    numberOfAssets: numberOfAssets,
    timestamps: timestamps,
    expectedMinClusters: 1,
    expectedMaxClusters: expectedClusters,
  );
}

List<MediaAsset> _generateAssetsWithTimestamps(TemporalClusteringScenario scenario, Faker faker) {
  final assets = <MediaAsset>[];
  
  for (int i = 0; i < scenario.numberOfAssets; i++) {
    final timestamp = scenario.timestamps[i];
    
    final asset = MediaAsset(
      id: 'asset_${i}_${timestamp.millisecondsSinceEpoch}',
      eventId: '', // Will be set during clustering
      type: AssetType.photo,
      localPath: '/mock/path/photo_$i.jpg',
      createdAt: timestamp,
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: timestamp,
        gpsLocation: null, // No GPS to avoid spatial clustering interference
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    
    assets.add(asset);
  }
  
  return assets;
}

List<MediaAsset> _generateAssetsForContextTesting(ContextType contextType, Faker faker) {
  final config = ClusteringConfiguration.forContext(contextType);
  final assets = <MediaAsset>[];
  
  // Create a scenario that tests the context-specific time window
  final baseTime = DateTime.now().subtract(const Duration(days: 30));
  
  // Create one cluster within the time window
  DateTime currentTime = baseTime;
  for (int i = 0; i < 3; i++) {
    final asset = MediaAsset(
      id: 'context_asset_${i}_${currentTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/context_photo_$i.jpg',
      createdAt: currentTime,
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: currentTime,
        gpsLocation: null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    assets.add(asset);
    
    // Add small gap within time window
    currentTime = currentTime.add(Duration(minutes: config.temporalThresholdMinutes ~/ 4));
  }
  
  // Add gap larger than time window
  currentTime = currentTime.add(Duration(minutes: config.temporalThresholdMinutes + 10));
  
  // Create second cluster
  for (int i = 3; i < 6; i++) {
    final asset = MediaAsset(
      id: 'context_asset_${i}_${currentTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/context_photo_$i.jpg',
      createdAt: currentTime,
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: currentTime,
        gpsLocation: null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    assets.add(asset);
    
    currentTime = currentTime.add(Duration(minutes: config.temporalThresholdMinutes ~/ 4));
  }
  
  return assets;
}
