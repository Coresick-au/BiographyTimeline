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
  final double particleProgress;

  const RiverPainter({
    required this.nodes,
    required this.connections,
    required this.events,
    this.selectedArea,
    this.animationProgress = 1.0,
    this.particleProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw background gradient
    _drawBackground(canvas, size, paint);

    // Draw timeline grid lines for temporal orientation
    _drawTimeGrid(canvas, size);

    // Draw connections (rivers) first so they appear behind nodes
    for (final connection in connections) {
      _drawConnection(canvas, connection, paint);
    }

    // Draw animated flow particles along connections
    _drawFlowParticles(canvas);

    // Draw nodes (timeline segments)
    for (final node in nodes) {
      _drawNode(canvas, node, paint);
    }

    // Draw events on top
    for (final event in events) {
      _drawEvent(canvas, event, paint);
    }

    // Draw user labels to identify rivers
    _drawUserLabels(canvas, size);

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
          const Color(0xFF0F172A), // Deep navy
          const Color(0xFF1E1B4B), // Dark purple
          const Color(0xFF312E81), // Medium purple
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
  }

  void _drawTimeGrid(Canvas canvas, Size size) {
    // Draw subtle vertical grid lines at each node position
    final Set<double> gridPositions = {};
    
    // Collect unique X positions from nodes
    for (final node in nodes) {
      gridPositions.add(node.x);
    }
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (final x in gridPositions) {
      // Draw dashed vertical line
      const dashHeight = 10.0;
      const dashSpace = 10.0;
      double startY = 0;
      
      while (startY < size.height) {
        canvas.drawLine(
          Offset(x + 100, startY), // Center of node
          Offset(x + 100, startY + dashHeight),
          dashPaint,
        );
        startY += dashHeight + dashSpace;
      }
    }
  }

  void _drawFlowParticles(Canvas canvas) {
    // Draw 3 particles per connection at different positions
    for (final connection in connections) {
      if (connection.controlPoints.length < 2) continue;
      
      // Create path for this connection
      final path = Path();
      path.moveTo(connection.controlPoints[0].dx, connection.controlPoints[0].dy);
      
      for (int i = 1; i < connection.controlPoints.length - 1; i++) {
        final current = connection.controlPoints[i];
        final next = connection.controlPoints[i + 1];
        final cp1x = current.dx + (next.dx - current.dx) * 0.25;
        final cp1y = current.dy;
        final cp2x = current.dx + (next.dx - current.dx) * 0.75;
        final cp2y = next.dy;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, next.dx, next.dy);
      }
      
      // Draw 3 particles at different offsets
      for (int particleIndex = 0; particleIndex < 3; particleIndex++) {
        final offset = (particleIndex / 3.0);
        final progress = (particleProgress + offset) % 1.0;
        
        for (final pathMetric in path.computeMetrics()) {
          final distance = pathMetric.length * progress;
          final tangent = pathMetric.getTangentForOffset(distance);
          
          if (tangent != null && tangent.position != null) {
            // Draw glowing particle
            final particlePaint = Paint()
              ..shader = RadialGradient(
                colors: [
                  connection.color.withOpacity(0.8),
                  connection.color.withOpacity(0.4),
                  connection.color.withOpacity(0.0),
                ],
              ).createShader(Rect.fromCircle(center: tangent.position, radius: 6));
            
            canvas.drawCircle(tangent.position, 6, particlePaint);
            
            // Draw bright center
            final centerPaint = Paint()
              ..color = Colors.white.withOpacity(0.9);
            canvas.drawCircle(tangent.position, 2, centerPaint);
          }
          break; // Only process first contour
        }
      }
    }
  }

  void _drawConnection(Canvas canvas, RiverConnection connection, Paint paint) {
    if (connection.controlPoints.length < 2) return;

    final path = Path();
    
    // Create smooth Bézier curve through control points
    path.moveTo(connection.controlPoints[0].dx, connection.controlPoints[0].dy);
    
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
    final bounds = path.getBounds();
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        connection.color.withOpacity(0.9 * animationProgress),
        connection.color.withOpacity(0.5 * animationProgress),
      ],
    );
    
    final riverPaint = Paint()
      ..shader = gradient.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = connection.width * animationProgress
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Add shadow for depth
    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.3),
      4.0,
      true,
    );

    canvas.drawPath(path, riverPaint);

    // Draw flow direction indicators
    _drawFlowIndicators(canvas, connection, path);
  }

  void _drawFlowIndicators(Canvas canvas, RiverConnection connection, Path path) {
    if (connection.width * animationProgress < 5.0) return; // Skip small indicators

    for (final pathMetric in path.computeMetrics()) {
      final pathLength = pathMetric.length;
      if (pathLength == 0) continue;
      
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
      break; // Only process the first contour
    }
  }

  void _drawNode(Canvas canvas, RiverNode node, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(node.x, node.y, node.width, 36),
      const Radius.circular(18),
    );
    
    final center = Offset(node.x + node.width / 2, node.y + 18);
    final isShared = node.userName.contains('(Shared)');

    // Radial glow effect for shared events
    if (isShared) {
      final glowGradient = RadialGradient(
        colors: [
          node.color.withOpacity(0.5),
          node.color.withOpacity(0.3),
          node.color.withOpacity(0.1),
          node.color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      );
      final glowPaint = Paint()
        ..shader = glowGradient.createShader(
          Rect.fromCircle(center: center, radius: 70),
        );
      canvas.drawCircle(center, 70, glowPaint);
    }
    
    // Draw node shadow with blur (glassmorphism effect)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isShared ? 0.2 : 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isShared ? 12 : 8);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(node.x - 2, node.y - 2, node.width + 4, 40),
        const Radius.circular(20),
      ),
      shadowPaint,
    );

    // Draw node background with glassmorphism (semi-transparent gradient)
    final nodePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          node.color.withOpacity(0.25),
          node.color.withOpacity(0.15),
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

    // Draw node border (brighter for shared events)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isShared ? 2.5 : 2
      ..color = node.color.withOpacity(isShared ? 0.6 : 0.4);

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
    final position = _calculateEventPosition(event);
    if (position == null) return;

    // Determine event color and icon based on type
    Color eventColor;
    IconData iconData;
    
    switch (event.type) {
      case EventType.individual:
        eventColor = const Color(0xFF60A5FA); // Bright blue
        iconData = Icons.person;
        break;
      case EventType.shared:
        eventColor = const Color(0xFF34D399); // Bright green
        iconData = Icons.people;
        break;
      case EventType.merged:
        eventColor = const Color(0xFFC084FC); // Bright purple
        iconData = Icons.merge;
        break;
      case EventType.diverged:
        eventColor = const Color(0xFFFB923C); // Bright orange
        iconData = Icons.call_split;
        break;
    }

    // Draw subtle glow around event
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          eventColor.withOpacity(0.4 * animationProgress),
          eventColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: position, radius: 15));
    canvas.drawCircle(position, 15, glowPaint);

    // Draw event marker background
    final eventPaint = Paint()
      ..color = eventColor.withOpacity(0.9 * animationProgress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 8, eventPaint);

    // Draw event border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * animationProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, 8, borderPaint);

    // Draw icon using TextPainter (Material Icons are fonts)
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          fontSize: 10,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 0.5),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        position.dx - iconPainter.width / 2,
        position.dy - iconPainter.height / 2,
      ),
    );
  }

  void _drawUserLabels(Canvas canvas, Size size) {
    // Track which users we've drawn labels for
    final Set<String> drawnUsers = {};
    
    for (final node in nodes) {
      // Only draw label for the first node of each user
      if (!drawnUsers.contains(node.userId)) {
        drawnUsers.add(node.userId);
        
        // Draw user label badge
        final labelX = 10.0;
        final labelY = node.y + 18;
        
        // Background circle
        final badgePaint = Paint()
          ..color = node.color.withOpacity(0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(labelX, labelY), 20, badgePaint);
        
        // Border
        final borderPaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(labelX, labelY), 20, borderPaint);
        
        // User initials (extract from userId)
        final initials = node.userId.replaceAll('user-', 'U').toUpperCase();
        final textPainter = TextPainter(
          text: TextSpan(
            text: initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            labelX - textPainter.width / 2,
            labelY - textPainter.height / 2,
          ),
        );
      }
    }
  }

  Offset? _calculateEventPosition(RiverEvent event) {
    // Find the node that contains this event
    for (final node in nodes) {
      final index = node.events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        // Distribute events horizontally across the node
        // If single event, center it
        if (node.events.length == 1) {
          return Offset(node.x + node.width / 2, node.y + 18);
        }

        // Multiple events: spread them out
        // Use 80% of width to leave some padding on sides
        final availableWidth = node.width * 0.8;
        final startX = node.x + (node.width - availableWidth) / 2;
        
        // Calculate X position based on index
        // safe spacing calculation
        final step = availableWidth / (node.events.length - 1);
        final x = startX + (index * step);
        
        return Offset(x, node.y + 18);
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
  bool shouldRepaint(RiverPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
           oldDelegate.connections != connections ||
           oldDelegate.events != events ||
           oldDelegate.selectedArea != selectedArea ||
           oldDelegate.animationProgress != animationProgress ||
           oldDelegate.particleProgress != particleProgress;
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
  Offset? _dragEnd;
  bool _isSelecting = false;
  late AnimationController _particleAnimationController;
  RiverEvent? _selectedEvent;
  Offset? _selectedEventPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
    
    // Initialize particle animation controller
    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main river visualization
        AnimatedBuilder(
          animation: Listenable.merge([_animationController, _particleAnimationController]),
          builder: (context, child) {
            return CustomPaint(
              painter: RiverPainter(
                nodes: widget.nodes,
                connections: widget.connections,
                events: widget.events,
                selectedArea: _selectedArea,
                animationProgress: _animationController.value,
                particleProgress: _particleAnimationController.value,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,  // Ensure gestures are detected
                onTapDown: _handleTapDown,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,  // Make container hittable
                ),
              ),
            );
          },
        ),
        
        // Event card overlay
        if (_selectedEvent != null && _selectedEventPosition != null)
          _buildEventCardOverlay(context),
      ],
    );
  }

  Widget _buildEventCardOverlay(BuildContext context) {
    if (_selectedEvent == null || _selectedEventPosition == null) {
      return const SizedBox.shrink();
    }

    // Position the card near the event, but ensure it stays on screen
    final cardWidth = 350.0;
    final cardHeight = 200.0;
    double left = _selectedEventPosition!.dx + 20;
    double top = _selectedEventPosition!.dy - cardHeight / 2;

    // Keep card on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (left + cardWidth > screenWidth) {
      left = _selectedEventPosition!.dx - cardWidth - 20;
    }
    if (top < 0) top = 10;
    if (top + cardHeight > screenHeight) {
      top = screenHeight - cardHeight - 10;
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: cardWidth,
          constraints: BoxConstraints(maxHeight: cardHeight),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedEvent!.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Event Type: ${_selectedEvent!.type.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Participants: ${_selectedEvent!.participantIds.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedEvent = null;
                      _selectedEventPosition = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final position = details.localPosition;
    debugPrint('Tap at: $position');
    
    // Check if an event was tapped (increased hit radius to 20px for easier clicking)
    for (final event in widget.events) {
      final eventPos = _calculateEventPosition(event);
      if (eventPos != null) {
        final distance = (position - eventPos).distance;
        debugPrint('Event ${event.title} at $eventPos, distance: $distance');
        if (distance <= 20) {  // Increased from 10 to 20 for easier clicking
          debugPrint('Event tapped: ${event.title}');
          setState(() {
            _selectedEvent = event;
            _selectedEventPosition = eventPos;
          });
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
    
    // Tap on empty area - clear selection
    if (_selectedEvent != null) {
      setState(() {
        _selectedEvent = null;
        _selectedEventPosition = null;
      });
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
      final index = node.events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        if (node.events.length == 1) {
          return Offset(node.x + node.width / 2, node.y + 18);
        }
        
        final availableWidth = node.width * 0.8;
        final startX = node.x + (node.width - availableWidth) / 2;
        final step = availableWidth / (node.events.length - 1);
        final x = startX + (index * step);
        
        return Offset(x, node.y + 18);
      }
    }
    return null;
  }
}
