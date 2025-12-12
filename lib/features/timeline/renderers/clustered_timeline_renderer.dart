import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../../../core/templates/template_manager.dart';
import '../services/event_clustering_service.dart';

/// Clustered timeline renderer that groups events by time periods and themes
class ClusteredTimelineRenderer extends BaseTimelineRenderer {
  final ScrollController _scrollController = ScrollController();
  final TemplateManager _templateManager = TemplateManager();
  final EventClusteringService _clusteringService = EventClusteringService();
  
  // Clustering configuration
  final List<EventCluster> _clusters = [];
  final Map<String, Widget> _clusterWidgets = {};
  ClusterConfig _clusterConfig = const ClusterConfig();
  
  ClusteredTimelineRenderer(
    super.config, 
    super.data,
  ) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _templateManager.initialize();
    await _updateClusters();
  }

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return StreamBuilder<List<EventCluster>>(
      stream: _getClusteredEventsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final clusters = snapshot.data!;
        if (clusters.isEmpty) {
          return _buildEmptyState();
        }

        return _buildClusteredTimelineView(
          clusters,
          onEventTap: onEventTap,
          onEventLongPress: onEventLongPress,
          onDateTap: onDateTap,
          onContextTap: onContextTap,
          scrollController: scrollController,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No clustered events',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Events will be grouped by time and theme',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusteredTimelineView(
    List<EventCluster> clusters, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return CustomScrollView(
      controller: scrollController ?? _scrollController,
      slivers: [
        _buildClusterHeader(clusters),
        ...clusters.map((cluster) => 
          _buildClusterSection(
            cluster,
            onEventTap: onEventTap,
            onEventLongPress: onEventLongPress,
            onDateTap: onDateTap,
            onContextTap: onContextTap,
          )
        ),
        _buildClusterFooter(),
      ],
    );
  }

  Widget _buildClusterHeader(List<EventCluster> clusters) {
    final totalEvents = clusters.fold(0, (sum, cluster) => sum + cluster.events.length);
    
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Clustered Timeline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                _buildClusteringOptionsButton(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${clusters.length} clusters • $totalEvents events',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusteringOptionsButton() {
    return PopupMenuButton<ClusterType>(
      icon: const Icon(Icons.tune),
      onSelected: (type) {
        _updateClusterConfig(type);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ClusterType.monthly,
          child: Text('Monthly'),
        ),
        const PopupMenuItem(
          value: ClusterType.weekly,
          child: Text('Weekly'),
        ),
        const PopupMenuItem(
          value: ClusterType.thematic,
          child: Text('Thematic'),
        ),
        const PopupMenuItem(
          value: ClusterType.contextual,
          child: Text('By Context'),
        ),
      ],
    );
  }

  Widget _buildClusterSection(
    EventCluster cluster, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClusterSectionHeader(cluster),
            const SizedBox(height: 8),
            _buildClusterContent(
              cluster.events,
              onEventTap: onEventTap,
              onEventLongPress: onEventLongPress,
              onContextTap: onContextTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterSectionHeader(EventCluster cluster) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cluster.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${cluster.events.length} events',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${cluster.events.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterContent(
    List<TimelineEvent> events, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    if (events.length <= 3) {
      // Show all events for small clusters
      return Column(
        children: events.map((event) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCompactEventCard(
              event,
              onEventTap: onEventTap,
              onEventLongPress: onEventLongPress,
              onContextTap: onContextTap,
            ),
          ),
        ).toList(),
      );
    } else {
      // Show summary for large clusters
      return Column(
        children: [
          ...events.take(2).map((event) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCompactEventCard(
                event,
                onEventTap: onEventTap,
                onEventLongPress: onEventLongPress,
                onContextTap: onContextTap,
              ),
            ),
          ),
          _buildExpandableClusterSection(events),
        ],
      );
    }
  }

  Widget _buildCompactEventCard(
    TimelineEvent event, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    final context = data.contexts.firstWhere(
      (ctx) => ctx.id == event.contextId,
      orElse: () => Context(
        id: 'default',
        ownerId: event.ownerId,
        type: ContextType.person,
        name: 'Default',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onEventTap?.call(event),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(
              _getEventIcon(event.eventType),
            size: 20,
            color: Colors.grey[600],
          ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'Untitled Event',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null)
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatCompactDate(event.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableClusterSection(List<TimelineEvent> events) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.expand_more,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '+${events.length - 2} more events',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Handle expanding cluster
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterFooter() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'End of clusters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<EventCluster>> _getClusteredEventsStream() {
    return Stream.value(_clusters);
  }

  Future<void> _updateClusters() async {
    // Initialize clusters if needed
    if (_clusters.isEmpty) {
      await _generateClusters();
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'photo':
        return Icons.photo;
      case 'text':
        return Icons.text_fields;
      case 'milestone':
        return Icons.flag;
      default:
        return Icons.event;
    }
  }

  String _formatCompactDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _generateClusters() async {
    _clusters.clear();
    final filteredEvents = filterEvents(data.events);
    
    // Simple clustering by month
    final monthGroups = <String, List<TimelineEvent>>{};
    for (final event in filteredEvents) {
      final monthKey = '${event.timestamp.year}-${event.timestamp.month}';
      monthGroups.putIfAbsent(monthKey, () => []).add(event);
    }

    for (final entry in monthGroups.entries) {
      final date = DateTime.parse('${entry.key}-01');
      _clusters.add(EventCluster(
        key: entry.key,
        title: _formatMonthYear(date),
        events: entry.value,
        type: ClusterType.month,
      ));
    }
    
    _clusters.sort((a, b) => a.key.compareTo(b.key));
  }

  void _updateClusterConfig(ClusterType type) {
    _clusterConfig = ClusterConfig(type: type);
    _generateClusters();
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    await super.updateData(data);
    await _generateClusters();
    await _updateClusters();
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Navigate to the cluster containing the date
    final targetCluster = _clusters.firstWhere(
      (cluster) => _clusterContainsDate(cluster, date),
      orElse: () => EventCluster(
        key: '',
        title: '',
        events: [],
        type: ClusterType.month,
      ),
    );
    
    if (targetCluster.key.isNotEmpty && _scrollController.hasClients) {
      // Find and scroll to the cluster
      final clusterIndex = _clusters.indexWhere((cluster) => cluster.key == targetCluster.key);
      if (clusterIndex != -1) {
        final estimatedPosition = clusterIndex * 300.0; // Estimated cluster height
        await _scrollController.animateTo(
          estimatedPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
    
    await super.navigateToDate(date);
  }

  bool _clusterContainsDate(EventCluster cluster, DateTime date) {
    // Simple check - if the cluster contains events around the date
    return cluster.events.any((event) => 
      event.timestamp.year == date.year && event.timestamp.month == date.month
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _clusters.clear();
    _clusterWidgets.clear();
    super.dispose();
  }
}

/// Event cluster data structure
class EventCluster {
  final String key;
  final String title;
  final List<TimelineEvent> events;
  final ClusterType type;

  const EventCluster({
    required this.key,
    required this.title,
    required this.events,
    required this.type,
  });
}

/// Configuration for event clustering
class ClusterConfig {
  final ClusterType type;
  final int maxEventsPerCluster;
  final bool showEmptyClusters;
  final Map<String, dynamic> customSettings;

  const ClusterConfig({
    this.type = ClusterType.monthly,
    this.maxEventsPerCluster = 10,
    this.showEmptyClusters = false,
    this.customSettings = const {},
  });
}

/// Types of clustering available
enum ClusterType {
  monthly,
  weekly,
  thematic,
  contextual,
  month,
}

/// Information about a cluster
class ClusterInfo {
  final ClusterType type;
  final String title;
  final String? subtitle;
  final DateTime date;

  const ClusterInfo({
    required this.type,
    required this.title,
    this.subtitle,
    required this.date,
  });
}
