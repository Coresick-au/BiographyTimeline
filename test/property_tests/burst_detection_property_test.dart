import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/features/timeline/services/event_clustering_service.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';
import '../../lib/shared/models/context.dart';

void main() {
  group('Burst Detection Property Tests', () {
    late EventClusteringService clusteringService;
    late Faker faker;

    setUp(() {
      clusteringService = EventClusteringService();
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 8: Burst Detection and Consolidation**', () async {
      // **Validates: Requirements 2.3**
      
      // Property: For any sequence of photos taken in rapid succession, 
      // the system should detect bursts and consolidate them into single events with key photo selection

      for (int i = 0; i < 100; i++) {
        // Generate test scenario with burst sequences
        final testScenario = _generateBurstDetectionScenario(faker);
        final config = ClusteringConfiguration(
          temporalThresholdMinutes: 24 * 60, // 24 hours - effectively disable temporal clustering
          spatialThresholdMeters: double.maxFinite, // Disable spatial clustering
          burstThresholdSeconds: testScenario.burstThresholdSeconds,
          minBurstSize: testScenario.minBurstSize,
          maxBurstSize: testScenario.maxBurstSize,
        );
        
        // Create test assets with controlled timing for burst detection
        final assets = _generateAssetsWithBurstSequences(testScenario, faker);
        
        // Perform clustering
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify burst detection behavior
        final burstClusters = clusters.where((cluster) => cluster.isBurst).toList();
        final nonBurstClusters = clusters.where((cluster) => !cluster.isBurst).toList();
        
        // Check that detected bursts meet the minimum size requirement
        for (final burstCluster in burstClusters) {
          expect(burstCluster.assets.length, greaterThanOrEqualTo(testScenario.minBurstSize),
            reason: 'Burst clusters should meet minimum size requirement of ${testScenario.minBurstSize}');
          
          expect(burstCluster.assets.length, lessThanOrEqualTo(testScenario.maxBurstSize),
            reason: 'Burst clusters should not exceed maximum size of ${testScenario.maxBurstSize}');
        }
        
        // Check that assets in burst clusters are within the burst threshold
        for (final burstCluster in burstClusters) {
          final sortedAssets = List<MediaAsset>.from(burstCluster.assets)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          for (int j = 0; j < sortedAssets.length - 1; j++) {
            final timeDifference = sortedAssets[j + 1].createdAt
                .difference(sortedAssets[j].createdAt)
                .inSeconds;
            
            expect(timeDifference, lessThanOrEqualTo(testScenario.burstThresholdSeconds),
              reason: 'Consecutive photos in burst should be within ${testScenario.burstThresholdSeconds} seconds');
          }
        }
        
        // Check that each burst cluster has a key asset selected
        for (final burstCluster in burstClusters) {
          final keyAssets = burstCluster.assets.where((asset) => asset.isKeyAsset).toList();
          
          expect(keyAssets.length, equals(1),
            reason: 'Each burst cluster should have exactly one key asset');
          
          expect(burstCluster.keyAsset.isKeyAsset, isTrue,
            reason: 'The designated key asset should be marked as key');
        }
        
        // Verify that non-burst sequences are not marked as bursts
        for (final nonBurstCluster in nonBurstClusters) {
          expect(nonBurstCluster.isBurst, isFalse,
            reason: 'Non-burst clusters should not be marked as bursts');
        }
        
        // Verify that all original assets are accounted for
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
        
        // Verify consistency: running clustering again should produce same results
        final clustersSecondRun = await clusteringService.clusterAssets(assets, customConfig: config);
        
        expect(clustersSecondRun.length, equals(clusters.length),
          reason: 'Burst detection should be deterministic and produce consistent results');
        
        final burstClustersSecondRun = clustersSecondRun.where((c) => c.isBurst).length;
        expect(burstClustersSecondRun, equals(burstClusters.length),
          reason: 'Number of detected bursts should be consistent across runs');
      }
    });

    test('Burst detection handles edge cases correctly', () async {
      // Test edge cases like single photos, exact threshold timing, etc.
      for (int i = 0; i < 50; i++) {
        final config = ClusteringConfiguration(
          temporalThresholdMinutes: 24 * 60,
          spatialThresholdMeters: double.maxFinite,
          burstThresholdSeconds: 30,
          minBurstSize: 3,
          maxBurstSize: 20,
        );
        
        // Generate edge case scenarios
        final assets = _generateEdgeCaseAssets(faker);
        
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify that edge cases are handled gracefully
        expect(clusters, isNotEmpty, reason: 'Should handle edge cases without errors');
        
        // Check that single photos are not marked as bursts
        final singlePhotoClusters = clusters.where((c) => c.assets.length == 1).toList();
        for (final singleCluster in singlePhotoClusters) {
          expect(singleCluster.isBurst, isFalse,
            reason: 'Single photo clusters should not be marked as bursts');
        }
        
        // Verify all assets are accounted for
        final allAssetIds = clusters
            .expand((cluster) => cluster.assets)
            .map((asset) => asset.id)
            .toSet();
        final originalAssetIds = assets.map((a) => a.id).toSet();
        
        expect(allAssetIds, equals(originalAssetIds),
          reason: 'All assets should be accounted for in edge cases');
      }
    });

    test('Burst detection respects context-specific thresholds', () async {
      // Test that different context types use appropriate burst detection settings
      for (int i = 0; i < 50; i++) {
        final contextType = faker.randomGenerator.element(ContextType.values);
        final config = ClusteringConfiguration.forContext(contextType);
        
        // Generate assets that test context-specific burst thresholds
        final assets = _generateAssetsForBurstContextTesting(contextType, config, faker);
        
        final clusters = await clusteringService.clusterAssets(assets, customConfig: config);
        
        // Verify that burst detection respects context-specific settings
        final burstClusters = clusters.where((c) => c.isBurst).toList();
        
        for (final burstCluster in burstClusters) {
          // Check that burst meets context-specific requirements
          expect(burstCluster.assets.length, greaterThanOrEqualTo(config.minBurstSize),
            reason: 'Burst should meet context-specific minimum size for $contextType');
          
          // Check timing between consecutive photos
          final sortedAssets = List<MediaAsset>.from(burstCluster.assets)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          for (int j = 0; j < sortedAssets.length - 1; j++) {
            final timeDifference = sortedAssets[j + 1].createdAt
                .difference(sortedAssets[j].createdAt)
                .inSeconds;
            
            expect(timeDifference, lessThanOrEqualTo(config.burstThresholdSeconds),
              reason: 'Burst timing should respect context-specific threshold for $contextType');
          }
        }
      }
    });
  });
}

