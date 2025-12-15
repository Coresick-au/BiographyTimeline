import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/flow_layout_engine.dart';
import '../widgets/flow_widgets.dart';
import '../../../shared/models/timeline_event.dart';

/// Renderer for the Flow View (KinFlow style)
class FlowTimelineRenderer extends BaseTimelineRenderer {
  final FlowLayoutEngine _layoutEngine = FlowLayoutEngine();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController(); // Usually flow view is fixed vertically or fits screen

  List<FlowPath> _paths = [];
  Size _contentSize = Size.zero;
  
  FlowTimelineRenderer(
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) : super(config, data);

  @override
  void onDataUpdated() {
    _calculateLayout();
  }
  
  @override
  void onConfigUpdated() {
    _calculateLayout();
  }

  void _calculateLayout() {
    if (data.events.isEmpty) return;

    final owners = data.events.map((e) => e.ownerId).toSet().toList()..sort();
    
    // Pixels per day could be dynamic based on zoom
    // config.zoomLevel? 
    // Default zoom level 0.5 -> ~50px per day?
    // Let's settle on a base and scale.
    final pixelsPerDay = 50.0 * (config.zoomLevel ?? 1.0);
    
    _paths = _layoutEngine.calculateFlowPaths(
      events: data.events,
      laneOwnerIds: owners,
      startDate: data.earliestDate,
      pixelsPerDay: pixelsPerDay,
    );
    
    // Calculate content size
    double maxWidth = 0;
    double maxHeight = owners.length * FlowLayoutEngine.kLaneHeight + 100.0;
    
    for (final path in _paths) {
      for (final node in path.nodes) {
        if (node.position.dx > maxWidth) maxWidth = node.position.dx;
      }
    }
    maxWidth += 300.0; // Padding
    
    _contentSize = Size(maxWidth, maxHeight);
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
    if (_paths.isEmpty) {
      return const Center(child: Text('No flow data available'));
    }

    return Container(
      color: const Color(0xFF0F172A), // Deep dark background for neon effect
      child: Stack(
        children: [
          // Background Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.3),
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          
          // Scrollable Canvas
          SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: _contentSize.width,
                height: _contentSize.height,
                child: Stack(
                  children: [
                    // Stream Painter
                    CustomPaint(
                      size: _contentSize,
                      painter: FlowPainter(
                        paths: _paths,
                        zoomLevel: config.zoomLevel ?? 1.0,
                      ),
                    ),
                    
                    // Node Overlays (Hit Targets)
                    ..._buildNodeOverlays(onEventTap),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating Controls (Left Panel Placeholder)
          const Positioned(
            left: 20,
            bottom: 20,
            child: Card(
              color: Colors.black54,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Flow View', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNodeOverlays(TimelineEventCallback? onTap) {
    final widgets = <Widget>[];
    
    for (final path in _paths) {
      for (final node in path.nodes) {
        widgets.add(Positioned(
          left: node.position.dx - 22, // Center assumption (44 width)
          top: node.position.dy - 22,
          child: StreamNodeWidget(
            node: node,
            scale: config.zoomLevel ?? 1.0,
            onTap: onTap != null ? () => onTap(node.event) : null,
          ),
        ));
      }
    }
    
    return widgets;
  }
}
