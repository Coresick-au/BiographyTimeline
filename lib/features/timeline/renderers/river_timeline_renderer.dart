import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../renderers/river_visualization.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// River timeline renderer for merged timeline visualization
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
      context: context,
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

/// River timeline renderer
class RiverTimelineRenderer implements ITimelineRenderer {
  TimelineRenderConfig? _config;
  TimelineRenderData? _data;
  List<RiverNode> _nodes = [];
  List<RiverConnection> _connections = [];
  List<RiverEvent> _events = [];
  
  // Layout constants
  double _totalWidth = 1000.0;
  final double _nodeSpacing = 250.0;
  final double _nodeY = 200.0;
  final double _nodeHeight = 40.0;

  @override
  TimelineViewMode get viewMode => TimelineViewMode.river;
  @override
  String get displayName => 'River View';
  @override
  IconData get icon => Icons.water;
  @override
  String get description => 'Flowing visualization of timeline events';
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
    if (_data != null) _initializeRiverData();
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    _data = data;
    if (_config != null) _initializeRiverData();
  }

  @override
  Future<void> updateConfig(TimelineRenderConfig config) async {
    _config = config;
    if (_data != null) _initializeRiverData();
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
    debugPrint('DEBUG: RiverRenderer.build() called');
    debugPrint('DEBUG: isReady = $isReady');
    debugPrint('DEBUG: _nodes.isEmpty = ${_nodes.isEmpty}');
    debugPrint('DEBUG: _nodes.length = ${_nodes.length}');
    
    if (!isReady || _nodes.isEmpty) {
      debugPrint('DEBUG: Showing empty state');
      return _buildEmptyState(context);
    }

    debugPrint('DEBUG: About to build river visualization');
    
    return Column(
      children: [
        if (context != null) _buildHeader(context),
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 4.0,
            constrained: false, // Allow canvas to be larger than screen
            child: SizedBox(
              width: _totalWidth,
              height: 800, // Fixed height canvas
              child: _buildRiverVisualization(context, onEventTap),
            ),
          ),
        ),
      ],
    );
  }

  /// Generate a vibrant color palette for multiple users
  List<Color> _generateColorPalette(int userCount) {
    // Base palette of distinct, vibrant colors
    final baseColors = [
      Colors.blue.shade400,      // Blue
      Colors.purple.shade400,    // Purple
      Colors.green.shade400,     // Green
      Colors.orange.shade400,    // Orange
      Colors.pink.shade400,      // Pink
      Colors.teal.shade400,      // Teal
      Colors.amber.shade400,     // Amber
      Colors.cyan.shade400,      // Cyan
      Colors.lime.shade400,      // Lime
      Colors.indigo.shade400,    // Indigo
    ];
    
    if (userCount <= baseColors.length) {
      return baseColors.sublist(0, userCount);
    }
    
    // If more users than base colors, generate additional colors
    final colors = List<Color>.from(baseColors);
    for (int i = baseColors.length; i < userCount; i++) {
      final hue = (i * 360.0 / userCount) % 360;
      colors.add(HSLColor.fromAHSL(1.0, hue, 0.6, 0.6).toColor());
    }
    return colors;
  }

  void _initializeRiverData() {
    debugPrint('DEBUG: RiverRenderer._initializeRiverData() called');
    
    if (_data?.events.isEmpty ?? true) {
      _nodes = [];
      _connections = [];
      _events = [];
      return;
    }

    final events = _data!.events;
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Group events by both time period AND user
    final Map<String, Map<String, List<TimelineEvent>>> timeUserGroups = {};
    final Set<String> allUserIds = {};
    
    for (var event in sortedEvents) {
      final timeKey = "${event.timestamp.year}-${event.timestamp.month.toString().padLeft(2, '0')}";
      final userId = event.ownerId; // Extract user ID from event
      
      allUserIds.add(userId);
      
      if (!timeUserGroups.containsKey(timeKey)) {
        timeUserGroups[timeKey] = {};
      }
      
      if (!timeUserGroups[timeKey]!.containsKey(userId)) {
        timeUserGroups[timeKey]![userId] = [];
      }
      timeUserGroups[timeKey]![userId]!.add(event);
    }

    _nodes = [];
    _connections = [];
    _events = [];

    // Dynamic color palette for unlimited users
    final colorPalette = _generateColorPalette(allUserIds.length);
    final Map<String, Color> userColors = {};
    int colorIndex = 0;
    for (final userId in allUserIds) {
      userColors[userId] = colorPalette[colorIndex % colorPalette.length];
      colorIndex++;
    }

    // Calculate dynamic Y positions based on user count
    final userCount = allUserIds.length;
    const canvasHeight = 800.0; // Matches the fixed height in build method
    const verticalPadding = 150.0; // Padding from top/bottom
    final availableHeight = canvasHeight - (2 * verticalPadding);
    
    final Map<String, double> userYPositions = {};
    if (userCount == 1) {
      userYPositions[allUserIds.first] = canvasHeight / 2;
    } else {
      final userSpacing = availableHeight / (userCount - 1);
      int userIndex = 0;
      for (final userId in allUserIds) {
        userYPositions[userId] = verticalPadding + (userIndex * userSpacing);
        userIndex++;
      }
    }

    double currentX = 50.0;
    final sortedTimeKeys = timeUserGroups.keys.toList()..sort();
    
    // Track previous nodes for each user to create connections
    final Map<String, RiverNode> previousNodes = {};

    for (var timeKey in sortedTimeKeys) {
      final usersInPeriod = timeUserGroups[timeKey]!;
      final parts = timeKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final monthName = _getMonthName(date.month);
      
      // Check if this is a shared event (both users have events at same time)
      final isSharedPeriod = usersInPeriod.length > 1;
      final sharedY = isSharedPeriod ? 250.0 : null; // Middle position for shared events

      // Create nodes for each user in this time period
      for (var userId in usersInPeriod.keys) {
        final userEvents = usersInPeriod[userId]!;
        final adaptiveWidth = 120.0 + (userEvents.length * 80.0);
        final yPos = sharedY ?? userYPositions[userId]!;
        
        final node = RiverNode(
          id: 'node_${timeKey}_$userId',
          userId: userId,
          userName: isSharedPeriod ? "$monthName ${date.year} (Shared)" : "$monthName ${date.year}",
          timestamp: date,
          x: currentX,
          y: yPos,
          width: adaptiveWidth,
          color: userColors[userId] ?? Colors.teal.shade400,
          events: userEvents.map((e) => RiverEvent(
            id: e.id,
            eventId: e.id,
            title: e.title ?? 'Untitled Event',
            timestamp: e.timestamp,
            participantIds: [],
            type: EventType.individual,
          )).toList(),
        );
        
        _nodes.add(node);

        // Create connection from previous node for this user
        if (previousNodes.containsKey(userId)) {
          final prevNode = previousNodes[userId]!;
          final gap = 100.0;
          
          _connections.add(RiverConnection(
            id: 'conn_${prevNode.id}_${node.id}',
            fromNodeId: prevNode.id,
            toNodeId: node.id,
            controlPoints: [
              Offset(prevNode.x + prevNode.width, prevNode.y + (_nodeHeight/2)),
              Offset(prevNode.x + prevNode.width + (gap/2), prevNode.y + (_nodeHeight/2)),
              Offset(node.x - (gap/2), node.y + (_nodeHeight/2)),
              Offset(node.x, node.y + (_nodeHeight/2)),
            ],
            width: 20,
            color: (userColors[userId] ?? Colors.teal.shade400).withOpacity(0.6),
          ));
        }
        
        previousNodes[userId] = node;
      }
      
      // Advance X position for next time period
      final maxWidth = usersInPeriod.values
          .map((events) => 120.0 + (events.length * 80.0))
          .reduce((a, b) => a > b ? a : b);
      currentX += maxWidth + 100.0;
    }

    _events = _nodes.expand((n) => n.events).toList();
    _totalWidth = currentX + 200.0;
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildRiverVisualization(BuildContext? context, TimelineEventCallback? onEventTap) {
    if (context == null) return const SizedBox.shrink();
    
    debugPrint('DEBUG: _buildRiverVisualization called');
    debugPrint('DEBUG: _totalWidth = $_totalWidth');
    debugPrint('DEBUG: _nodes.length = ${_nodes.length}');
    
    // Pass the calculated data to the Painter
    return RiverVisualization(
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
    );
  }

  void _handleNodeTap(BuildContext context, RiverNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${node.userName}: ${node.events.length} events')),
    );
  }

  // --- Boilerplate implementations for Interface ---
  @override
  List<TimelineEvent> getVisibleEvents() => _data?.events ?? [];
  @override
  DateTimeRange? getVisibleDateRange() => null;
  @override
  Future<void> navigateToDate(DateTime date) async {}
  @override
  Future<void> navigateToEvent(String eventId) async {}
  @override
  Future<void> setZoomLevel(double level) async {}
  @override
  Future<Uint8List?> exportAsImage() async => null;
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
          Icon(Icons.water_outlined, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text('Add events to see the river flow', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
     return Padding(
       padding: const EdgeInsets.all(16.0),
       child: Text("River View (Drag to pan, Pinch to zoom)", 
         style: Theme.of(context).textTheme.labelSmall
       ),
     );
  }
}
