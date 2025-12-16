import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/flow_layout_engine.dart';
import '../widgets/flow_widgets.dart';
import '../models/river_flow_models.dart';
import '../../../shared/models/timeline_event.dart';
import 'dart:math' as math;

/// Renderer for the RiverFlow View
/// Displays person-based flowing streams with intersection points
class FlowTimelineRenderer extends BaseTimelineRenderer {
  FlowTimelineRenderer(
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) : super(config, data);

  @override
  void onDataUpdated() {}

  @override
  void onConfigUpdated() {}

  @override
  Widget build({
    BuildContext? context,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return RiverFlowView(
      events: data.events,
      earliestDate: data.earliestDate,
      zoomLevel: config.zoomLevel ?? 1.0,
      onEventTap: onEventTap,
    );
  }
}

/// Stateful widget for RiverFlow visualization with person filtering
class RiverFlowView extends StatefulWidget {
  final List<TimelineEvent> events;
  final DateTime earliestDate;
  final double zoomLevel;
  final void Function(TimelineEvent)? onEventTap;

  const RiverFlowView({
    super.key,
    required this.events,
    required this.earliestDate,
    required this.zoomLevel,
    this.onEventTap,
  });

  @override
  State<RiverFlowView> createState() => _RiverFlowViewState();
}

class _RiverFlowViewState extends State<RiverFlowView> {
  final RiverFlowLayoutEngine _layoutEngine = RiverFlowLayoutEngine();
  final ScrollController _scrollController = ScrollController();

  List<RiverFlowPath> _paths = [];
  Size _contentSize = Size.zero;
  
