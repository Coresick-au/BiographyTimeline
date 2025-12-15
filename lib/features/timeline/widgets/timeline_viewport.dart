import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timeline_view_state.dart';
import '../models/render_node.dart';
import '../services/timeline_layout_engine.dart';
import '../services/timeline_data_service.dart';
import '../providers/timeline_viewport_provider.dart';
import 'timeline_painter.dart';
import 'timeline_event_card.dart';
import '../../../shared/design_system/design_system.dart' hide TimelineEventCard;

/// Unified timeline viewport widget
/// 
/// Handles both vertical and horizontal orientations with a single
/// implementation. Manages gestures, rendering, and card overlays.
class TimelineViewport extends ConsumerStatefulWidget {
  const TimelineViewport({super.key});

  @override
  ConsumerState<TimelineViewport> createState() => _TimelineViewportState();
}

class _TimelineViewportState extends ConsumerState<TimelineViewport> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(timelineViewStateProvider);
    final renderNodes = ref.watch(renderNodesProvider);
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get min date for position calculations
        final timelineState = ref.watch(timelineDataProvider);
        final minDate = timelineState.maybeWhen(
          data: (state) {
            if (state.filteredEvents.isEmpty) return DateTime.now();
            return state.filteredEvents
                .map((e) => e.timestamp)
                .reduce((a, b) => a.isBefore(b) ? a : b);
          },
          orElse: () => DateTime.now(),
        );
        
        // Compute layout
        final layoutNodes = TimelineLayoutEngine.layout(
          nodes: renderNodes,
          mode: viewState.displayMode,
          orientation: viewState.orientation,
          viewportSize: constraints.biggest,
          pixelsPerDay: viewState.pixelsPerDay,
          minDate: minDate,
        );
        
        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, layoutNodes),
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _handleScroll(event);
              }
            },
            child: Stack(
              children: [
                // Timeline canvas (axis + markers)
                CustomPaint(
                  size: constraints.biggest,
                  painter: TimelinePainter(
                    layoutNodes: layoutNodes,
                    orientation: viewState.orientation,
                    displayMode: viewState.displayMode,
                    selectedEventId: viewState.selectedEventId,
                    colorScheme: theme.colorScheme,
                  ),
                ),
                
                // Card overlay (maximal mode only)
                if (viewState.displayMode == TimelineDisplayMode.maximal)
                  _buildCardOverlay(layoutNodes, viewState),
                
                // Zoom controls
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: _buildZoomControls(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Build card overlay with positioned event cards
  Widget _buildCardOverlay(List<LayoutNode> layoutNodes, TimelineViewState viewState) {
    return Stack(
      children: layoutNodes
          .where((node) => node.cardRect != null)
          .map((layoutNode) {
        final cardRect = layoutNode.cardRect!;
        final node = layoutNode.node;
        
        if (node is! EventNode) return const SizedBox.shrink();
        
        return Positioned(
          left: cardRect.left,
          top: cardRect.top,
          width: cardRect.width,
          height: cardRect.height,
          child: TimelineEventCard(
            event: _createEventFromNode(node),
            isExpanded: false,
            onTap: () => _selectEvent(node.eventId),
          ),
        );
      }).toList(),
    );
  }
  
  /// Build zoom controls
  Widget _buildZoomControls() {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(AppIcons.add),
            onPressed: () => ref.read(timelineViewStateProvider.notifier).zoomIn(),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(AppIcons.remove),
            onPressed: () => ref.read(timelineViewStateProvider.notifier).zoomOut(),
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }
  
  /// Handle tap on timeline
  void _handleTap(Offset position, List<LayoutNode> layoutNodes) {
    // Check if tapped on a marker
    for (final layoutNode in layoutNodes) {
      final markerCenter = layoutNode.markerCenter;
      final distance = (position - markerCenter).distance;
      
      if (distance < 20) {
        final node = layoutNode.node;
        
        if (node is EventNode) {
          _selectEvent(node.eventId);
        } else if (node is ClusterNode) {
          _expandCluster(node.clusterId);
        }
        return;
      }
    }
    
    // Deselect if tapped on empty space
    ref.read(timelineViewStateProvider.notifier).selectEvent(null);
  }
  
  /// Handle scroll/zoom
  void _handleScroll(PointerScrollEvent event) {
    if (event.scrollDelta.dy.abs() > 0) {
      // Zoom with scroll wheel
      final delta = event.scrollDelta.dy > 0 ? -0.05 : 0.05;
      final currentZoom = ref.read(timelineViewStateProvider).zoomLevel;
      ref.read(timelineViewStateProvider.notifier).setZoomLevel(currentZoom + delta);
    }
  }
  
  /// Select event
  void _selectEvent(String eventId) {
    ref.read(timelineViewStateProvider.notifier).selectEvent(eventId);
  }
  
  /// Expand cluster
  void _expandCluster(String clusterId) {
    ref.read(timelineViewStateProvider.notifier).toggleCluster(clusterId);
  }
  
  /// Create TimelineEvent from EventNode (temporary helper)
  dynamic _createEventFromNode(EventNode node) {
    // This is a placeholder - in real implementation, we'd fetch the full event
    // For now, return a minimal event object
    return ref.read(timelineDataProvider).maybeWhen(
      data: (state) => state.filteredEvents.firstWhere(
        (e) => e.id == node.eventId,
        orElse: () => state.filteredEvents.first,
      ),
      orElse: () => null,
    );
  }
}
