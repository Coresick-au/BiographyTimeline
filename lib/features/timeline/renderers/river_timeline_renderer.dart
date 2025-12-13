import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../renderers/river_visualization.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../social/models/user_models.dart' as social;
import '../../social/services/relationship_service.dart';

/// Widget for River timeline renderer
class RiverTimelineRendererWidget extends StatefulWidget {
  final TimelineRenderConfig config;
  final TimelineRenderData data;
  final TimelineEventCallback? onEventTap;
  final TimelineEventCallback? onEventLongPress;
  final TimelineDateCallback? onDateTap;
  final TimelineContextCallback? onContextTap;
  final ScrollController? scrollController;

  const RiverTimelineRendererWidget({
    Key? key,
    required this.config,
    required this.data,
    this.onEventTap,
    this.onEventLongPress,
    this.onDateTap,
    this.onContextTap,
    this.scrollController,
  }) : super(key: key);

  @override
  State<RiverTimelineRendererWidget> createState() => _RiverTimelineRendererWidgetState();
}

class _RiverTimelineRendererWidgetState extends State<RiverTimelineRendererWidget> {
  late RiverTimelineRenderer _renderer;

  @override
  void initState() {
    super.initState();
    _renderer = RiverTimelineRenderer();
    _renderer.initialize(widget.config);
    _renderer.updateData(widget.data);
  }

  @override
  void didUpdateWidget(RiverTimelineRendererWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _renderer.updateConfig(widget.config);
    }
    if (oldWidget.data != widget.data) {
      _renderer.updateData(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _renderer.build(
      onEventTap: widget.onEventTap,
      onEventLongPress: widget.onEventLongPress,
      onDateTap: widget.onDateTap,
      onContextTap: widget.onContextTap,
      scrollController: widget.scrollController,
    );
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }
}

/// River timeline renderer for merged timeline visualization
class RiverTimelineRenderer implements ITimelineRenderer {
  TimelineRenderConfig? _config;
  TimelineRenderData? _data;
  List<RiverNode> _nodes = [];
  List<RiverConnection> _connections = [];
  List<RiverEvent> _events = [];

  @override
  TimelineViewMode get viewMode => TimelineViewMode.river;

  @override
  String get displayName => 'River View';

  @override
  IconData get icon => Icons.water;

  @override
  String get description => 'Sankey-style visualization of merged timelines';

  @override
  bool get isReady => _config != null && _data != null;

  @override
  bool get supportsInfiniteScroll => false;

  @override
  bool get supportsZoom => true;

  @override
  bool get supportsFiltering => true;

  @override
  bool get supportsSearch => false;

  @override
  Future<void> initialize(TimelineRenderConfig config) async {
    _config = config;
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    _data = data;
    await _initializeRiverData();
  }

  @override
  Future<void> updateConfig(TimelineRenderConfig config) async {
    _config = config;
    await _initializeRiverData();
  }

