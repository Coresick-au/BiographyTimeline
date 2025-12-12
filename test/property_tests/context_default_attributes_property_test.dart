import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';

void main() {
  group('Context-Specific Default Attributes Property Tests', () {
    late Faker faker;

    setUp(() {
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 9: Context-Specific Default Attributes**', () async {
      // **Validates: Requirements 2.4**
      
      // Property: For any timeline event creation and context type, 
      // the system should initialize custom_attributes with appropriate default values 
      // based on the event_type and context

      for (int i = 0; i < 100; i++) {
        // Generate test scenario with different context types and event types
        final testScenario = _generateContextAttributeScenario(faker);
        
        // Create timeline event with context-specific event type
        final event = TimelineEvent.create(
          id: testScenario.eventId,
          contextId: testScenario.contextId,
          ownerId: testScenario.ownerId,
          timestamp: testScenario.timestamp,
          eventType: testScenario.eventType,
          assets: testScenario.assets,
        );
        
        // Verify that custom attributes are initialized with context-appropriate defaults
        expect(event.customAttributes, isNotNull,
          reason: 'Custom attributes should be initialized');
        
        // Verify context-specific default attributes based on event type
        switch (testScenario.eventType) {
          case 'renovation_progress':
            _verifyRenovationDefaults(event.customAttributes);
            break;
          case 'pet_milestone':
            _verifyPetDefaults(event.customAttributes);
            break;
          case 'business_milestone':
            _verifyBusinessDefaults(event.customAttributes);
            break;
          case 'photo':
          case 'text':
          case 'mixed':
            _verifyGenericDefaults(event.customAttributes);
            break;
          default:
            // Custom event types should have empty defaults
            expect(event.customAttributes, isEmpty,
              reason: 'Unknown event types should have empty default attributes');
        }
        
        // Verify that the event type is preserved
        expect(event.eventType, equals(testScenario.eventType),
          reason: 'Event type should be preserved during creation');
        
        // Verify that context ID is preserved
        expect(event.contextId, equals(testScenario.contextId),
          reason: 'Context ID should be preserved during creation');
        
        // Verify that custom attributes can be modified without affecting defaults
        final modifiedAttributes = Map<String, dynamic>.from(event.customAttributes);
        modifiedAttributes['custom_field'] = 'custom_value';
        
        final eventWithCustomAttributes = event.copyWith(customAttributes: modifiedAttributes);
        
        expect(eventWithCustomAttributes.customAttributes['custom_field'], equals('custom_value'),
          reason: 'Custom attributes should be modifiable');
        
        // Original event should remain unchanged
        expect(event.customAttributes.containsKey('custom_field'), isFalse,
          reason: 'Original event should not be affected by modifications');
      }
    });

    test('Context-specific attributes are consistent across event creations', () async {
      // Test that the same event type always gets the same default attributes
      for (int i = 0; i < 50; i++) {
        final eventType = faker.randomGenerator.element([
          'renovation_progress',
          'pet_milestone',
          'business_milestone',
          'photo',
          'text',
        ]);
        
        // Create multiple events of the same type
        final events = <TimelineEvent>[];
        for (int j = 0; j < 5; j++) {
          final event = TimelineEvent.create(
            id: 'test_event_${i}_$j',
            contextId: 'test_context_$i',
            ownerId: 'test_owner_$i',
            timestamp: DateTime.now(),
            eventType: eventType,
          );
          events.add(event);
        }
        
        // Verify that all events of the same type have identical default attributes
        final firstEventAttributes = events.first.customAttributes;
        for (final event in events.skip(1)) {
          expect(event.customAttributes, equals(firstEventAttributes),
            reason: 'Events of the same type should have identical default attributes');
        }
      }
    });

    test('Default attributes do not interfere with explicit custom attributes', () async {
      // Test that providing explicit custom attributes overrides defaults
      for (int i = 0; i < 50; i++) {
        final eventType = faker.randomGenerator.element([
          'renovation_progress',
          'pet_milestone',
          'business_milestone',
        ]);
        
        final explicitAttributes = _generateExplicitAttributes(eventType, faker);
        
        final event = TimelineEvent.create(
          id: 'explicit_test_$i',
          contextId: 'test_context',
          ownerId: 'test_owner',
          timestamp: DateTime.now(),
          eventType: eventType,
          customAttributes: explicitAttributes,
        );
        
        // Verify that explicit attributes are preserved
        expect(event.customAttributes, equals(explicitAttributes),
          reason: 'Explicit custom attributes should override defaults');
        
        // Verify that explicit attributes contain expected keys
        for (final key in explicitAttributes.keys) {
          expect(event.customAttributes.containsKey(key), isTrue,
            reason: 'Explicit attribute key "$key" should be preserved');
          expect(event.customAttributes[key], equals(explicitAttributes[key]),
            reason: 'Explicit attribute value for "$key" should be preserved');
        }
      }
    });

    test('Default attributes handle null and empty values appropriately', () async {
      // Test that default attributes handle various null/empty scenarios
      for (int i = 0; i < 50; i++) {
        final eventType = faker.randomGenerator.element([
          'renovation_progress',
          'pet_milestone',
          'business_milestone',
        ]);
        
        // Test with null custom attributes
        final eventWithNull = TimelineEvent.create(
          id: 'null_test_$i',
          contextId: 'test_context',
          ownerId: 'test_owner',
          timestamp: DateTime.now(),
          eventType: eventType,
          customAttributes: null,
        );
        
        // Should get default attributes
        expect(eventWithNull.customAttributes, isNotEmpty,
          reason: 'Null custom attributes should be replaced with defaults for known event types');
        
        // Test with empty custom attributes
        final eventWithEmpty = TimelineEvent.create(
          id: 'empty_test_$i',
          contextId: 'test_context',
          ownerId: 'test_owner',
          timestamp: DateTime.now(),
          eventType: eventType,
          customAttributes: {},
        );
        
        // Should use provided empty map (not defaults)
        expect(eventWithEmpty.customAttributes, isEmpty,
          reason: 'Explicitly empty custom attributes should be preserved');
      }
    });
  });
}

