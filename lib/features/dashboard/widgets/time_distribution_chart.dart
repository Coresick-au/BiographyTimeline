import 'package:flutter/material.dart';

class TimeDistributionChart extends StatelessWidget {
  final Map<DateTime, int> data;

  const TimeDistributionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    final maxEvents = data.values.fold(0, (a, b) => a > b ? a : b);
    final sortedKeys = data.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final barWidth = (width / sortedKeys.length).clamp(4.0, 20.0);
        
        return CustomPaint(
          size: Size(width, height),
          painter: _BarChartPainter(
            data: data,
            keys: sortedKeys,
            maxVal: maxEvents,
            barWidth: barWidth,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<DateTime, int> data;
  final List<DateTime> keys;
  final int maxVal;
  final double barWidth;
  final Color color;

  _BarChartPainter({
    required this.data,
    required this.keys,
    required this.maxVal,
    required this.barWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (maxVal == 0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    // Simple distribution
    // For many data points, we might need to downsample or use a different visualization
    // Assuming monthly or yearly buckets
    
    final spacing = (size.width - (keys.length * barWidth)) / (keys.length + 1);
    
    for (int i = 0; i < keys.length; i++) {
      final value = data[keys[i]]!;
      final barHeight = (value / maxVal) * size.height;
      
      final left = spacing + i * (barWidth + spacing);
      final top = size.height - barHeight;
      
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      
      canvas.drawRRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => 
      oldDelegate.data != data;
}
