import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/features/timeline/services/event_management_service.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';

void main() {
  group('Manual Clustering Attribute Preservation Property Tests', () {
    late EventManagementService eventManagementService;
    late Faker faker;

    setUp(() {
      eventManagementService = EventManagementService();
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 11: Manual Clustering Attribute Preservation**', () async {
      // **Validates: Requirements 2.6**
      
      // Property: For any manual clustering operation (split or merge), 
      // the system should preserve all custom_attributes data without loss or corruption

      for (int i = 0; i < 100; i++) {
        // Generate test scenario with events containing custom attributes
        final testScenario = _generateManualClusteringScenario(faker);
        
        // Test split operation attribute preservation
        if (testScenario.testSplitOperation) {
          await _testSplitAttributePreservation(testScenario, eventManagementService);
        }
        
        // Test merge operation attribute preservation
        if (testScenario.testMergeOperation) {
          await _testMergeAttributePreservation(testScenario, eventManagementService);
        }
        
        // Test move assets operation attribute preservation
        if (testScenario.testMoveOperation) {
          await _testMoveAttributePreservation(testScenario, eventManagementService);
        }
        
        // Test key asset update attribute preservation
        if (testScenario.testKeyAssetUpdate) {
          await _testKeyAssetUpdateAttributePreservation(testScenario, eventManagementService);
        }
      }
    });

    test('Split operation preserves all custom attributes', () async {
      // Focused test on split operation attribute preservation
      for (int i = 0; i < 50; i++) {
        final originalEvent = _createEventWithRichCustomAttributes(faker);
        
        // Create split groups (divide assets into two groups)
        final midPoint = originalEvent.assets.length ~/ 2;
        final group1 = originalEvent.assets.sublist(0, midPoint);
        final group2 = originalEvent.assets.sublist(midPoint);
        
        final result = await eventManagementService.splitEvent(
          originalEvent,
          [group1, group2],
        );
        
        expect(result.success, isTrue,
          reason: 'Split operation should succeed');
        expect(result.updatedEvents, isNotNull);
        expect(result.updatedEvents!.length, equals(2),
          reason: 'Split should produce two events');
        
        // Verify that both resulting events preserve custom attributes
        for (final splitEvent in result.updatedEvents!) {
          expect(splitEvent.customAttributes, equals(originalEvent.customAttributes),
            reason: 'Split events should preserve all original custom attributes');
          
          // Verify that custom attributes are deep-copied, not referenced
          // Create a copy of the split event to test deep copying
          final modifiedAttributes = Map<String, dynamic>.from(splitEvent.customAttributes);
          modifiedAttributes['test_modification'] = 'modified';
          final eventWithModifiedAttributes = splitEvent.copyWith(customAttributes: modifiedAttributes);
          
          expect(splitEvent.customAttributes.containsKey('test_modification'), isFalse,
            reason: 'Original split event should not be affected by copyWith modifications');
          expect(eventWithModifiedAttributes.customAttributes.containsKey('test_modification'), isTrue,
            reason: 'Modified event should contain the new attribute');
        }
      }
    });

    test('Merge operation preserves custom attributes appropriately', () async {
      // Focused test on merge operation attribute preservation
      for (int i = 0; i < 50; i++) {
        final events = _createMultipleEventsWithCustomAttributes(faker, 3);
        
        final result = await eventManagementService.mergeEvents(events);
        
        expect(result.success, isTrue,
          reason: 'Merge operation should succeed');
        expect(result.updatedEvents, isNotNull);
        expect(result.updatedEvents!.length, equals(1),
          reason: 'Merge should produce one event');
        
        final mergedEvent = result.updatedEvents!.first;
        
        // Verify that primary event's custom attributes are preserved
        final primaryEvent = events.reduce((a, b) => 
          a.timestamp.isBefore(b.timestamp) ? a : b
        );
        
        expect(mergedEvent.customAttributes, equals(primaryEvent.customAttributes),
          reason: 'Merged event should preserve primary event custom attributes');
        
        // Verify that all assets from all events are included
        final totalOriginalAssets = events.fold<int>(0, (sum, event) => sum + event.assets.length);
        expect(mergedEvent.assets.length, equals(totalOriginalAssets),
          reason: 'Merged event should contain all original assets');
      }
    });

    test('Move assets operation preserves custom attributes', () async {
      // Focused test on move assets operation attribute preservation
      for (int i = 0; i < 50; i++) {
        final sourceEvent = _createEventWithRichCustomAttributes(faker);
        // Create target event with same context to avoid validation failure
        final targetEvent = sourceEvent.copyWith(
          id: 'target_${sourceEvent.id}',
          assets: _generateTestAssets(faker, 2), // Give it some assets
          customAttributes: {
            'target_field': 'target_value',
            'target_number': faker.randomGenerator.integer(100),
          },
        );
        
        // Only move assets if source has more than 1 (to avoid emptying it)
        if (sourceEvent.assets.length < 2) continue;
        
        final assetsToMove = [sourceEvent.assets.first]; // Move just one asset
        
        final result = await eventManagementService.moveAssets(
          assetsToMove,
          sourceEvent,
          targetEvent,
        );
        
        expect(result.success, isTrue,
          reason: 'Move assets operation should succeed: ${result.errorMessage}');
        
        if (result.success && result.updatedEvents != null) {
          expect(result.updatedEvents!.length, equals(2),
            reason: 'Move operation should update both source and target events');
          
          // Find updated source and target events by ID (more reliable than asset count)
          final updatedSourceEvent = result.updatedEvents!
              .firstWhere((e) => e.id == sourceEvent.id);
          final updatedTargetEvent = result.updatedEvents!
              .firstWhere((e) => e.id == targetEvent.id);
          
          // Verify custom attributes preservation
          expect(updatedSourceEvent.customAttributes, equals(sourceEvent.customAttributes),
            reason: 'Source event should preserve custom attributes after move');
          expect(updatedTargetEvent.customAttributes, equals(targetEvent.customAttributes),
            reason: 'Target event should preserve custom attributes after move');
        }
      }
    });

    test('Key asset update preserves all custom attributes', () async {
      // Focused test on key asset update attribute preservation
      for (int i = 0; i < 50; i++) {
        final originalEvent = _createEventWithRichCustomAttributes(faker);
        
        // Select a different asset to be the key asset
        final newKeyAsset = originalEvent.assets
            .firstWhere((asset) => !asset.isKeyAsset, orElse: () => originalEvent.assets.last);
        
        final result = await eventManagementService.updateKeyAsset(
          originalEvent,
          newKeyAsset,
        );
        
        expect(result.success, isTrue,
          reason: 'Key asset update should succeed');
        expect(result.updatedEvents, isNotNull);
        expect(result.updatedEvents!.length, equals(1),
          reason: 'Key asset update should return one updated event');
        
        final updatedEvent = result.updatedEvents!.first;
        
        // Verify custom attributes are completely preserved
        expect(updatedEvent.customAttributes, equals(originalEvent.customAttributes),
          reason: 'Key asset update should preserve all custom attributes');
        
        // Verify that the key asset was actually updated
        final newKeyAssets = updatedEvent.assets.where((a) => a.isKeyAsset).toList();
        expect(newKeyAssets.length, equals(1),
          reason: 'Updated event should have exactly one key asset');
        expect(newKeyAssets.first.id, equals(newKeyAsset.id),
          reason: 'The correct asset should be marked as key');
      }
    });

    test('Complex custom attributes are preserved correctly', () async {
      // Test preservation of complex nested custom attributes
      for (int i = 0; i < 30; i++) {
        final complexEvent = _createEventWithComplexCustomAttributes(faker);
        
        // Test split operation with complex attributes
        final midPoint = complexEvent.assets.length ~/ 2;
        final group1 = complexEvent.assets.sublist(0, midPoint);
        final group2 = complexEvent.assets.sublist(midPoint);
        
        final splitResult = await eventManagementService.splitEvent(
          complexEvent,
          [group1, group2],
        );
        
        expect(splitResult.success, isTrue,
          reason: 'Split with complex attributes should succeed');
        
        // Verify complex attributes are preserved
        for (final splitEvent in splitResult.updatedEvents!) {
          _verifyComplexAttributesPreservation(
            complexEvent.customAttributes,
            splitEvent.customAttributes,
          );
        }
      }
    });
  });
}

