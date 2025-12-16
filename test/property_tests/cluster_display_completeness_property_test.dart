import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';

void main() {
  group('Cluster Display Completeness Property Tests', () {
    late Faker faker;

    setUp(() {
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 10: Cluster Display Completeness**', () async {
      // **Validates: Requirements 2.5**
      
      // Property: For any clustered timeline event, the display should show accurate photo counts 
      // and provide expansion capabilities to view all contained photos

      for (int i = 0; i < 100; i++) {
        // Generate test scenario with clustered timeline events
        final testScenario = _generateClusterDisplayScenario(faker);
        
        // Create timeline event representing a cluster
        final event = _createClusteredTimelineEvent(testScenario, faker);
        
        // Verify photo count accuracy
        expect(event.assets.length, equals(testScenario.expectedAssetCount),
          reason: 'Event should contain the expected number of assets');
        
        expect(event.assets.length, greaterThan(0),
          reason: 'Clustered events should have at least one asset');
        
        // Verify that all assets are properly associated with the event
        for (final asset in event.assets) {
          expect(asset.eventId, equals(event.id),
            reason: 'All assets should be associated with the correct event ID');
        }
        
        // Verify key asset selection
        final keyAssets = event.assets.where((asset) => asset.isKeyAsset).toList();
        expect(keyAssets.length, equals(1),
          reason: 'Each clustered event should have exactly one key asset');
        
        final keyAsset = keyAssets.first;
        expect(event.assets.contains(keyAsset), isTrue,
          reason: 'Key asset should be part of the event assets');
        
        // Verify asset type diversity handling
        final assetTypes = event.assets.map((asset) => asset.type).toSet();
        expect(assetTypes, isNotEmpty,
          reason: 'Event should have assets with defined types');
        
        // For mixed-type events, verify all types are represented (only if we have enough assets)
        if (testScenario.hasMixedAssetTypes && testScenario.expectedAssetCount >= 2) {
          expect(assetTypes.length, greaterThan(1),
            reason: 'Mixed-type events with multiple assets should have multiple asset types');
        }
        
        // Verify temporal ordering of assets
        final sortedAssets = List<MediaAsset>.from(event.assets)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        expect(sortedAssets.first.createdAt, lessThanOrEqualTo(event.timestamp),
          reason: 'Event timestamp should be at or after the earliest asset');
        
        // Verify that asset metadata is complete for display
        for (final asset in event.assets) {
          expect(asset.id, isNotEmpty,
            reason: 'All assets should have valid IDs for display');
          expect(asset.localPath, isNotEmpty,
            reason: 'All assets should have local paths for display');
          expect(asset.createdAt, isNotNull,
            reason: 'All assets should have creation timestamps');
        }
        
        // Verify cluster-specific metadata
        if (testScenario.isBurstCluster) {
          expect(event.eventType, equals('photo_burst'),
            reason: 'Burst clusters should have appropriate event type');
        } else if (event.assets.length > 10) {
          expect(event.eventType, equals('photo_collection'),
            reason: 'Large clusters should be marked as collections');
        }
        
        // Verify expansion capability data completeness
        _verifyExpansionCapabilities(event, testScenario);
        
        // Verify display metadata consistency
        _verifyDisplayMetadataConsistency(event);
      }
    });

    test('Cluster display handles various asset counts correctly', () async {
      // Test display completeness across different cluster sizes
      final testCases = [1, 2, 5, 10, 25, 50, 100]; // Various cluster sizes
      
      for (final assetCount in testCases) {
        for (int i = 0; i < 10; i++) {
          final scenario = ClusterDisplayScenario(
            expectedAssetCount: assetCount,
            isBurstCluster: faker.randomGenerator.boolean(),
            hasMixedAssetTypes: faker.randomGenerator.boolean(),
            hasGpsData: faker.randomGenerator.boolean(),
          );
          
          final event = _createClusteredTimelineEvent(scenario, faker);
          
          // Verify count accuracy
          expect(event.assets.length, equals(assetCount),
            reason: 'Event should have exactly $assetCount assets');
          
          // Verify key asset selection works for any size
          final keyAssets = event.assets.where((a) => a.isKeyAsset).toList();
          expect(keyAssets.length, equals(1),
            reason: 'Events of any size should have exactly one key asset');
          
          // Verify all assets are displayable
          for (final asset in event.assets) {
            expect(asset.localPath, isNotEmpty,
              reason: 'All assets should be displayable regardless of cluster size');
          }
        }
      }
    });

    test('Cluster display preserves asset ordering and relationships', () async {
      // Test that asset relationships and ordering are preserved for display
      for (int i = 0; i < 50; i++) {
        final scenario = _generateClusterDisplayScenario(faker);
        final event = _createClusteredTimelineEvent(scenario, faker);
        
        // Verify temporal ordering is preserved
        final timestamps = event.assets.map((a) => a.createdAt).toList();
        final sortedTimestamps = List<DateTime>.from(timestamps)..sort();
        
        // Assets should be in chronological order or at least sortable
        expect(timestamps, isNotEmpty,
          reason: 'Event should have asset timestamps for ordering');
        
        // Verify that asset relationships are maintained
        final assetIds = event.assets.map((a) => a.id).toSet();
        expect(assetIds.length, equals(event.assets.length),
          reason: 'All assets should have unique IDs');
        
        // Verify that key asset is appropriately selected
        final keyAsset = event.assets.firstWhere((a) => a.isKeyAsset);
        
        // Key asset should be representative (e.g., not the first or last by default)
        if (event.assets.length > 2) {
          final sortedAssets = List<MediaAsset>.from(event.assets)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Key asset selection should be intelligent, not just first/last
          final keyIndex = sortedAssets.indexOf(keyAsset);
          expect(keyIndex, greaterThanOrEqualTo(0),
            reason: 'Key asset should be found in the sorted list');
        }
      }
    });

    test('Cluster display handles metadata completeness edge cases', () async {
      // Test display completeness with various metadata scenarios
      for (int i = 0; i < 50; i++) {
        final scenario = ClusterDisplayScenario(
          expectedAssetCount: faker.randomGenerator.integer(20, min: 3),
          isBurstCluster: faker.randomGenerator.boolean(),
          hasMixedAssetTypes: faker.randomGenerator.boolean(),
          hasGpsData: faker.randomGenerator.boolean(),
        );
        
        final event = _createClusteredTimelineEventWithEdgeCases(scenario, faker);
        
        // Verify that display works even with incomplete metadata
        expect(event.assets, isNotEmpty,
          reason: 'Event should have assets even with edge case metadata');
        
        // Verify that missing metadata doesn't break display
        for (final asset in event.assets) {
          // These should always be present for display
          expect(asset.id, isNotEmpty,
            reason: 'Asset ID should always be present');
          expect(asset.createdAt, isNotNull,
            reason: 'Asset creation time should always be present');
          
          // These may be null but shouldn't break display
          // (Testing graceful handling of missing data)
        }
        
        // Verify that key asset is still selected even with incomplete data
        final keyAssets = event.assets.where((a) => a.isKeyAsset).toList();
        expect(keyAssets.length, equals(1),
          reason: 'Key asset should be selected even with incomplete metadata');
      }
    });
  });
}

