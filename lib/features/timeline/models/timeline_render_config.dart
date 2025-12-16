import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Configuration for timeline rendering
class TimelineRenderConfig {
  final TimelineTheme theme;
  final TimelineViewMode viewMode;
  final bool showPrivateEvents;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String>? filterTags;
  final Set<String> selectedEventIds;
  final double zoomLevel;
  final Map<String, dynamic> customSettings;

  const TimelineRenderConfig({
    required this.theme,
    required this.viewMode,
    required this.showPrivateEvents,
    this.startDate,
    this.endDate,
    this.filterTags,
    this.selectedEventIds = const {},
    this.zoomLevel = 1.0,
    this.customSettings = const {},
  });

  factory TimelineRenderConfig.defaults() {
    return const TimelineRenderConfig(
      theme: TimelineTheme.defaultTheme, // Assuming a default theme is needed
      viewMode: TimelineViewMode.chronological,
      startDate: null,
      endDate: null,
      filterTags: null,
      selectedEventIds: {},
      showPrivateEvents: false,
      zoomLevel: 1.0,
      customSettings: {},
    );
  }
}

/// Timeline view modes
enum TimelineViewMode {
  chronological,
  river,
  grid,
  enhanced,
}

/// Timeline theme configuration
class TimelineTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color eventColor;
  final Color textColor;
  final double eventSpacing;
  final double lineWidth;

  const TimelineTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.eventColor,
    required this.textColor,
    required this.eventSpacing,
    required this.lineWidth,
  });

  static const TimelineTheme defaultTheme = TimelineTheme(
    primaryColor: Colors.blue,
    backgroundColor: Colors.white,
    eventColor: Colors.lightBlue,
    textColor: Colors.black,
    eventSpacing: 16.0,
    lineWidth: 2.0,
  );
}

/// Timeline render data wrapper
class TimelineRenderData {
  final List<TimelineEvent> events;
  final List<Context> contexts;
  final TimelineRenderConfig config;
  final DateTime earliestDate;
  final DateTime latestDate;
  final Map<String, List<TimelineEvent>> clusteredEvents;
  
  const TimelineRenderData({
    required this.events,
    required this.contexts,
    required this.config,
    required this.earliestDate,
    required this.latestDate,
    required this.clusteredEvents,
  });
}
