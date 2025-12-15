import 'package:flutter/material.dart';
import '../models/render_node.dart';
import '../models/timeline_view_state.dart';

/// Layout engine for timeline rendering
/// 
/// Computes visual positions for render nodes in an orientation-agnostic way.
/// Handles card placement, collision resolution, and marker positioning.
class TimelineLayoutEngine {
  /// Card dimensions
  static const double cardWidth = 280.0;
  static const double cardMinHeight = 120.0;
  static const double cardMaxHeight = 400.0;
  
  /// Spacing constants
  static const double gutter = 24.0;  // Gap between axis and cards
  static const double markerSize = 12.0;
  static const double minVerticalSpacing = 16.0;
  
  /// Compute layout nodes from render nodes
  /// 
  /// Returns positioned layout nodes with card rects and marker positions
  /// based on orientation and display mode.
  static List<LayoutNode> layout({
    required List<RenderNode> nodes,
    required TimelineDisplayMode mode,
    required TimelineOrientation orientation,
    required Size viewportSize,
    required double pixelsPerDay,
    required DateTime minDate,
  }) {
    if (nodes.isEmpty) return [];
    
    // Compute primary axis positions for all nodes
    for (final node in nodes) {
      final dayIndex = node.start.difference(minDate).inDays;
      node.primaryPx = dayIndex * pixelsPerDay;
    }
    
    // Sort nodes by primary position
    nodes.sort((a, b) => a.primaryPx.compareTo(b.primaryPx));
    
    // Layout based on orientation
    switch (orientation) {
      case TimelineOrientation.vertical:
        return _layoutVertical(nodes, mode, viewportSize);
      case TimelineOrientation.horizontal:
        return _layoutHorizontal(nodes, mode, viewportSize);
    }
  }
  
  /// Layout for vertical timeline (cards left/right of axis)
  static List<LayoutNode> _layoutVertical(
    List<RenderNode> nodes,
    TimelineDisplayMode mode,
    Size viewportSize,
  ) {
    final layoutNodes = <LayoutNode>[];
    final centerX = viewportSize.width / 2;
    
    // Track occupied regions for collision detection
    final leftOccupied = <Rect>[];
    final rightOccupied = <Rect>[];
    
    bool placeOnLeft = true;
    
    for (final node in nodes) {
      final y = node.primaryPx;
      final markerCenter = Offset(centerX, y);
      
      Rect? cardRect;
      bool isLabelVisible = true;
      
      if (mode == TimelineDisplayMode.maximal) {
        // Estimate card height based on node type
        final cardHeight = _estimateCardHeight(node);
        
        // Try to place card on alternating sides
        Rect? proposedRect;
        List<Rect> occupiedList;
        
        if (placeOnLeft) {
          proposedRect = Rect.fromLTWH(
            centerX - gutter - cardWidth,
            y - cardHeight / 2,
            cardWidth,
            cardHeight,
          );
          occupiedList = leftOccupied;
        } else {
          proposedRect = Rect.fromLTWH(
            centerX + gutter,
            y - cardHeight / 2,
            cardWidth,
            cardHeight,
          );
          occupiedList = rightOccupied;
        }
        
        // Check for collisions and adjust
        proposedRect = _resolveCollisions(proposedRect, occupiedList);
        
        cardRect = proposedRect;
        occupiedList.add(proposedRect);
        
        // Alternate side for next card
        placeOnLeft = !placeOnLeft;
      } else {
        // Minimal mode: no cards, check label collision
        isLabelVisible = _checkLabelVisible(y, layoutNodes);
      }
      
      layoutNodes.add(LayoutNode(
        node: node,
        cardRect: cardRect,
        markerCenter: markerCenter,
        isLabelVisible: isLabelVisible,
      ));
    }
    
    return layoutNodes;
  }
  
  /// Layout for horizontal timeline (cards above/below axis)
  static List<LayoutNode> _layoutHorizontal(
    List<RenderNode> nodes,
    TimelineDisplayMode mode,
    Size viewportSize,
  ) {
    final layoutNodes = <LayoutNode>[];
    final centerY = viewportSize.height / 2;
    
    final topOccupied = <Rect>[];
    final bottomOccupied = <Rect>[];
    
    bool placeOnTop = true;
    
    for (final node in nodes) {
      final x = node.primaryPx;
      final markerCenter = Offset(x, centerY);
      
      Rect? cardRect;
      bool isLabelVisible = true;
      
      if (mode == TimelineDisplayMode.maximal) {
        final cardHeight = _estimateCardHeight(node);
        
        Rect? proposedRect;
        List<Rect> occupiedList;
        
        if (placeOnTop) {
          proposedRect = Rect.fromLTWH(
            x - cardWidth / 2,
            centerY - gutter - cardHeight,
            cardWidth,
            cardHeight,
          );
          occupiedList = topOccupied;
        } else {
          proposedRect = Rect.fromLTWH(
            x - cardWidth / 2,
            centerY + gutter,
            cardWidth,
            cardHeight,
          );
          occupiedList = bottomOccupied;
        }
        
        proposedRect = _resolveCollisions(proposedRect, occupiedList);
        
        cardRect = proposedRect;
        occupiedList.add(proposedRect);
        
        placeOnTop = !placeOnTop;
      } else {
        isLabelVisible = _checkLabelVisible(x, layoutNodes);
      }
      
      layoutNodes.add(LayoutNode(
        node: node,
        cardRect: cardRect,
        markerCenter: markerCenter,
        isLabelVisible: isLabelVisible,
      ));
    }
    
    return layoutNodes;
  }
  
  /// Resolve collisions by shifting rect vertically/horizontally
  static Rect _resolveCollisions(Rect proposed, List<Rect> occupied) {
    if (occupied.isEmpty) return proposed;
    
    var adjusted = proposed;
    
    // Check for overlaps and shift if needed
    for (final existing in occupied) {
      if (adjusted.overlaps(existing)) {
        // Shift down/right to avoid collision
        final shift = existing.bottom - adjusted.top + minVerticalSpacing;
        adjusted = adjusted.shift(Offset(0, shift));
      }
    }
    
    return adjusted;
  }
  
  /// Estimate card height based on node content
  static double _estimateCardHeight(RenderNode node) {
    if (node is EventNode) {
      // Events with media are taller
      return node.hasMedia ? 240.0 : cardMinHeight;
    } else if (node is ClusterNode) {
      // Clusters are compact
      return 100.0;
    }
    return cardMinHeight;
  }
  
  /// Check if label should be visible (collision avoidance)
  static bool _checkLabelVisible(double position, List<LayoutNode> existing) {
    const minLabelSpacing = 40.0;
    
    for (final node in existing) {
      if (node.isLabelVisible) {
        final distance = (position - node.markerCenter.dy).abs();
        if (distance < minLabelSpacing) {
          return false;
        }
      }
    }
    
    return true;
  }
}
