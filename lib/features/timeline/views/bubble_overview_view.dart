import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bubble_aggregation_service.dart';
import '../widgets/bubble_widget.dart';
import '../models/timeline_view_state.dart';
import '../services/timeline_data_service.dart';

/// Bubble Overview View - high-level entry point showing time buckets as bubbles
class BubbleOverviewView extends ConsumerStatefulWidget {
  final Function(DateTime start, DateTime end)? onBubbleTap;
  
  const BubbleOverviewView({
    super.key,
    this.onBubbleTap,
  });

  @override
  ConsumerState<BubbleOverviewView> createState() => _BubbleOverviewViewState();
}

class _BubbleOverviewViewState extends ConsumerState<BubbleOverviewView> {
  final BubbleAggregationService _aggregationService = BubbleAggregationService();
  ZoomTier _currentTier = ZoomTier.year;
  
  @override
  Widget build(BuildContext context) {
    final timelineDataAsync = ref.watch(timelineDataProvider);
    
    return timelineDataAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bubble_chart,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      data: (data) => _buildBubbleView(context, data.filteredEvents),
    );
  }
  
  Widget _buildBubbleView(BuildContext context, List<dynamic> events) {
    // Cast to TimelineEvent list
    final timelineEvents = events.cast<dynamic>().toList();
    
    if (timelineEvents.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Aggregate events into bubbles
    final bubbles = _aggregationService.aggregate(
      events: timelineEvents.map((e) => e as dynamic).whereType<dynamic>().toList().cast(),
      tier: _currentTier,
    );
    
    return Column(
      children: [
        // Tier selector
        _buildTierSelector(context),
        
        // Bubbles grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildBubbleLayout(context, bubbles),
          ),
        ),
        
        // Legend
        _buildLegend(context),
      ],
    );
  }
  
  Widget _buildTierSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View by: ',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(width: 8),
          SegmentedButton<ZoomTier>(
            segments: const [
              ButtonSegment(
                value: ZoomTier.year,
                label: Text('Year'),
                icon: Icon(Icons.calendar_today, size: 16),
              ),
              ButtonSegment(
                value: ZoomTier.month,
                label: Text('Month'),
                icon: Icon(Icons.date_range, size: 16),
              ),
              ButtonSegment(
                value: ZoomTier.week,
                label: Text('Week'),
                icon: Icon(Icons.view_week, size: 16),
              ),
            ],
            selected: {_currentTier},
            onSelectionChanged: (tiers) {
              setState(() {
                _currentTier = tiers.first;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBubbleLayout(BuildContext context, List<BubbleData> bubbles) {
    if (bubbles.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Use a wrap layout for flexible bubble positioning
    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: bubbles.map((bubble) {
            return BubbleWidget(
              data: bubble,
              baseSize: _getBaseSizeForTier(),
              onTap: () {
                widget.onBubbleTap?.call(bubble.start, bubble.end);
                _showBubbleDetails(context, bubble);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  double _getBaseSizeForTier() {
    switch (_currentTier) {
      case ZoomTier.year:
        return 100.0;
      case ZoomTier.month:
        return 80.0;
      case ZoomTier.week:
        return 70.0;
      case ZoomTier.day:
      case ZoomTier.focus:
        return 60.0;
    }
  }
  
  void _showBubbleDetails(BuildContext context, BubbleData bubble) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bubble.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Events', bubble.eventCount.toString()),
            _buildDetailRow('Category', bubble.dominantCategory),
            _buildDetailRow('Participants', bubble.participantIds.length.toString()),
            const SizedBox(height: 16),
            Text(
              'Tap "Zoom In" to view events in this period',
              style: Theme.of(context).textTheme.bodySmall,
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
            child: const Text('Zoom In'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: BubbleAggregationService.categoryColors.entries
            .take(6)
            .map((entry) => _buildLegendItem(context, entry.key, entry.value))
            .toList(),
      ),
    );
  }
  
  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No events yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add events to see your timeline bubbles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