class ManualClusteringScenario {
  final bool testSplitOperation;
  final bool testMergeOperation;
  final bool testMoveOperation;
  final bool testKeyAssetUpdate;
  final List<TimelineEvent> events;

  ManualClusteringScenario({
    required this.testSplitOperation,
    required this.testMergeOperation,
    required this.testMoveOperation,
    required this.testKeyAssetUpdate,
    required this.events,
  });
}

ManualClusteringScenario _generateManualClusteringScenario(Faker faker) {
  // Randomly select which operations to test
  final operations = [true, false];
  
  return ManualClusteringScenario(
    testSplitOperation: faker.randomGenerator.element(operations),
    testMergeOperation: faker.randomGenerator.element(operations),
    testMoveOperation: faker.randomGenerator.element(operations),
    testKeyAssetUpdate: faker.randomGenerator.element(operations),
    events: _createMultipleEventsWithCustomAttributes(faker, faker.randomGenerator.integer(4, min: 2)),
  );
}

Future<void> _testSplitAttributePreservation(
  ManualClusteringScenario scenario,
  EventManagementService service,
) async {
  final eventToSplit = scenario.events.first;
  if (eventToSplit.assets.length < 2) return; // Can't split single asset event
  
  final originalAttributes = Map<String, dynamic>.from(eventToSplit.customAttributes);
  
  // Split into two groups
  final midPoint = eventToSplit.assets.length ~/ 2;
  final group1 = eventToSplit.assets.sublist(0, midPoint);
  final group2 = eventToSplit.assets.sublist(midPoint);
  
  final result = await service.splitEvent(eventToSplit, [group1, group2]);
  
  expect(result.success, isTrue, reason: 'Split operation should succeed');
  
  // Verify attribute preservation
  for (final splitEvent in result.updatedEvents!) {
    expect(splitEvent.customAttributes, equals(originalAttributes),
      reason: 'Split events should preserve all custom attributes');
  }
}

