import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/flow_layout_engine.dart';
import '../models/river_flow_models.dart';
import '../../../shared/models/timeline_event.dart';

/// Painter for the RiverFlow visualization
/// Renders multi-layered bezier paths with neon glow effects
/// Draws multi-colored gradient strokes where streams merge
class RiverFlowPainter extends CustomPainter {
  final List<RiverFlowPath> paths;
  final double zoomLevel;
  final RiverFlowConfig config;

  RiverFlowPainter({
    required this.paths,
    this.zoomLevel = 1.0,
    this.config = const RiverFlowConfig(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all streams - each keeps its own color
    for (final flowPath in paths) {
      _drawStream(canvas, flowPath);
    }
    // Multi-color junction effect disabled - streams just overlap with individual colors
  }

  void _drawStream(Canvas canvas, RiverFlowPath flowPath) {
    final path = flowPath.path;
    final color = flowPath.color;
    final intensity = config.glowIntensity;

    // Layer 1: Wide atmospheric glow (outermost)
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.08 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 50.0 * zoomLevel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawPath(path, outerGlowPaint);

    // Layer 2: Medium glow
    final midGlowPaint = Paint()
      ..color = color.withOpacity(0.15 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25.0 * zoomLevel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, midGlowPaint);

    // Layer 3: Soft glow (closer to core)
    final softGlowPaint = Paint()
      ..color = color.withOpacity(0.35 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 * zoomLevel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, softGlowPaint);

    // Layer 4: Core stroke
    final corePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.streamWidth * zoomLevel
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);

    // Layer 5: Bright center highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * zoomLevel
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, highlightPaint);
  }
  
  void _drawJunctionSections(Canvas canvas) {
    // Find all junction nodes and group by position
    final junctionMap = <Offset, List<MapEntry<RiverFlowPath, RiverFlowNode>>>{};
    
    for (final flowPath in paths) {
      for (final node in flowPath.nodes) {
        if (node.isJunction && node.participantIds.length >= 2) {
          final existing = junctionMap[node.position] ?? [];
          existing.add(MapEntry(flowPath, node));
          junctionMap[node.position] = existing;
        }
      }
    }
    
    // Draw multi-colored sections between consecutive junction points
    for (final flowPath in paths) {
      final junctionNodes = flowPath.nodes.where((n) => n.isJunction).toList();
      
      for (int i = 0; i < junctionNodes.length - 1; i++) {
        final startNode = junctionNodes[i];
        final endNode = junctionNodes[i + 1];
        
        // Get all participants at these junctions
        final participants = {...startNode.participantIds, ...endNode.participantIds};
        if (participants.length < 2) continue;
        
        // Collect colors for all participants
        final colors = <Color>[];
        for (int pathIdx = 0; pathIdx < paths.length; pathIdx++) {
          final path = paths[pathIdx];
          if (participants.contains(path.personId)) {
            colors.add(path.color);
          }
        }
        
        if (colors.length < 2) continue;
        
        // Draw thick multi-colored line between these points
        _drawMultiColoredSegment(
          canvas,
          startNode.position,
          endNode.position,
          colors,
        );
      }
    }
  }
  
  void _drawMultiColoredSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    List<Color> colors,
  ) {
    // Create gradient path
    final path = Path()
      ..moveTo(start.dx, start.dy);
    
    // Smooth curve between points
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    path.quadraticBezierTo(
      midX,
      midY,
      end.dx,
      end.dy,
    );
    
    // Calculate bounds for gradient
    final bounds = Rect.fromPoints(start, end);
    
    // Extra thick stroke for merged section (more people = thicker)
    final baseWidth = config.streamWidth * 2;
    final strokeWidth = (baseWidth + colors.length * 1.5) * zoomLevel;
    
    // Create multipart gradient
    final gradient = ui.Gradient.linear(
      start,
      end,
      colors,
      _createColorStops(colors.length),
    );
    
    // Outer glow - rainbow effect
    final outerGlow = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(path, outerGlow);
    
    // Mid glow
    final midGlow = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, midGlow);
    
    // Core gradient stroke
    final gradientPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, gradientPaint);
    
    // White highlight overlay
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * zoomLevel
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, highlightPaint);
  }
  
  List<double> _createColorStops(int colorCount) {
    if (colorCount == 1) return [0.0];
    
    final stops = <double>[];
    for (int i = 0; i < colorCount; i++) {
      stops.add(i / (colorCount - 1));
    }
    return stops;
  }

  @override
  bool shouldRepaint(covariant RiverFlowPainter oldDelegate) {
    return oldDelegate.paths != paths || 
           oldDelegate.zoomLevel != zoomLevel ||
           oldDelegate.config != config;
  }
}

/// Widget for person info box at the top of their stream
class RiverPersonInfoBox extends StatelessWidget {
  final RiverFlowPath flowPath;
  final VoidCallback? onTap;

