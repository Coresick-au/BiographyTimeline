import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/features/timeline/services/timeline_renderer_interface.dart';
import '../../lib/features/timeline/services/timeline_service.dart';

/**
 * Feature: users-timeline, Property 20: Visualization Mode Completeness
 * 
 * Property: Timeline visualization engine should provide complete, 
 * functional implementations for all supported view modes
 * 
 * Validates: Requirements 5.1, 5.2, 5.3, 5.4
 */

void main() {
  group('Visualization Completeness Property Tests', () {
    late TimelineService timelineService;
    final faker = Faker();
    final uuid = const Uuid();

    setUp(() {
      timelineService = TimelineService();
    });

    tearDown(() {
      timelineService.dispose();
    });

    test('Property: Timeline service supports all required view modes', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Test: All view modes are available in enum
        final allViewModes = TimelineViewMode.values;
        
        // Verify: Required view modes are present
        expect(allViewModes, contains(TimelineViewMode.lifeStream));
        expect(allViewModes, contains(TimelineViewMode.mapView));
        expect(allViewModes, contains(TimelineViewMode.bentoGrid));
        
        // Verify: No duplicate view modes
        expect(allViewModes.length, equals(allViewModes.toSet().length));
      }
    });

    test('Property: Timeline render config handles all configuration options', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random configuration
        final viewMode = TimelineViewMode.values[faker.randomGenerator.integer(TimelineViewMode.values.length)];
        final startDate = faker.date.dateTime();
        final endDate = startDate.add(Duration(days: faker.randomGenerator.integer(365, min: 1)));
        final context = _generateRandomContext();
        final selectedEventIds = Set<String>.from(
          List.generate(faker.randomGenerator.integer(5, min: 0), (_) => uuid.v4())
        );
        final showPrivateEvents = faker.randomGenerator.boolean();
        final zoomLevel = faker.randomGenerator.decimal(range: 0.1, min: 5.0);
        
        // Test: Create configuration
        final config = TimelineRenderConfig(
          viewMode: viewMode,
          startDate: startDate,
          endDate: endDate,
          activeContext: context,
          selectedEventIds: selectedEventIds,
          showPrivateEvents: showPrivateEvents,
          zoomLevel: zoomLevel,
        );
        
        // Verify: Configuration properties are set correctly
        expect(config.viewMode, equals(viewMode));
        expect(config.startDate, equals(startDate));
        expect(config.endDate, equals(endDate));
        expect(config.activeContext, equals(context));
        expect(config.selectedEventIds, equals(selectedEventIds));
        expect(config.showPrivateEvents, equals(showPrivateEvents));
        expect(config.zoomLevel, equals(zoomLevel));
        
        // Test: Copy with modifications
        final newViewMode = TimelineViewMode.values[faker.randomGenerator.integer(TimelineViewMode.values.length)];
        final copiedConfig = config.copyWith(viewMode: newViewMode);
        
        // Verify: Copy preserves other properties
        expect(copiedConfig.viewMode, equals(newViewMode));
        expect(copiedConfig.startDate, equals(startDate));
        expect(copiedConfig.endDate, equals(endDate));
        expect(copiedConfig.activeContext, equals(context));
        expect(copiedConfig.selectedEventIds, equals(selectedEventIds));
        expect(copiedConfig.showPrivateEvents, equals(showPrivateEvents));
        expect(copiedConfig.zoomLevel, equals(zoomLevel));
      }
    });

    test('Property: Timeline render data maintains data integrity', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random timeline data
        final events = List.generate(faker.randomGenerator.integer(10, min: 1), (_) => _generateRandomEvent());
        final contexts = List.generate(faker.randomGenerator.integer(3, min: 1), (_) => _generateRandomContext());
        final earliestDate = events.map((e) => e.occurredAt).reduce((a, b) => a.isBefore(b) ? a : b);
        final latestDate = events.map((e) => e.occurredAt).reduce((a, b) => a.isAfter(b) ? a : b);
        final clusteredEvents = _generateClusteredEvents(events);
        final metadata = {'test': faker.lorem.word()};
        
        // Test: Create render data
        final renderData = TimelineRenderData(
          events: events,
          contexts: contexts,
          earliestDate: earliestDate,
          latestDate: latestDate,
          clusteredEvents: clusteredEvents,
          metadata: metadata,
        );
        
        // Verify: Data integrity is maintained
        expect(renderData.events, equals(events));
        expect(renderData.contexts, equals(contexts));
        expect(renderData.earliestDate, equals(earliestDate));
        expect(renderData.latestDate, equals(latestDate));
        expect(renderData.clusteredEvents, equals(clusteredEvents));
        expect(renderData.metadata, equals(metadata));
        
        // Test: Copy with modifications
        final newEvents = List.generate(faker.randomGenerator.integer(5, min: 1), (_) => _generateRandomEvent());
        final copiedData = renderData.copyWith(events: newEvents);
        
        // Verify: Copy preserves other properties
        expect(copiedData.events, equals(newEvents));
        expect(copiedData.contexts, equals(contexts));
        expect(copiedData.earliestDate, equals(earliestDate));
        expect(copiedData.latestDate, equals(latestDate));
        expect(copiedData.clusteredEvents, equals(clusteredEvents));
        expect(copiedData.metadata, equals(metadata));
      }
    });

    test('Property: Timeline service manages renderers correctly', () async {
      // Run property test with 50 iterations (smaller due to async operations)
      for (int i = 0; i < 50; i++) {
        // Create mock renderers
        final renderers = List.generate(faker.randomGenerator.integer(3, min: 1), (index) {
          final viewMode = TimelineViewMode.values[index % TimelineViewMode.values.length];
          return _MockTimelineRenderer(
            TimelineRenderConfig(viewMode: viewMode),
            TimelineRenderData(
              events: [],
              contexts: [],
              earliestDate: DateTime.now(),
              latestDate: DateTime.now(),
              clusteredEvents: {},
            ),
          );
        });
        
        // Test: Register renderers
        for (final renderer in renderers) {
          timelineService.registerRenderer(renderer);
        }
        
        // Verify: All renderers are registered
        for (final renderer in renderers) {
          final foundRenderer = timelineService.getRenderer(renderer.config.viewMode);
          expect(foundRenderer, isNotNull);
          expect(foundRenderer, equals(renderer));
        }
        
        // Test: Update configuration
        final newConfig = TimelineRenderConfig(
          viewMode: TimelineViewMode.values[faker.randomGenerator.integer(TimelineViewMode.values.length)],
          startDate: faker.date.dateTime(),
        );
        await timelineService.updateConfig(newConfig);
        
        // Verify: Configuration was updated
        expect(timelineService.currentConfig, equals(newConfig));
        
        // Test: Unregister renderers
        for (final renderer in renderers) {
          timelineService.unregisterRenderer(renderer);
        }
        
        // Verify: Renderers are unregistered
        for (final renderer in renderers) {
          final foundRenderer = timelineService.getRenderer(renderer.config.viewMode);
          expect(foundRenderer, isNull);
        }
      }
    });

    test('Property: Timeline service handles event operations correctly', () async {
      // Run property test with 50 iterations
      for (int i = 0; i < 50; i++) {
        // Generate random events
        final events = List.generate(faker.randomGenerator.integer(5, min: 1), (_) => _generateRandomEvent());
        
        // Test: Add events
        await timelineService.addEvents(events);
        
        // Verify: Events were added
        expect(timelineService.events.length, greaterThanOrEqualTo(events.length));
        for (final event in events) {
          expect(timelineService.events, contains(event));
        }
        
        // Test: Update an event
        final eventToUpdate = timelineService.events.first;
        final updatedEvent = eventToUpdate.copyWith(
          title: faker.lorem.sentence(),
          description: faker.lorem.paragraph(),
        );
        await timelineService.updateEvent(updatedEvent);
        
        // Verify: Event was updated
        final foundEvent = timelineService.events.firstWhere((e) => e.id == updatedEvent.id);
        expect(foundEvent.title, equals(updatedEvent.title));
        expect(foundEvent.description, equals(updatedEvent.description));
        
        // Test: Remove events
        final eventsToRemove = timelineService.events.take(faker.randomGenerator.integer(3, min: 1)).map((e) => e.id).toList();
        await timelineService.removeEvents(eventsToRemove);
        
        // Verify: Events were removed
        for (final eventId in eventsToRemove) {
          expect(timelineService.events.any((e) => e.id == eventId), isFalse);
        }
        
        // Clean up for next iteration
        final allEventIds = timelineService.events.map((e) => e.id).toList();
        if (allEventIds.isNotEmpty) {
          await timelineService.removeEvents(allEventIds);
        }
      }
    });

    test('Property: Timeline service provides accurate statistics', () async {
      // Run property test with 50 iterations
      for (int i = 0; i < 50; i++) {
        // Generate random data
        final events = List.generate(faker.randomGenerator.integer(10, min: 1), (_) => _generateRandomEvent());
        final contexts = List.generate(faker.randomGenerator.integer(3, min: 1), (_) => _generateRandomContext());
        
        // Add data to service
        await timelineService.addEvents(events);
        await timelineService.addContexts(contexts);
        
        // Test: Get statistics
        final stats = timelineService.getStatistics();
        
        // Verify: Statistics are accurate
        expect(stats['totalEvents'], equals(events.length));
        expect(stats['totalContexts'], equals(contexts.length));
        expect(stats['dateRange'], isNotNull);
        expect(stats['eventsPerContext'], isNotNull);
        expect(stats['eventsPerYear'], isNotNull);
        
        // Verify date range
        final dateRange = stats['dateRange'] as Map<String, dynamic>;
        final eventDates = events.map((e) => e.occurredAt).toList();
        eventDates.sort();
        expect(dateRange['start'], equals(eventDates.first));
        expect(dateRange['end'], equals(eventDates.last));
        
        // Clean up for next iteration
        await timelineService.removeEvents(events.map((e) => e.id).toList());
        await timelineService.removeContexts(contexts.map((c) => c.id).toList());
      }
    });
  });
}

