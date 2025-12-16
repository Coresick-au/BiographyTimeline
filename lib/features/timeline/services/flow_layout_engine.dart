import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../models/river_flow_models.dart';

/// Layout engine for the RiverFlow visualization
/// Calculates vertical bezier paths for each person's stream over time.
class RiverFlowLayoutEngine {
  static const double kDefaultLaneWidth = 150.0;
  static const double kDefaultPixelsPerDay = 3.0;
  static const double kHeaderHeight = 80.0; // Space for person info at top
  static const double kMinStreamSpacing = 40.0;

  /// Calculate river flow paths for selected people
  List<RiverFlowPath> calculateRiverPaths({
    required List<TimelineEvent> events,
    required List<String> selectedPersonIds,
    required DateTime startDate,
    required double pixelsPerDay,
    required double laneWidth,
    required double viewWidth,
  }) {
    print('DEBUG RiverFlow: calculateRiverPaths called');
    print('DEBUG RiverFlow: events.length = ${events.length}');
    print('DEBUG RiverFlow: selectedPersonIds = $selectedPersonIds');
    
    if (selectedPersonIds.isEmpty || events.isEmpty) {
      print('DEBUG RiverFlow: Empty events or no selected people - returning empty');
      return [];
    }

    final paths = <RiverFlowPath>[];
    final random = math.Random(42); // Deterministic randomness for weaving

    // Calculate lane positions (centered horizontally)
    final totalWidth = selectedPersonIds.length * laneWidth;
    final startX = (viewWidth - totalWidth) / 2 + laneWidth / 2;

    for (int laneIdx = 0; laneIdx < selectedPersonIds.length; laneIdx++) {
      final personId = selectedPersonIds[laneIdx];
      final personEvents = events.eventsForPerson(personId);

      print('DEBUG RiverFlow: Person $personId has ${personEvents.length} events');
      
      if (personEvents.isEmpty) continue;

      final path = Path();
      final nodes = <RiverFlowNode>[];

      // Base X position for this lane (stay vertical here)
      final baseLaneX = startX + laneIdx * laneWidth;
      
      // Calculate center X (where streams merge)
      final centerX = startX + (selectedPersonIds.length - 1) * laneWidth / 2;
      
      // Calculate color
      final color = RiverFlowColors.getColorForPerson(personId, laneIdx);

      Offset? lastPoint;
      bool wasJunction = false;
      
      // Origin point (top of stream)
      final originY = kHeaderHeight;
      final originX = baseLaneX;
      final originPosition = Offset(originX, originY);

      for (int i = 0; i < personEvents.length; i++) {
        final event = personEvents[i];

        // Calculate Y based on time (vertical flow)
        final daysDiff = event.timestamp.difference(startDate).inDays.toDouble();
        final y = kHeaderHeight + daysDiff * pixelsPerDay + 50;

        // Check if this is a junction (shared event)
        final eventParticipants = {event.ownerId, ...event.participantIds};
        final sharedWith = selectedPersonIds.where(
          (id) => id != personId && eventParticipants.contains(id)
        ).toList();
        final isJunction = sharedWith.isNotEmpty;

        // Calculate X position:
        // - Normal: stay in lane (baseLaneX)
        // - Junction: move toward center where streams merge
        double x;
        if (isJunction) {
          // Calculate shared center point among all participants
          double sharedCenterX = baseLaneX;
          int participantCount = 1;
          for (final sharedId in sharedWith) {
            final sharedIdx = selectedPersonIds.indexOf(sharedId);
            if (sharedIdx != -1) {
              sharedCenterX += startX + sharedIdx * laneWidth;
              participantCount++;
            }
          }
          x = sharedCenterX / participantCount;
        } else {
          // Stay vertical in own lane - NO weaving
          x = baseLaneX;
        }

        final currentPoint = Offset(x, y);

        // Get thumbnail
        String? thumbnailPath;
        if (event.assets.isNotEmpty) {
          final keyAsset = event.assets.firstWhere(
            (a) => a.isKeyAsset,
            orElse: () => event.assets.first,
          );
          thumbnailPath = keyAsset.localPath;
        }

        nodes.add(RiverFlowNode(
          event: event,
          position: currentPoint,
          isJunction: isJunction,
          participantIds: eventParticipants.toList(),
          thumbnailPath: thumbnailPath,
        ));

        if (i == 0) {
          // Start from origin - straight vertical line
          path.moveTo(originX, originY);
          if (isJunction) {
            // Angle inward to junction
            final midY = (originY + y) / 2;
            path.cubicTo(
              originX, midY,
              x, midY,
              x, y,
            );
          } else {
            // Straight down to first point
            path.lineTo(originX, y);
          }
        } else if (lastPoint != null) {
          // Drawing from lastPoint to currentPoint
          final midY = (lastPoint.dy + y) / 2;
          
          if (isJunction && !wasJunction) {
            // Entering a junction: angle INWARD from lane to center
            path.cubicTo(
              lastPoint.dx, midY,
              x, midY,
              x, y,
            );
          } else if (!isJunction && wasJunction) {
            // Leaving a junction: angle OUTWARD from center back to lane
            path.cubicTo(
              lastPoint.dx, midY,
              x, midY,
              x, y,
            );
          } else if (isJunction && wasJunction) {
            // HELIX EFFECT: Both points are junctions - create DNA spiral!
            // Phase offset: 180° apart for 2 people (like DNA double helix)
            final phaseOffset = laneIdx * math.pi; // 0, π, 2π, etc.
            
            // Helix parameters - wider, smoother
            const helixRadius = 35.0; // Width of the spiral
            
            // Distance between points
            final segmentHeight = y - lastPoint.dy;
            
            // Calculate how many waves based on segment height (1 wave per ~150px)
            final numWaves = (segmentHeight / 150).clamp(1.0, 5.0);
            
            // Draw smooth helix using bezier curves for each half-wave
            final waveHeight = segmentHeight / (numWaves * 2);
            var currentY = lastPoint.dy;
            var currentX = lastPoint.dx;
            
            for (int wave = 0; wave < (numWaves * 2).round(); wave++) {
              final nextY = currentY + waveHeight;
              // Alternate left/right based on wave number and phase
              final direction = ((wave + (phaseOffset ~/ math.pi)) % 2 == 0) ? 1.0 : -1.0;
              final peakX = x + (helixRadius * direction);
              
              // Smooth bezier curve for each half-wave
              path.quadraticBezierTo(
                peakX, currentY + waveHeight * 0.5,
                x, nextY,
              );
              
              currentY = nextY;
              currentX = x;
            }
            
            // Ensure we end exactly at the target
            if (currentY < y) {
              path.lineTo(x, y);
            }
          } else {
            // Normal: stay perfectly vertical in lane
            path.lineTo(x, y);
          }
        }

        lastPoint = currentPoint;
        wasJunction = isJunction;
      }

      // Extend stream beyond last event for visual continuity
      if (lastPoint != null) {
        final extendY = lastPoint.dy + 100;
        path.cubicTo(
          lastPoint.dx, lastPoint.dy + 30,
          baseLaneX, extendY - 30,
          baseLaneX, extendY,
        );
      }

      // Extract person name from events (use owner name if available)
      final personName = _getPersonName(personId, personEvents);

      paths.add(RiverFlowPath(
        personId: personId,
        personName: personName,
        path: path,
        color: color,
        nodes: nodes,
        originPosition: originPosition,
      ));
    }

    return paths;
  }

