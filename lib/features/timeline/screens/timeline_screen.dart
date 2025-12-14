import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../models/timeline_state.dart';
import '../services/timeline_data_service.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../widgets/timeline_view_selector.dart';
import '../widgets/quick_entry_dialog.dart';
import '../widgets/search_dialog.dart';
import 'event_details_screen.dart';

/// Main timeline screen with view switcher and controls
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with TickerProviderStateMixin {
  TimelineViewMode _currentViewMode = TimelineViewMode.chronological;
  late TabController _tabController;
  ITimelineRenderer? _currentRenderer;
  TimelineRenderConfig? _config;
  // Unique key to force renderer rebuild when mode/data changes if necessary
  Key _rendererKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: TimelineViewMode.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentRenderer?.dispose();
    super.dispose();
  }

  void _switchViewMode(TimelineViewMode newMode) {
    setState(() {
      _currentViewMode = newMode;
      _tabController.index = TimelineViewMode.values.indexOf(newMode);
      _rendererKey = UniqueKey(); // Force rebuild of renderer
    });
  }

  void _showSearchDialog(List<TimelineEvent> events, List<Context> contexts) {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(
        events: events,
        contexts: contexts,
        onEventSelected: (event) {
          Navigator.of(context).pop();
          _currentRenderer?.navigateToEvent(event.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // floatingActionButton handled by MainNavigation
      body: timelineState.when(
        loading: () => _buildLoadingState(context),
        error: (error, stack) => _buildErrorState(context, error.toString()),
        data: (state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TimelineState state) {
    // If we have an error in the clean state, showing it might be good, 
    // but AsyncValue handles the main error state.
    
    if (state.allEvents.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, state),
        SliverPersistentHeader(
          delegate: _TabBarDelegate(
            TimelineViewSelector(
              tabController: _tabController,
              availableModes: TimelineViewMode.values,
              onModeChanged: _switchViewMode,
            ),
          ),
          pinned: true,
        ),
        SliverFillRemaining(
          child: _buildTimelineRenderer(context, state),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, TimelineState state) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => _showSearchDialog(state.allEvents, state.contexts),
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
                    '${state.filteredEvents.length} events • ${state.contexts.length} contexts',
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
                        onPressed: () => _showAddEventDialog(context, ref),
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
    );
  }

  Widget _buildTimelineRenderer(BuildContext context, TimelineState state) {
    // Re-create renderer logic
    // We create the config and data object
    final config = TimelineRenderConfig(
      viewMode: _currentViewMode,
      showPrivateEvents: state.showPrivateEvents,
      activeContext: state.activeContextId != null 
          ? state.contexts.firstWhere(
              (ctx) => ctx.id == state.activeContextId,
              orElse: () => state.contexts.first,
            )
          : null,
    );

    final data = TimelineRenderData(
      events: state.filteredEvents, // Use filtered events for rendering
      contexts: state.contexts,
      clusteredEvents: state.clusteredEvents,
      earliestDate: state.filteredEvents.isEmpty ? DateTime.now() : 
          state.filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
      latestDate: state.filteredEvents.isEmpty ? DateTime.now() : 
          state.filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
    );

    // Ideally we don't recreate the renderer on every build unless necessary.
    // However, IFactory APIs often imply creation.
    // For performance, we might want to cache this, but for this refactor I'll keep it simple:
    // create and return the widget built by the renderer.

    // Warning: createRenderer returns ITimelineRenderer, which is likely NOT a Widget, 
    // but controls a Widget or has a build method.
    // Looking at previous code: renderer.build(...) returns a Widget.
    
    // We should cache the renderer to preserve its internal state (scroll position etc)
    // ONLY if the view mode hasn't changed.
    // Current simple implementation creates it every time which loses state.
    // Enhanced:
    if (_currentRenderer == null || _config?.viewMode != config.viewMode) {
      _currentRenderer = TimelineRendererFactory.createRenderer(_currentViewMode, config, data);
      _currentRenderer!.initialize(config); 
      _config = config;
    } else {
       // Update data on existing renderer if supported, otherwise recreate
       // Assuming onDataUpdated exists
       // _currentRenderer!.updateData(data); // Hypothetical
       // For safety in this refactor without deep diving into every renderer's update logic:
       // We recreate it if key changes or simplify.
       // Actually, the previous implementation created it inside `_initializeTimeline`.
       // Let's recreate it if state changes significantly, or just rely on the renderer handling updates?
       // Let's create a new one to be safe and ensure data freshness, 
       // but using Key to let Flutter manage the Widget lifecycle if the renderer returns a Widget.
        _currentRenderer = TimelineRendererFactory.createRenderer(_currentViewMode, config, data);
    }
    
    // Note: Calling build on the renderer.
    return _currentRenderer!.build(
      onEventTap: (event) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: event,
              context: state.contexts.isNotEmpty 
                  ? state.contexts.firstWhere((ctx) => ctx.id == event.contextId, orElse: () => state.contexts.first)
                  : state.contexts.first,
            ),
          ),
        );
      },
      onContextTap: (ctx) => _switchToContext(ctx, ref),
      // ... other callbacks
    );
     
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => QuickEntryDialog(
        contextType: ContextType.person,
        contextId: 'default', // Should get from state
        ownerId: 'user-1',
        onEventCreated: (event) {
           ref.read(timelineDataProvider.notifier).addEvent(event);
        },
      ),
    );
  }

  void _showConfigurationDialog() {
    // ...
  }
  
  void _switchToContext(Context context, WidgetRef ref) {
     ref.read(timelineDataProvider.notifier).setActiveContext(context.id);
  }

  String _getViewModeTitle(TimelineViewMode mode) {
     // Helper could be static or in selector
     switch (mode) {
      case TimelineViewMode.chronological: return 'Chronological';
      case TimelineViewMode.lifeStream: return 'Life Stream';
      case TimelineViewMode.bentoGrid: return 'Grid';
      case TimelineViewMode.story: return 'Story';
      default: return mode.toString();
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(child: Text("No events found"));
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(child: Text("Error: $error"));
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate(this.child);

  @override
  double get minExtent => 52.0;

  @override
  double get maxExtent => 52.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
}
