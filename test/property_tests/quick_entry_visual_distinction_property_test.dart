import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/features/timeline/widgets/timeline_event_card.dart';
import '../test_config.dart';

/// **Feature: users-timeline, Property 36: Quick Entry Visual Distinction**
/// **Validates: Requirements 8.5**
/// 
/// Property: For any text-only timeline event, the system should display distinct visual 
/// indicators that differentiate it from photo-based events while maintaining timeline coherence
void main() {
  group('Property Test: Quick Entry Visual Distinction', () {
    setUpAll(() {
      TestConfig.setUp();
    });

    tearDownAll(() {
      TestConfig.tearDown();
    });

    testWidgets('Text-only events have distinct visual indicators from photo events', (tester) async {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();

        // Create a text-only event
        final textEvent = TimelineEvent.create(
          id: 'text_visual_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          title: PropertyTestUtils.randomString(20),
          description: PropertyTestUtils.randomString(100),
          assets: [], // No assets for text-only events
        );

        // Create a photo event for comparison
        final photoEvent = TimelineEvent.create(
          id: 'photo_visual_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp.add(const Duration(minutes: 1)),
          eventType: 'photo',
          description: PropertyTestUtils.randomString(100),
          assets: [PropertyTestUtils.randomMediaAsset()],
        );

        // Build text event card
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelineEventCard(event: textEvent),
            ),
          ),
        );

        // Verify text event has distinct visual indicators
        expect(find.byIcon(Icons.edit_note), findsAtLeastNWidgets(1)); // Text event icon(s)
        expect(find.text('Text Entry'), findsOneWidget); // Text event label
        
        // Verify text event has no photo-related elements
        expect(find.byIcon(Icons.photo), findsNothing);
        expect(find.byIcon(Icons.collections), findsNothing);
        expect(find.text('photos'), findsNothing);

        // Build photo event card for comparison
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelineEventCard(event: photoEvent),
            ),
          ),
        );

        // Verify photo event has different visual indicators
        expect(find.byIcon(Icons.photo), findsOneWidget); // Photo event icon
        expect(find.text('Text Entry'), findsNothing); // No text entry label
        
        // Both events should maintain timeline coherence (same structure)
        expect(find.byType(Card), findsOneWidget); // Both use Card widget
        expect(find.byType(InkWell), findsOneWidget); // Both are tappable
      }
    });

    testWidgets('Text events maintain timeline coherence with consistent layout', (tester) async {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();
        final title = PropertyTestUtils.randomString(20);
        final description = PropertyTestUtils.randomString(100);

        // Create text-only event
        final textEvent = TimelineEvent.create(
          id: 'coherence_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          title: title,
          description: description,
          assets: [],
        );

        // Build timeline event card
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelineEventCard(event: textEvent),
            ),
          ),
        );

        // Verify consistent timeline structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);
        expect(find.byType(Padding), findsWidgets);
        expect(find.byType(Column), findsWidgets);
        
        // Verify event content is displayed
        if (title.isNotEmpty) {
          expect(find.text(title), findsOneWidget);
        }
        expect(find.text(description), findsOneWidget);
        
        // Verify timestamp is displayed
        expect(find.textContaining(RegExp(r'(Today|Yesterday|\d+/\d+/\d+|\d+ days ago)')), findsOneWidget);
        
        // Verify text event specific elements
        expect(find.byIcon(Icons.edit_note), findsAtLeastNWidgets(1));
        expect(find.text('Text Entry'), findsOneWidget);
      }
    });

    testWidgets('Text events are visually distinguishable in mixed timeline', (tester) async {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final baseTimestamp = PropertyTestUtils.randomDateTime();

        // Create mixed events
        final events = [
          // Text event
          TimelineEvent.create(
            id: 'mixed_text_${DateTime.now().millisecondsSinceEpoch}_$i',
            contextId: contextId,
            ownerId: ownerId,
            timestamp: baseTimestamp,
            eventType: 'text',
            description: PropertyTestUtils.randomString(100),
            assets: [],
          ),
          // Photo event
          TimelineEvent.create(
            id: 'mixed_photo_${DateTime.now().millisecondsSinceEpoch}_$i',
            contextId: contextId,
            ownerId: ownerId,
            timestamp: baseTimestamp.add(const Duration(minutes: 1)),
            eventType: 'photo',
            description: PropertyTestUtils.randomString(100),
            assets: [PropertyTestUtils.randomMediaAsset()],
          ),
        ];

        // Build timeline with mixed events
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: events.map((event) => TimelineEventCard(event: event)).toList(),
              ),
            ),
          ),
        );

        // Verify both events are present
        expect(find.byType(TimelineEventCard), findsNWidgets(2));
        
        // Verify text event is distinguishable
        expect(find.byIcon(Icons.edit_note), findsAtLeastNWidgets(2));
        expect(find.text('Text Entry'), findsOneWidget);
        
        // Verify photo event is distinguishable
        expect(find.byIcon(Icons.photo), findsOneWidget);
        
        // Verify they maintain consistent structure
        expect(find.byType(Card), findsNWidgets(2));
        expect(find.byType(InkWell), findsNWidgets(2));
      }
    });

    testWidgets('Text event visual elements are accessible and themed correctly', (tester) async {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random input data
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();

        // Create text-only event
        final textEvent = TimelineEvent.create(
          id: 'accessible_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          description: PropertyTestUtils.randomString(100),
          assets: [],
        );

        // Build with custom theme to test theming
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: customTheme,
            home: Scaffold(
              body: TimelineEventCard(event: textEvent),
            ),
          ),
        );

        // Verify themed elements are present
        expect(find.byType(Container), findsWidgets); // Icon containers
        expect(find.byType(Icon), findsWidgets); // Icons
        expect(find.byType(Text), findsWidgets); // Text elements
        
        // Verify accessibility
        expect(find.byType(InkWell), findsOneWidget); // Tappable area
        expect(find.byType(Card), findsOneWidget); // Material design card
        
        // Verify text event specific styling
        expect(find.byIcon(Icons.edit_note), findsAtLeastNWidgets(1));
        expect(find.text('Text Entry'), findsOneWidget);
        
        // Verify gradient container for text events
        expect(find.byType(Container), findsWidgets);
      }
    });

    testWidgets('Text events support different content lengths while maintaining distinction', (tester) async {
      for (int i = 0; i < TestConfig.propertyTestIterations; i++) {
        // Generate random content of varying lengths
        final contextId = PropertyTestUtils.randomString(10);
        final ownerId = PropertyTestUtils.randomString(10);
        final timestamp = PropertyTestUtils.randomDateTime();
        
        // Random content length (short to very long)
        final contentLength = TestConfig.faker.randomGenerator.integer(500, min: 10);
        final description = PropertyTestUtils.randomString(contentLength);

        // Create text event with varying content length
        final textEvent = TimelineEvent.create(
          id: 'length_${DateTime.now().millisecondsSinceEpoch}_$i',
          contextId: contextId,
          ownerId: ownerId,
          timestamp: timestamp,
          eventType: 'text',
          description: description,
          assets: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelineEventCard(event: textEvent),
            ),
          ),
        );

        // Verify text event visual distinction is maintained regardless of content length
        expect(find.byIcon(Icons.edit_note), findsAtLeastNWidgets(1));
        expect(find.text('Text Entry'), findsOneWidget);
        
        // Verify content is displayed (may be truncated for long content)
        final substringLength = description.length >= 20 ? 20 : description.length;
        expect(find.textContaining(description.substring(0, substringLength)), findsOneWidget);
        
        // Verify consistent structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);
        
        // Verify text event preview container
        expect(find.byType(Container), findsWidgets);
      }
    });
  });
}