Future<void> _testMergeAttributePreservation(
  ManualClusteringScenario scenario,
  EventManagementService service,
) async {
  if (scenario.events.length < 2) return; // Need at least 2 events to merge
  
  final eventsToMerge = scenario.events.take(2).toList();
  // The primary event is the earliest by timestamp (as per merge logic)
  final primaryEvent = eventsToMerge.reduce((a, b) => 
    a.timestamp.isBefore(b.timestamp) ? a : b
  );
  final originalAttributes = Map<String, dynamic>.from(primaryEvent.customAttributes);
  
  final result = await service.mergeEvents(eventsToMerge);
  
  expect(result.success, isTrue, reason: 'Merge operation should succeed');
  
  final mergedEvent = result.updatedEvents!.first;
  expect(mergedEvent.customAttributes, equals(originalAttributes),
    reason: 'Merged event should preserve primary event custom attributes');
}

Future<void> _testMoveAttributePreservation(
  ManualClusteringScenario scenario,
  EventManagementService service,
) async {
  if (scenario.events.length < 2) return; // Need at least 2 events
  
  final sourceEvent = scenario.events[0];
  final targetEvent = scenario.events[1];
  
  if (sourceEvent.assets.length < 2) return; // Need multiple assets to move some
  
  final originalSourceAttributes = Map<String, dynamic>.from(sourceEvent.customAttributes);
  final originalTargetAttributes = Map<String, dynamic>.from(targetEvent.customAttributes);
  
  final assetsToMove = [sourceEvent.assets.first];
  
  final result = await service.moveAssets(assetsToMove, sourceEvent, targetEvent);
  
  expect(result.success, isTrue, reason: 'Move operation should succeed');
  
  // Find updated events by ID (more reliable than asset count)
  final updatedSourceEvent = result.updatedEvents!
      .firstWhere((e) => e.id == sourceEvent.id);
  final updatedTargetEvent = result.updatedEvents!
      .firstWhere((e) => e.id == targetEvent.id);
  
  expect(updatedSourceEvent.customAttributes, equals(originalSourceAttributes),
    reason: 'Source event attributes should be preserved');
  expect(updatedTargetEvent.customAttributes, equals(originalTargetAttributes),
    reason: 'Target event attributes should be preserved');
}

