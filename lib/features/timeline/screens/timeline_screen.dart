import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../services/timeline_data_service.dart';
import '../widgets/quick_entry_dialog.dart';
import '../widgets/search_dialog.dart';
import '../renderers/life_stream_timeline_renderer.dart';
import '../renderers/vertical_timeline_renderer.dart';
import '../renderers/grid_timeline_renderer.dart';
import '../renderers/enhanced_vertical_timeline_renderer.dart';
import '../renderers/life_stream_timeline_renderer.dart' as life_stream;
import '../services/timeline_renderer_interface.dart';
import 'event_details_screen.dart';

// Timeline integration service provider
final timelineIntegrationServiceProvider = Provider<TimelineDataService>((ref) {
  throw UnimplementedError('TimelineIntegrationService not implemented');
});

// Timeline service provider
final timelineServiceProvider = Provider<TimelineDataService>((ref) {
  return TimelineDataService();
});

// Timeline renderer factory
class TimelineRendererFactory {
  static ITimelineRenderer createRenderer(
    TimelineViewMode mode,
    TimelineRenderConfig config,
    TimelineRenderData data,
  ) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return VerticalTimelineRenderer();
      case TimelineViewMode.lifeStream:
        return LifeStreamTimelineRenderer(
          config,
          data,
        );
      case TimelineViewMode.bentoGrid:
        return GridTimelineRenderer();
      case TimelineViewMode.story:
        return EnhancedVerticalTimelineRenderer();
      case TimelineViewMode.mapView:
      case TimelineViewMode.clustered:
      case TimelineViewMode.river:
        // Default to chronological for unsupported modes
        return VerticalTimelineRenderer();
    }
  }
}

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
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.bentoGrid:
        return 'Grid';
      case TimelineViewMode.story:
        return 'Story';
      case TimelineViewMode.mapView:
        return 'Map';
      case TimelineViewMode.clustered:
        return 'Clustered';
      case TimelineViewMode.river:
        return 'River';
    }
  }

  /// Show search dialog for filtering events
  void _showSearchDialog() {
    final dataService = ref.read(timelineServiceProvider);
    
    showDialog(
      context: context,
      builder: (context) => SearchDialog(
        events: dataService.events,
        contexts: dataService.contexts,
        onEventSelected: (event) {
          Navigator.of(context).pop();
          // Navigate to the event in the timeline
          if (_currentRenderer != null) {
            _currentRenderer!.navigateToEvent(event.id);
          }
        },
      ),
    );
  }

  IconData _getViewModeIcon(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return Icons.timeline;
      case TimelineViewMode.lifeStream:
        return Icons.waves;
      case TimelineViewMode.bentoGrid:
        return Icons.grid_view;
      case TimelineViewMode.story:
        return Icons.book;
      case TimelineViewMode.mapView:
        return Icons.map;
      case TimelineViewMode.clustered:
        return Icons.scatter_plot;
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
      // final integrationService = ref.read(timelineIntegrationServiceProvider);
      // await integrationService.initialize();
      
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
              SizedBox(height: 16),
              Text(
                'No events to display',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
            actions: [
              IconButton(
                onPressed: _showSearchDialog,
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: 'Search Events',
              ),
            ],
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
                            ElevatedButton(
                              onPressed: _showAddEventDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF667EEA),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Add Event'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _showConfigurationDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Settings'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: event,
              context: _contexts.isNotEmpty 
                  ? _contexts.firstWhere((ctx) => ctx.id == event.contextId, orElse: () => _contexts.first)
                  : _contexts.first,
            ),
          ),
        );
      },
      onEventLongPress: (event) {
        // TODO: Show event options
        debugPrint('Long pressed event: ${event.title}');
      },
      onDateTap: (date) {
        _showDateFilterDialog(date);
      },
      onContextTap: (context) {
        _switchToContext(context);
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
          ElevatedButton(
            onPressed: _showAddEventDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add Event'),
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
    // Get the current context ID or default to the first available
    final currentContextId = _contexts.isNotEmpty ? _contexts.first.id : 'default-context';
    
    showDialog(
      context: context,
      builder: (context) => QuickEntryDialog(
        contextType: ContextType.person, // Or derive from currentContext
        contextId: currentContextId,
        ownerId: 'user-1', // Replace with actual user ID service later
        onEventCreated: (newEvent) {
          // 1. Get the service
          final dataService = ref.read(timelineServiceProvider);
          
          // 2. Add the event (this already notifies listeners)
          dataService.addEvent(newEvent);
          
          // 3. No need to call _initializeTimeline() again, 
          // the stream listener or Riverpod watcher should update the UI automatically.
          // If your UI doesn't update, you can call setState(() {});
        },
      ),
    );
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

  void _showDateFilterDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Date: ${date.day}/${date.month}/${date.year}'),
        content: Text('Show all events from ${date.day}/${date.month}/${date.year}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Apply date filter
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Showing events from ${date.day}/${date.month}/${date.year}'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Filter'),
          ),
        ],
      ),
    );
  }

  void _switchToContext(Context newContext) {
    final dataService = ref.read(timelineServiceProvider);
    
    // Update the active context in the data service
    dataService.setActiveContext(newContext.id);
    
    // Re-initialize timeline with new context
    _initializeTimeline();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${newContext.name} context'),
        backgroundColor: Colors.green,
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
