import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/user.dart';

/// Timeline visualization modes supported by the renderer
enum TimelineViewMode {
  lifeStream,
  mapView,
  bentoGrid,
  chronological,
  clustered,
  story,
  river,
}

/// Configuration for timeline rendering
class TimelineRenderConfig {
  final TimelineViewMode viewMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final Context? activeContext;
  final Set<String> selectedEventIds;
  final bool showPrivateEvents;
  final double? zoomLevel;
  final Map<String, dynamic> customSettings;

  const TimelineRenderConfig({
    required this.viewMode,
    this.startDate,
    this.endDate,
    this.activeContext,
    this.selectedEventIds = const {},
    this.showPrivateEvents = true,
    this.zoomLevel,
    this.customSettings = const {},
  });

  TimelineRenderConfig copyWith({
    TimelineViewMode? viewMode,
    DateTime? startDate,
    DateTime? endDate,
    Context? activeContext,
    Set<String>? selectedEventIds,
    bool? showPrivateEvents,
    double? zoomLevel,
    Map<String, dynamic>? customSettings,
  }) {
    return TimelineRenderConfig(
      viewMode: viewMode ?? this.viewMode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activeContext: activeContext ?? this.activeContext,
      selectedEventIds: selectedEventIds ?? this.selectedEventIds,
      showPrivateEvents: showPrivateEvents ?? this.showPrivateEvents,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Data model for timeline rendering information
class TimelineRenderData {
  final List<TimelineEvent> events;
  final List<Context> contexts;
  final DateTime earliestDate;
  final DateTime latestDate;
  final Map<String, List<TimelineEvent>> clusteredEvents;
  final Map<String, dynamic> metadata;

  const TimelineRenderData({
    required this.events,
    required this.contexts,
    required this.earliestDate,
    required this.latestDate,
    required this.clusteredEvents,
    this.metadata = const {},
  });

  TimelineRenderData copyWith({
    List<TimelineEvent>? events,
    List<Context>? contexts,
    DateTime? earliestDate,
    DateTime? latestDate,
    Map<String, List<TimelineEvent>>? clusteredEvents,
    Map<String, dynamic>? metadata,
  }) {
    return TimelineRenderData(
      events: events ?? this.events,
      contexts: contexts ?? this.contexts,
      earliestDate: earliestDate ?? this.earliestDate,
      latestDate: latestDate ?? this.latestDate,
      clusteredEvents: clusteredEvents ?? this.clusteredEvents,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Callback for timeline interactions
typedef TimelineEventCallback = void Function(TimelineEvent event);
typedef TimelineDateCallback = void Function(DateTime date);
typedef TimelineContextCallback = void Function(Context context);

/// Interface for timeline visualization renderers
abstract class ITimelineRenderer {
  /// Current configuration for this renderer
  TimelineRenderConfig get config;
  
  /// Current data being rendered
  TimelineRenderData get data;
  
  /// Whether the renderer is ready to display
  bool get isReady;
  
  /// Initialize the renderer with configuration
  Future<void> initialize(TimelineRenderConfig config);
  
  /// Update the data to be rendered
  Future<void> updateData(TimelineRenderData data);
  
  /// Update configuration without rebuilding data
  Future<void> updateConfig(TimelineRenderConfig config);
  
  /// Build the widget for this timeline view
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  });
  
  /// Navigate to a specific date in the timeline
  Future<void> navigateToDate(DateTime date);
  
  /// Navigate to a specific event
  Future<void> navigateToEvent(String eventId);
  
  /// Get visible events in current viewport
  List<TimelineEvent> getVisibleEvents();
  
  /// Get date range currently visible
  DateTimeRange? getVisibleDateRange();
  
  /// Zoom in/out (for supported views)
  Future<void> setZoomLevel(double level);
  
  /// Export current view as image (for supported views)
  Future<Uint8List?> exportAsImage();
  
  /// Dispose resources
  void dispose();
}

/// Base implementation providing common functionality
abstract class BaseTimelineRenderer implements ITimelineRenderer {
  TimelineRenderConfig _config;
  TimelineRenderData _data;
  bool _isReady = false;

  BaseTimelineRenderer(this._config, this._data);

  @override
  TimelineRenderConfig get config => _config;

  @override
  TimelineRenderData get data => _data;

  @override
  bool get isReady => _isReady;

  @override
  Future<void> initialize(TimelineRenderConfig config) async {
    _config = config;
    _isReady = true;
    await onConfigUpdated();
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    _data = data;
    await onDataUpdated();
  }

  @override
  Future<void> updateConfig(TimelineRenderConfig config) async {
    _config = config;
    await onConfigUpdated();
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Default implementation - override in subclasses
    _config = _config.copyWith(startDate: date);
    await onConfigUpdated();
  }

  @override
  Future<void> navigateToEvent(String eventId) async {
    final event = _data.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Event not found: $eventId'),
    );
    await navigateToDate(event.timestamp);
  }

  @override
  List<TimelineEvent> getVisibleEvents() {
    // Default implementation - return all events
    // Override in subclasses for viewport-specific filtering
    return _data.events;
  }

  @override
  DateTimeRange? getVisibleDateRange() {
    if (_data.events.isEmpty) return null;
    
    final dates = _data.events.map((e) => e.timestamp).toList();
    dates.sort();
    
    return DateTimeRange(
      start: dates.first,
      end: dates.last,
    );
  }

  @override
  Future<void> setZoomLevel(double level) async {
    _config = _config.copyWith(zoomLevel: level);
    await onConfigUpdated();
  }

  @override
  Future<Uint8List?> exportAsImage() async {
    // Default implementation - not supported
    return null;
  }

  @override
  void dispose() {
    _isReady = false;
  }

  /// Hook called when data is updated
  Future<void> onDataUpdated() async {}

  /// Hook called when configuration is updated
  Future<void> onConfigUpdated() async {}

  /// Filter events based on current configuration
  List<TimelineEvent> filterEvents(List<TimelineEvent> events) {
    var filtered = <TimelineEvent>[];

    for (final event in events) {
      // Date range filtering
      if (_config.startDate != null && event.timestamp.isBefore(_config.startDate!)) {
        continue;
      }
      if (_config.endDate != null && event.timestamp.isAfter(_config.endDate!)) {
        continue;
      }

      // Context filtering
      if (_config.activeContext != null && event.contextId != _config.activeContext!.id) {
        continue;
      }

      // Privacy filtering
      if (!_config.showPrivateEvents && event.privacyLevel == PrivacyLevel.private) {
        continue;
      }

      filtered.add(event);
    }

    return filtered;
  }
}


/// Layout options for Story View
enum StoryLayout {
  fullscreen,
  split,
  carousel,
}

/// Types of clustering for events
enum ClusterType {
  location,
  time,
  semantic,
  person,
}
