import 'package:flutter/material.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> data; // Date -> Count

  const ActivityHeatmap({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // We want to show last 365 days or so
    // GitHub style: 7 rows (days of week), ~52 columns (weeks)
    
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    
    // Normalize data to simple dates
    final normalizedData = <DateTime, int>{};
    for (final entry in data.entries) {
      final date = DateTime(entry.key.year, entry.key.month, entry.key.day);
      normalizedData[date] = (normalizedData[date] ?? 0) + entry.value;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = (constraints.maxWidth / 53).clamp(4.0, 16.0); // 53 weeks
        final spacing = 2.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (boxSize + spacing) * 53,
            height: (boxSize + spacing) * 7 + 20, // +20 for labels
            child: CustomPaint(
              painter: _HeatmapPainter(
                data: normalizedData,
                startDate: oneYearAgo,
                cellSize: boxSize,
                spacing: spacing,
                theme: Theme.of(context),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final Map<DateTime, int> data;
  final DateTime startDate;
  final double cellSize;
  final double spacing;
  final ThemeData theme;

  _HeatmapPainter({
    required this.data,
    required this.startDate,
    required this.cellSize,
    required this.spacing,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Align start date to previous Sunday to keep rows correct
    final dayOfWeek = startDate.weekday % 7; // Sunday = 0
    final alignDate = startDate.subtract(Duration(days: dayOfWeek));
    
    for (int i = 0; i < 371; i++) { // 7 * 53
      final currentDate = alignDate.add(Duration(days: i));
      if (currentDate.isAfter(DateTime.now())) break;

      final count = data[DateTime(currentDate.year, currentDate.month, currentDate.day)] ?? 0;
      
      final weekIndex = i ~/ 7;
      final dayIndex = i % 7;
      
      final left = weekIndex * (cellSize + spacing);
      final top = dayIndex * (cellSize + spacing);
      
      final color = _getColorForCount(count);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cellSize, cellSize),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }
  }

  Color _getColorForCount(int count) {
    if (count == 0) return theme.colorScheme.surfaceVariant.withOpacity(0.3);
    if (count <= 1) return theme.colorScheme.primary.withOpacity(0.2);
    if (count <= 3) return theme.colorScheme.primary.withOpacity(0.5);
    if (count <= 6) return theme.colorScheme.primary.withOpacity(0.8);
    return theme.colorScheme.primary;
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) => 
      oldDelegate.data != data;
}