class ContextAttributeScenario {
  final String eventId;
  final String contextId;
  final String ownerId;
  final DateTime timestamp;
  final String eventType;
  final List<MediaAsset> assets;

  ContextAttributeScenario({
    required this.eventId,
    required this.contextId,
    required this.ownerId,
    required this.timestamp,
    required this.eventType,
    required this.assets,
  });
}

ContextAttributeScenario _generateContextAttributeScenario(Faker faker) {
  final eventTypes = [
    'renovation_progress',
    'pet_milestone',
    'business_milestone',
    'photo',
    'text',
    'mixed',
    'custom_event_type', // Test unknown event type
  ];
  
  final eventType = faker.randomGenerator.element(eventTypes);
  final timestamp = faker.date.dateTimeBetween(
    DateTime(2023, 1, 1),
    DateTime(2024, 12, 31),
  );
  
  // Generate some test assets
  final assets = <MediaAsset>[];
  final assetCount = faker.randomGenerator.integer(5, min: 1);
  
  for (int i = 0; i < assetCount; i++) {
    final asset = MediaAsset(
      id: 'asset_${timestamp.millisecondsSinceEpoch}_$i',
      eventId: '', // Will be set during event creation
      type: AssetType.photo,
      localPath: '/mock/path/photo_$i.jpg',
      createdAt: timestamp.add(Duration(seconds: i)),
      isKeyAsset: i == 0, // First asset is key
      exifData: ExifData(
        dateTimeOriginal: timestamp.add(Duration(seconds: i)),
        gpsLocation: null,
        timezone: null,
        cameraModel: faker.company.name(),
        cameraMake: faker.company.name(),
      ),
    );
    assets.add(asset);
  }
  
  return ContextAttributeScenario(
    eventId: 'event_${timestamp.millisecondsSinceEpoch}',
    contextId: 'context_${faker.guid.guid()}',
    ownerId: 'owner_${faker.guid.guid()}',
    timestamp: timestamp,
    eventType: eventType,
    assets: assets,
  );
}