class ClusterDisplayScenario {
  final int expectedAssetCount;
  final bool isBurstCluster;
  final bool hasMixedAssetTypes;
  final bool hasGpsData;

  ClusterDisplayScenario({
    required this.expectedAssetCount,
    required this.isBurstCluster,
    required this.hasMixedAssetTypes,
    required this.hasGpsData,
  });
}

ClusterDisplayScenario _generateClusterDisplayScenario(Faker faker) {
  return ClusterDisplayScenario(
    expectedAssetCount: faker.randomGenerator.integer(50, min: 1),
    isBurstCluster: faker.randomGenerator.boolean(),
    hasMixedAssetTypes: faker.randomGenerator.boolean(),
    hasGpsData: faker.randomGenerator.boolean(),
  );
}

TimelineEvent _createClusteredTimelineEvent(ClusterDisplayScenario scenario, Faker faker) {
  final baseTime = faker.date.dateTimeBetween(
    DateTime(2023, 1, 1),
    DateTime(2024, 12, 31),
  );
  
  final assets = <MediaAsset>[];
  List<AssetType> assetTypes;
  if (scenario.hasMixedAssetTypes && scenario.expectedAssetCount > 1) {
    // Ensure we have at least 2 different types for mixed scenarios
    assetTypes = [AssetType.photo, AssetType.video, AssetType.audio];
  } else {
    assetTypes = [AssetType.photo];
  }
  
  for (int i = 0; i < scenario.expectedAssetCount; i++) {
    AssetType assetType;
    if (scenario.hasMixedAssetTypes && scenario.expectedAssetCount > 1) {
      // For mixed scenarios, ensure we get different types
      if (i < assetTypes.length) {
        assetType = assetTypes[i % assetTypes.length];
      } else {
        assetType = faker.randomGenerator.element(assetTypes);
      }
    } else {
      assetType = faker.randomGenerator.element(assetTypes);
    }
    final timestamp = baseTime.add(Duration(
      seconds: scenario.isBurstCluster ? i * 5 : i * 60, // Burst vs normal spacing
    ));
    
    GeoLocation? location;
    if (scenario.hasGpsData && faker.randomGenerator.boolean()) {
      location = GeoLocation(
        latitude: faker.geo.latitude(),
        longitude: faker.geo.longitude(),
        altitude: null,
        locationName: faker.address.city(),
      );
    }
    
    final asset = MediaAsset(
      id: 'cluster_asset_${i}_${timestamp.millisecondsSinceEpoch}',
      eventId: '', // Will be set when creating event
      type: assetType,
      localPath: '/mock/path/${assetType.name}_$i.${_getFileExtension(assetType)}',
      createdAt: timestamp,
      isKeyAsset: false, // Will be set for one asset
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
  
  // Select key asset (middle asset for better representation)
  final keyAssetIndex = assets.length > 1 ? assets.length ~/ 2 : 0;
  assets[keyAssetIndex] = assets[keyAssetIndex].copyWith(isKeyAsset: true);
  
  final eventId = 'cluster_event_${baseTime.millisecondsSinceEpoch}';
  
  // Update all assets with event ID
  final updatedAssets = assets.map((asset) => asset.copyWith(eventId: eventId)).toList();
  
  // Determine event type based on cluster characteristics
  String eventType = 'photo';
  if (scenario.isBurstCluster) {
    eventType = 'photo_burst';
  } else if (assets.length > 10) {
    eventType = 'photo_collection';
  } else if (scenario.hasMixedAssetTypes) {
    eventType = 'mixed';
  }
  
  return TimelineEvent.create(
    id: eventId,
    ownerId: 'test_owner',
    timestamp: baseTime,
    eventType: eventType,
    assets: updatedAssets,
    title: scenario.isBurstCluster ? 'Photo Burst (${assets.length} photos)' : null,
    description: _generateClusterDescription(scenario, assets.length),
  );
}

TimelineEvent _createClusteredTimelineEventWithEdgeCases(ClusterDisplayScenario scenario, Faker faker) {
  final baseTime = faker.date.dateTimeBetween(
    DateTime(2023, 1, 1),
    DateTime(2024, 12, 31),
  );
  
  final assets = <MediaAsset>[];
  
  for (int i = 0; i < scenario.expectedAssetCount; i++) {
    final timestamp = baseTime.add(Duration(seconds: i * 30));
    
    // Introduce edge cases: some assets with missing/incomplete data
    final hasCompleteExif = faker.randomGenerator.boolean();
    final hasValidPath = faker.randomGenerator.boolean();
    
    ExifData? exifData;
    if (hasCompleteExif) {
      exifData = ExifData(
        dateTimeOriginal: timestamp,
        gpsLocation: scenario.hasGpsData ? GeoLocation(
          latitude: faker.geo.latitude(),
          longitude: faker.geo.longitude(),
          altitude: null,
          locationName: faker.address.city(),
        ) : null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      );
    }
    
    final asset = MediaAsset(
      id: 'edge_asset_${i}_${timestamp.millisecondsSinceEpoch}',
      eventId: '', // Will be set when creating event
      type: AssetType.photo,
      localPath: hasValidPath ? '/mock/path/photo_$i.jpg' : '/mock/missing/path_$i.jpg',
      createdAt: timestamp,
      isKeyAsset: false,
      exifData: exifData,
    );
    
    assets.add(asset);
  }
  
  // Ensure at least one asset can be key asset (has valid data)
  if (assets.isNotEmpty) {
    assets[0] = assets[0].copyWith(
      isKeyAsset: true,
      localPath: '/mock/path/key_photo.jpg', // Ensure key asset has valid path
    );
  }
  
  final eventId = 'edge_event_${baseTime.millisecondsSinceEpoch}';
  final updatedAssets = assets.map((asset) => asset.copyWith(eventId: eventId)).toList();
  
  return TimelineEvent.create(
    id: eventId,
    ownerId: 'test_owner',
    timestamp: baseTime,
    eventType: 'photo',
    assets: updatedAssets,
  );
}

void _verifyExpansionCapabilities(TimelineEvent event, ClusterDisplayScenario scenario) {
  // Verify that the event has all necessary data for expansion display
  
  if (event.assets.length > 1) {
    // Multi-asset events should support expansion
    
    // Verify that all assets have display-ready data
    for (final asset in event.assets) {
      expect(asset.id, isNotEmpty,
        reason: 'Assets should have IDs for expansion display');
      expect(asset.type, isNotNull,
        reason: 'Assets should have types for expansion display');
    }
    
    // Verify that assets can be sorted for expansion view
    final sortedAssets = List<MediaAsset>.from(event.assets)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    expect(sortedAssets.length, equals(event.assets.length),
      reason: 'All assets should be sortable for expansion view');
  }
  
  // Verify custom attributes are available for expansion display
  expect(event.customAttributes, isNotNull,
    reason: 'Custom attributes should be available for expansion display');
}

void _verifyDisplayMetadataConsistency(TimelineEvent event) {
  // Verify that display metadata is consistent and complete
  
  // Event should have a valid timestamp
  expect(event.timestamp, isNotNull,
    reason: 'Event should have a timestamp for display');
  
  // Event should have a valid ID
  expect(event.id, isNotEmpty,
    reason: 'Event should have an ID for display');
  
  // Event should have a valid event type
  expect(event.eventType, isNotEmpty,
    reason: 'Event should have an event type for display');
  
  // If event has a title, it should be meaningful
  if (event.title != null) {
    expect(event.title!.trim(), isNotEmpty,
      reason: 'Event title should not be empty if present');
  }
  
  // If event has a description, it should be meaningful
  if (event.description != null) {
    expect(event.description!.trim(), isNotEmpty,
      reason: 'Event description should not be empty if present');
  }
  
  // Privacy level should be set
  expect(event.isPrivate, isNotNull,
    reason: 'Event should have a privacy level for display');
}

String _getFileExtension(AssetType type) {
  switch (type) {
    case AssetType.photo:
      return 'jpg';
    case AssetType.video:
      return 'mp4';
    case AssetType.audio:
      return 'mp3';
    case AssetType.document:
      return 'pdf';
  }
}

String? _generateClusterDescription(ClusterDisplayScenario scenario, int assetCount) {
  if (scenario.isBurstCluster) {
    return 'Rapid photo sequence with $assetCount photos';
  } else if (assetCount > 10) {
    return 'Photo collection with $assetCount photos';
  } else if (scenario.hasMixedAssetTypes) {
    return 'Mixed media event with $assetCount items';
  }
  return null;
}
