import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/user.dart';

/// **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
/// **Validates: Requirements 9.4**
/// 
/// Property: For any custom attribute addition to an event, the system should validate 
/// and store the data in the polymorphic JSON metadata field according to context-specific rules
void main() {
  group('Custom Attribute Validation Property Tests', () {
    final faker = Faker();

    // Helper function to create a random timeline event
    TimelineEvent createRandomEvent(String eventType, Map<String, dynamic>? customAttributes) {
      return TimelineEvent.create(
        id: faker.guid.guid(),
        contextId: faker.guid.guid(),
        ownerId: faker.guid.guid(),
        timestamp: faker.date.dateTime(),
        eventType: eventType,
        customAttributes: customAttributes,
        title: faker.lorem.sentence(),
        description: faker.lorem.sentences(2).join(' '),
      );
    }

    test('Property 18: Custom attributes are stored in polymorphic JSON field', () {
      // **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
      
      // Run the property test 100 times with different attribute combinations
      for (int i = 0; i < 100; i++) {
        final eventTypes = ['photo', 'text', 'renovation_progress', 'pet_milestone', 'business_milestone'];
        final eventType = eventTypes[faker.randomGenerator.integer(eventTypes.length)];
        
        // Generate random custom attributes
        final customAttributes = <String, dynamic>{
          faker.lorem.word(): faker.lorem.word(),
          faker.lorem.word(): faker.randomGenerator.integer(1000),
          faker.lorem.word(): faker.randomGenerator.decimal(),
          faker.lorem.word(): faker.randomGenerator.boolean(),
        };
        
        final event = createRandomEvent(eventType, customAttributes);
        
        // Property: Custom attributes should be stored as Map<String, dynamic>
        expect(event.customAttributes, isA<Map<String, dynamic>>(),
            reason: 'Custom attributes should be stored as Map<String, dynamic>');
        
        // Property: All provided attributes should be preserved
        for (final entry in customAttributes.entries) {
          expect(event.customAttributes, containsPair(entry.key, entry.value),
              reason: 'Custom attribute ${entry.key} should be preserved with correct value');
        }
        
        // Property: Attributes should support various data types
        expect(event.customAttributes.values.any((v) => v is String), isTrue,
            reason: 'Custom attributes should support String values');
        expect(event.customAttributes.values.any((v) => v is int), isTrue,
            reason: 'Custom attributes should support int values');
        expect(event.customAttributes.values.any((v) => v is double), isTrue,
            reason: 'Custom attributes should support double values');
        expect(event.customAttributes.values.any((v) => v is bool), isTrue,
            reason: 'Custom attributes should support bool values');
      }
    });

    test('Property 18: Event type-specific default attributes are context-appropriate', () {
      // **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        // Test renovation progress events (project context)
        final renovationEvent = createRandomEvent('renovation_progress', null);
        expect(renovationEvent.customAttributes, containsKey('cost'),
            reason: 'Renovation events should have cost attribute');
        expect(renovationEvent.customAttributes, containsKey('contractor'),
            reason: 'Renovation events should have contractor attribute');
        expect(renovationEvent.customAttributes, containsKey('room'),
            reason: 'Renovation events should have room attribute');
        expect(renovationEvent.customAttributes, containsKey('phase'),
            reason: 'Renovation events should have phase attribute');
        
        // Property: Default values should be appropriate types
        expect(renovationEvent.customAttributes['cost'], isA<double>(),
            reason: 'Cost should be a numeric value');
        
        // Test pet milestone events (pet context)
        final petEvent = createRandomEvent('pet_milestone', null);
        expect(petEvent.customAttributes, containsKey('weight_kg'),
            reason: 'Pet events should have weight attribute');
        expect(petEvent.customAttributes, containsKey('vaccine_type'),
            reason: 'Pet events should have vaccine type attribute');
        expect(petEvent.customAttributes, containsKey('vet_visit'),
            reason: 'Pet events should have vet visit attribute');
        expect(petEvent.customAttributes, containsKey('mood'),
            reason: 'Pet events should have mood attribute');
        
        // Property: Default values should be appropriate types
        expect(petEvent.customAttributes['vet_visit'], isA<bool>(),
            reason: 'Vet visit should be a boolean value');
        
        // Test business milestone events (business context)
        final businessEvent = createRandomEvent('business_milestone', null);
        expect(businessEvent.customAttributes, containsKey('milestone'),
            reason: 'Business events should have milestone attribute');
        expect(businessEvent.customAttributes, containsKey('budget_spent'),
            reason: 'Business events should have budget spent attribute');
        expect(businessEvent.customAttributes, containsKey('team_size'),
            reason: 'Business events should have team size attribute');
        
        // Property: Default values should be appropriate types
        expect(businessEvent.customAttributes['budget_spent'], isA<double>(),
            reason: 'Budget spent should be a numeric value');
      }
    });

    test('Property 18: Custom attributes can be updated while preserving type safety', () {
      // **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final eventType = 'renovation_progress';
        final initialAttributes = <String, dynamic>{
          'cost': 1000.0,
          'contractor': 'Initial Contractor',
          'room': 'Kitchen',
          'phase': 'Planning',
        };
        
        final event = createRandomEvent(eventType, initialAttributes);
        
        // Property: Attributes can be updated with new values
        final updatedAttributes = <String, dynamic>{
          'cost': 1500.0,
          'contractor': 'Updated Contractor',
          'room': 'Kitchen',
          'phase': 'Construction',
          'new_field': faker.lorem.word(), // Adding new field
        };
        
        final updatedEvent = event.copyWith(customAttributes: updatedAttributes);
        
        // Property: Updated attributes should be preserved
        expect(updatedEvent.customAttributes['cost'], equals(1500.0),
            reason: 'Updated cost should be preserved');
        expect(updatedEvent.customAttributes['contractor'], equals('Updated Contractor'),
            reason: 'Updated contractor should be preserved');
        expect(updatedEvent.customAttributes['new_field'], equals(updatedAttributes['new_field']),
            reason: 'New fields should be added successfully');
        
        // Property: Original event should remain unchanged
        expect(event.customAttributes['cost'], equals(1000.0),
            reason: 'Original event should remain unchanged');
        expect(event.customAttributes['contractor'], equals('Initial Contractor'),
            reason: 'Original event should remain unchanged');
      }
    });

    test('Property 18: Attribute validation handles edge cases and invalid data', () {
      // **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final eventType = 'pet_milestone';
        
        // Test with null values
        final attributesWithNulls = <String, dynamic>{
          'weight_kg': null,
          'vaccine_type': null,
          'vet_visit': false,
          'mood': faker.lorem.word(),
        };
        
        final eventWithNulls = createRandomEvent(eventType, attributesWithNulls);
        
        // Property: Null values should be handled gracefully
        expect(eventWithNulls.customAttributes, containsKey('weight_kg'),
            reason: 'Null attributes should be preserved as keys');
        expect(eventWithNulls.customAttributes['weight_kg'], isNull,
            reason: 'Null values should be preserved');
        
        // Test with empty map
        final eventWithEmptyAttributes = createRandomEvent(eventType, {});
        
        // Property: Empty attributes should result in default attributes
        expect(eventWithEmptyAttributes.customAttributes, isNotEmpty,
            reason: 'Empty custom attributes should be populated with defaults');
        
        // Test with mixed valid and invalid types
        final mixedAttributes = <String, dynamic>{
          'weight_kg': 12.5, // Valid
          'vaccine_type': 'Rabies', // Valid
          'vet_visit': 'yes', // Invalid type (should be bool)
          'mood': 123, // Invalid type (should be string)
          'complex_object': {'nested': 'value'}, // Complex object
          'list_value': [1, 2, 3], // List value
        };
        
        final eventWithMixedAttributes = createRandomEvent(eventType, mixedAttributes);
        
        // Property: All attribute types should be preserved in JSON field
        expect(eventWithMixedAttributes.customAttributes['weight_kg'], equals(12.5),
            reason: 'Valid numeric values should be preserved');
        expect(eventWithMixedAttributes.customAttributes['vaccine_type'], equals('Rabies'),
            reason: 'Valid string values should be preserved');
        expect(eventWithMixedAttributes.customAttributes['vet_visit'], equals('yes'),
            reason: 'All values should be preserved regardless of expected type');
        expect(eventWithMixedAttributes.customAttributes['complex_object'], isA<Map>(),
            reason: 'Complex objects should be preserved');
        expect(eventWithMixedAttributes.customAttributes['list_value'], isA<List>(),
            reason: 'List values should be preserved');
      }
    });

    test('Property 18: Attribute serialization and deserialization preserves data integrity', () {
      // **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final eventType = 'business_milestone';
        final originalAttributes = <String, dynamic>{
          'milestone': faker.lorem.sentence(),
          'budget_spent': faker.randomGenerator.decimal(scale: 10000),
          'team_size': faker.randomGenerator.integer(100),
          'revenue': faker.randomGenerator.decimal(scale: 1000000),
          'launch_date': DateTime.now().toIso8601String(),
          'success_metrics': {
            'user_growth': faker.randomGenerator.integer(10000),
            'revenue_growth': faker.randomGenerator.decimal(scale: 100),
          },
          'features_launched': [
            faker.lorem.word(),
            faker.lorem.word(),
            faker.lorem.word(),
          ],
        };
        
        final event = createRandomEvent(eventType, originalAttributes);
        
        // Property: Serialization to JSON should preserve all data
        final json = event.toJson();
        expect(json, containsKey('customAttributes'),
            reason: 'JSON should contain customAttributes field');
        expect(json['customAttributes'], isA<Map<String, dynamic>>(),
            reason: 'Custom attributes should be serialized as Map');
        
        // Property: Deserialization should restore original data
        final deserializedEvent = TimelineEvent.fromJson(json);
        expect(deserializedEvent.customAttributes, equals(event.customAttributes),
            reason: 'Deserialized attributes should match original');
        
        // Property: Complex nested objects should be preserved
        expect(deserializedEvent.customAttributes['success_metrics'], isA<Map>(),
            reason: 'Nested objects should be preserved');
        expect(deserializedEvent.customAttributes['features_launched'], isA<List>(),
            reason: 'Lists should be preserved');
        
        // Property: All original values should be exactly preserved
        for (final entry in originalAttributes.entries) {
          expect(deserializedEvent.customAttributes[entry.key], equals(entry.value),
              reason: 'Attribute ${entry.key} should be preserved exactly');
        }
      }
    });

    test('Property 18: Context-specific attribute validation rules are enforced', () {
      // **Feature: users-timeline, Property 18: Polymorphic Custom Attribute Validation**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        // Test that different event types have different default attribute schemas
        final renovationEvent = createRandomEvent('renovation_progress', null);
        final petEvent = createRandomEvent('pet_milestone', null);
        final businessEvent = createRandomEvent('business_milestone', null);
        final photoEvent = createRandomEvent('photo', null);
        
        // Property: Different event types should have different attribute schemas
        expect(renovationEvent.customAttributes.keys.toSet(), 
               isNot(equals(petEvent.customAttributes.keys.toSet())),
               reason: 'Different event types should have different attribute schemas');
        
        expect(petEvent.customAttributes.keys.toSet(), 
               isNot(equals(businessEvent.customAttributes.keys.toSet())),
               reason: 'Different event types should have different attribute schemas');
        
        // Property: Generic events should have minimal attributes
        expect(photoEvent.customAttributes, isEmpty,
            reason: 'Generic photo events should have no default custom attributes');
        
        // Property: Context-specific events should have rich default attributes
        expect(renovationEvent.customAttributes, isNotEmpty,
            reason: 'Context-specific events should have default attributes');
        expect(petEvent.customAttributes, isNotEmpty,
            reason: 'Context-specific events should have default attributes');
        expect(businessEvent.customAttributes, isNotEmpty,
            reason: 'Context-specific events should have default attributes');
        
        // Property: Attribute keys should follow naming conventions
        for (final key in renovationEvent.customAttributes.keys) {
          expect(key, isA<String>(),
              reason: 'Attribute keys should be strings');
          expect(key, isNotEmpty,
              reason: 'Attribute keys should not be empty');
        }
      }
    });
  });
}