import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timeline_renderer_interface.dart';
import '../services/timeline_renderer_factory.dart';
import '../services/timeline_data_service.dart';
import '../services/timeline_integration_service.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/widgets/modern/glassmorphism_card.dart';
import '../../../shared/widgets/modern/animated_buttons.dart';
import '../../../shared/widgets/modern/shimmer_loading.dart';

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
      case TimelineViewMode.map:
        return 'Map';
      case TimelineViewMode.stories:
        return 'Stories';
    }
  }

  IconData _getViewModeIcon(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return Icons.timeline;
      case TimelineViewMode.clustered:
        return Icons.category;
      case TimelineViewMode.map:
        return Icons.map;
      case TimelineViewMode.stories:
        return Icons.auto_stories;
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

      // Validate data before creating renderer
      if (_events.isEmpty) {
        throw Exception('No events available to display');
      }

      // Get renderer for current view mode
      _currentRenderer = TimelineRendererFactory.createRenderer(_currentViewMode);
      
      // Initialize renderer
      await _currentRenderer?.initialize(timelineData, _config!);

    } catch (e) {
      debugPrint('Error initializing timeline: $e');
      // Fallback to chronological view
      _currentViewMode = TimelineViewMode.chronological;
      _currentRenderer = TimelineRendererFactory.createRenderer(_currentViewMode);
    } finally {
      setState(() => _isLoading = false);
    }
              _config!.viewMode,
              _config!,
              timelineData,
            );

            if (_currentRenderer == null) {
              throw Exception('Failed to create renderer with new configuration');
            }

            await _currentRenderer!.initialize(_config!);
            
            // Dispose old renderer after successful initialization
            oldRenderer?.dispose();
            
            // Update current view mode if changed
            if (_currentViewMode != _config!.viewMode) {
              _currentViewMode = _config!.viewMode;
              final availableViewModes = _getAvailableViewModes();
              final newIndex = availableViewModes.indexOf(_currentViewMode);
              if (newIndex != -1) {
                _tabController.index = newIndex;
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings applied successfully'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            
          } catch (e) {
            debugPrint('Error applying configuration: $e');
            _showErrorDialog('Configuration Error', 'Failed to apply settings: ${e.toString()}');
            
            // Revert to previous configuration
            final dataService = ref.read(timelineServiceProvider);
            _config = TimelineRenderConfig(
              viewMode: _config!.viewMode,
              showPrivateEvents: dataService.showPrivateEvents,
              activeContext: dataService.activeContextId != null 
                  ? dataService.contexts.firstWhere(
                      (ctx) => ctx.id == dataService.activeContextId,
                      orElse: () => dataService.contexts.first,
                    )
                  : null,
            );
            final timelineData = TimelineRenderData(
              events: dataService.events,
              contexts: dataService.contexts,
              earliestDate: dataService.events.isEmpty ? DateTime.now() : 
                           dataService.events.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
              latestDate: dataService.events.isEmpty ? DateTime.now() : 
                         dataService.events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
              clusteredEvents: dataService.clusteredEvents,
            );
            _currentRenderer = TimelineRendererFactory.createRenderer(
              _config!.viewMode,
              _config!,
              timelineData,
            );
            await _currentRenderer?.initialize(_config!);
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentRenderer == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Modern shimmer header
              Container(
                margin: const EdgeInsets.all(16),
                child: GlassmorphismCard(
                  height: 80,
                  borderRadius: 16,
                  opacity: 0.1,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Center(
                    child: ModernLoadingIndicator(
                      size: 24,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
              ),
              // Shimmer timeline events
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return const TimelineEventSkeleton(
                      showAvatar: true,
                      showDate: true,
                      showDescription: true,
                      margin: EdgeInsets.only(bottom: 16),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Watch data service for reactive updates
    final dataService = ref.watch(timelineServiceProvider);
    final currentEvents = dataService.events;
    final currentContexts = dataService.contexts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getViewModeTitle(_currentViewMode),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentEvents.length} events • ${currentContexts.length} contexts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              ModernAnimatedButton(
                                text: 'Add Event',
                                onPressed: () => _showAddEventDialog(),
                                primaryColor: const Color(0xFF667EEA),
                                height: 36,
                                borderRadius: 18,
                                enableGradient: false,
                              ),
                              const SizedBox(width: 12),
                              ModernOutlineButton(
                                text: 'Settings',
                                onPressed: _showConfigurationDialog,
                                textColor: Colors.white,
                                borderColor: Colors.white,
                                height: 36,
                                borderRadius: 18,
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
            SliverPersistentHeader(
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  onTap: (index) => _switchViewMode(_getAvailableViewModes()[index]),
                  tabs: _getAvailableViewModes().map((mode) => Tab(
                    text: TimelineRendererFactory.getViewModeDisplayName(mode),
                    icon: Icon(_getViewModeIcon(mode)),
                  )).toList(),
                  labelColor: const Color(0xFF667EEA),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF667EEA),
                  indicatorWeight: 3,
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: Column(
          children: [
            // Quick action bar with modern design
            _buildModernQuickActionBar(),
            // View mode specific controls
            _buildViewModeControls(),
            // Timeline content
            Expanded(
              child: _buildTimelineContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: ModernFloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF667EEA),
        enableRotation: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _buildModernBottomNavigationBar(),
    );
  }

  Widget _buildModernQuickActionBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassmorphismCard(
        height: 60,
        borderRadius: 16,
        opacity: 0.1,
        backgroundColor: const Color(0xFF667EEA),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ModernOutlineButton(
              text: 'Filter',
              onPressed: () {},
              textColor: const Color(0xFF667EEA),
              borderColor: const Color(0xFF667EEA),
              height: 36,
              icon: const Icon(Icons.filter_list, size: 16),
            ),
            const SizedBox(width: 12),
            ModernOutlineButton(
              text: 'Search',
              onPressed: () {},
              textColor: const Color(0xFF667EEA),
              borderColor: const Color(0xFF667EEA),
              height: 36,
              icon: const Icon(Icons.search, size: 16),
            ),
            const Spacer(),
            ModernAnimatedButton(
              text: 'Refresh',
              onPressed: _initializeTimeline,
              primaryColor: const Color(0xFF667EEA),
              height: 36,
              borderRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline),
              label: 'Timeline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Social',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add New Event',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ModernAnimatedButton(
                  text: 'Create Event',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  primaryColor: const Color(0xFF667EEA),
                ),
                const SizedBox(height: 12),
                ModernOutlineButton(
                  text: 'Cancel',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  borderColor: const Color(0xFF667EEA),
                  textColor: const Color(0xFF667EEA),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildQuickActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Previous view mode
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToPreviousViewMode,
            tooltip: 'Previous View',
          ),
          const SizedBox(width: 8),
          // Current view mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getViewModeIcon(_currentViewMode),
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  _getViewModeTitle(_currentViewMode),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Next view mode
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _navigateToNextViewMode,
            tooltip: 'Next View',
          ),
          const Spacer(),
          // Action buttons
          ModernAnimatedButton(
            text: 'Add Event',
            onPressed: _showAddEventDialog,
            height: 32,
            borderRadius: 16,
          ),
          const SizedBox(width: 8),
          ModernAnimatedButton(
            text: 'Filter',
            onPressed: _showFilterDialog,
            height: 32,
            borderRadius: 16,
            enableGradient: false,
          ),
        ],
      ),
    );
  }

  void _navigateToPreviousViewMode() {
    final availableViewModes = _getAvailableViewModes();
    final currentIndex = availableViewModes.indexOf(_currentViewMode);
    
    if (currentIndex > 0) {
      _switchViewMode(availableViewModes[currentIndex - 1]);
    } else {
      _switchViewMode(availableViewModes.last);
    }
  }

  void _navigateToNextViewMode() {
    final availableViewModes = _getAvailableViewModes();
    final currentIndex = availableViewModes.indexOf(_currentViewMode);
    
    if (currentIndex < availableViewModes.length - 1) {
      _switchViewMode(availableViewModes[currentIndex + 1]);
    } else {
      _switchViewMode(availableViewModes.first);
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: const Text('Event dialog would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
        ],
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
              final dataService = ref.watch(timelineServiceProvider);
              final locationCount = dataService.events.where((e) => e.location != null).length;
              return Text(
                '$locationCount locations',
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoryControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.view_carousel),
            onPressed: () {
              // TODO: Switch story layout
            },
            tooltip: 'Layout',
          ),
          IconButton(
            icon: const Icon(Icons.auto_stories),
            onPressed: () {
              // TODO: Toggle narrative mode
            },
            tooltip: 'Narrative',
          ),
          const Spacer(),
          Text(
            'Story Mode',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildClusteredControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              // TODO: Show clustering options
            },
            tooltip: 'Clustering',
          ),
          IconButton(
            icon: const Icon(Icons.expand_less),
            onPressed: () {
              // TODO: Expand/collapse all
            },
            tooltip: 'Expand All',
          ),
          const Spacer(),
          Text(
            'Clustered View',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineContent() {
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
      scrollController: _scrollController,
    );
  }

  String _getViewModeTitle(TimelineViewMode viewMode) {
    return TimelineRendererFactory.getViewModeDisplayName(viewMode);
  }

  IconData _getViewModeIcon(TimelineViewMode viewMode) {
    final iconName = TimelineRendererFactory.getViewModeIcon(viewMode);
    switch (iconName) {
      case 'timeline':
        return Icons.timeline;
      case 'category':
        return Icons.category;
      case 'map':
        return Icons.map;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'water':
        return Icons.water;
      case 'grid_view':
        return Icons.grid_view;
      default:
        return Icons.timeline;
    }
  }
}

