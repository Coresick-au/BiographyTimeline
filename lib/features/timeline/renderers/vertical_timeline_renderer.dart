import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../models/timeline_render_data.dart';
import '../widgets/timeline_event_card.dart'; // Ensure this import points to your existing card widget

/// Vertical timeline renderer implementation
class VerticalTimelineRenderer extends BaseTimelineRenderer {
  VerticalTimelineRenderer() : super(
    // 1. Fixed Configuration (Removed invalid 'activeContext')
    const TimelineRenderConfig(
      viewMode: TimelineViewMode.chronological,
      startDate: null,
      endDate: null,
      selectedEventIds: <String>{},
      showPrivateEvents: false,
      zoomLevel: 1.0,
      customSettings: {},
    ),
    // 2. Sample Data Added
    TimelineRenderData(
      events: [
        TimelineEvent(
          id: 'sample-1',
          tags: ['Coding', 'Milestone'],
          ownerId: 'current-user',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          eventType: 'milestone',
          customAttributes: {},
          assets: [],
          title: 'Timeline Fixed',
          description: 'Successfully restored the vertical timeline renderer with a visual spine and resolved compilation errors.',
          participantIds: [],
          isPrivate: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TimelineEvent(
          id: 'sample-2',
          tags: ['Design'],
          ownerId: 'current-user',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          eventType: 'text',
          customAttributes: {},
          assets: [],
          title: 'Design Review',
          description: 'Analyzing the new vertical layout structure. The spine connects events chronologically.',
          participantIds: [],
          isPrivate: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TimelineEvent(
          id: 'sample-3',
          tags: ['Memory'],
          ownerId: 'current-user',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          eventType: 'photo',
          customAttributes: {},
          assets: [],
          title: 'Project Start',
          description: 'The beginning of this biography application journey.',
          participantIds: [],
          isPrivate: false,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      contexts: [],
      earliestDate: DateTime.now().subtract(const Duration(days: 10)),
      latestDate: DateTime.now(),
      clusteredEvents: {},
    ),
  );

  @override
  Widget build({
    BuildContext? context,
    void Function(TimelineEvent)? onEventTap,
    void Function(TimelineEvent)? onEventLongPress,
    void Function(DateTime)? onDateTap,
    void Function(Context)? onContextTap,
    ScrollController? scrollController,
  }) {
    // 1. Sort events: Newest at the top (standard for social/biography)
    final sortedEvents = List<TimelineEvent>.from(data.events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (sortedEvents.isEmpty) {
      return Builder(
        builder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text(
                  "No events yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Add your first memory to start the timeline!"),
              ],
            ),
          );
        },
      );
    }

    // 2. Build the list with the "Line" visual
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final isLast = index == sortedEvents.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- THE VISUAL LINE SECTION ---
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // The Dot (Node) representing the event
                    Container(
                      margin: const EdgeInsets.only(top: 20), // Align dot with Card title
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    
                    // The Line (Spine) connecting this dot to the next
                    Expanded(
                      child: isLast
                          ? const SizedBox.shrink() // No line after the last event
                          : Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // --- THE CONTENT SECTION ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: TimelineEventCard(
                    event: event,
                    onTap: () => onEventTap?.call(event),
                  ),
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
    // No complex init needed for simple vertical list
  }
  
  @override
  void dispose() {
    // Clean up resources if needed
  }
}
