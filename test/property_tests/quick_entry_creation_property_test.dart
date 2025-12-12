import 'package:flutter_test/flutter_test.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/fuzzy_date.dart';
import '../test_config.dart';

/// **Feature: users-timeline, Property 35: Quick Entry Creation**
/// **Validates: Requirements 8.1, 8.3, 8.4**
/// 
/// Property: For any text-only timeline entry, the system should create a Timeline_Event 
/// that integrates seamlessly with photo-based events and supports both precise and fuzzy dates
void main() {
  group('Property Test: Quick Entry Creation', () {
    setUpAll(() {
      TestConfig.setUp();
    });

    tearDownAll(() {
      TestConfig.tearDown();
    });

    test('Quick entry creation with precise dates', () {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextType = PropertyTestUtils.randomContextType();
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();
        final title = PropertyTestUtils.randomString(20);
        final description = PropertyTestUtils.randomString(100);

        // Create quick entry with precise date
        final event = TimelineEvent.create(
          id: 'quick_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          title: title,
          description: description,
          assets: [], // Text-only entries have no assets
        );

        // Verify the event is created correctly
        expect(event.id, isNotEmpty);
        expect(event.contextId, equals(contextId));
        expect(event.ownerId, equals(ownerId));
        expect(event.timestamp, equals(timestamp));
        expect(event.eventType, equals('text'));
        expect(event.title, equals(title));
        expect(event.description, equals(description));
        expect(event.assets, isEmpty);
        expect(event.fuzzyDate, isNull); // Precise date should not have fuzzy date
        expect(event.privacyLevel, equals(PrivacyLevel.private)); // Default privacy
        
        // Verify it integrates with timeline (has required fields)
        expect(event.createdAt, isNotNull);
        expect(event.updatedAt, isNotNull);
        expect(event.participantIds, isNotNull);
        expect(event.customAttributes, isNotNull);
      }
    });

    test('Quick entry creation with fuzzy dates', () {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextType = PropertyTestUtils.randomContextType();
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final fuzzyDate = PropertyTestUtils.randomFuzzyDate();
        final title = PropertyTestUtils.randomString(20);
        final description = PropertyTestUtils.randomString(100);

        // Create quick entry with fuzzy date
        final event = TimelineEvent.create(
          id: 'quick_fuzzy_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: fuzzyDate.toApproximateDateTime(),
          fuzzyDate: fuzzyDate,
          eventType: 'text',
          title: title,
          description: description,
          assets: [], // Text-only entries have no assets
        );

        // Verify the event is created correctly
        expect(event.id, isNotEmpty);
        expect(event.contextId, equals(contextId));
        expect(event.ownerId, equals(ownerId));
        expect(event.timestamp, equals(fuzzyDate.toApproximateDateTime()));
        expect(event.fuzzyDate, equals(fuzzyDate));
        expect(event.eventType, equals('text'));
        expect(event.title, equals(title));
        expect(event.description, equals(description));
        expect(event.assets, isEmpty);
        
        // Verify it integrates with timeline (has required fields)
        expect(event.createdAt, isNotNull);
        expect(event.updatedAt, isNotNull);
        expect(event.participantIds, isNotNull);
        expect(event.customAttributes, isNotNull);
      }
    });

    test('Quick entry seamless integration with photo-based events', () {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();

        // Create a text-only event
        final textEvent = TimelineEvent.create(
          id: 'text_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          description: PropertyTestUtils.randomString(100),
          assets: [],
        );

        // Create a photo-based event for comparison
        final photoEvent = TimelineEvent.create(
          id: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp.add(const Duration(minutes: 1)),
          eventType: 'photo',
          description: PropertyTestUtils.randomString(100),
          assets: [PropertyTestUtils.randomMediaAsset()],
        );

        // Verify both events have the same structure and can be sorted together
        expect(textEvent.contextId, equals(photoEvent.contextId));
        expect(textEvent.ownerId, equals(photoEvent.ownerId));
        expect(textEvent.runtimeType, equals(photoEvent.runtimeType));
        
        // Verify they can be sorted chronologically
        final events = [textEvent, photoEvent];
        events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        expect(events.first.eventType, equals('text'));
        expect(events.last.eventType, equals('photo'));
        
        // Verify both have all required timeline event fields
        for (final event in events) {
          expect(event.id, isNotEmpty);
          expect(event.contextId, isNotEmpty);
          expect(event.ownerId, isNotEmpty);
          expect(event.timestamp, isNotNull);
          expect(event.eventType, isNotEmpty);
          expect(event.createdAt, isNotNull);
          expect(event.updatedAt, isNotNull);
          expect(event.participantIds, isNotNull);
          expect(event.customAttributes, isNotNull);
          expect(event.privacyLevel, isNotNull);
        }
      }
    });

    test('Quick entry supports both title and description content', () {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();
        final hasTitle = PropertyTestUtils.randomBool();
        final title = hasTitle ? PropertyTestUtils.randomString(20) : null;
        final description = PropertyTestUtils.randomString(100);

        // Create quick entry
        final event = TimelineEvent.create(
          id: 'content_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          title: title,
          description: description,
          assets: [],
        );

        // Verify content is preserved correctly
        expect(event.title, equals(title));
        expect(event.description, equals(description));
        expect(event.eventType, equals('text'));
        expect(event.assets, isEmpty);
        
        // Verify the event is valid regardless of title presence
        expect(event.id, isNotEmpty);
        expect(event.contextId, equals(contextId));
        expect(event.ownerId, equals(ownerId));
        expect(event.timestamp, equals(timestamp));
      }
    });

    test('Quick entry maintains privacy and context isolation', () {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data for different contexts
        final contextId1 = PropertyTestUtils.randomString(10);
        final contextId2 = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();

        // Create quick entries in different contexts
        final event1 = TimelineEvent.create(
          id: 'privacy1_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId1,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          description: PropertyTestUtils.randomString(100),
          assets: [],
        );

        final event2 = TimelineEvent.create(
          id: 'privacy2_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId2,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          description: PropertyTestUtils.randomString(100),
          assets: [],
        );

        // Verify context isolation
        expect(event1.contextId, isNot(equals(event2.contextId)));
        expect(event1.contextId, equals(contextId1));
        expect(event2.contextId, equals(contextId2));
        
        // Verify both have default privacy settings
        expect(event1.privacyLevel, equals(PrivacyLevel.private));
        expect(event2.privacyLevel, equals(PrivacyLevel.private));
        
        // Verify they are separate events
        expect(event1.id, isNot(equals(event2.id)));
      }
    });
  });
}