import 'package:flutter/material.dart';
import '../models/render_node.dart';
import '../models/timeline_view_state.dart';
import '../../../shared/design_system/design_system.dart';

/// Custom painter for timeline axis, markers, and clusters
/// 
/// Draws the central axis line, event markers, cluster indicators,
/// and connection lines in an orientation-agnostic way.
class TimelinePainter extends CustomPainter {
  final List<LayoutNode> layoutNodes;
  final TimelineOrientation orientation;
  final TimelineDisplayMode displayMode;
  final String? selectedEventId;
  final ColorScheme colorScheme;
  
  TimelinePainter({
    required this.layoutNodes,
    required this.orientation,
    required this.displayMode,
    this.selectedEventId,
    required this.colorScheme,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    _drawAxis(canvas, size);
    _drawMarkers(canvas, size);
    if (displayMode == TimelineDisplayMode.maximal) {
      _drawConnectionLines(canvas, size);
    }
  }
  
  /// Draw the central timeline axis
  void _drawAxis(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    if (orientation == TimelineOrientation.vertical) {
      // Vertical line down the center
      final centerX = size.width / 2;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        axisPaint,
      );
    } else {
      // Horizontal line across the center
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        axisPaint,
      );
    }
  }
  
  /// Draw markers for events and clusters
  void _drawMarkers(Canvas canvas, Size size) {
    for (final layoutNode in layoutNodes) {
      final node = layoutNode.node;
      final center = layoutNode.markerCenter;
      
      // Skip if off-screen
      if (center.dx < 0 || center.dx > size.width ||
          center.dy < 0 || center.dy > size.height) {
        continue;
      }
      
      if (node is EventNode) {
        _drawEventMarker(canvas, center, node, node.eventId == selectedEventId);
      } else if (node is ClusterNode) {
        _drawClusterMarker(canvas, center, node);
      }
      
      // Draw label if visible
      if (layoutNode.isLabelVisible && displayMode == TimelineDisplayMode.minimal) {
        _drawLabel(canvas, center, node.label);
      }
    }
  }
  
  /// Draw event marker with tier-based sizing
  void _drawEventMarker(Canvas canvas, Offset center, EventNode node, bool isSelected) {
    // Tier-based sizing: larger markers for higher-level nodes
    final tierMultiplier = _getTierSizeMultiplier(node.tier);
    final baseSize = 10.0;
    final markerSize = (isSelected ? baseSize + 4 : baseSize) * tierMultiplier;
    final color = _getEventTypeColor(node.type);
    
    // Outer glow (more prominent for higher tiers or selection)
    if (isSelected || node.tier == ZoomTier.year || node.tier == ZoomTier.month) {
      final glowPaint = Paint()
        ..color = color.withOpacity(isSelected ? 0.4 : 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, markerSize + (isSelected ? 6 : 3), glowPaint);
    }
    
    // Main marker circle
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, markerSize, markerPaint);
    
    // Border ring for emphasis on higher tiers
    if (node.tier == ZoomTier.year || node.tier == ZoomTier.month) {
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, markerSize - 1, borderPaint);
    }
    
    // Inner dot (proportional to marker size)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, markerSize / 3, innerPaint);
  }
  
  /// Get size multiplier based on zoom tier
  double _getTierSizeMultiplier(ZoomTier tier) {
    switch (tier) {
      case ZoomTier.year:
        return 1.6;
      case ZoomTier.month:
        return 1.3;
      case ZoomTier.week:
        return 1.1;
      case ZoomTier.day:
        return 1.0;
      case ZoomTier.focus:
        return 1.2;
    }
  }
  
  /// Draw cluster marker with tier hierarchy
  void _drawClusterMarker(Canvas canvas, Offset center, ClusterNode node) {
    // Tier-based sizing for clusters too
    final tierMultiplier = _getTierSizeMultiplier(node.tier);
    final baseSize = 16.0;
    final markerSize = baseSize * tierMultiplier;
    final color = _getEventTypeColor(node.dominantType);
    
    // Outer glow for visual prominence
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, markerSize + 4, glowPaint);
    
    // Cluster background
    final bgPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, markerSize, bgPaint);
    
    // Cluster border (thicker for higher tiers)
    final borderWidth = node.tier == ZoomTier.year ? 3.0 : 2.0;
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, markerSize, borderPaint);
    
    // Count text (scaled with tier)
    final fontSize = 10.0 * tierMultiplier;
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.count.toString(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
  
  /// Draw connection lines from markers to cards
  void _drawConnectionLines(Canvas canvas, Size size) {
    for (final layoutNode in layoutNodes) {
      if (layoutNode.cardRect == null) continue;
      
      final markerCenter = layoutNode.markerCenter;
      final cardRect = layoutNode.cardRect!;
      
      // Find connection point on card edge
      Offset cardConnection;
      if (orientation == TimelineOrientation.vertical) {
        // Connect to left or right edge of card
        if (cardRect.right < markerCenter.dx) {
          // Card is on left
          cardConnection = Offset(cardRect.right, cardRect.center.dy);
        } else {
          // Card is on right
          cardConnection = Offset(cardRect.left, cardRect.center.dy);
        }
      } else {
        // Connect to top or bottom edge of card
        if (cardRect.bottom < markerCenter.dy) {
          // Card is on top
          cardConnection = Offset(cardRect.center.dx, cardRect.bottom);
        } else {
          // Card is on bottom
          cardConnection = Offset(cardRect.center.dx, cardRect.top);
        }
      }
      
      // Draw connection line
      final linePaint = Paint()
        ..color = colorScheme.outline.withOpacity(0.2)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(markerCenter, cardConnection, linePaint);
    }
  }
  
  /// Draw label text
  void _drawLabel(Canvas canvas, Offset center, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Position label to the right of marker
    final labelOffset = center + const Offset(20, -6);
    textPainter.paint(canvas, labelOffset);
  }
  
  /// Get color for event type
  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.milestone:
        return colorScheme.primary;
      case EventType.photo:
        return colorScheme.secondary;
      case EventType.note:
        return colorScheme.tertiary;
      case EventType.other:
        return colorScheme.onSurfaceVariant;
    }
  }
  
  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return layoutNodes != oldDelegate.layoutNodes ||
           orientation != oldDelegate.orientation ||
           displayMode != oldDelegate.displayMode ||
           selectedEventId != oldDelegate.selectedEventId;
  }
  
  @override
  bool hitTest(Offset position) => true;
}