void _verifyRenovationDefaults(Map<String, dynamic> attributes) {
  // Verify renovation-specific default attributes
  expect(attributes.containsKey('cost'), isTrue,
    reason: 'Renovation events should have cost attribute');
  expect(attributes['cost'], equals(0.0),
    reason: 'Default cost should be 0.0');
  
  expect(attributes.containsKey('contractor'), isTrue,
    reason: 'Renovation events should have contractor attribute');
  expect(attributes['contractor'], isNull,
    reason: 'Default contractor should be null');
  
  expect(attributes.containsKey('room'), isTrue,
    reason: 'Renovation events should have room attribute');
  expect(attributes['room'], isNull,
    reason: 'Default room should be null');
  
  expect(attributes.containsKey('phase'), isTrue,
    reason: 'Renovation events should have phase attribute');
  expect(attributes['phase'], isNull,
    reason: 'Default phase should be null');
}

void _verifyPetDefaults(Map<String, dynamic> attributes) {
  // Verify pet-specific default attributes
  expect(attributes.containsKey('weight_kg'), isTrue,
    reason: 'Pet events should have weight_kg attribute');
  expect(attributes['weight_kg'], isNull,
    reason: 'Default weight_kg should be null');
  
  expect(attributes.containsKey('vaccine_type'), isTrue,
    reason: 'Pet events should have vaccine_type attribute');
  expect(attributes['vaccine_type'], isNull,
    reason: 'Default vaccine_type should be null');
  
  expect(attributes.containsKey('vet_visit'), isTrue,
    reason: 'Pet events should have vet_visit attribute');
  expect(attributes['vet_visit'], equals(false),
    reason: 'Default vet_visit should be false');
  
  expect(attributes.containsKey('mood'), isTrue,
    reason: 'Pet events should have mood attribute');
  expect(attributes['mood'], isNull,
    reason: 'Default mood should be null');
}

void _verifyBusinessDefaults(Map<String, dynamic> attributes) {
  // Verify business-specific default attributes
  expect(attributes.containsKey('milestone'), isTrue,
    reason: 'Business events should have milestone attribute');
  expect(attributes['milestone'], isNull,
    reason: 'Default milestone should be null');
  
  expect(attributes.containsKey('budget_spent'), isTrue,
    reason: 'Business events should have budget_spent attribute');
  expect(attributes['budget_spent'], equals(0.0),
    reason: 'Default budget_spent should be 0.0');
  
  expect(attributes.containsKey('team_size'), isTrue,
    reason: 'Business events should have team_size attribute');
  expect(attributes['team_size'], isNull,
    reason: 'Default team_size should be null');
}

void _verifyGenericDefaults(Map<String, dynamic> attributes) {
  // Generic event types (photo, text, mixed) should have empty defaults
  expect(attributes, isEmpty,
    reason: 'Generic event types should have empty default attributes');
}

Map<String, dynamic> _generateExplicitAttributes(String eventType, Faker faker) {
  switch (eventType) {
    case 'renovation_progress':
      return {
        'cost': faker.randomGenerator.decimal(scale: 10000),
        'contractor': faker.person.name(),
        'room': faker.randomGenerator.element(['kitchen', 'bathroom', 'bedroom', 'living room']),
        'phase': faker.randomGenerator.element(['planning', 'demolition', 'construction', 'finishing']),
        'custom_field': 'custom_value',
      };
    case 'pet_milestone':
      return {
        'weight_kg': faker.randomGenerator.decimal(scale: 50, min: 1),
        'vaccine_type': faker.randomGenerator.element(['Rabies', 'DHPP', 'Bordetella']),
        'vet_visit': faker.randomGenerator.boolean(),
        'mood': faker.randomGenerator.element(['playful', 'sleepy', 'excited', 'calm']),
        'custom_field': 'custom_value',
      };
    case 'business_milestone':
      return {
        'milestone': faker.randomGenerator.element(['MVP Launch', 'Series A', 'Product Launch']),
        'budget_spent': faker.randomGenerator.decimal(scale: 100000),
        'team_size': faker.randomGenerator.integer(50, min: 1),
        'custom_field': 'custom_value',
      };
    default:
      return {
        'custom_field': 'custom_value',
        'another_field': faker.lorem.word(),
      };
  }
}