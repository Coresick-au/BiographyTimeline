import 'package:flutter/material.dart';
import '../services/flow_layout_engine.dart';
import '../../../shared/models/timeline_event.dart';

/// Painter for the Flow View streams (Hero visual)
/// Renders multi-layered bezier paths with glow effects.
class FlowPainter extends CustomPainter {
  final List<FlowPath> paths;
  final double zoomLevel;

  FlowPainter({
    required this.paths,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw streams (bottom to top)
    for (final flowPath in paths) {
      _drawStream(canvas, flowPath);
    }
  }

  void _drawStream(Canvas canvas, FlowPath flowPath) {
    final path = flowPath.path;
    final color = flowPath.color;

    // Layer 1: Wide blurred under-stroke (Atmospheric glow)
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0 * zoomLevel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(path, glowPaint);

    // Layer 2: Medium blurred stroke (Softer core)
    final softPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 * zoomLevel
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, softPaint);

    // Layer 3: Sharp core stroke
    final corePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * zoomLevel
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);

    // Layer 4: Highlight stroke (Top edge shine)
    // To do this properly requires shifting the path or specialized shader.
    // Simplifying to a thin brighter center line for "neon" effect.
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * zoomLevel;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant FlowPainter oldDelegate) {
    return oldDelegate.paths != paths || oldDelegate.zoomLevel != zoomLevel;
  }
}

/// Widget representing a node on the stream
class StreamNodeWidget extends StatelessWidget {
  final FlowNode node;
  final double scale;
  final VoidCallback? onTap;

  const StreamNodeWidget({
    super.key,
    required this.node,
    this.scale = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = node.isJunction ? 32.0 * scale : 20.0 * scale;
    // Ensure min touch size
    final touchSize = size < 44.0 ? 44.0 : size;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent, // Allow touches near visual center
        child: SizedBox(
          width: touchSize,
          height: touchSize,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: node.isJunction 
                    ? Theme.of(context).colorScheme.surface 
                    : Theme.of(context).colorScheme.primaryContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: node.isJunction ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    blurRadius: node.isJunction ? 12 : 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: node.isJunction
                  ? Icon(Icons.star, size: size * 0.6, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