  const RiverPersonInfoBox({
    super.key,
    required this.flowPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: flowPath.color.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: flowPath.color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color dot indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: flowPath.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: flowPath.color.withOpacity(0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Person name
            Text(
              flowPath.personName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget representing an event node on the stream
class RiverEventNode extends StatelessWidget {
  final RiverFlowNode node;
  final Color streamColor;
  final double scale;
  final VoidCallback? onTap;

  const RiverEventNode({
    super.key,
    required this.node,
    required this.streamColor,
    this.scale = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = node.isJunction ? 56.0 * scale : 44.0 * scale;
    final borderWidth = node.isJunction ? 3.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * scale),
          color: const Color(0xFF1E293B),
          border: Border.all(
            color: streamColor.withOpacity(node.isJunction ? 1.0 : 0.7),
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: streamColor.withOpacity(node.isJunction ? 0.5 : 0.3),
              blurRadius: node.isJunction ? 16 : 10,
              spreadRadius: node.isJunction ? 2 : 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10 * scale),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Try to show thumbnail image
    if (node.thumbnailPath != null) {
      final isNetwork = node.thumbnailPath!.startsWith('http');
      return isNetwork
          ? Image.network(
              node.thumbnailPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(context),
            )
          : Image.asset(
              node.thumbnailPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(context),
            );
    }

    return _buildFallbackIcon(context);
  }

  Widget _buildFallbackIcon(BuildContext context) {
    IconData icon;
    switch (node.event.eventType) {
      case 'photo':
      case 'photo_burst':
      case 'photo_collection':
        icon = Icons.photo;
        break;
      case 'text':
        icon = Icons.edit_note;
        break;
      case 'milestone':
        icon = Icons.flag;
        break;
      default:
        icon = node.isJunction ? Icons.people : Icons.event;
    }

    return Container(
      color: streamColor.withOpacity(0.2),
      child: Center(
        child: Icon(
          icon,
          color: streamColor,
          size: node.isJunction ? 24 : 20,
        ),
      ),
    );
  }
}

/// Widget for event label/card displayed near nodes
class RiverEventLabel extends StatelessWidget {
  final RiverFlowNode node;
  final Color streamColor;
  final bool isLeft; // Display on left or right of stream

  const RiverEventLabel({
    super.key,
    required this.node,
    required this.streamColor,
    this.isLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: streamColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (node.event.title != null)
            Text(
              node.event.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Text(
            _formatDate(node.event.timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9,
            ),
          ),
          if (node.isJunction) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  size: 10,
                  color: streamColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${node.participantIds.length} people',
                  style: TextStyle(
                    color: streamColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Filter chip for selecting people to display
class RiverPersonFilterChip extends StatelessWidget {
  final String personId;
  final String personName;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const RiverPersonFilterChip({
    super.key,
    required this.personId,
    required this.personName,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.2) 
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              personName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini-map showing full timeline overview with current viewport indicator
class RiverFlowMiniMap extends StatelessWidget {
  final List<RiverFlowPath> paths;
  final double contentHeight;
  final double viewportHeight;
  final double scrollPosition;
  final Function(double) onSeek;
  
  const RiverFlowMiniMap({
    super.key,
    required this.paths,
    required this.contentHeight,
    required this.viewportHeight,
    required this.scrollPosition,
    required this.onSeek,
  });
  
  @override
  Widget build(BuildContext context) {
    const miniMapHeight = 200.0;
    const miniMapWidth = 80.0;
    
    // Calculate viewport position percentage
    final viewportTop = (scrollPosition / contentHeight) * miniMapHeight;
    final viewportBottom = ((scrollPosition + viewportHeight) / contentHeight) * miniMapHeight;
    final viewportSize = (viewportBottom - viewportTop).clamp(10.0, miniMapHeight);
    
    return Positioned(
      right: 16,
      top: 100,
      child: GestureDetector(
        onTapDown: (details) {
          final relativeY = details.localPosition.dy;
          final targetScroll = (relativeY / miniMapHeight) * contentHeight;
          onSeek(targetScroll);
        },
        child: Container(
          width: miniMapWidth,
          height: miniMapHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1420).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Timeline streams (simplified)
              CustomPaint(
                size: const Size(miniMapWidth, miniMapHeight),
                painter: MiniMapPainter(
                  paths: paths,
                  fullHeight: contentHeight,
                  miniHeight: miniMapHeight,
                ),
              ),
              
              // Viewport indicator
              Positioned(
                left: 0,
                right: 0,
                top: viewportTop.clamp(0.0, miniMapHeight - viewportSize),
                child: Container(
                  height: viewportSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade400, width: 2),
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ),
              
              // Tap hint
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Text(
                  'TAP TO\nJUMP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 8,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simplified painter for mini-map
class MiniMapPainter extends CustomPainter {
  final List<RiverFlowPath> paths;
  final double fullHeight;
  final double miniHeight;
  
  MiniMapPainter({
    required this.paths,
    required this.fullHeight,
    required this.miniHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final scale = miniHeight / fullHeight;
    
    for (final flowPath in paths) {
      final paint = Paint()
        ..color = flowPath.color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      // Draw simplified path
      final scaledPath = Path();
      var isFirst = true;
      
      for (final node in flowPath.nodes) {
        final scaledY = node.position.dy * scale;
        final scaledX = (node.position.dx / 1000) * size.width; // Normalize X
        
        if (isFirst) {
          scaledPath.moveTo(scaledX, scaledY);
          isFirst = false;
        } else {
          scaledPath.lineTo(scaledX, scaledY);
        }
      }
      
      canvas.drawPath(scaledPath, paint);
    }
  }
  
  @override
  bool shouldRepaint(MiniMapPainter oldDelegate) => 
      oldDelegate.paths != paths ||
      oldDelegate.fullHeight != fullHeight;
}
