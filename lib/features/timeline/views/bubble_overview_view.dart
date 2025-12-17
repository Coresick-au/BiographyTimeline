import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../services/bubble_aggregation_service.dart';
import '../models/timeline_view_state.dart';
import '../services/timeline_data_service.dart';
import '../../../shared/models/timeline_event.dart';
import '../models/river_flow_models.dart';

/// Bubbles View - Vertical timeline with activity bubbles along a central line
/// Highlights high activity periods with larger, more vibrant bubbles
class BubbleOverviewView extends ConsumerStatefulWidget {
  final List<TimelineEvent> events;
  final Function(DateTime start, DateTime end)? onBubbleTap;
  
  const BubbleOverviewView({
    super.key,
    required this.events,
    this.onBubbleTap,
  });

  @override
  ConsumerState<BubbleOverviewView> createState() => _BubbleOverviewViewState();
}

class _BubbleOverviewViewState extends ConsumerState<BubbleOverviewView> {
  final BubbleAggregationService _aggregationService = BubbleAggregationService();
  final ScrollController _scrollController = ScrollController();
  ZoomTier _currentTier = ZoomTier.year;
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.events directly
    return _buildBubblesView(context, widget.events);
  }
  
  Widget _buildBubblesView(BuildContext context, List<dynamic> events) {
    final timelineEvents = events.cast<TimelineEvent>().toList();
    
    if (timelineEvents.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Aggregate events into bubbles
    final bubbles = _aggregationService.aggregate(
      events: timelineEvents,
      tier: _currentTier,
    );
    
    // Calculate max event count for relative sizing
    final maxEvents = bubbles.isEmpty ? 1 : 
        bubbles.map((b) => b.eventCount).reduce((a, b) => a > b ? a : b);
    
    return Container(
      color: const Color(0xFF0A0F1A),
      child: Column(
        children: [
          // Header with tier selector
          _buildHeader(context),
          
          // Vertical timeline with bubbles
          Expanded(
            child: _buildVerticalTimeline(context, bubbles, maxEvents),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1420),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bubble_chart,
            color: Colors.purple.shade300,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Activity Bubbles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Tier selector
          SegmentedButton<ZoomTier>(
            segments: const [
              ButtonSegment(
                value: ZoomTier.year,
                label: Text('Year', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: ZoomTier.month,
                label: Text('Month', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {_currentTier},
            onSelectionChanged: (tiers) {
              setState(() => _currentTier = tiers.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVerticalTimeline(
    BuildContext context,
    List<BubbleData> bubbles,
    int maxEvents,
  ) {
    return Stack(
      children: [
        // Background gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1F2E).withOpacity(0.3),
                  const Color(0xFF0A0F1A),
                  const Color(0xFF0A0F1A),
                  const Color(0xFF1A1F2E).withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        
        // Central timeline line
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 1.5,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.purple.withOpacity(0.5),
                  Colors.blue.withOpacity(0.5),
                  Colors.cyan.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        
        // Scrollable bubbles
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: bubbles.asMap().entries.map((entry) {
              final index = entry.key;
              final bubble = entry.value;
              final isLeft = index.isEven;
              
              return _buildBubbleRow(
                context,
                bubble,
                maxEvents,
                isLeft,
                index == 0,
                index == bubbles.length - 1,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBubbleRow(
    BuildContext context,
    BubbleData bubble,
    int maxEvents,
    bool isLeft,
    bool isFirst,
    bool isLast,
  ) {
    // Calculate bubble size based on event count (40-120 range)
    final sizeRatio = bubble.eventCount / maxEvents;
    final bubbleSize = 40.0 + (sizeRatio * 80.0);
    
    // Get color based on dominant category
    final color = BubbleAggregationService.categoryColors[bubble.dominantCategory] 
        ?? Colors.purple;
    
    // Intensity of glow based on activity
    final glowIntensity = 0.3 + (sizeRatio * 0.4);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : 20,
        bottom: isLast ? 0 : 20,
      ),
      child: SizedBox(
        height: bubbleSize + 20,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Connection line to center
            Positioned(
              left: isLeft ? centerX - bubbleSize / 2 - 30 : centerX,
              top: bubbleSize / 2 + 10,
              child: Container(
                width: bubbleSize / 2 + 30,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLeft
                        ? [color.withOpacity(0.8), color.withOpacity(0.1)]
                        : [color.withOpacity(0.1), color.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
            
            // Center dot on timeline
            Positioned(
              left: centerX - 6,
              top: bubbleSize / 2 + 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bubble
            Positioned(
              left: isLeft 
                  ? centerX - bubbleSize - 50
                  : centerX + 50,
              top: 10,
              child: GestureDetector(
                onTap: () {
                  widget.onBubbleTap?.call(bubble.start, bubble.end);
                  _showBubbleDetails(context, bubble);
                },
                child: _buildBubble(
                  context,
                  bubble,
                  bubbleSize,
                  color,
                  glowIntensity,
                ),
              ),
            ),
            
            // Label on opposite side
            Positioned(
              left: isLeft 
                  ? centerX + 24
                  : null,
              right: isLeft
                  ? null
                  : centerX + 24,
              top: bubbleSize / 2 - 8,
              child: _buildLabel(context, bubble, color, isLeft),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBubble(
    BuildContext context,
    BubbleData bubble,
    double size,
    Color color,
    double glowIntensity,
  ) {
    if (bubble.personCounts.length > 1) {
      return _buildMultiPersonBubble(bubble, size, glowIntensity);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.4),
            color.withOpacity(0.1),
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
        border: Border.all(
          color: color.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(glowIntensity),
            blurRadius: size / 3,
            spreadRadius: size / 10,
          ),
        ],
      ),
      child: _buildBubbleContent(bubble, size),
    );
  }

  Widget _buildMultiPersonBubble(BubbleData bubble, double size, double glowIntensity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(glowIntensity * 0.5), // Generic glow
            blurRadius: size / 3,
            spreadRadius: size / 10,
          ),
        ],
      ),
      child: CustomPaint(
        painter: PieChartBubblePainter(
          personCounts: bubble.personCounts,
          total: bubble.eventCount,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: _buildBubbleContent(bubble, size),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(BubbleData bubble, double size) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bubble.eventCount.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size / 3,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          if (size > 60)
            Text(
              'events',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: size / 6,
                shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLabel(
    BuildContext context,
    BubbleData bubble,
    Color color,
    bool isLeft,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Column(
        crossAxisAlignment: isLeft 
            ? CrossAxisAlignment.start 
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bubble.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bubble.dominantCategory,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showBubbleDetails(BuildContext context, BubbleData bubble) {
    final color = BubbleAggregationService.categoryColors[bubble.dominantCategory] 
        ?? Colors.purple;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              bubble.label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Events', bubble.eventCount.toString(), color),
            _buildDetailRow('Primary Category', bubble.dominantCategory, color),
            _buildDetailRow('People Involved', bubble.participantIds.length.toString(), color),
            const SizedBox(height: 16),
            Text(
              'Tap "Explore" to view events from this period',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBubbleTap?.call(bubble.start, bubble.end);
            },
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bubble_chart,
            size: 80,
            color: Colors.purple.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No events yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add events to see your activity bubbles',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading timeline',
            style: TextStyle(color: Colors.white),
          ),
          Text(
            error.toString(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PieChartBubblePainter extends CustomPainter {
  final Map<String, int> personCounts;
  final int total;

  PieChartBubblePainter({required this.personCounts, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -math.pi / 2; // Start from top

    personCounts.forEach((personId, count) {
      final sweepAngle = (count / total) * 2 * math.pi;
      final color = RiverFlowColors.getColorForPerson(personId);
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant PieChartBubblePainter oldDelegate) {
    return oldDelegate.personCounts != personCounts || oldDelegate.total != total;
  }
}