  @override
  Widget build({
    BuildContext? context,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    if (!isReady || _nodes.isEmpty) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildRiverVisualization(context, onEventTap),
          ),
        ],
      ),
    );
  }

  @override
  List<TimelineEvent> getVisibleEvents() {
    return _data?.events ?? [];
  }

  @override
  DateTimeRange? getVisibleDateRange() {
    if (_data?.events.isEmpty ?? true) return null;
    
    final events = _data!.events;
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return DateTimeRange(
      start: sortedEvents.first.timestamp,
      end: sortedEvents.last.timestamp,
    );
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Implementation for navigating to specific date in river view
    // This would involve scrolling/zooming to the appropriate section
  }

  @override
  Future<void> navigateToEvent(String eventId) async {
    // Implementation for navigating to specific event in river view
    // This would highlight the event and scroll to its position
  }

  @override
  Future<void> setZoomLevel(double level) async {
    // Implementation for zooming the river visualization
    // This would adjust the spacing and width of river flows
  }

  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation for exporting river visualization as image
    return null;
  }

  @override
  TimelineRenderConfig get config => _config ?? TimelineRenderConfig(viewMode: viewMode);

  @override
  TimelineRenderData get data => _data ?? TimelineRenderData(
    events: [],
    contexts: [],
    earliestDate: DateTime.now(),
    latestDate: DateTime.now(),
    clusteredEvents: {},
  );

  @override
  void dispose() {
    _nodes.clear();
    _connections.clear();
    _events.clear();
  }

  Widget _buildEmptyState(BuildContext? context) {
    if (context == null) return const SizedBox.shrink();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Timeline Data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with others to see merged timelines',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext? context) {
    if (context == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'River Visualization',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Visualize how timelines merge and diverge between connected users',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsRow(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext? context) {
    if (context == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        _buildStatCard(context, 'Users', _nodes.length.toString(), Icons.people),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Connections', _connections.length.toString(), Icons.link),
        const SizedBox(width: 12),
        _buildStatCard(context, 'Shared Events', _events.length.toString(), Icons.share),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiverVisualization(BuildContext? context, TimelineEventCallback? onEventTap) {
    if (context == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: RiverVisualization(
          nodes: _nodes,
          connections: _connections,
          events: _events,
          onNodeTap: (node) => _handleNodeTap(context, node),
          onEventTap: (event) {
            final timelineEvent = _data?.events.firstWhere(
              (e) => e.id == event.eventId,
              orElse: () => throw Exception('Event not found'),
            );
            if (timelineEvent != null) {
              onEventTap?.call(timelineEvent);
            }
          },
          onAreaSelected: (area) => _handleAreaSelected(context, area),
        ),
      ),
    );
  }

  void _handleNodeTap(BuildContext context, RiverNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.userName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${node.userId}'),
            Text('Events: ${node.events.length}'),
            if (node.events.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Recent Events:'),
              ...node.events.take(3).map((event) => Text('• ${event.title}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleAreaSelected(BuildContext context, Rect area) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected area: ${area.width.toInt()}x${area.height.toInt()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('River Visualization'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This view shows how timelines merge and flow between connected users:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• Blue flows: Individual timeline segments'),
            Text('• Green flows: Shared events between users'),
            Text('• Purple flows: Merged timeline sections'),
            Text('• Orange flows: Diverged timeline sections'),
            SizedBox(height: 16),
            Text(
              'Tap on nodes to see user details, or on events to view specific moments.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _createSampleRiverData() {
    final now = DateTime.now();
    final userColors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
    ];

    // Create sample nodes (timeline segments)
    _nodes = [
      RiverNode(
        id: 'user1',
        userId: 'user1',
        userName: 'You',
        timestamp: now.subtract(const Duration(days: 30)),
        x: 50,
        y: 100,
        width: 200,
        color: userColors[0],
        events: [
          RiverEvent(
            id: 'event1',
            eventId: 'event1',
            title: 'Started Journey',
            timestamp: now.subtract(const Duration(days: 30)),
            participantIds: ['user1'],
            type: EventType.individual,
          ),
        ],
      ),
      RiverNode(
        id: 'user2',
        userId: 'user2',
        userName: 'Friend',
        timestamp: now.subtract(const Duration(days: 25)),
        x: 300,
        y: 100,
        width: 180,
        color: userColors[1],
        events: [
          RiverEvent(
            id: 'event2',
            eventId: 'event2',
            title: 'Joined Project',
            timestamp: now.subtract(const Duration(days: 25)),
            participantIds: ['user2'],
            type: EventType.individual,
          ),
        ],
      ),
      RiverNode(
        id: 'merged1',
        userId: 'merged',
        userName: 'Shared Timeline',
        timestamp: now.subtract(const Duration(days: 20)),
        x: 550,
        y: 100,
        width: 220,
        color: Colors.purple.shade400,
        events: [
          RiverEvent(
            id: 'event3',
            eventId: 'event3',
            title: 'Collaboration Started',
            timestamp: now.subtract(const Duration(days: 20)),
            participantIds: ['user1', 'user2'],
            type: EventType.shared,
          ),
        ],
      ),
      RiverNode(
        id: 'user3',
        userId: 'user3',
        userName: 'Partner',
        timestamp: now.subtract(const Duration(days: 15)),
        x: 300,
        y: 200,
        width: 160,
        color: userColors[2],
        events: [
          RiverEvent(
            id: 'event4',
            eventId: 'event4',
            title: ' Partnership',
            timestamp: now.subtract(const Duration(days: 15)),
            participantIds: ['user3'],
            type: EventType.individual,
          ),
        ],
      ),
    ];

    // Create connections (river flows)
    _connections = [
      RiverConnection(
        id: 'flow1',
        fromNodeId: 'user1',
        toNodeId: 'merged1',
        controlPoints: [
          const Offset(150, 118),
          const Offset(250, 118),
          const Offset(450, 118),
          const Offset(550, 118),
        ],
        width: 20,
        color: Colors.blue.shade300,
      ),
      RiverConnection(
        id: 'flow2',
        fromNodeId: 'user2',
        toNodeId: 'merged1',
        controlPoints: [
          const Offset(390, 118),
          const Offset(450, 118),
          const Offset(490, 118),
          const Offset(550, 118),
        ],
        width: 18,
        color: Colors.green.shade300,
      ),
      RiverConnection(
        id: 'flow3',
        fromNodeId: 'user3',
        toNodeId: 'merged1',
        controlPoints: [
          const Offset(380, 218),
          const Offset(450, 180),
          const Offset(500, 150),
          const Offset(550, 118),
        ],
        width: 16,
        color: Colors.purple.shade300,
      ),
    ];

    // Create events for visualization
    _events = [
      ..._nodes.expand((node) => node.events),
    ];
  }

  Future<void> _initializeRiverData() async {
    if (_data?.events.isEmpty ?? true) return;

    // Create river visualization from actual timeline data
    _createRiverDataFromEvents();
  }

  void _createRiverDataFromEvents() {
    if (_data?.events.isEmpty ?? true) return;

    final events = _data!.events;
    final now = DateTime.now();
    final userColors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
    ];

    // Sort events by timestamp
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Create river nodes based on actual timeline data
    _nodes = [
      RiverNode(
        id: 'main_timeline',
        userId: 'current_user',
        userName: 'Your Timeline',
        timestamp: sortedEvents.first.timestamp,
        x: 50,
        y: 150,
        width: 300,
        color: userColors[0],
        events: sortedEvents.map((event) => RiverEvent(
          id: 'river_${event.id}',
          eventId: event.id,
          title: event.title?.isNotEmpty == true ? event.title! : 'Timeline Event',
          timestamp: event.timestamp,
          participantIds: ['current_user'],
          type: EventType.individual,
        )).toList(),
      ),
    ];

    // Create connections between related events (grouped by context or time proximity)
    _connections = [];
    
    // Group events by month to create visual flows
    final monthlyGroups = <String, List<TimelineEvent>>{};
    for (final event in sortedEvents) {
      final monthKey = '${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}';
      monthlyGroups.putIfAbsent(monthKey, () => []).add(event);
    }

    // Create flow connections between monthly groups
    final sortedMonths = monthlyGroups.keys.toList()..sort();
    for (int i = 0; i < sortedMonths.length - 1; i++) {
      final currentMonth = sortedMonths[i];
      final nextMonth = sortedMonths[i + 1];
      
      final currentEvents = monthlyGroups[currentMonth]!;
      final nextEvents = monthlyGroups[nextMonth]!;
      
      if (currentEvents.isNotEmpty && nextEvents.isNotEmpty) {
        _connections.add(RiverConnection(
          id: 'flow_$i',
          fromNodeId: 'main_timeline',
          toNodeId: 'main_timeline',
          controlPoints: [
            Offset(50 + (i * 80), 168),
            Offset(90 + (i * 80), 168),
            Offset(130 + (i * 80), 168),
            Offset(170 + (i * 80), 168),
          ],
          width: 20.0 - (i * 2), // Gradually decrease width
          color: userColors[0].withOpacity(0.7),
        ));
      }
    }

    // Create events for visualization
    _events = _nodes.expand((node) => node.events).toList();

    // Add shared events if there are any with location data
    final locationEvents = sortedEvents.where((e) => e.location != null).toList();
    if (locationEvents.isNotEmpty) {
      _nodes.add(RiverNode(
        id: 'location_timeline',
        userId: 'location_user',
        userName: 'Location Events',
        timestamp: locationEvents.first.timestamp,
        x: 400,
        y: 150,
        width: 250,
        color: userColors[1],
        events: locationEvents.map((event) => RiverEvent(
          id: 'loc_${event.id}',
          eventId: event.id,
          title: event.title?.isNotEmpty == true ? event.title! : 'Location Event',
          timestamp: event.timestamp,
          participantIds: ['current_user'],
          type: EventType.shared,
        )).toList(),
      ));

      // Add connection from main timeline to location events
      _connections.add(RiverConnection(
        id: 'location_flow',
        fromNodeId: 'main_timeline',
        toNodeId: 'location_timeline',
        controlPoints: [
          const Offset(350, 168),
          const Offset(375, 168),
          const Offset(400, 168),
        ],
        width: 15,
        color: userColors[1].withOpacity(0.7),
      ));
    }
  }
}