  /// Calculate the total content size needed
  Size calculateContentSize({
    required List<TimelineEvent> events,
    required List<String> selectedPersonIds,
    required DateTime startDate,
    required double pixelsPerDay,
    required double laneWidth,
    required double viewWidth,
  }) {
    if (events.isEmpty) return Size(viewWidth, 500);

    // Find latest event
    final latestEvent = events.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b
    );
    final daysDiff = latestEvent.timestamp.difference(startDate).inDays;
    final height = kHeaderHeight + daysDiff * pixelsPerDay + 200; // Padding

    final width = math.max(
      viewWidth,
      selectedPersonIds.length * laneWidth + 100,
    );

    return Size(width, height);
  }

  /// Find intersections between selected people's streams
  List<RiverFlowIntersection> findIntersections({
    required List<TimelineEvent> events,
    required List<String> selectedPersonIds,
  }) {
    if (selectedPersonIds.length < 2) return [];

    final intersections = <RiverFlowIntersection>[];

    for (final event in events) {
      final eventPeople = {event.ownerId, ...event.participantIds};
      final matchedPeople = selectedPersonIds.where(
        (id) => eventPeople.contains(id)
      ).toList();

      if (matchedPeople.length >= 2) {
        // This is an intersection event
        intersections.add(RiverFlowIntersection(
          position: Offset.zero, // Will be calculated during rendering
          event: event,
          participantIds: matchedPeople,
        ));
      }
    }

    return intersections;
  }

  String _getPersonName(String personId, List<TimelineEvent> events) {
    // For now, use a shortened version of the ID
    // In future, this would come from a Person/Contact model
    if (personId.length > 8) {
      return personId.substring(0, 8);
    }
    return personId;
  }
}
