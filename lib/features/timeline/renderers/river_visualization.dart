import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Data model for River visualization nodes
class RiverNode {
  final String id;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final double x;
  final double y;
  final double width;
  final Color color;
  final List<RiverEvent> events;

  const RiverNode({
    required this.id,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.x,
    required this.y,
    required this.width,
    required this.color,
    this.events = const [],
  });

  RiverNode copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? timestamp,
    double? x,
    double? y,
    double? width,
    Color? color,
    List<RiverEvent>? events,
  }) {
    return RiverNode(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      color: color ?? this.color,
      events: events ?? this.events,
    );
  }
}

/// Data model for events in the River visualization
class RiverEvent {
  final String id;
  final String eventId;
  final String title;
  final DateTime timestamp;
  final List<String> participantIds;
  final EventType type;

  const RiverEvent({
    required this.id,
    required this.eventId,
    required this.title,
    required this.timestamp,
    required this.participantIds,
    required this.type,
  });
}

/// Types of events in the River visualization
enum EventType {
  individual,
  shared,
  merged,
  diverged,
}

/// Data model for River connections (flows between nodes)
class RiverConnection {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final List<Offset> controlPoints;
  final double width;
  final Color color;
  final double opacity;

  const RiverConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.controlPoints,
    required this.width,
    required this.color,
    this.opacity = 1.0,
  });
}

/// Custom painter for River visualization (Sankey-style timeline merging)
class RiverPainter extends CustomPainter {
  final List<RiverNode> nodes;
  final List<RiverConnection> connections;
  final List<RiverEvent> events;
  final Rect? selectedArea;
  final double animationProgress;

  const RiverPainter({
    required this.nodes,
    required this.connections,
    required this.events,
    this.selectedArea,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw background gradient
    _drawBackground(canvas, size, paint);

    // Draw connections (rivers) first so they appear behind nodes
    for (final connection in connections) {
      _drawConnection(canvas, connection, paint);
    }

    // Draw nodes (timeline segments)
    for (final node in nodes) {
      _drawNode(canvas, node, paint);
    }

    // Draw events on top
    for (final event in events) {
      _drawEvent(canvas, event, paint);
    }

    // Draw selection area if present
    if (selectedArea != null) {
      _drawSelectionArea(canvas, selectedArea!, paint);
    }
  }

  void _drawBackground(Canvas canvas, Size size, Paint paint) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade50,
          Colors.purple.shade50,
          Colors.pink.shade50,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
  }

