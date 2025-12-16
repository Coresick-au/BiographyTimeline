import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';

/// Represents a person's "river" stream in the visualization
class RiverFlowPath {
  final String personId;
  final String personName;
  final Path path;
  final Color color;
  final List<RiverFlowNode> nodes;
  final Offset originPosition;

  const RiverFlowPath({
    required this.personId,
    required this.personName,
    required this.path,
    required this.color,
    required this.nodes,
    required this.originPosition,
  });
}

/// Represents a node (event) on a river stream
class RiverFlowNode {
  final TimelineEvent event;
  final Offset position;
  final bool isJunction;
  final List<String> participantIds;
  final String? thumbnailPath; // First asset from event if available

  const RiverFlowNode({
    required this.event,
    required this.position,
    required this.isJunction,
    required this.participantIds,
    this.thumbnailPath,
  });
}

/// Represents an intersection where multiple streams meet
class RiverFlowIntersection {
  final Offset position;
  final TimelineEvent event;
  final List<String> participantIds;

  const RiverFlowIntersection({
    required this.position,
    required this.event,
    required this.participantIds,
  });
}

/// Configuration for river flow rendering
class RiverFlowConfig {
  final double laneWidth;
  final double pixelsPerDay;
  final double streamWidth;
  final double glowIntensity;
  final bool showLabels;
  final bool showIntersectionCards;

  const RiverFlowConfig({
    this.laneWidth = 150.0,
    this.pixelsPerDay = 3.0,
    this.streamWidth = 4.0,
    this.glowIntensity = 1.0,
    this.showLabels = true,
    this.showIntersectionCards = true,
  });
}

/// Vibrant neon color palette for streams
class RiverFlowColors {
  static const List<Color> streamColors = [
    Color(0xFF3B82F6), // Electric Blue
    Color(0xFFEC4899), // Hot Pink
    Color(0xFF22C55E), // Lime Green
    Color(0xFFF97316), // Sunset Orange
    Color(0xFFA855F7), // Electric Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFFFACC15), // Yellow
  ];

  static Color getColorForPerson(String personId, int index) {
    return streamColors[index % streamColors.length];
  }

  static Color getColorFromHash(String personId) {
    final hash = personId.hashCode.abs();
    return streamColors[hash % streamColors.length];
  }
}

/// Extension to extract unique participants from events
extension EventParticipantExtraction on List<TimelineEvent> {
  /// Get all unique person IDs from events (owners + participants)
  Set<String> get allParticipantIds {
    final ids = <String>{};
    for (final event in this) {
      ids.add(event.ownerId);
      ids.addAll(event.participantIds);
    }
    return ids;
  }

  /// Get events where a specific person is involved
  List<TimelineEvent> eventsForPerson(String personId) {
    return where((e) => 
      e.ownerId == personId || e.participantIds.contains(personId)
    ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get events shared between multiple people
  List<TimelineEvent> sharedEvents(List<String> personIds) {
    if (personIds.length < 2) return [];
    return where((e) {
      final eventPeople = {e.ownerId, ...e.participantIds};
      int matchCount = personIds.where((id) => eventPeople.contains(id)).length;
      return matchCount >= 2;
    }).toList();
  }
}
