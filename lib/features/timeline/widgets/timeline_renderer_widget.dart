import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_service.dart';

/// Widget that displays timeline using the appropriate renderer
class TimelineRendererWidget extends StatefulWidget {
  final TimelineService timelineService;
  final TimelineViewMode initialViewMode;
  final TimelineEventCallback? onEventTap;
  final TimelineEventCallback? onEventLongPress;
  final TimelineDateCallback? onDateTap;
  final TimelineContextCallback? onContextTap;
  final bool enableViewSwitching;
  final List<TimelineViewMode> availableViewModes;

  const TimelineRendererWidget({
    Key? key,
    required this.timelineService,
    this.initialViewMode = TimelineViewMode.lifeStream,
    this.onEventTap,
    this.onEventLongPress,
    this.onDateTap,
    this.onContextTap,
    this.enableViewSwitching = true,
    this.availableViewModes = const [
      TimelineViewMode.lifeStream,
      TimelineViewMode.mapView,
      TimelineViewMode.bentoGrid,
    ],
  }) : super(key: key);

  @override
  State<TimelineRendererWidget> createState() => _TimelineRendererWidgetState();
}

class _TimelineRendererWidgetState extends State<TimelineRendererWidget>
    with TickerProviderStateMixin {
  late TimelineViewMode _currentViewMode;
  late TabController _tabController;
  ITimelineRenderer? _currentRenderer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentViewMode = widget.initialViewMode;
    _tabController = TabController(
      length: widget.availableViewModes.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _initializeTimeline();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeTimeline() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get or create renderer for current view mode
      _currentRenderer = widget.timelineService.getRenderer(_currentViewMode);
      
      if (_currentRenderer == null) {
        throw Exception('No renderer available for view mode: $_currentViewMode');
      }

      // Wait for renderer to be ready
      if (!_currentRenderer!.isReady) {
        await _currentRenderer!.initialize(widget.timelineService.currentConfig);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _onTabChanged() {
    if (!widget.enableViewSwitching) return;
    
    final newIndex = _tabController.index;
    if (newIndex >= 0 && newIndex < widget.availableViewModes.length) {
      final newViewMode = widget.availableViewModes[newIndex];
      if (newViewMode != _currentViewMode) {
        _switchViewMode(newViewMode);
      }
    }
  }

  Future<void> _switchViewMode(TimelineViewMode newViewMode) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Update configuration
      final newConfig = widget.timelineService.currentConfig.copyWith(
        viewMode: newViewMode,
      );
      await widget.timelineService.updateConfig(newConfig);

      // Get new renderer
      _currentRenderer = widget.timelineService.getRenderer(newViewMode);
      
      if (_currentRenderer == null) {
        throw Exception('No renderer available for view mode: $newViewMode');
      }

      // Initialize if needed
      if (!_currentRenderer!.isReady) {
        await _currentRenderer!.initialize(newConfig);
      }

      setState(() {
        _currentViewMode = newViewMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading timeline...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load timeline',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeTimeline,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentRenderer == null) {
      return const Center(
        child: Text('No timeline renderer available'),
      );
    }

    return Column(
      children: [
        if (widget.enableViewSwitching) _buildViewSwitcher(),
        Expanded(
          child: _buildTimelineContent(),
        ),
      ],
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: widget.availableViewModes.map((mode) {
          return Tab(
            text: _getViewModeDisplayName(mode),
            icon: Icon(_getViewModeIcon(mode)),
          );
        }).toList(),
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildTimelineContent() {
    try {
      return _currentRenderer!.build(
        onEventTap: widget.onEventTap,
        onEventLongPress: widget.onEventLongPress,
        onDateTap: widget.onDateTap,
        onContextTap: widget.onContextTap,
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Timeline rendering error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  String _getViewModeDisplayName(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.mapView:
        return 'Map View';
      case TimelineViewMode.bentoGrid:
        return 'Grid View';
    }
  }

  IconData _getViewModeIcon(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.lifeStream:
        return Icons.timeline;
      case TimelineViewMode.mapView:
        return Icons.map;
      case TimelineViewMode.bentoGrid:
        return Icons.grid_view;
    }
  }
}

/// Widget for timeline controls (zoom, navigation, etc.)
class TimelineControls extends StatelessWidget {
  final ITimelineRenderer renderer;
  final VoidCallback? onExport;
  final bool showExportButton;

  const TimelineControls({
    Key? key,
    required this.renderer,
    this.onExport,
    this.showExportButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _handleZoom(context, 1.2),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _handleZoom(context, 0.8),
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _handleNavigateToToday,
            tooltip: 'Go to Today',
          ),
          if (showExportButton && onExport != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _handleExport,
              tooltip: 'Export View',
            ),
        ],
      ),
    );
  }

  void _handleZoom(BuildContext context, double factor) {
    final currentZoom = renderer.config.zoomLevel ?? 1.0;
    final newZoom = (currentZoom * factor).clamp(0.1, 5.0);
    renderer.setZoomLevel(newZoom);
  }

  void _handleNavigateToToday() {
    renderer.navigateToDate(DateTime.now());
  }

  Future<void> _handleExport() async {
    if (onExport != null) {
      onExport!();
    }
  }
}
