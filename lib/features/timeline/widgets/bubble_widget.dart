import 'package:flutter/material.dart';
import '../services/bubble_aggregation_service.dart';

/// Widget displaying a single time bucket bubble
class BubbleWidget extends StatefulWidget {
  final BubbleData data;
  final VoidCallback? onTap;
  final double baseSize;

  const BubbleWidget({
    super.key,
    required this.data,
    this.onTap,
    this.baseSize = 80.0,
  });

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget> 
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  double get _size => widget.baseSize * widget.data.sizeMultiplier;

  @override
  Widget build(BuildContext context) {
    final size = _isHovered ? _size * 1.1 : _size;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.data.color.withOpacity(_isHovered ? 0.5 : 0.3),
                      blurRadius: _isHovered ? 20 : 12,
                      spreadRadius: _isHovered ? 4 : 2,
                    ),
                  ],
                ),
              ),
              
              // Main bubble
              Container(
                width: size * 0.85,
                height: size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      widget.data.color.withOpacity(0.9),
                      widget.data.color.withOpacity(0.7),
                      widget.data.color.withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Event count
                    Text(
                      widget.data.eventCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Label
                    if (size > 60)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          widget.data.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: size * 0.12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Participant avatars ring
              if (widget.data.participantIds.length > 1)
                _buildParticipantRing(size),

              // Highlight shine
              Positioned(
                top: size * 0.1,
                left: size * 0.2,
                child: Container(
                  width: size * 0.15,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(size * 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantRing(double size) {
    final participantCount = widget.data.participantIds.length;
    
    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticipantRingPainter(
          count: participantCount,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }
}

/// Painter for participant indicator dots around bubble edge
class _ParticipantRingPainter extends CustomPainter {
  final int count;
  final Color color;
  final double size;

  _ParticipantRingPainter({
    required this.count,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size * 0.42;
    final dotRadius = 4.0 + (count > 3 ? 0 : 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Position dots evenly around the edge
    for (var i = 0; i < count && i < 6; i++) {
      final angle = (i / count) * 2 * 3.14159 - (3.14159 / 2);
      final x = center.dx + radius * 1.1 * cos(angle);
      final y = center.dy + radius * 1.1 * sin(angle);

      canvas.drawCircle(Offset(x, y), dotRadius, paint);
      canvas.drawCircle(Offset(x, y), dotRadius, borderPaint);
    }
  }

  double cos(double radians) => 
      (radians == 0) ? 1.0 : (radians - (radians * radians * radians) / 6);
  double sin(double radians) => 
      (radians == 3.14159 / 2) ? 1.0 : radians - (radians * radians * radians) / 6;

  @override
  bool shouldRepaint(_ParticipantRingPainter oldDelegate) => 
      count != oldDelegate.count;
}
