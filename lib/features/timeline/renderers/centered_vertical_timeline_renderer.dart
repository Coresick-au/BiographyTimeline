import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../models/timeline_render_data.dart';
import '../widgets/timeline_event_card.dart';

/// Beautiful centered vertical timeline with alternating cards
class CenteredVerticalTimelineRenderer extends BaseTimelineRenderer {
  CenteredVerticalTimelineRenderer() : super(
    const TimelineRenderConfig(
      viewMode: TimelineViewMode.chronological,
      startDate: null,
      endDate: null,
      selectedEventIds: <String>{},
      showPrivateEvents: false,
      zoomLevel: 1.0,
      customSettings: {},
    ),
    TimelineRenderData(
      events: [],
      contexts: [],
      earliestDate: DateTime.now(),
      latestDate: DateTime.now(),
      clusteredEvents: {},
    ),
  );

  @override
  Widget build({
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

        return Column(
          children: [
            if (showMonthHeader) _buildMonthHeader(context, event.timestamp),
            _buildTimelineItem(
              context,
              event,
              isLeft,
              isLast,
              onEventTap,
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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              monthYear,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
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
    const dotSize = 20.0;
    const cardWidth = 0.42; // 42% of screen width

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left card (or spacer)
          Expanded(
            flex: 42,
            child: isLeft
                ? Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildEventCard(context, event, onEventTap, Alignment.centerRight),
                  )
                : const SizedBox(),
          ),

          // Center spine
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Connecting line from previous event
                if (!isLast)
                  Container(
                    width: spineWidth,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                // Event dot
                Container(
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _getEventIcon(context, event),
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
                                Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                    padding: const EdgeInsets.only(left: 16.0),
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
        padding: const EdgeInsets.only(bottom: 32.0),
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
      size: 10,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                "No events yet",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add your first memory to start the timeline!",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
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