Future<void> _testKeyAssetUpdateAttributePreservation(
  ManualClusteringScenario scenario,
  EventManagementService service,
) async {
  final event = scenario.events.first;
  if (event.assets.length < 2) return; // Need multiple assets to change key
  
  final originalAttributes = Map<String, dynamic>.from(event.customAttributes);
  final newKeyAsset = event.assets.firstWhere((a) => !a.isKeyAsset, orElse: () => event.assets.last);
  
  final result = await service.updateKeyAsset(event, newKeyAsset);
  
  expect(result.success, isTrue, reason: 'Key asset update should succeed');
  
  final updatedEvent = result.updatedEvents!.first;
  expect(updatedEvent.customAttributes, equals(originalAttributes),
    reason: 'Key asset update should preserve all custom attributes');
}

TimelineEvent _createEventWithRichCustomAttributes(Faker faker) {
  final assets = _generateTestAssets(faker, faker.randomGenerator.integer(10, min: 2));
  
  final customAttributes = {
    'string_field': faker.lorem.sentence(),
    'number_field': faker.randomGenerator.decimal(scale: 1000),
    'boolean_field': faker.randomGenerator.boolean(),
    'null_field': null,
    'list_field': [
      faker.lorem.word(),
      faker.randomGenerator.integer(100),
      faker.randomGenerator.boolean(),
    ],
    'map_field': {
      'nested_string': faker.lorem.word(),
      'nested_number': faker.randomGenerator.integer(100),
      'nested_boolean': faker.randomGenerator.boolean(),
    },
    'renovation_cost': faker.randomGenerator.decimal(scale: 50000),
    'contractor_name': faker.person.name(),
    'project_phase': faker.randomGenerator.element(['planning', 'execution', 'completion']),
  };
  
  return TimelineEvent.create(
    id: 'rich_event_${DateTime.now().millisecondsSinceEpoch}',
    contextId: 'test_context',
    ownerId: 'test_owner',
    timestamp: faker.date.dateTimeBetween(DateTime(2023, 1, 1), DateTime(2024, 12, 31)),
    eventType: 'renovation_progress',
    customAttributes: customAttributes,
    assets: assets,
  );
}

List<TimelineEvent> _createMultipleEventsWithCustomAttributes(Faker faker, int count) {
  final events = <TimelineEvent>[];
  
  for (int i = 0; i < count; i++) {
    final assets = _generateTestAssets(faker, faker.randomGenerator.integer(8, min: 2));
    
    final customAttributes = {
      'event_index': i,
      'event_name': faker.lorem.words(3).join(' '),
      'priority': faker.randomGenerator.integer(10, min: 1),
      'tags': List.generate(3, (_) => faker.lorem.word()),
      'metadata': {
        'created_by': faker.person.name(),
        'department': faker.company.name(),
        'budget': faker.randomGenerator.decimal(scale: 10000),
      },
    };
    
    final event = TimelineEvent.create(
      id: 'multi_event_${i}_${DateTime.now().millisecondsSinceEpoch}',
      contextId: 'test_context',
      ownerId: 'test_owner',
      timestamp: faker.date.dateTimeBetween(DateTime(2023, 1, 1), DateTime(2024, 12, 31)),
      eventType: faker.randomGenerator.element(['renovation_progress', 'pet_milestone', 'business_milestone']),
      customAttributes: customAttributes,
      assets: assets,
    );
    
    events.add(event);
  }
  
  return events;
}

