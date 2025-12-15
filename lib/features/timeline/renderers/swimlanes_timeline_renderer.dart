import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/swimlane_layout_service.dart';
import '../widgets/swimlane_widgets.dart';

/// Renderer for the Swimlanes view
/// Displays a split view with sticky headers on the left and a horizontally scrollable timeline on the right.
class SwimlanesTimelineRenderer extends BaseTimelineRenderer {
  final SwimlaneLayoutService _layoutService = SwimlaneLayoutService();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Cached layout
  List<SwimlaneLayoutItem> _layoutItems = [];
  List<String> _laneOwnerIds = [];
  double _contentWidth = 0.0;
  
  SwimlanesTimelineRenderer(
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

    // Identify owners (lanes) - sort by usage or alphabetical
    final owners = data.events.map((e) => e.ownerId).toSet().toList();
    owners.sort(); // Consistent ordering
    _laneOwnerIds = owners;

    // Start date for relative positioning
    final minDate = data.earliestDate;
    
    // Pixels per day (fixed for now, or from config)
    const pixelsPerDay = 50.0; 

    _layoutItems = _layoutService.calculateLayout(
      events: data.events,
      laneOwnerIds: _laneOwnerIds,
      startDate: minDate,
      pixelsPerDay: pixelsPerDay,
    );
    
    // Calculate total content width
    if (_layoutItems.isNotEmpty) {
      double maxRight = 0.0;
      for (final item in _layoutItems) {
        if (item.rect.right > maxRight) maxRight = item.rect.right;
      }
      _contentWidth = maxRight + 200.0; // Padding
    }
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
    // If external scroll controller is provided, link it to vertical?
    // Swimlanes needs 2D scrolling usually, but simpler: 
    // Vertical for lanes (if many), Horizontal for time.
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Headers Column
        _buildHeaders(context!),
        
        // RIGHT: Scrollable Timeline
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _contentWidth,
              height: _laneOwnerIds.length * SwimlaneLayoutService.kLaneHeight,
              child: Stack(
                children: [
                  // Lane backgrounds
                  _buildLaneBackgrounds(context),
                  
                  // Time Axis (simple)
                  // _buildTimeAxis(), 
                  
                  // Events
                  ..._layoutItems.map((item) => _buildEventItem(context, item, onEventTap)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaders(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: _laneOwnerIds.map((ownerId) {
          // Resolve owner name (mock logic for now)
          // In real app, look up user profile using ownerId
          final name = ownerId == 'user-1' ? 'Me' : 
                       ownerId == 'user-2' ? 'Partner' : 'Family';
                       
          return SizedBox(
            height: SwimlaneLayoutService.kLaneHeight,
            child: SwimlaneHeader(
              label: name,
              color: _getOwnerColor(ownerId),
              isExpanded: true,
              onToggle: () {}, // Collapse implementation later
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildLaneBackgrounds(BuildContext context) {
    return Column(
      children: List.generate(_laneOwnerIds.length, (index) {
        return Container(
          height: SwimlaneLayoutService.kLaneHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
            ),
            color: index % 2 == 0 
                ?Theme.of(context).colorScheme.surface.withOpacity(0.3)
                : Colors.transparent,
          ),
        );
      }),
    );
  }

  Widget _buildEventItem(
    BuildContext context, 
    SwimlaneLayoutItem item,
    TimelineEventCallback? onEventTap,
  ) {
    return Positioned(
      left: item.rect.left,
      top: item.rect.top,
      width: item.rect.width,
      height: item.rect.height,
      child: item.isBridge
          ? BridgeCard(
              event: item.event,
              height: item.rect.height,
              onTap: onEventTap != null ? () => onEventTap(item.event) : null,
            )
          : GestureDetector(
              onTap: onEventTap != null ? () => onEventTap(item.event) : null,
              child: Container(
                // Placeholder for standard card, reused BridgeCard styling for consistency/speed in this phase
                // Ideally use TimelineEventCard but adapted for swimlanes?
                // BridgeCard is already suited for this compact view.
                child: BridgeCard(
                    event: item.event,
                    height: item.rect.height,
                ),
              ),
            ),
    );
  }
  
  Color _getOwnerColor(String ownerId) {
    // Deterministic color from string
    final hash = ownerId.hashCode;
    const colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}