/// Mock timeline renderer for testing
class _MockTimelineRenderer extends BaseTimelineRenderer {
  _MockTimelineRenderer(super.config, super.data);

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return Container(
      child: Text('Mock Renderer: ${config.viewMode}'),
    );
  }
}

/// Generate a random timeline event for testing
TimelineEvent _generateRandomEvent() {
  final faker = Faker();
  final uuid = const Uuid();
  
  return TimelineEvent(
    id: uuid.v4(),
    contextId: uuid.v4(),
    ownerId: uuid.v4(),
    timestamp: faker.date.dateTime(),
    eventType: faker.lorem.word(),
    customAttributes: {
      for (int i = 0; i < faker.randomGenerator.integer(3, min: 0); i++)
        faker.lorem.word(): faker.lorem.sentence(),
    },
    assets: [],
    title: faker.lorem.sentence(),
    description: faker.lorem.paragraph(),
    participantIds: [],
    privacyLevel: PrivacyLevel.values[faker.randomGenerator.integer(PrivacyLevel.values.length)],
    createdAt: faker.date.dateTime(),
    updatedAt: faker.date.dateTime(),
  );
}

/// Generate a random context for testing
Context _generateRandomContext() {
  final faker = Faker();
  final uuid = const Uuid();
  
  return Context(
    id: uuid.v4(),
    ownerId: uuid.v4(),
    name: faker.person.name(),
    type: ContextType.values[faker.randomGenerator.integer(ContextType.values.length)],
    themeId: uuid.v4(),
    moduleConfiguration: {
      for (int i = 0; i < faker.randomGenerator.integer(3, min: 0); i++)
        faker.lorem.word(): faker.randomGenerator.boolean(),
    },
    createdAt: faker.date.dateTime(),
    updatedAt: faker.date.dateTime(),
  );
}

/// Generate clustered events for testing
Map<String, List<TimelineEvent>> _generateClusteredEvents(List<TimelineEvent> events) {
  final clustered = <String, List<TimelineEvent>>{};
  
  for (final event in events) {
    final clusterId = event.id;
    clustered[clusterId] = [event];
  }
  
  return clustered;
}
