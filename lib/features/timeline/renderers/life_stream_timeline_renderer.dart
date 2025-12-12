import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';

/// Life Stream timeline renderer with infinite scroll
class LifeStreamTimelineRenderer extends ITimelineRenderer {
  final ScrollController _scrollController = ScrollController();
  final List<TimelineEvent> _visibleEvents = [];
  final Map<String, Widget> _eventCache = {};
  
  int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  
  TimelineRenderConfig? _config;
  TimelineRenderData? _data;
  BuildContext? _context;
  
  @override
  TimelineViewMode get viewMode => TimelineViewMode.lifeStream;
  
  @override
  String get displayName => 'Life Stream';
  
  @override
  IconData get icon => Icons.stream;
  
  @override
  String get description => 'Infinite scroll through your life events';
  
  @override
  bool get supportsInfiniteScroll => true;
  
  @override
  bool get supportsZoom => false;
  
  @override
  bool get supportsFiltering => true;
  
  @override
  bool get supportsSearch => true;
  
  @override
  List<TimelineViewMode> get availableViewModes => [
    TimelineViewMode.lifeStream,
    TimelineViewMode.chronological,
    TimelineViewMode.clustered,
    TimelineViewMode.story,
  ];
  
  @override
  Future<void> initialize(TimelineRenderConfig config) async {
    _config = config;
    _scrollController.addListener(_onScroll);
    _resetPagination();
  }
  
  @override
  TimelineRenderConfig get config => _config ?? TimelineRenderConfig(viewMode: viewMode);
  
  @override
  TimelineRenderData get data => _data ?? TimelineRenderData(
    events: [],
    contexts: [],
    earliestDate: DateTime.now(),
    latestDate: DateTime.now(),
    clusteredEvents: {},
  );
  
  @override
  bool get isReady => _config != null && _data != null;
  