/// Enhanced timeline configuration dialog
class TimelineConfigurationDialog extends StatefulWidget {
  final TimelineRenderConfig config;
  final Function(TimelineRenderConfig) onConfigChanged;

  const TimelineConfigurationDialog({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<TimelineConfigurationDialog> createState() => _TimelineConfigurationDialogState();
}

class _TimelineConfigurationDialogState extends State<TimelineConfigurationDialog> {
  late bool _showPrivateEvents;
  late double? _zoomLevel;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _selectedContextId;
  late String _timeFilter;
  late String _eventFilter;

  @override
  void initState() {
    super.initState();
    _showPrivateEvents = widget.config.showPrivateEvents;
    _zoomLevel = widget.config.zoomLevel;
    _startDate = widget.config.startDate;
    _endDate = widget.config.endDate;
    _selectedContextId = widget.config.activeContext?.id ?? 'all';
    _timeFilter = 'all'; // all, today, week, month, year, custom
    _eventFilter = 'all'; // all, photos, milestones, text
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Timeline Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralSettings(),
                    const SizedBox(height: 24),
                    _buildDateRangeSettings(),
                    const SizedBox(height: 24),
                    _buildFilterSettings(),
                    const SizedBox(height: 24),
                    if (widget.config.viewMode == TimelineViewMode.mapView) ...[
                      _buildMapSettings(),
                      const SizedBox(height: 24),
                    ],
                    if (widget.config.viewMode == TimelineViewMode.story) ...[
                      _buildStorySettings(),
                      const SizedBox(height: 24),
                    ],
                    if (widget.config.viewMode == TimelineViewMode.clustered) ...[
                      _buildClusteredSettings(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSettingsSection('General Settings', [
      SwitchListTile(
        title: const Text('Show Private Events'),
        subtitle: const Text('Include events marked as private'),
        value: _showPrivateEvents,
        onChanged: (value) {
          setState(() {
            _showPrivateEvents = value;
          });
        },
      ),
      if (widget.config.viewMode == TimelineViewMode.mapView) ...[
        ListTile(
          title: const Text('Zoom Level'),
          subtitle: Text('${_zoomLevel?.toStringAsFixed(1) ?? '1.0'}x'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: _zoomLevel ?? 1.0,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _zoomLevel = value;
                });
              },
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildDateRangeSettings() {
    return _buildSettingsSection('Date Range', [
      ListTile(
        title: const Text('Time Filter'),
        subtitle: Text(_getTimeFilterDisplay(_timeFilter)),
        trailing: DropdownButton<String>(
          value: _timeFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Time')),
            DropdownMenuItem(value: 'today', child: Text('Today')),
            DropdownMenuItem(value: 'week', child: Text('This Week')),
            DropdownMenuItem(value: 'month', child: Text('This Month')),
            DropdownMenuItem(value: 'year', child: Text('This Year')),
            DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
          ],
          onChanged: (value) {
            setState(() {
              _timeFilter = value!;
              if (value != 'custom') {
                _startDate = null;
                _endDate = null;
              }
            });
          },
        ),
      ),
      if (_timeFilter == 'custom') ...[
        ListTile(
          title: const Text('Start Date'),
          subtitle: Text(_startDate != null 
              ? _formatDate(_startDate!) 
              : 'Select start date'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectStartDate,
        ),
        ListTile(
          title: const Text('End Date'),
          subtitle: Text(_endDate != null 
              ? _formatDate(_endDate!) 
              : 'Select end date'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectEndDate,
        ),
      ],
    ]);
  }

  Widget _buildFilterSettings() {
    return _buildSettingsSection('Filters', [
      ListTile(
        title: const Text('Event Type'),
        subtitle: Text(_getEventFilterDisplay(_eventFilter)),
        trailing: DropdownButton<String>(
          value: _eventFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Events')),
            DropdownMenuItem(value: 'photos', child: Text('Photos Only')),
            DropdownMenuItem(value: 'milestones', child: Text('Milestones Only')),
            DropdownMenuItem(value: 'text', child: Text('Text Events Only')),
          ],
          onChanged: (value) {
            setState(() {
              _eventFilter = value!;
            });
          },
        ),
      ),
      ListTile(
        title: const Text('Context'),
        subtitle: Text(_getContextDisplay(_selectedContextId)),
        trailing: DropdownButton<String>(
          value: _selectedContextId,
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Contexts')),
            const DropdownMenuItem(value: 'context-1', child: Text('Personal Timeline')),
            const DropdownMenuItem(value: 'context-2', child: Text('Adventures')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedContextId = value!;
            });
          },
        ),
      ),
    ]);
  }

  Widget _buildMapSettings() {
    return _buildSettingsSection('Map Settings', [
      const ListTile(
        title: Text('Map Type'),
        subtitle: Text('Choose map visualization style'),
        trailing: Icon(Icons.map),
      ),
      const ListTile(
        title: Text('Show Heatmap'),
        subtitle: Text('Display event density as heatmap'),
        trailing: Icon(Icons.heat_pump),
      ),
      const ListTile(
        title: Text('Playback Controls'),
        subtitle: Text('Enable timeline playback on map'),
        trailing: Icon(Icons.play_arrow),
      ),
    ]);
  }

  Widget _buildStorySettings() {
    return _buildSettingsSection('Story Settings', [
      const ListTile(
        title: Text('Story Layout'),
        subtitle: Text('Choose story presentation style'),
        trailing: Icon(Icons.view_carousel),
      ),
      const ListTile(
        title: Text('Narrative Mode'),
        subtitle: Text('Enable narrative flow between events'),
        trailing: Icon(Icons.auto_stories),
      ),
      const ListTile(
        title: Text('Chapter Grouping'),
        subtitle: Text('Group events into chapters'),
        trailing: Icon(Icons.book),
      ),
    ]);
  }

  Widget _buildClusteredSettings() {
    return _buildSettingsSection('Cluster Settings', [
      const ListTile(
        title: Text('Cluster By'),
        subtitle: Text('Choose clustering method'),
        trailing: Icon(Icons.category),
      ),
      const ListTile(
        title: Text('Cluster Size'),
        subtitle: Text('Minimum events per cluster'),
        trailing: Icon(Icons.group),
      ),
      const ListTile(
        title: Text('Auto-expand'),
        subtitle: Text('Automatically expand clusters'),
        trailing: Icon(Icons.expand_less),
      ),
    ]);
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _resetToDefaults,
          child: const Text('Reset to Defaults'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _applySettings,
          child: const Text('Apply Settings'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _resetToDefaults() {
    setState(() {
      _showPrivateEvents = true;
      _zoomLevel = 1.0;
      _startDate = null;
      _endDate = null;
      _selectedContextId = 'all';
      _timeFilter = 'all';
      _eventFilter = 'all';
    });
  }

  void _applySettings() {
    // Create active context based on selection
    Context? activeContext;
    if (_selectedContextId != 'all') {
      activeContext = Context(
        id: _selectedContextId,
        ownerId: 'user-1',
        type: ContextType.person,
        name: _selectedContextId == 'context-1' ? 'Personal Timeline' : 'Adventures',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final newConfig = widget.config.copyWith(
      showPrivateEvents: _showPrivateEvents,
      zoomLevel: _zoomLevel,
      startDate: _startDate,
      endDate: _endDate,
      activeContext: activeContext,
      customSettings: {
        'timeFilter': _timeFilter,
        'eventFilter': _eventFilter,
      },
    );
    widget.onConfigChanged(newConfig);
    Navigator.of(context).pop();
  }

  String _getTimeFilterDisplay(String filter) {
    switch (filter) {
      case 'all': return 'All Time';
      case 'today': return 'Today';
      case 'week': return 'This Week';
      case 'month': return 'This Month';
      case 'year': return 'This Year';
      case 'custom': return 'Custom Range';
      default: return filter;
    }
  }

  String _getEventFilterDisplay(String filter) {
    switch (filter) {
      case 'all': return 'All Events';
      case 'photos': return 'Photos Only';
      case 'milestones': return 'Milestones Only';
      case 'text': return 'Text Events Only';
      default: return filter;
    }
  }

  String _getContextDisplay(String contextId) {
    switch (contextId) {
      case 'all': return 'All Contexts';
      case 'context-1': return 'Personal Timeline';
      case 'context-2': return 'Adventures';
      default: return contextId;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
