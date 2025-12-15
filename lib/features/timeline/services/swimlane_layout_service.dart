import 'dart:math';
import 'package:flutter/widgets.dart';
import '../../../shared/models/timeline_event.dart';

/// Represents a positioned item in the swimlane layout
class SwimlaneLayoutItem {
  final TimelineEvent event;
  final Rect rect;
  final int startLaneIndex;
  final int endLaneIndex;
  final bool isBridge;

  const SwimlaneLayoutItem({
    required this.event,
    required this.rect,
    required this.startLaneIndex,
    required this.endLaneIndex,
    required this.isBridge,
  });
}

/// Service to calculate layout for swimlanes
class SwimlaneLayoutService {
  static const double kLaneHeight = 200.0;
  static const double kEventWidth = 280.0;
  static const double kEventHeight = 160.0;
  static const double kBridgePadding = 20.0;
  
  /// Calculate layout for events across swimlanes
  List<SwimlaneLayoutItem> calculateLayout({
    required List<TimelineEvent> events,
    required List<String> laneOwnerIds,
    required DateTime startDate,
    required double pixelsPerDay,
  }) {
    final items = <SwimlaneLayoutItem>[];
    
    for (final event in events) {
      // Determine participating lanes
      final participants = _getParticipants(event, laneOwnerIds);
      if (participants.isEmpty) continue; // Skip if no relevant participants
      
      final minLane = participants.reduce(min);
      final maxLane = participants.reduce(max);
      final isBridge = participants.length > 1;
      
      // Calculate X Position (Horizontal Time)
      final daysDiff = event.timestamp.difference(startDate).inDays;
      final x = daysDiff * pixelsPerDay;
      
      // Calculate Y Position and Height
      final y = minLane * kLaneHeight + (kLaneHeight - kEventHeight) / 2;
      double height = kEventHeight;
      
      if (isBridge) {
        // Bridge card spans from top of min lane to bottom of max lane (minus padding)
        final topY = minLane * kLaneHeight + kBridgePadding;
        final bottomY = (maxLane + 1) * kLaneHeight - kBridgePadding;
        height = bottomY - topY;
        
        items.add(SwimlaneLayoutItem(
          event: event,
          rect: Rect.fromLTWH(x, topY, kEventWidth, height),
          startLaneIndex: minLane,
          endLaneIndex: maxLane,
          isBridge: true,
        ));
      } else {
        // Standard card in single lane
        items.add(SwimlaneLayoutItem(
          event: event,
          rect: Rect.fromLTWH(x, y, kEventWidth, height),
          startLaneIndex: minLane,
          endLaneIndex: minLane,
          isBridge: false,
        ));
      }
    }
    
    // Simple collision resolution (shift overlapping events to right)
    _resolveCollisions(items);
    
    return items;
  }
  
  List<int> _getParticipants(TimelineEvent event, List<String> laneOwnerIds) {
    final indices = <int>{};
    
    // Owner always participates
    final ownerIndex = laneOwnerIds.indexOf(event.ownerId);
    if (ownerIndex != -1) indices.add(ownerIndex);
    
    // Check other participants
    for (final pid in event.participantIds) {
      final idx = laneOwnerIds.indexOf(pid);
      if (idx != -1) indices.add(idx);
    }
    
    return indices.toList()..sort();
  }
  
  void _resolveCollisions(List<SwimlaneLayoutItem> items) {
    // Sort by X position
    items.sort((a, b) => a.rect.left.compareTo(b.rect.left));
    
    // Group by lane (bridges affect multiple lanes)
    // Detailed collision is complex. For now, simple strict horizontal stacking.
    // If two events overlap in X and share ANY lane, shift the later one.
    
    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        final itemA = items[i];
        final itemB = items[j];
        
        // Check X overlap
        if (itemA.rect.right > itemB.rect.left) {
          // Check Lane overlap
          if (_lanesOverlap(itemA, itemB)) {
             // Shift B to right
             final shift = itemA.rect.right - itemB.rect.left + 20.0;
             final newRect = itemB.rect.shift(Offset(shift, 0));
             
             // Update itemB (need to replace in list or use mutable wrapper)
             // Since internal fields final, replace
             items[j] = SwimlaneLayoutItem(
               event: itemB.event,
               rect: newRect,
               startLaneIndex: itemB.startLaneIndex,
               endLaneIndex: itemB.endLaneIndex,
               isBridge: itemB.isBridge,
             );
          }
        } else {
          // Sorted by X, so if no overlap with current interaction, subsequent ones might
          // But actually if A.right < B.left, we are good for A vs B.
          // Optimization: break? No, B might be far but C close? No, sorted by left.
          // If B.left >= A.right, then all subsequent items are also right of A.
          // But we are modifying B's usage.
          break; 
        }
      }
    }
  }
  
  bool _lanesOverlap(SwimlaneLayoutItem a, SwimlaneLayoutItem b) {
    return max(a.startLaneIndex, b.startLaneIndex) <= min(a.endLaneIndex, b.endLaneIndex);
  }
}