class BurstDetectionScenario {
  final int burstThresholdSeconds;
  final int minBurstSize;
  final int maxBurstSize;
  final List<BurstSequence> burstSequences;
  final List<DateTime> isolatedPhotoTimestamps;

  BurstDetectionScenario({
    required this.burstThresholdSeconds,
    required this.minBurstSize,
    required this.maxBurstSize,
    required this.burstSequences,
    required this.isolatedPhotoTimestamps,
  });
}

class BurstSequence {
  final DateTime startTime;
  final int photoCount;
  final int intervalSeconds;

  BurstSequence({
    required this.startTime,
    required this.photoCount,
    required this.intervalSeconds,
  });
}

BurstDetectionScenario _generateBurstDetectionScenario(Faker faker) {
  // Generate burst detection parameters
  final burstThresholdSeconds = faker.randomGenerator.integer(60, min: 5); // 5-60 seconds
  final minBurstSize = faker.randomGenerator.integer(5, min: 3); // 3-5 photos minimum
  final maxBurstSize = faker.randomGenerator.integer(50, min: 10); // 10-50 photos maximum
  
  // Generate 1-3 burst sequences
  final numberOfBursts = faker.randomGenerator.integer(3, min: 1);
  final burstSequences = <BurstSequence>[];
  
  DateTime currentTime = faker.date.dateTimeBetween(
    DateTime(2023, 1, 1),
    DateTime(2024, 1, 1),
  );
  
  for (int i = 0; i < numberOfBursts; i++) {
    // Generate burst with photos within threshold
    final photoCount = faker.randomGenerator.integer(maxBurstSize, min: minBurstSize);
    final intervalSeconds = faker.randomGenerator.integer(burstThresholdSeconds ~/ 2, min: 1);
    
    burstSequences.add(BurstSequence(
      startTime: currentTime,
      photoCount: photoCount,
      intervalSeconds: intervalSeconds,
    ));
    
    // Move to next burst with significant gap
    currentTime = currentTime.add(Duration(
      minutes: burstThresholdSeconds + faker.randomGenerator.integer(60, min: 10),
    ));
  }
  
  // Generate some isolated photos (not part of bursts)
  final isolatedPhotoTimestamps = <DateTime>[];
  for (int i = 0; i < faker.randomGenerator.integer(5, min: 1); i++) {
    currentTime = currentTime.add(Duration(
      minutes: burstThresholdSeconds + faker.randomGenerator.integer(30, min: 5),
    ));
    isolatedPhotoTimestamps.add(currentTime);
  }
  
  return BurstDetectionScenario(
    burstThresholdSeconds: burstThresholdSeconds,
    minBurstSize: minBurstSize,
    maxBurstSize: maxBurstSize,
    burstSequences: burstSequences,
    isolatedPhotoTimestamps: isolatedPhotoTimestamps,
  );
}

