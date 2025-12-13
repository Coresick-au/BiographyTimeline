import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../services/timeline_data_service.dart';
import '../services/timeline_integration_service.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/design_system/design_system.dart';

/// Main timeline screen with view switcher and controls
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with TickerProviderStateMixin {
  TimelineViewMode _currentViewMode = TimelineViewMode.chronological;
  TimelineRenderConfig? _config;
  ITimelineRenderer? _currentRenderer;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  // Data service watchers
  late List<TimelineEvent> _events;
  late List<Context> _contexts;
  late Map<String, List<TimelineEvent>> _clusteredEvents;

  @override
  void initState() {
    super.initState();
    final availableViewModes = _getAvailableViewModes();
    _tabController = TabController(length: availableViewModes.length, vsync: this);
    
    // Initialize with empty data, will be updated by data service
    _events = [];
    _contexts = [];
    _clusteredEvents = {};
    
    // Initialize timeline after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimeline();
    });
  }

  // Helper methods
  List<TimelineViewMode> _getAvailableViewModes() {
    return TimelineViewMode.values;
  }

  void _switchViewMode(TimelineViewMode newMode) {
    setState(() {
      _currentViewMode = newMode;
      _tabController.index = _getAvailableViewModes().indexOf(newMode);
    });
    _initializeTimeline();
  }

  String _getViewModeTitle(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return 'Chronological';
      case TimelineViewMode.clustered:
        return 'Clustered';
      case TimelineViewMode.mapView:
        return 'Map';
      case TimelineViewMode.story:
        return 'Stories';
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.bentoGrid:
        return 'Bento Grid';
      case TimelineViewMode.river:
        return 'River';
    }
  }

  IconData _getViewModeIcon(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return Icons.timeline;
      case TimelineViewMode.clustered:
        return Icons.category;
      case TimelineViewMode.mapView:
        return Icons.map;
      case TimelineViewMode.story:
        return Icons.auto_stories;
      case TimelineViewMode.lifeStream:
        return Icons.stream;
      case TimelineViewMode.bentoGrid:
        return Icons.grid_view;
      case TimelineViewMode.river:
        return Icons.water;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _currentRenderer?.dispose();
    super.dispose();
  }

  Future<void> _initializeTimeline() async {
    setState(() => _isLoading = true);
    
    try {
      // Get integration service and initialize it
      final integrationService = ref.read(timelineIntegrationServiceProvider);
      await integrationService.initialize();
      
      // Get data service
      final dataService = ref.read(timelineServiceProvider);
      
      // Create initial configuration
      _config = TimelineRenderConfig(
        viewMode: _currentViewMode,
        showPrivateEvents: dataService.showPrivateEvents,
        activeContext: dataService.activeContextId != null 
            ? dataService.contexts.firstWhere(
                (ctx) => ctx.id == dataService.activeContextId,
                orElse: () => dataService.contexts.first,
              )
            : null,
      );

      // Initialize data service with sample data
      await dataService.initialize();
      
      // Get data from service
      _events = dataService.events;
      _contexts = dataService.contexts;
      _clusteredEvents = dataService.clusteredEvents;
      
      // Debug output
      debugPrint('Timeline Debug: Loaded ${_events.length} events and ${_contexts.length} contexts');
      debugPrint('Timeline Debug: Events: ${_events.map((e) => e.title).join(', ')}');

      // Create timeline render data
      final timelineData = TimelineRenderData(
        events: _events,
        contexts: _contexts,
        earliestDate: _events.isEmpty ? DateTime.now() : 
                     _events.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
        latestDate: _events.isEmpty ? DateTime.now() : 
                   _events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
        clusteredEvents: _clusteredEvents,
      );

      // Get renderer for current view mode
      _currentRenderer = TimelineRendererFactory.createRenderer(
        _currentViewMode,
        _config!,
        timelineData,
      );
      
      // Initialize renderer
      await _currentRenderer?.initialize(_config!);

    } catch (e) {
      debugPrint('Error initializing timeline: $e');
      // Fallback to chronological view
      _currentViewMode = TimelineViewMode.chronological;
      final fallbackData = TimelineRenderData(
        events: _events,
        contexts: _contexts,
        earliestDate: _events.isEmpty ? DateTime.now() : 
                     _events.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
        latestDate: _events.isEmpty ? DateTime.now() : 
                   _events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
        clusteredEvents: _clusteredEvents,
      );
      _currentRenderer = TimelineRendererFactory.createRenderer(
        _currentViewMode,
        _config!,
        fallbackData,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current data from providers
    final dataService = ref.watch(timelineServiceProvider);
    final currentEvents = dataService.events;
    final currentContexts = dataService.contexts;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modern loading indicator
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: DesignTokens.space4),
              Text(
                'Loading Timeline...',
                style: DesignTokens.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern glassmorphic app bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                      const Color(0xFF667EEA).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getViewModeTitle(_currentViewMode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentEvents.length} events • ${currentContexts.length} contexts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ModernAnimatedButton(
                              text: 'Add Event',
                              onPressed: _showAddEventDialog,
                              primaryColor: Colors.white,
                              height: DesignTokens.space8,
                            ),
                            SizedBox(width: DesignTokens.space2),
                            ModernOutlineButton(
                              text: 'Settings',
                              onPressed: _showConfigurationDialog,
                              textColor: Colors.white,
                              borderColor: Colors.white,
                              height: DesignTokens.space8,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tab bar for view modes
          SliverPersistentHeader(
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _getAvailableViewModes().map((mode) {
                  return Tab(
                    text: _getViewModeTitle(mode),
                    icon: Icon(_getViewModeIcon(mode)),
                  );
                }).toList(),
                labelColor: const Color(0xFF667EEA),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF667EEA),
                indicatorWeight: 3,
                onTap: (index) {
                  _switchViewMode(_getAvailableViewModes()[index]);
                },
              ),
            ),
            pinned: true,
          ),
          // Main content
          SliverFillRemaining(
            child: _buildTimelineContent(),
          ),
        ],
      ),
      floatingActionButton: ModernFloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        enableRotation: true,
      ),
    );
  }

  Widget _buildTimelineContent() {
    if (_currentRenderer == null) {
      return _buildErrorState('Timeline renderer not initialized');
    }

    debugPrint('Timeline Debug: _buildTimelineContent called with ${_events.length} events');
    
    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return _currentRenderer!.build(
      onEventTap: (event) {
        // TODO: Navigate to event details
        debugPrint('Tapped event: ${event.title}');
      },
      onEventLongPress: (event) {
        // TODO: Show event options
        debugPrint('Long pressed event: ${event.title}');
      },
      onDateTap: (date) {
        // TODO: Navigate to date
        debugPrint('Tapped date: $date');
      },
      onContextTap: (context) {
        // TODO: Switch to context
        debugPrint('Tapped context: ${context.name}');
      },
      // Don't pass scrollController to avoid conflicts with CustomScrollView
      scrollController: null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getViewModeIcon(_currentViewMode),
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events to display',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first event to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          ModernAnimatedButton(
            text: 'Add Event',
            onPressed: _showAddEventDialog,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ModernAnimatedButton(
            text: 'Retry',
            onPressed: _initializeTimeline,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'Enter event title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter event description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addNewEvent(titleController.text, descriptionController.text);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _addNewEvent(String title, String description) {
    final dataService = ref.read(timelineServiceProvider);
    
    final newEvent = TimelineEvent.create(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      contextId: _contexts.isNotEmpty ? _contexts.first.id : 'context-1',
      ownerId: 'user-1',
      timestamp: DateTime.now(),
      eventType: 'text',
      title: title,
      description: description,
    );
    
    dataService.addEvent(newEvent);
    
    // Refresh the timeline
    _initializeTimeline();
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timeline Configuration'),
        content: const Text('Configuration dialog would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Custom delegate for the persistent header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
