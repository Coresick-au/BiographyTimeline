import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';

class FlowPath {
  final String ownerId;
  final Path path;
  final Color color;
  final List<FlowNode> nodes;

  const FlowPath({
    required this.ownerId,
    required this.path,
    required this.color,
    required this.nodes,
  });
}

class FlowNode {
  final TimelineEvent event;
  final Offset position;
  final bool isJunction; // Shared event

  const FlowNode({
    required this.event,
    required this.position,
    required this.isJunction,
  });
}

/// Layout engine for the Flow View (KinFlow style)
/// Calculates Bezier paths for each user's stream over time.
class FlowLayoutEngine {
  static const double kLaneHeight = 150.0;
  static const double kNodeRadius = 8.0;
  
  /// Calculate flow paths for all users
  List<FlowPath> calculateFlowPaths({
    required List<TimelineEvent> events,
    required List<String> laneOwnerIds,
    required DateTime startDate,
    required double pixelsPerDay,
  }) {
    final paths = <FlowPath>[];
    
    // Process each owner's stream independently (but meeting at shared events)
    for (int laneInx = 0; laneInx < laneOwnerIds.length; laneInx++) {
      final ownerId = laneOwnerIds[laneInx];
      final ownerEvents = events.where((e) => 
        e.ownerId == ownerId || e.participantIds.contains(ownerId)
      ).toList();
      
      // Sort by time
      ownerEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (ownerEvents.isEmpty) continue;

      final path = Path();
      final nodes = <FlowNode>[];
      
      Offset? lastPoint;
      
      for (int i = 0; i < ownerEvents.length; i++) {
        final event = ownerEvents[i];
        
        // Calculate X based on time
        final daysDiff = event.timestamp.difference(startDate).inDays;
        final x = daysDiff * pixelsPerDay;
        
        // Calculate Y. 
        // Logic: Standard Y is owner's lane center.
        // Shared events (junctions): Ideally pull towards a common center or keep in owner's lane 
        // but draw connection?
        // "Shared events = junction nodes where streams merge."
        // To implement merge, we need a shared Y for the shared event.
        // Let's position shared events at the weighted average Y of participants.
        
        double y = _calculateEventY(event, laneOwnerIds);
        
        final currentPoint = Offset(x, y);
        final isJunction = event.participantIds.length > 1 || 
                           (event.ownerId != ownerId && event.participantIds.contains(ownerId)); // Simple check

        nodes.add(FlowNode(
          event: event, 
          position: currentPoint,
          isJunction: isJunction,
        ));
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // Cubic Bezier to next point
          final midX = (lastPoint!.dx + x) / 2;
          path.cubicTo(
            midX, lastPoint.dy, // Control point 1 (flat exit)
            midX, y,            // Control point 2 (flat entry)
            x, y,
          );
        }
        
        lastPoint = currentPoint;
      }
      
      paths.add(FlowPath(
        ownerId: ownerId,
        path: path,
        color: _getOwnerColor(ownerId), // Helper color
        nodes: nodes,
      ));
    }
    
    return paths;
  }
  
  double _calculateEventY(TimelineEvent event, List<String> laneOwnerIds) {
    // If single owner, return lane center
    if (event.participantIds.length <= 1) {
       final ownerIdx = laneOwnerIds.indexOf(event.ownerId);
       return ownerIdx * kLaneHeight + kLaneHeight / 2;
    }
    
    // If shared, calculate average Y of all participants
    // This creates the visual effect of streams merging
    double totalY = 0;
    int count = 0;
    
    // Owner
    int idx = laneOwnerIds.indexOf(event.ownerId);
    if (idx != -1) {
      totalY += idx * kLaneHeight + kLaneHeight / 2;
      count++;
    }
    
    // Participants
    for (final pid in event.participantIds) {
      idx = laneOwnerIds.indexOf(pid);
      if (idx != -1) {
        totalY += idx * kLaneHeight + kLaneHeight / 2;
        count++;
      }
    }
    
    return count > 0 ? totalY / count : 0;
  }

  Color _getOwnerColor(String ownerId) {
    // Deterministic color
    final hash = ownerId.hashCode;
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFFEC4899), // Pink
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
    ];
    return colors[hash.abs() % colors.length];
  }
}