  @override
  void dispose() {
    _scrollController.dispose();
    _eventCache.clear();
    _visibleEvents.clear();
  }
  
  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return Builder(
      builder: (context) {
        if (_data?.events.isEmpty ?? true) {
          return _buildEmptyState(context);
        }
        
        return Column(
          children: [
            _buildHeader(context, _data!, _config!),
            Expanded(
              child: _buildLifeStream(context, _data!, _config!),
            ),
            if (_isLoading) _buildLoadingIndicator(),
          ],
        );
      },
    );
  }
  
  @override
  List<TimelineEvent> getVisibleEvents() {
    return List.unmodifiable(_visibleEvents);
  }
  
  @override
  DateTimeRange? getVisibleDateRange() {
    if (_visibleEvents.isEmpty) return null;
    
    final dates = _visibleEvents.map((e) => e.timestamp).toList();
    dates.sort();
    
    return DateTimeRange(
      start: dates.first,
      end: dates.last,
    );
  }
  
  @override
  Future<void> updateData(TimelineRenderData data) async {
    _data = data;
    _resetPagination();
  }
  
  @override
  Future<void> updateConfig(TimelineRenderConfig config) async {
    _config = config;
  }
  
  @override
  Future<void> navigateToDate(DateTime date) async {
    // Find the first event on or after the target date
    if (_data?.events.isEmpty ?? true) return;
    
    final targetEvent = _data!.events.firstWhere(
      (event) => event.timestamp.isAfter(date) || event.timestamp.isAtSameMomentAs(date),
      orElse: () => _data!.events.last,
    );
    
    // Scroll to the event (implementation would depend on scroll controller)
    _scrollController.animateTo(
      0, // Would calculate actual position
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  @override
  Future<void> navigateToEvent(String eventId) async {
    // Find and navigate to specific event
    final event = _visibleEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => _visibleEvents.first,
    );
    
    // Implementation would scroll to specific event
  }
  
  @override
  Future<void> setZoomLevel(double level) async {
    // Life Stream doesn't support zoom
  }
  
  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation would capture the view as image
    return null;
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stream,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Events Yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding events to see your life stream',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, TimelineRenderData data, TimelineRenderConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stream,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life Stream',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data.events.length} total events • Showing ${_visibleEvents.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          _buildFilterButton(context, config),
          _buildSearchButton(context, config),
        ],
      ),
    );
  }
  
  Widget _buildFilterButton(BuildContext context, TimelineRenderConfig config) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () => _showFilterDialog(context, config),
      tooltip: 'Filter Events',
    );
  }
  
  Widget _buildSearchButton(BuildContext context, TimelineRenderConfig config) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => _showSearchDialog(context, config),
      tooltip: 'Search Events',
    );
  }
  
  Widget _buildLifeStream(BuildContext context, TimelineRenderData data, TimelineRenderConfig config) {
    if (_visibleEvents.isEmpty && !_isLoading) {
      _loadMoreEvents(data.events);
    }
    
    return RefreshIndicator(
      onRefresh: () => _refreshEvents(data.events),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _hasMore ? _visibleEvents.length + 1 : _visibleEvents.length,
        itemBuilder: (context, index) {
          if (index == _visibleEvents.length && _hasMore) {
            return _buildLoadMoreIndicator();
          }
          
          if (index >= _visibleEvents.length) {
            return const SizedBox.shrink();
          }
          
          final event = _visibleEvents[index];
          return _buildEventCard(context, event, data.contexts, config);
        },
      ),
    );
  }
  
  Widget _buildEventCard(BuildContext context, TimelineEvent event, List<Context> contexts, TimelineRenderConfig config) {
    final contextEntity = contexts.firstWhere(
      (ctx) => ctx.id == event.contextId,
      orElse: () => contexts.first,
    );
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(context, event, contextEntity),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventHeader(context, event, contextEntity),
              const SizedBox(height: 12),
              if (event.description != null) ...[
                Text(
                  event.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              if (event.location != null) _buildLocationInfo(context, event.location!),
              _buildEventFooter(context, event),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEventHeader(BuildContext context, TimelineEvent event, Context contextEntity) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getEventTypeColor(event.eventType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getEventTypeIcon(event.eventType),
            color: _getEventTypeColor(event.eventType),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title ?? 'Untitled Event',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                contextEntity.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(event.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatTime(event.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLocationInfo(BuildContext context, GeoLocation location) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location.locationName ?? 'Unknown Location',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEventFooter(BuildContext context, TimelineEvent event) {
    return Row(
      children: [
        if (event.assets.isNotEmpty) ...[
          Icon(
            Icons.photo_library,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${event.assets.length} media',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
        const Spacer(),
        Icon(
          _getPrivacyIcon(event.privacyLevel),
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Load more when 200px from bottom
    
    if (maxScroll - currentScroll <= delta && !_isLoading && _hasMore) {
      _loadMoreEvents([]);
    }
  }
  
  void _loadMoreEvents(List<TimelineEvent> allEvents) {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (allEvents.isNotEmpty) {
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, allEvents.length);
        
        if (startIndex < allEvents.length) {
          final newEvents = allEvents.sublist(startIndex, endIndex);
          _visibleEvents.addAll(newEvents);
          _currentPage++;
          _hasMore = endIndex < allEvents.length;
        } else {
          _hasMore = false;
        }
      }
      
      _isLoading = false;
    });
  }
  
  Future<void> _refreshEvents(List<TimelineEvent> allEvents) async {
    _resetPagination();
    _loadMoreEvents(allEvents);
  }
  
  void _resetPagination() {
    _currentPage = 0;
    _visibleEvents.clear();
    _isLoading = false;
    _hasMore = true;
    _eventCache.clear();
  }
  
  void _showEventDetails(BuildContext context, TimelineEvent event, Context contextEntity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.eventType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventTypeIcon(event.eventType),
                      color: _getEventTypeColor(event.eventType),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title ?? 'Untitled Event',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          contextEntity.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Date', _formatFullDate(event.timestamp)),
                      _buildDetailRow('Time', _formatTime(event.timestamp)),
                      if (event.location != null)
                        _buildDetailRow('Location', event.location!.locationName ?? 'Unknown'),
                      _buildDetailRow('Type', event.eventType),
                      if (event.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(event.description!),
                      ],
                      if (event.assets.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Media (${event.assets.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.assets.map((asset) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
              Icons.image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog(BuildContext context, TimelineRenderConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: const Text('Filter options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showSearchDialog(BuildContext context, TimelineRenderConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Events'),
        content: const Text('Search functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'photo':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'milestone':
        return Colors.green;
      case 'text':
        return Colors.purple;
      case 'location':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'photo':
        return Icons.photo;
      case 'video':
        return Icons.videocam;
      case 'milestone':
        return Icons.star;
      case 'text':
        return Icons.text_fields;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.event;
    }
  }
  
  IconData _getPrivacyIcon(PrivacyLevel privacyLevel) {
    switch (privacyLevel) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.private:
        return Icons.lock;
      default:
        return Icons.visibility;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