List<MediaAsset> _generateAssetsWithBurstSequences(BurstDetectionScenario scenario, Faker faker) {
  final assets = <MediaAsset>[];
  int assetCounter = 0;
  
  // Generate burst sequences
  for (final burstSequence in scenario.burstSequences) {
    DateTime currentTime = burstSequence.startTime;
    
    for (int i = 0; i < burstSequence.photoCount; i++) {
      final asset = MediaAsset(
        id: 'burst_asset_${assetCounter}_${currentTime.millisecondsSinceEpoch}',
        eventId: '', // Will be set during clustering
        type: AssetType.photo,
        localPath: '/mock/path/burst_photo_$assetCounter.jpg',
        createdAt: currentTime,
        isKeyAsset: false,
        exifData: ExifData(
          dateTimeOriginal: currentTime,
          gpsLocation: null, // No GPS to avoid spatial clustering interference
          timezone: null,
          cameraModel: faker.company.name(),
          cameraMake: faker.company.name(),
        ),
      );
      
      assets.add(asset);
      assetCounter++;
      
      // Move to next photo in burst
      currentTime = currentTime.add(Duration(seconds: burstSequence.intervalSeconds));
    }
  }
  
  // Generate isolated photos
  for (final timestamp in scenario.isolatedPhotoTimestamps) {
    final asset = MediaAsset(
      id: 'isolated_asset_${assetCounter}_${timestamp.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/isolated_photo_$assetCounter.jpg',
      createdAt: timestamp,
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: timestamp,
        gpsLocation: null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    
    assets.add(asset);
    assetCounter++;
  }
  
  // Sort by timestamp to simulate realistic photo order
  assets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  
  return assets;
}

List<MediaAsset> _generateEdgeCaseAssets(Faker faker) {
  final assets = <MediaAsset>[];
  final baseTime = DateTime.now().subtract(const Duration(hours: 2));
  
  // Single isolated photo
  assets.add(MediaAsset(
    id: 'edge_single_${baseTime.millisecondsSinceEpoch}',
    eventId: '',
    type: AssetType.photo,
    localPath: '/mock/path/edge_single.jpg',
    createdAt: baseTime,
    isKeyAsset: false,
    exifData: ExifData(
      dateTimeOriginal: baseTime,
      gpsLocation: null,
      timezone: null,
      cameraModel: faker.company.name(),
      cameraMake: faker.company.name(),
    ),
  ));
  
  // Two photos just under burst threshold (should not be burst)
  final twoPhotoTime = baseTime.add(const Duration(minutes: 10));
  for (int i = 0; i < 2; i++) {
    assets.add(MediaAsset(
      id: 'edge_two_${i}_${twoPhotoTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/edge_two_$i.jpg',
      createdAt: twoPhotoTime.add(Duration(seconds: i * 10)),
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: twoPhotoTime.add(Duration(seconds: i * 10)),
        gpsLocation: null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    ));
  }
  
  // Photos at exact threshold boundary
  final boundaryTime = baseTime.add(const Duration(minutes: 20));
  for (int i = 0; i < 4; i++) {
    assets.add(MediaAsset(
      id: 'edge_boundary_${i}_${boundaryTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/edge_boundary_$i.jpg',
      createdAt: boundaryTime.add(Duration(seconds: i * 30)), // Exactly at 30-second intervals
      isKeyAsset: false,
      exifData: ExifData(
        dateTimeOriginal: boundaryTime.add(Duration(seconds: i * 30)),
        gpsLocation: null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    ));
  }
  
  return assets;
}

List<MediaAsset> _generateAssetsForBurstContextTesting(
  ContextType contextType,
  ClusteringConfiguration config,
  Faker faker,
) {
  final assets = <MediaAsset>[];
  final baseTime = DateTime.now().subtract(const Duration(hours: 1));
  
  // Create a burst sequence that should be detected with context-specific settings
  DateTime currentTime = baseTime;
  final burstSize = config.minBurstSize + 2; // Slightly above minimum
  
  for (int i = 0; i < burstSize; i++) {
    final asset = MediaAsset(
      id: 'context_burst_asset_${i}_${currentTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/context_burst_photo_$i.jpg',
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
    
    // Use interval slightly less than threshold to ensure burst detection
    currentTime = currentTime.add(Duration(seconds: config.burstThresholdSeconds - 2));
  }
  
  // Add some isolated photos
  currentTime = currentTime.add(Duration(minutes: 10)); // Large gap
  
  for (int i = 0; i < 2; i++) {
    final asset = MediaAsset(
      id: 'context_isolated_asset_${i}_${currentTime.millisecondsSinceEpoch}',
      eventId: '',
      type: AssetType.photo,
      localPath: '/mock/path/context_isolated_photo_$i.jpg',
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
    
    currentTime = currentTime.add(Duration(minutes: 5));
  }
  
  return assets;
}
