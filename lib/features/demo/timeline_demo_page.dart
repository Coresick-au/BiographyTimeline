import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../timeline/providers/timeline_provider.dart';
import '../timeline/widgets/timeline_renderer_widget.dart';
import '../timeline/services/timeline_renderer_interface.dart';
import '../../shared/models/timeline_event.dart';
import '../../shared/models/context.dart';
import '../../core/factories/context_factory.dart';
import '../../core/factories/timeline_event_factory.dart';

/// Demo page showcasing the new timeline visualization engine
class TimelineDemoPage extends ConsumerStatefulWidget {
  const TimelineDemoPage({super.key});

  @override
  ConsumerState<TimelineDemoPage> createState() => _TimelineDemoPageState();
}

class _TimelineDemoPageState extends ConsumerState<TimelineDemoPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDemoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDemoData() async {
    final timelineActions = ref.read(timelineActionsProvider);
    final timelineNotifier = ref.read(timelineNotifierProvider.notifier);

    try {
      // Create demo contexts
      final contexts = [
        ContextFactory.createContext(
          id: 'personal-context',
          ownerId: 'demo-user',
          type: ContextType.person,
          name: 'My Life Journey',
          description: 'Personal memories and milestones',
        ),
        ContextFactory.createContext(
          id: 'project-context',
          ownerId: 'demo-user',
          type: ContextType.project,
          name: 'Home Renovation',
          description: 'Our house transformation journey',
        ),
      ];

      // Create demo events with location data for map view
      final events = [
        // Personal events
        TimelineEventFactory.createEvent(
          id: 'graduation',
          contextId: 'personal-context',
          ownerId: 'demo-user',
          title: 'University Graduation',
          description: 'Finally graduated with honors in Computer Science',
          timestamp: DateTime(2020, 6, 15),
          eventType: 'achievement',
          location: {
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        TimelineEventFactory.createEvent(
          id: 'first-job',
          contextId: 'personal-context',
          ownerId: 'demo-user',
          title: 'Started First Job',
          description: 'Joined tech company as software engineer',
          timestamp: DateTime(2020, 9, 1),
          eventType: 'career',
          location: {
            'latitude': 37.7849,
            'longitude': -122.4094,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        
        // Renovation events
        TimelineEventFactory.createEvent(
          id: 'bought-house',
          contextId: 'project-context',
          ownerId: 'demo-user',
          title: 'Bought Our House',
          description: 'Closed on our first home',
          timestamp: DateTime(2021, 3, 15),
          eventType: 'milestone',
          location: {
            'latitude': 37.7649,
            'longitude': -122.4294,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        TimelineEventFactory.createEvent(
          id: 'kitchen-demo',
          contextId: 'project-context',
          ownerId: 'demo-user',
          title: 'Kitchen Demolition',
          description: 'Day 1 of kitchen renovation',
          timestamp: DateTime(2021, 4, 10),
          eventType: 'renovation',
          location: {
            'latitude': 37.7649,
            'longitude': -122.4294,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        TimelineEventFactory.createEvent(
          id: 'kitchen-finished',
          contextId: 'project-context',
          ownerId: 'demo-user',
          title: 'Kitchen Completed',
          description: 'New kitchen is finally ready',
          timestamp: DateTime(2021, 6, 20),
          eventType: 'renovation',
          location: {
            'latitude': 37.7649,
            'longitude': -122.4294,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        
        // More events for timeline density
        TimelineEventFactory.createEvent(
          id: 'vacation-1',
          contextId: 'personal-context',
          ownerId: 'demo-user',
          title: 'Summer Vacation',
          description: 'Beach trip with friends',
          timestamp: DateTime(2021, 8, 5),
          eventType: 'travel',
          location: {
            'latitude': 36.7783,
            'longitude': -119.4179,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        TimelineEventFactory.createEvent(
          id: 'birthday-2021',
          contextId: 'personal-context',
          ownerId: 'demo-user',
          title: '25th Birthday',
          description: 'Celebrated with family and friends',
          timestamp: DateTime(2021, 11, 12),
          eventType: 'personal',
          location: {
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        TimelineEventFactory.createEvent(
          id: 'promotion',
          contextId: 'personal-context',
          ownerId: 'demo-user',
          title: 'Job Promotion',
          description: 'Promoted to Senior Developer',
          timestamp: DateTime(2022, 1, 15),
          eventType: 'career',
          location: {
            'latitude': 37.7849,
            'longitude': -122.4094,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
        TimelineEventFactory.createEvent(
          id: 'bathroom-reno',
          contextId: 'project-context',
          ownerId: 'demo-user',
          title: 'Bathroom Renovation',
          description: 'Complete bathroom remodel',
          timestamp: DateTime(2022, 3, 1),
          eventType: 'renovation',
          location: {
            'latitude': 37.7649,
            'longitude': -122.4294,
          },
          assets: [],
          participantIds: [],
          privacyLevel: PrivacyLevel.public,
        ),
      ];

      await timelineActions.addContexts(contexts);
      await timelineActions.addEvents(events);
      await timelineNotifier.initializeWithDemoData();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final timelineStats = ref.watch(timelineStatsProvider);
    final availableViewModes = ref.watch(availableViewModesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Visualization Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Life Stream', icon: Icon(Icons.timeline)),
            Tab(text: 'Map View', icon: Icon(Icons.map)),
            Tab(text: 'Grid View', icon: Icon(Icons.grid_view)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViewMode(TimelineViewMode.lifeStream),
          _buildViewMode(TimelineViewMode.mapView),
          _buildViewMode(TimelineViewMode.bentoGrid),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(timelineStats),
    );
  }

  Widget _buildViewMode(TimelineViewMode viewMode) {
    final timelineService = ref.read(timelineServiceProvider);
    
    return Column(
      children: [
        _buildViewControls(viewMode),
        Expanded(
          child: TimelineRendererWidget(
            timelineService: timelineService,
            initialViewMode: viewMode,
            enableViewSwitching: false, // We control switching via tabs
            onEventTap: _onEventTap,
            onEventLongPress: _onEventLongPress,
          ),
        ),
      ],
    );
  }

  Widget _buildViewControls(TimelineViewMode viewMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            _getViewModeIcon(viewMode),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _getViewModeDescription(viewMode),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (viewMode == TimelineViewMode.lifeStream)
            TextButton.icon(
              onPressed: _scrollToToday,
              icon: const Icon(Icons.today),
              label: const Text('Today'),
            ),
          if (viewMode == TimelineViewMode.mapView)
            TextButton.icon(
              onPressed: _startMapPlayback,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
          if (viewMode == TimelineViewMode.bentoGrid)
            TextButton.icon(
              onPressed: _resetGridZoom,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> stats) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Events', '${stats['totalEvents'] ?? 0}'),
          _buildStatItem('Contexts', '${stats['totalContexts'] ?? 0}'),
          _buildStatItem('Days', '${stats['dateRange']?['span'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  IconData _getViewModeIcon(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.lifeStream:
        return Icons.timeline;
      case TimelineViewMode.mapView:
        return Icons.map;
      case TimelineViewMode.bentoGrid:
        return Icons.grid_view;
    }
  }

  String _getViewModeDescription(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.lifeStream:
        return 'Chronological timeline with infinite scroll';
      case TimelineViewMode.mapView:
        return 'Animated playback with location clustering';
      case TimelineViewMode.bentoGrid:
        return 'Life overview with density patterns';
    }
  }

  void _onEventTap(TimelineEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title ?? 'Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${event.timestamp.toString().split(' ')[0]}'),
            if (event.description != null)
              Text('Description: ${event.description}'),
            Text('Type: ${event.eventType}'),
            if (event.location != null)
              Text('Location: ${event.location!.latitude}, ${event.location!.longitude}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onEventLongPress(TimelineEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Long pressed: ${event.title ?? 'Event'}')),
    );
  }

  void _scrollToToday() {
    final timelineActions = ref.read(timelineActionsProvider);
    timelineActions.navigateToDate(DateTime.now());
  }

  void _startMapPlayback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map playback started - use controls in map view')),
    );
  }

  void _resetGridZoom() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grid zoom reset')),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timeline Visualization Engine'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Features:'),
            SizedBox(height: 8),
            Text('• Life Stream: Infinite scroll with sticky headers'),
            Text('• Map View: Animated playback with location clustering'),
            Text('• Bento Grid: Life overview with density patterns'),
            SizedBox(height: 16),
            Text('This demo showcases the new timeline rendering system.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