  void _drawConnection(Canvas canvas, RiverConnection connection, Paint paint) {
    if (connection.controlPoints.length < 2) return;

    final path = Path();
    
    // Create smooth Bézier curve through control points
    path.moveTo(connection.controlPoints.first.dx, connection.controlPoints.first.dy);
    
    for (int i = 1; i < connection.controlPoints.length - 1; i++) {
      final current = connection.controlPoints[i];
      final next = connection.controlPoints[i + 1];
      
      final cp1x = current.dx + (next.dx - current.dx) * 0.25;
      final cp1y = current.dy;
      final cp2x = current.dx + (next.dx - current.dx) * 0.75;
      final cp2y = next.dy;
      
      path.cubicTo(
        cp1x, cp1y,
        cp2x, cp2y,
        next.dx, next.dy,
      );
    }

    // Draw the river flow with gradient
    final riverPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = connection.width * animationProgress
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = connection.color.withOpacity(connection.opacity * animationProgress);

    // Add shadow for depth
    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.2),
      3.0,
      true,
    );

    canvas.drawPath(path, riverPaint);

    // Draw flow direction indicators
    _drawFlowIndicators(canvas, connection, path);
  }

  void _drawFlowIndicators(Canvas canvas, RiverConnection connection, Path path) {
    final pathMetrics = path.computeMetrics();
    if (pathMetrics.isEmpty) return;

    final pathMetric = pathMetrics.first;
    final pathLength = pathMetric.length;
    
    // Draw arrows along the flow
    const arrowCount = 5;
    for (int i = 0; i < arrowCount; i++) {
      final distance = (pathLength / arrowCount) * (i + 0.5);
      final tangent = pathMetric.getTangentForOffset(distance);
      
      if (tangent != null) {
        final position = tangent.position;
        final angle = tangent.angle;
        
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle);
        
        // Draw arrow
        final arrowPaint = Paint()
          ..color = connection.color.withOpacity(0.6 * animationProgress)
          ..style = PaintingStyle.fill;
        
        final arrowPath = Path();
        arrowPath.moveTo(0, -4);
        arrowPath.lineTo(8, 0);
        arrowPath.lineTo(0, 4);
        arrowPath.close();
        
        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
      }
    }
  }

  void _drawNode(Canvas canvas, RiverNode node, Paint paint) {
    // Draw node shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(node.x - 2, node.y - 2, node.width + 4, 40),
        const Radius.circular(20),
      ),
      shadowPaint,
    );

    // Draw node background with gradient
    final nodePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          node.color.withOpacity(0.9),
          node.color.withOpacity(0.7),
        ],
      ).createShader(
        Rect.fromLTWH(node.x, node.y, node.width, 36),
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(node.x, node.y, node.width, 36),
        const Radius.circular(18),
      ),
      nodePaint,
    );

    // Draw node border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = node.color.withOpacity(0.8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(node.x, node.y, node.width, 36),
        const Radius.circular(18),
      ),
      borderPaint,
    );

    // Draw user name
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.userName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textX = node.x + (node.width - textPainter.width) / 2;
    final textY = node.y + (36 - textPainter.height) / 2;
    
    textPainter.paint(canvas, Offset(textX, textY));

    // Draw event count badge
    if (node.events.isNotEmpty) {
      _drawEventBadge(canvas, node);
    }
  }

  void _drawEventBadge(Canvas canvas, RiverNode node) {
    final badgePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final badgeX = node.x + node.width - 12;
    final badgeY = node.y - 4;

    canvas.drawCircle(Offset(badgeX, badgeY), 8, badgePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: node.events.length.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(badgeX - textPainter.width / 2, badgeY - textPainter.height / 2),
    );
  }

  void _drawEvent(Canvas canvas, RiverEvent event, Paint paint) {
    // Find the position for this event based on its timestamp
    final position = _calculateEventPosition(event);
    if (position == null) return;

    Color eventColor;
    switch (event.type) {
      case EventType.individual:
        eventColor = Colors.blue;
        break;
      case EventType.shared:
        eventColor = Colors.green;
        break;
      case EventType.merged:
        eventColor = Colors.purple;
        break;
      case EventType.diverged:
        eventColor = Colors.orange;
        break;
    }

    // Draw event marker
    final eventPaint = Paint()
      ..color = eventColor.withOpacity(animationProgress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 6, eventPaint);

    // Draw event border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(animationProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(position, 6, borderPaint);

    // Draw event title if there's space
    final textPainter = TextPainter(
      text: TextSpan(
        text: event.title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white.withOpacity(0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx + 10, position.dy - textPainter.height / 2),
    );
  }

  Offset? _calculateEventPosition(RiverEvent event) {
    // Find the node that contains this event
    for (final node in nodes) {
      if (node.events.any((e) => e.id == event.id)) {
        return Offset(node.x + node.width / 2, node.y + 18);
      }
    }
    return null;
  }

  void _drawSelectionArea(Canvas canvas, Rect area, Paint paint) {
    final selectionPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(area, selectionPaint);

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(area, borderPaint);
  }

  @override
  bool shouldRepaint(covariant RiverPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
           oldDelegate.connections != connections ||
           oldDelegate.events != events ||
           oldDelegate.selectedArea != selectedArea ||
           oldDelegate.animationProgress != animationProgress;
  }
}

/// Widget for displaying River visualization
class RiverVisualization extends StatefulWidget {
  final List<RiverNode> nodes;
  final List<RiverConnection> connections;
  final List<RiverEvent> events;
  final Function(RiverNode)? onNodeTap;
  final Function(RiverEvent)? onEventTap;
  final Function(Rect)? onAreaSelected;

  const RiverVisualization({
    Key? key,
    required this.nodes,
    required this.connections,
    required this.events,
    this.onNodeTap,
    this.onEventTap,
    this.onAreaSelected,
  }) : super(key: key);

  @override
  State<RiverVisualization> createState() => _RiverVisualizationState();
}

class _RiverVisualizationState extends State<RiverVisualization>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Rect? _selectedArea;
  Offset? _dragStart;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: RiverPainter(
            nodes: widget.nodes,
            connections: widget.connections,
            events: widget.events,
            selectedArea: _selectedArea,
            animationProgress: _animationController.value,
          ),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: Container(
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      },
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final position = details.globalPosition;
    
    // Check if an event was tapped
    for (final event in widget.events) {
      final eventPos = _calculateEventPosition(event);
      if (eventPos != null) {
        final distance = (position - eventPos).distance;
        if (distance <= 10) {
          widget.onEventTap?.call(event);
          return;
        }
      }
    }

    // Check if a node was tapped
    for (final node in widget.nodes) {
      final nodeRect = Rect.fromLTWH(node.x, node.y, node.width, 36);
      if (nodeRect.contains(position)) {
        widget.onNodeTap?.call(node);
        return;
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
    _isSelecting = true;
    _selectedArea = null;
    setState(() {});
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isSelecting || _dragStart == null) return;

    final current = details.globalPosition;
    _selectedArea = Rect.fromPoints(
      _dragStart!,
      current,
    );
    setState(() {});
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectedArea != null) {
      widget.onAreaSelected?.call(_selectedArea!);
    }
    
    _isSelecting = false;
    _dragStart = null;
    _selectedArea = null;
    setState(() {});
  }

  Offset? _calculateEventPosition(RiverEvent event) {
    for (final node in widget.nodes) {
      if (node.events.any((e) => e.id == event.id)) {
        return Offset(node.x + node.width / 2, node.y + 18);
      }
    }
    return null;
  }
}
