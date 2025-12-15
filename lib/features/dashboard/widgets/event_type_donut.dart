import 'package:flutter/material.dart';
import 'dart:math';

class EventTypeDonut extends StatelessWidget {
  final Map<String, int> data;

  const EventTypeDonut({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final total = data.values.fold(0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Donut
            Expanded(
              flex: 1,
              child: CustomPaint(
                size: Size(constraints.maxHeight, constraints.maxHeight),
                painter: _DonutPainter(
                  data: data,
                  total: total,
                  colors: _generateColors(data.length, context),
                ),
              ),
            ),
            // Legend
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final key = data.keys.elementAt(index);
                  final value = data[key]!;
                  final color = _generateColors(data.length, context)[index];
                  final percentage = (value / total * 100).toStringAsFixed(1);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(key, overflow: TextOverflow.ellipsis)),
                        Text('$percentage%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Color> _generateColors(int count, BuildContext context) {
    // Generate distinct colors
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final hue = (i * 360 / count) % 360;
      colors.add(HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor());
    }
    return colors;
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  final int total;
  final List<Color> colors;

  _DonutPainter({
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -pi / 2;

    int i = 0;
    for (final value in data.values) {
      final sweepAngle = (value / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => 
      oldDelegate.data != data;
}
