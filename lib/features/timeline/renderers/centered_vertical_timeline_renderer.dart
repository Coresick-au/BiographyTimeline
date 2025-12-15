import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../models/timeline_render_data.dart';
import '../widgets/timeline_event_card.dart';

/// Beautiful centered vertical timeline with alternating cards and animations
class CenteredVerticalTimelineRenderer extends BaseTimelineRenderer {
  CenteredVerticalTimelineRenderer(
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) : super(config, data);

  @override
  Widget build({
    BuildContext? context,
    void Function(TimelineEvent)? onEventTap,
    void Function(TimelineEvent)? onEventLongPress,
    void Function(DateTime)? onDateTap,
    void Function(Context)? onContextTap,
    ScrollController? scrollController,
  }) {
    // Sort events: Newest at the top
    final sortedEvents = List<TimelineEvent>.from(data.events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (sortedEvents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final isLeft = index % 2 == 0; // Alternate sides
        final isLast = index == sortedEvents.length - 1;
        
        // Check if we need a month header
        final showMonthHeader = index == 0 || 
          _isDifferentMonth(sortedEvents[index - 1].timestamp, event.timestamp);

        // Stagger animation delay
        final delay = Duration(milliseconds: 50 * index);

        return Column(
          children: [
            if (showMonthHeader) _buildMonthHeader(context, event.timestamp),
            _buildAnimatedTimelineItem(
              context,
              event,
              isLeft,
              isLast,
              onEventTap,
              delay,
            ),
          ],
        );
      },
    );
  }

  bool _isDifferentMonth(DateTime date1, DateTime date2) {
    return date1.year != date2.year || date1.month != date2.month;
  }

  Widget _buildMonthHeader(BuildContext context, DateTime date) {
    final monthYear = DateFormat('MMMM yyyy').format(date);
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32.0, top: 24.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  monthYear,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTimelineItem(
    BuildContext context,
    TimelineEvent event,
    bool isLeft,
    bool isLast,
    void Function(TimelineEvent)? onEventTap,
    Duration delay,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              isLeft ? -50 * (1 - value) : 50 * (1 - value),
              0,
            ),
            child: child,
          ),
        );
      },
      child: _buildTimelineItem(
        context,
        event,
        isLeft,
        isLast,
        onEventTap,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEvent event,
    bool isLeft,
    bool isLast,
    void Function(TimelineEvent)? onEventTap,
  ) {
    const spineWidth = 4.0;
    const dotSize = 24.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left card (or spacer)
          Expanded(
            flex: 42,
            child: isLeft
                ? Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: _buildEventCard(context, event, onEventTap, Alignment.centerRight),
                  )
                : const SizedBox(),
          ),

          // Center spine
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Connecting line from previous event
                Container(
                  width: spineWidth,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Event dot with pulse animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.8, end: 1.0),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _getEventIcon(context, event),
                    ),
                  ),
                ),

                // Connecting line to next event
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                          width: spineWidth,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Right card (or spacer)
          Expanded(
            flex: 42,
            child: !isLeft
                ? Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: _buildEventCard(context, event, onEventTap, Alignment.centerLeft),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    TimelineEvent event,
    void Function(TimelineEvent)? onEventTap,
    Alignment alignment,
  ) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: TimelineEventCard(
          event: event,
          onTap: () => onEventTap?.call(event),
        ),
      ),
    );
  }

  Widget? _getEventIcon(BuildContext context, TimelineEvent event) {
    IconData? iconData;
    
    switch (event.eventType.toLowerCase()) {
      case 'milestone':
        iconData = Icons.flag;
        break;
      case 'photo':
        iconData = Icons.photo_camera;
        break;
      case 'video':
        iconData = Icons.videocam;
        break;
      case 'text':
        iconData = Icons.article;
        break;
      default:
        return null;
    }

    return Icon(
      iconData,
      size: 12,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) {
        return Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timeline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "No events yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Add your first memory to start the timeline!",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> initialize(dynamic config) async {
    // No complex init needed
  }

  @override
  void dispose() {
    // Clean up resources if needed
  }
}
