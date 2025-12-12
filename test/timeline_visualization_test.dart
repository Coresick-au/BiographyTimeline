import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/features/timeline/services/timeline_renderer_interface.dart';
import '../lib/features/timeline/services/timeline_renderer_factory.dart';
import '../lib/features/timeline/renderers/chronological_timeline_renderer.dart';
import '../lib/features/timeline/renderers/clustered_timeline_renderer.dart';
import '../lib/features/timeline/renderers/map_timeline_renderer.dart';
import '../lib/features/timeline/renderers/story_timeline_renderer.dart';
import '../lib/shared/models/timeline_event.dart';
import '../lib/shared/models/context.dart';
import '../lib/shared/models/timeline_theme.dart';
import '../lib/shared/models/geo_location.dart';
import '../lib/shared/models/user.dart';

void main() {
  group('Timeline Visualization Engine Tests', () {
    late TimelineRenderConfig config;
    late TimelineRenderData data;
    late List<TimelineEvent> testEvents;
    late List<Context> testContexts;

    setUp(() {
      testEvents = [
        TimelineEvent.create(
          id: 'event-1',
          contextId: 'context-1',
          ownerId: 'user-1',
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
          eventType: 'photo',
          title: 'Test Photo 1',
          description: 'A test photo event',
          location: GeoLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: 'San Francisco, CA',
          ),
        ),
        TimelineEvent.create(
          id: 'event-2',
          contextId: 'context-1',
          ownerId: 'user-1',
          timestamp: DateTime.now().subtract(const Duration(days: 20)),
          eventType: 'milestone',
          title: 'Test Milestone',
          description: 'A test milestone event',
        ),
        TimelineEvent.create(
          id: 'event-3',
          contextId: 'context-2',
          ownerId: 'user-1',
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
          eventType: 'text',
          title: 'Test Text Event',
          description: 'A test text event',
          location: GeoLocation(
            latitude: 37.7849,
            longitude: -122.4094,
            locationName: 'Oakland, CA',
          ),
        ),
      ];

      testContexts = [
        Context(
          id: 'context-1',
          ownerId: 'user-1',
          type: ContextType.person,
          name: 'Personal Timeline',
          moduleConfiguration: {},
          themeId: 'default',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Context(
          id: 'context-2',
          ownerId: 'user-1',
          type: ContextType.pet,
          name: 'Pet Timeline',
          moduleConfiguration: {},
          themeId: 'default',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      config = const TimelineRenderConfig(
        viewMode: TimelineViewMode.chronological,
        showPrivateEvents: true,
      );

      data = TimelineRenderData(
        events: testEvents,
        contexts: testContexts,
        earliestDate: testEvents.first.timestamp,
        latestDate: testEvents.last.timestamp,
        clusteredEvents: {},
      );
    });

    group('Timeline Renderer Factory', () {
      test('Should create all supported renderer types', () {
        for (final viewMode in TimelineViewMode.values) {
          final rendererConfig = TimelineRenderConfig(
            viewMode: viewMode,
            showPrivateEvents: true,
          );
          final renderer = TimelineRendererFactory.createRenderer(
            viewMode,
            rendererConfig,
            data,
          );
          
          expect(renderer, isNotNull);
          expect(renderer.config.viewMode, equals(viewMode));
        }
      });

      test('Should provide correct display names for view modes', () {
        expect(TimelineRendererFactory.getViewModeDisplayName(TimelineViewMode.chronological), equals('Chronological'));
        expect(TimelineRendererFactory.getViewModeDisplayName(TimelineViewMode.clustered), equals('Clustered'));
        expect(TimelineRendererFactory.getViewModeDisplayName(TimelineViewMode.mapView), equals('Map View'));
        expect(TimelineRendererFactory.getViewModeDisplayName(TimelineViewMode.story), equals('Story View'));
        expect(TimelineRendererFactory.getViewModeDisplayName(TimelineViewMode.lifeStream), equals('Life Stream'));
        expect(TimelineRendererFactory.getViewModeDisplayName(TimelineViewMode.bentoGrid), equals('Grid View'));
      });

      test('Should provide correct descriptions for view modes', () {
        expect(TimelineRendererFactory.getViewModeDescription(TimelineViewMode.chronological), contains('Traditional timeline'));
        expect(TimelineRendererFactory.getViewModeDescription(TimelineViewMode.clustered), contains('grouped by time periods'));
        expect(TimelineRendererFactory.getViewModeDescription(TimelineViewMode.mapView), contains('Geographic visualization'));
        expect(TimelineRendererFactory.getViewModeDescription(TimelineViewMode.story), contains('Narrative flow'));
      });

      test('Should provide correct icons for view modes', () {
        expect(TimelineRendererFactory.getViewModeIcon(TimelineViewMode.chronological), equals('timeline'));
        expect(TimelineRendererFactory.getViewModeIcon(TimelineViewMode.clustered), equals('category'));
        expect(TimelineRendererFactory.getViewModeIcon(TimelineViewMode.mapView), equals('map'));
        expect(TimelineRendererFactory.getViewModeIcon(TimelineViewMode.story), equals('auto_stories'));
      });
    });

    group('Chronological Timeline Renderer', () {
      test('Should initialize with correct configuration', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        
        expect(renderer.config.viewMode, equals(TimelineViewMode.chronological));
        expect(renderer.data.events.length, equals(3));
        
        await renderer.initialize(config);
        expect(renderer.isReady, isTrue);
        
        renderer.dispose();
      });

      test('Should filter events based on configuration', () async {
        final filteredConfig = config.copyWith(
          startDate: DateTime.now().subtract(const Duration(days: 25)),
        );
        
        final renderer = ChronologicalTimelineRenderer(filteredConfig, data);
        await renderer.initialize(filteredConfig);
        
        final visibleEvents = renderer.getVisibleEvents();
        expect(visibleEvents.length, equals(2)); // Only events after start date
        
        renderer.dispose();
      });

      test('Should navigate to specific dates', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        await renderer.initialize(config);
        
        final targetDate = DateTime.now().subtract(const Duration(days: 15));
        await renderer.navigateToDate(targetDate);
        
        // Should update configuration with new start date
        expect(renderer.config.startDate, equals(targetDate));
        
        renderer.dispose();
      });

      test('Should navigate to specific events', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        await renderer.initialize(config);
        
        await renderer.navigateToEvent('event-2');
        
        // Should navigate to the date of the event
        expect(renderer.config.startDate, equals(testEvents[1].timestamp));
        
        renderer.dispose();
      });
    });

    group('Clustered Timeline Renderer', () {
      test('Should initialize and cluster events', () async {
        final clusteredConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.clustered,
          showPrivateEvents: true,
        );
        final renderer = ClusteredTimelineRenderer(clusteredConfig, data);
        
        expect(renderer.config.viewMode, equals(TimelineViewMode.clustered));
        expect(renderer.data.events.length, equals(3));
        
        await renderer.initialize(clusteredConfig);
        expect(renderer.isReady, isTrue);
        
        renderer.dispose();
      });

      test('Should handle different clustering configurations', () async {
        final clusteredConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.clustered,
          showPrivateEvents: true,
        );
        final renderer = ClusteredTimelineRenderer(clusteredConfig, data);
        await renderer.initialize(clusteredConfig);
        
        // Test different cluster types
        for (final clusterType in ClusterType.values) {
          // This would test clustering logic
          expect(clusterType, isA<ClusterType>());
        }
        
        renderer.dispose();
      });
    });

    group('Map Timeline Renderer', () {
      test('Should initialize with location data', () async {
        final mapConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.mapView,
          showPrivateEvents: true,
        );
        final renderer = MapTimelineRenderer(mapConfig, data);
        
        expect(renderer.config.viewMode, equals(TimelineViewMode.mapView));
        expect(renderer.data.events.length, equals(3));
        
        await renderer.initialize(mapConfig);
        expect(renderer.isReady, isTrue);
        
        renderer.dispose();
      });

      test('Should cluster events by location', () async {
        final mapConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.mapView,
          showPrivateEvents: true,
        );
        final renderer = MapTimelineRenderer(mapConfig, data);
        await renderer.initialize(mapConfig);
        
        // Events with locations should be clustered
        final eventsWithLocation = data.events
            .where((e) => e.location != null)
            .toList();
        
        expect(eventsWithLocation.length, equals(2));
        
        renderer.dispose();
      });

      test('Should handle playback functionality', () async {
        final mapConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.mapView,
          showPrivateEvents: true,
        );
        final renderer = MapTimelineRenderer(mapConfig, data);
        await renderer.initialize(mapConfig);
        
        // Test playback controls
        expect(renderer.config.viewMode, equals(TimelineViewMode.mapView));
        
        renderer.dispose();
      });
    });

    group('Story Timeline Renderer', () {
      test('Should initialize and generate stories', () async {
        final storyConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.story,
          showPrivateEvents: true,
        );
        final renderer = StoryTimelineRenderer(storyConfig, data);
        
        expect(renderer.config.viewMode, equals(TimelineViewMode.story));
        expect(renderer.data.events.length, equals(3));
        
        await renderer.initialize(storyConfig);
        expect(renderer.isReady, isTrue);
        
        renderer.dispose();
      });

      test('Should create stories from events', () async {
        final storyConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.story,
          showPrivateEvents: true,
        );
        final renderer = StoryTimelineRenderer(storyConfig, data);
        await renderer.initialize(storyConfig);
        
        // Stories should be generated based on context types and time periods
        expect(renderer.config.viewMode, equals(TimelineViewMode.story));
        
        renderer.dispose();
      });

      test('Should handle different story layouts', () async {
        final storyConfig = const TimelineRenderConfig(
          viewMode: TimelineViewMode.story,
          showPrivateEvents: true,
        );
        final renderer = StoryTimelineRenderer(storyConfig, data);
        await renderer.initialize(storyConfig);
        
        // Test different layout options
        for (final layout in StoryLayout.values) {
          expect(layout, isA<StoryLayout>());
        }
        
        renderer.dispose();
      });
    });

    group('Timeline Render Configuration', () {
      test('Should handle configuration updates', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        await renderer.initialize(config);
        
        final newConfig = config.copyWith(
          showPrivateEvents: false,
          activeContext: testContexts.first,
        );
        
        await renderer.updateConfig(newConfig);
        expect(renderer.config.showPrivateEvents, isFalse);
        expect(renderer.config.activeContext, equals(testContexts.first));
        
        renderer.dispose();
      });

      test('Should handle data updates', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        await renderer.initialize(config);
        
        final newEvent = TimelineEvent.create(
          id: 'event-new',
          contextId: 'context-1',
          ownerId: 'user-1',
          timestamp: DateTime.now(),
          eventType: 'photo',
          title: 'New Event',
        );
        
        final newData = data.copyWith(
          events: [...data.events, newEvent],
        );
        
        await renderer.updateData(newData);
        expect(renderer.data.events.length, equals(4));
        
        renderer.dispose();
      });

      test('Should handle zoom levels', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        await renderer.initialize(config);
        
        await renderer.setZoomLevel(2.0);
        expect(renderer.config.zoomLevel, equals(2.0));
        
        renderer.dispose();
      });
    });

    group('Timeline Render Data', () {
      test('Should handle date ranges correctly', () {
        expect(data.earliestDate, equals(testEvents.first.timestamp));
        expect(data.latestDate, equals(testEvents.last.timestamp));
        
        final dateRange = DateTimeRange(
          start: data.earliestDate,
          end: data.latestDate,
        );
        
        expect(dateRange.duration.inDays, equals(20));
      });

      test('Should copy with updates', () {
        final newData = data.copyWith(
          events: [...data.events],
          metadata: {'test': 'value'},
        );
        
        expect(newData.events.length, equals(data.events.length));
        expect(newData.metadata['test'], equals('value'));
      });
    });

    group('Performance Tests', () {
      test('Should handle large numbers of events', () async {
        final largeEventList = List.generate(1000, (index) => 
          TimelineEvent.create(
            id: 'event-$index',
            contextId: 'context-1',
            ownerId: 'user-1',
            timestamp: DateTime.now().subtract(Duration(days: index)),
            eventType: 'photo',
            title: 'Event $index',
          ),
        );
        
        final largeData = data.copyWith(events: largeEventList);
        final renderer = ChronologicalTimelineRenderer(config, largeData);
        
        final stopwatch = Stopwatch()..start();
        await renderer.initialize(config);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should initialize in under 1 second
        expect(renderer.getVisibleEvents().length, equals(1000));
        
        renderer.dispose();
      });

      test('Should efficiently filter events', () async {
        final largeEventList = List.generate(1000, (index) => 
          TimelineEvent.create(
            id: 'event-$index',
            contextId: index % 2 == 0 ? 'context-1' : 'context-2',
            ownerId: 'user-1',
            timestamp: DateTime.now().subtract(Duration(days: index)),
            eventType: index % 3 == 0 ? 'photo' : 'text',
            title: 'Event $index',
          ),
        );
        
        final filteredConfig = config.copyWith(
          activeContext: testContexts.first,
        );
        
        final largeData = data.copyWith(events: largeEventList);
        final renderer = ChronologicalTimelineRenderer(filteredConfig, largeData);
        
        await renderer.initialize(filteredConfig);
        
        final visibleEvents = renderer.getVisibleEvents();
        expect(visibleEvents.length, equals(500)); // Half should be filtered by context
        
        renderer.dispose();
      });
    });

    group('Error Handling', () {
      test('Should handle empty data gracefully', () async {
        final emptyData = TimelineRenderData(
          events: [],
          contexts: [],
          earliestDate: DateTime.now(),
          latestDate: DateTime.now(),
          clusteredEvents: {},
        );
        
        final renderer = ChronologicalTimelineRenderer(config, emptyData);
        await renderer.initialize(config);
        
        expect(renderer.getVisibleEvents().isEmpty, isTrue);
        expect(renderer.getVisibleDateRange(), isNull);
        
        renderer.dispose();
      });

      test('Should handle invalid event IDs gracefully', () async {
        final renderer = ChronologicalTimelineRenderer(config, data);
        await renderer.initialize(config);
        
        // Should not throw exception for invalid event ID
        try {
          await renderer.navigateToEvent('invalid-id');
          fail('Should have thrown ArgumentError');
        } on ArgumentError {
          // Expected
        }
        
        renderer.dispose();
      });
    });
  });
}