  // New State for Zoom and Filters
  double _zoomMultiplier = 1.0;
  Set<String> _selectedEventTypes = {}; // Empty means all
  bool _showFilters = false;
  bool _showEventNodes = true; // Toggle for showing/hiding event markers

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {}); // Update mini-map on scroll
    });
  }

  @override
  void didUpdateWidget(RiverFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
    }
  }

  void _calculateLayout(double viewWidth) {
    if (widget.events.isEmpty || viewWidth <= 0) {
      _paths = [];
      _contentSize = Size(viewWidth > 0 ? viewWidth : 400, 500);
      return;
    }

    // 1. Filter events based on selections
    // Events are already filtered by person externally, so we only need to filter by local type toggles.
    var filteredEvents = widget.events.where((e) {
      if (_selectedEventTypes.isNotEmpty) {
        bool typeMatch = _selectedEventTypes.contains(e.eventType);
        // Also check simplified types mapping
        if (!typeMatch) {
             if (_selectedEventTypes.contains('Milestone') && e.eventType == 'milestone') typeMatch = true;
             if (_selectedEventTypes.contains('Photo') && (e.eventType == 'photo' || e.eventType == 'photo_burst')) typeMatch = true;
             if (_selectedEventTypes.contains('Achievement') && e.tags.contains('Achievement')) typeMatch = true;
        }
        if (!typeMatch) return false;
      }
      return true;
    }).toList();

    if (filteredEvents.isEmpty) {
      _paths = [];
      _contentSize = Size(viewWidth, 500);
      return;
    }

    // 2. Calculate adaptive scale
    filteredEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final earliest = filteredEvents.first.timestamp;
    final latest = filteredEvents.last.timestamp;
    final totalDays = latest.difference(earliest).inDays.abs() + 1;
    
    // Target a sensible content height based on zoom
    // Base height of ~1500px, scaled by zoom
    final baseHeight = 1500.0;
    final targetHeight = (baseHeight * widget.zoomLevel * _zoomMultiplier)
        .clamp(400.0, 20000.0); // Allow it to get quite small (400px) or very large
    
    // Calculate pixelsPerDay
    // Allow much wider range for zoom: 0.1 to 10.0
    final pixelsPerDay = (targetHeight / totalDays).clamp(0.05, 10.0);
    
    // 3. Layout
    // Extract participants visible in these filtered events
    final visibleParticipants = filteredEvents
        .expand((e) => [e.ownerId, ...e.participantIds])
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()..sort();

    _paths = _layoutEngine.calculateRiverPaths(
      events: filteredEvents, 
      selectedPersonIds: visibleParticipants,
      startDate: widget.earliestDate,
      pixelsPerDay: pixelsPerDay,
      laneWidth: 150.0 * math.min(1.0, math.max(0.5, _zoomMultiplier)),
      viewWidth: viewWidth,
    );

    _contentSize = _layoutEngine.calculateContentSize(
      events: filteredEvents,
      selectedPersonIds: visibleParticipants,
      startDate: widget.earliestDate,
      pixelsPerDay: pixelsPerDay,
      laneWidth: 150.0,
      viewWidth: viewWidth,
    );
  }


  
  void _toggleEventType(String type) {
    setState(() {
      if (_selectedEventTypes.contains(type)) {
        _selectedEventTypes.remove(type);
      } else {
        _selectedEventTypes.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewWidth = constraints.maxWidth;
        if (viewWidth > 0) {
          _calculateLayout(viewWidth);
        }

        return Container(
          color: const Color(0xFF0A0F1A),
          child: Column(
            children: [
              _buildControlPanel(),
              Expanded(
                child: _paths.isEmpty
                    ? _buildEmptyState()
                    : _buildRiverContent(constraints),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1420),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Title, Zoom, Filter Toggle
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue.shade300, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Life Flow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              
              // Zoom Controls
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out, size: 16, color: Colors.white54),
                    SizedBox(
                      width: 100,
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _zoomMultiplier,
                          min: 0.2,
                          max: 3.0,
                          activeColor: Colors.blue.shade400,
                          inactiveColor: Colors.white10,
                          onChanged: (val) => setState(() => _zoomMultiplier = val),
                        ),
                      ),
                    ),
                    const Icon(Icons.zoom_in, size: 16, color: Colors.white54),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Event Nodes Toggle
              IconButton(
                icon: Icon(
                  _showEventNodes ? Icons.visibility : Icons.visibility_off,
                  color: _showEventNodes ? Colors.blue.shade300 : Colors.white54,
                ),
                onPressed: () => setState(() => _showEventNodes = !_showEventNodes),
                tooltip: _showEventNodes ? 'Hide Events' : 'Show Events',
              ),
              
              // Filter Toggle
              IconButton(
                icon: Icon(
                  Icons.filter_list, 
                  color: _showFilters || _selectedEventTypes.isNotEmpty ? Colors.blue.shade300 : Colors.white54
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: 'Filter Events',
              ),
            ],
          ),
          
          if (_showFilters) ...[
            const SizedBox(height: 12),
            // Event Type Filters
             Row(
               children: [
                 Text('Show only:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: [
                       _buildFilterChip('Milestone', Icons.star),
                       _buildFilterChip('Photo', Icons.photo),
                       _buildFilterChip('Achievement', Icons.emoji_events),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
          
          // Note: Global person selector is in the top app bar
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedEventTypes.contains(label);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _toggleEventType(label),
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: Colors.blue.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.events.isEmpty 
                ? 'No events found' 
                : 'No events match your filters',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiverContent(BoxConstraints constraints) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 2.0,
                colors: [
                  const Color(0xFF1A1F2E).withOpacity(0.5),
                  const Color(0xFF0A0F1A),
                ],
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            width: constraints.maxWidth,
            height: _contentSize.height,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, _contentSize.height),
                  painter: RiverFlowPainter(
                    paths: _paths,
                    zoomLevel: widget.zoomLevel,
                  ),
                ),
                ..._buildPersonInfoBoxes(),
                if (_showEventNodes) ..._buildEventNodes(),
                if (_showEventNodes) ..._buildEventLabels(),
              ],
            ),
          ),
        ),
        
        // Mini-map navigator
        if (_paths.isNotEmpty && _contentSize.height > 0)
          RiverFlowMiniMap(
            paths: _paths,
            contentHeight: _contentSize.height,
            viewportHeight: constraints.maxHeight,
            scrollPosition: _scrollController.hasClients ? _scrollController.offset : 0,
            onSeek: (targetPosition) {
              _scrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
          ),
      ],
    );
  }
  
  // Reusing existing helper methods
  List<Widget> _buildPersonInfoBoxes() {
    return _paths.map((path) {
      return Positioned(
        left: path.originPosition.dx - 50,
        top: path.originPosition.dy - 40,
        child: RiverPersonInfoBox(flowPath: path),
      );
    }).toList();
  }

  List<Widget> _buildEventNodes() {
    final widgets = <Widget>[];
    for (final path in _paths) {
      for (final node in path.nodes) {
        final nodeSize = (node.isJunction ? 56.0 : 44.0) * math.min(1.2, math.max(0.6, _zoomMultiplier));
        widgets.add(
          Positioned(
            left: node.position.dx - nodeSize / 2,
            top: node.position.dy - nodeSize / 2,
            child: Transform.scale(
              scale: math.min(1.2, math.max(0.6, _zoomMultiplier)),
               child: RiverEventNode(
                node: node,
                streamColor: path.color,
                scale: widget.zoomLevel,
                onTap: widget.onEventTap != null ? () => widget.onEventTap!(node.event) : null,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
  
  List<Widget> _buildEventLabels() {
    // Only show labels if zoom is high enough
    if (_zoomMultiplier < 0.5) return [];
    
    final widgets = <Widget>[];
    for (final path in _paths) {
      for (int i = 0; i < path.nodes.length; i++) {
        final node = path.nodes[i];
         // Logic to thin out labels if zoomed out
        bool shouldShow = node.isJunction;
        if (!shouldShow) {
           final density = (1.0 / _zoomMultiplier).round();
           shouldShow = (i % (density > 0 ? density * 4 : 4) == 0) && node.event.title != null;
        }

        if (shouldShow) {
          final isLeft = path.originPosition.dx < 400;
          final labelOffset = isLeft ? -160.0 : 50.0;
          widgets.add(
            Positioned(
              left: node.position.dx + labelOffset,
              top: node.position.dy - 20,
              child: RiverEventLabel(
                node: node,
                streamColor: path.color,
                isLeft: !isLeft,
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }
  

  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Needed to avoid import errors since math is used