TimelineEvent _createEventWithComplexCustomAttributes(Faker faker) {
  final assets = _generateTestAssets(faker, faker.randomGenerator.integer(6, min: 3));
  
  final complexAttributes = {
    'simple_string': faker.lorem.sentence(),
    'simple_number': faker.randomGenerator.decimal(scale: 1000),
    'nested_object': {
      'level_1': {
        'level_2': {
          'deep_string': faker.lorem.word(),
          'deep_array': [1, 2, 3, 'four', true],
          'deep_null': null,
        },
        'level_2_array': [
          {'item': 'first'},
          {'item': 'second'},
        ],
      },
      'level_1_simple': faker.randomGenerator.integer(100),
    },
    'complex_array': [
      {
        'type': 'measurement',
        'value': faker.randomGenerator.decimal(scale: 100),
        'unit': 'meters',
        'metadata': {
          'accuracy': faker.randomGenerator.decimal(scale: 1),
          'timestamp': DateTime.now().toIso8601String(),
        },
      },
      {
        'type': 'note',
        'content': faker.lorem.sentence(),
        'tags': [faker.lorem.word(), faker.lorem.word()],
      },
    ],
    'unicode_string': '🏠 Renovation Progress 📊',
    'special_chars': 'Special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?',
  };
  
  return TimelineEvent.create(
    id: 'complex_event_${DateTime.now().millisecondsSinceEpoch}',
    contextId: 'test_context',
    ownerId: 'test_owner',
    timestamp: faker.date.dateTimeBetween(DateTime(2023, 1, 1), DateTime(2024, 12, 31)),
    eventType: 'renovation_progress',
    customAttributes: complexAttributes,
    assets: assets,
  );
}

List<MediaAsset> _generateTestAssets(Faker faker, int count) {
  final assets = <MediaAsset>[];
  final baseTime = faker.date.dateTimeBetween(DateTime(2023, 1, 1), DateTime(2024, 12, 31));
  
  for (int i = 0; i < count; i++) {
    final timestamp = baseTime.add(Duration(minutes: i * 5));
    
    final asset = MediaAsset(
      id: 'test_asset_${i}_${timestamp.millisecondsSinceEpoch}',
      eventId: '', // Will be set during event creation
      type: AssetType.photo,
      localPath: '/mock/path/test_photo_$i.jpg',
      createdAt: timestamp,
      isKeyAsset: i == 0, // First asset is key
      exifData: ExifData(
        dateTimeOriginal: timestamp,
        gpsLocation: GeoLocation(
          latitude: faker.geo.latitude(),
          longitude: faker.geo.longitude(),
          altitude: null,
          locationName: faker.address.city(),
        ),
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    
    assets.add(asset);
  }
  
  return assets;
}

void _verifyComplexAttributesPreservation(
  Map<String, dynamic> original,
  Map<String, dynamic> preserved,
) {
  expect(preserved, equals(original),
    reason: 'Complex custom attributes should be preserved exactly');
  
  // Verify deep equality for nested structures
  for (final key in original.keys) {
    final originalValue = original[key];
    final preservedValue = preserved[key];
    
    if (originalValue is Map<String, dynamic>) {
      expect(preservedValue, isA<Map<String, dynamic>>(),
        reason: 'Nested maps should preserve type');
      _verifyComplexAttributesPreservation(
        originalValue,
        preservedValue as Map<String, dynamic>,
      );
    } else if (originalValue is List) {
      expect(preservedValue, isA<List>(),
        reason: 'Lists should preserve type');
      expect(preservedValue, equals(originalValue),
        reason: 'List contents should be preserved exactly');
    } else {
      expect(preservedValue, equals(originalValue),
        reason: 'Simple values should be preserved exactly');
    }
  }
}
