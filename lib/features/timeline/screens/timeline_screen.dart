import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/widgets/welcome_dialog.dart';
import '../models/timeline_state.dart';
import '../models/view_state.dart';
import '../services/timeline_data_service.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../services/view_state_manager.dart';
import '../widgets/timeline_view_selector.dart';
import '../widgets/quick_entry_dialog.dart';
import '../widgets/timeline_event_card.dart';
import '../../../shared/widgets/modern/dark_theme.dart';
import '../../../shared/widgets/modern/animated_buttons.dart';
import '../widgets/search_dialog.dart';
import '../widgets/export_dialog.dart';
import 'event_details_screen.dart';
import '../providers/timeline_view_provider.dart';
import '../providers/timeline_viewport_provider.dart';
import '../models/timeline_view_state.dart';
import '../widgets/timeline_viewport.dart';
import '../../dashboard/screens/dashboard_screen.dart';

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
  
  // Renderer cache to preserve state across view switches
  final Map<TimelineViewMode, ITimelineRenderer> _rendererCache = {};
  
  // Track if welcome dialog has been shown
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: TimelineViewMode.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all cached renderers
    for (final renderer in _rendererCache.values) {
      renderer.dispose();
    }
    _rendererCache.clear();
    super.dispose();
  }

  void _switchViewMode(TimelineViewMode newMode) async {
    // Save current view state before switching
    if (_currentRenderer != null) {
      final visibleRange = _currentRenderer!.getVisibleDateRange();
      final currentState = ViewState(
        viewMode: _currentViewMode,
        scrollOffset: visibleRange?.start.millisecondsSinceEpoch.toDouble() ?? 0.0,
        zoomLevel: 1.0, // TODO: Get from renderer if supported
      );
      ref.read(viewStateManagerProvider.notifier).saveViewState(
        _currentViewMode,
        currentState,
      );
    }

    setState(() {
      _currentViewMode = newMode;
      _tabController.index = TimelineViewMode.values.indexOf(newMode);
      // Don't force rebuild - let renderer cache work
    });
    
    // Update provider to keep in sync
    ref.read(timelineViewProvider.notifier).setViewMode(newMode);

    // Restore view state after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentRenderer != null) {
        ref.read(viewStateManagerProvider.notifier).restoreViewState(
          newMode,
          _currentRenderer!,
        );
      }
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
    
    // Watch timeline view provider and update view mode when it changes
    ref.listen<TimelineViewMode>(timelineViewProvider, (previous, next) {
      if (next != _currentViewMode) {
        _switchViewMode(next);
      }
    });

    // Show welcome dialog on first launch if timeline is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownWelcome && 
          timelineState.hasValue && 
          timelineState.value!.allEvents.isEmpty) {
        _hasShownWelcome = true;
        _showWelcomeDialog();
      }
    });

    return AppScaffold(
      body: timelineState.when(
        data: (state) => _buildTimelineContent(context, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          debugPrint('Timeline Error: $error');
          return AppEmptyState.error(
            message: error.toString(),
            onRetry: () => ref.invalidate(timelineDataProvider),
          );
        },
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, TimelineState state) {
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
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Your Timeline',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '${state.allEvents.length} events',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ExportDialog(events: state.allEvents),
          ),
          icon: const Icon(Icons.ios_share, color: Colors.white),
          tooltip: 'Export Timeline',
        ),
        IconButton(
          onPressed: () => _showSearchDialog(state.allEvents, state.contexts),
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Search Events',
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
          icon: const Icon(Icons.dashboard, color: Colors.white),
          tooltip: 'Dashboard',
        ),
      ],
    );
  }

  Widget _buildTimelineRenderer(BuildContext context, TimelineState state) {
    // Create config and data objects
    final config = TimelineRenderConfig(
      viewMode: _currentViewMode,
      showPrivateEvents: state.showPrivateEvents,
    );

    final data = TimelineRenderData(
      events: state.filteredEvents,
      contexts: state.contexts,
      clusteredEvents: state.clusteredEvents,
      earliestDate: state.filteredEvents.isEmpty ? DateTime.now() : 
          state.filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
      latestDate: state.filteredEvents.isEmpty ? DateTime.now() : 
          state.filteredEvents.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
    );

    // Check if we have a cached renderer for this view mode
    if (!_rendererCache.containsKey(_currentViewMode)) {
      // Create new renderer and cache it
      final renderer = TimelineRendererFactory.createRenderer(
        _currentViewMode,
        config,
        data,
      );
      _rendererCache[_currentViewMode] = renderer;
      _currentRenderer = renderer;
    } else {
      _currentRenderer = _rendererCache[_currentViewMode];
      // Sync the renderer with the latest state
      _currentRenderer?.updateConfig(config);
      _currentRenderer?.updateData(data);
    }
    
    // Note: Calling build on the renderer.
    return _currentRenderer!.build(
      context: context,
      onEventTap: (event) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: event,
              context: state.contexts.isNotEmpty 
                  ? state.contexts.first
                  : null,
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
        tags: ['Family'],
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
  
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeDialog(
        onCreateEvent: () {
          Navigator.of(context).pop();
          _showAddEventDialog(context, ref);
        },
        onExplore: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  void _switchToContext(Context context, WidgetRef ref) {
    // setActiveContext removed in Family-First MVP
    // All events are now family events with tags
  }

  String _getViewModeTitle(TimelineViewMode mode) {
     // Helper could be static or in selector
     switch (mode) {
      case TimelineViewMode.chronological: return 'Chronological';
      case TimelineViewMode.lifeStream: return 'Life Stream';
      case TimelineViewMode.bentoGrid: return 'Grid';
      case TimelineViewMode.story: return 'Story';
      case TimelineViewMode.bubble: return 'Overview';
      case TimelineViewMode.swimlanes: return 'Timeline Lanes';
      case TimelineViewMode.river: return 'Flow View';
      default: return mode.toString();
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      title: 'No Timeline Data',
      subtitle: 'Start by adding your first event',
      icon: Icons.timeline,
      action: FilledButton.icon(
        onPressed: () => _showAddEventDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return AppEmptyState.error(message: error);
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
}
