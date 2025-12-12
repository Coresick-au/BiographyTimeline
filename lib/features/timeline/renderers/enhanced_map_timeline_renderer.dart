import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';

/// Enhanced Map-based timeline renderer with animated playback and temporal controls
class EnhancedMapTimelineRenderer extends ITimelineRenderer {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  final Map<String, List<TimelineEvent>> _locationClusters = {};
  
  // Map configuration
  MapType _mapType = MapType.normal;
  bool _showHeatmap = false;
  bool _showPlayback = false;
  bool _isPlaying = false;
  DateTime? _playbackDate;
  DateTime? _playbackStartDate;
  DateTime? _playbackEndDate;
  Timer? _playbackTimer;
  double _playbackSpeed = 1.0;
  int _currentEventIndex = 0;
  
  // Animation configuration
  Duration _animationDuration = const Duration(seconds: 2);
  Curve _animationCurve = Curves.easeInOut;
  bool _showEventTrail = true;
  bool _showTemporalHeatmap = false;
  
  // Clustering configuration
  double _clusterRadius = 50.0; // meters
  int _minClusterSize = 3;
  
  // Data
  TimelineRenderConfig? _config;
  TimelineRenderData? _data;
  List<TimelineEvent> _sortedEvents = [];
  BuildContext? _context;
  
  EnhancedMapTimelineRenderer() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize any services needed
  }

  @override
  TimelineViewMode get viewMode => TimelineViewMode.mapView;
  
  @override
  String get displayName => 'Enhanced Map';
  
  @override
  IconData get icon => Icons.map;
  
  @override
  String get description => 'Geographic visualization with animated timeline playback';
  
  @override
  bool get supportsInfiniteScroll => false;
  
  @override
  bool get supportsZoom => true;
  
  @override
  bool get supportsFiltering => true;
  
  @override
  bool get supportsSearch => true;
  
  @override
  List<TimelineViewMode> get availableViewModes => [
    TimelineViewMode.mapView,
    TimelineViewMode.chronological,
    TimelineViewMode.clustered,
    TimelineViewMode.lifeStream,
    TimelineViewMode.story,
  ];
  
  @override
  Future<void> initialize(TimelineRenderConfig config) async {
    _config = config;
    _sortedEvents = [];
    _currentEventIndex = 0;
    _playbackDate = null;
    _isPlaying = false;
    _playbackTimer?.cancel();
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
    _playbackTimer?.cancel();
    _mapController?.dispose();
    _markers.clear();
    _polylines.clear();
    _circles.clear();
    _locationClusters.clear();
    _sortedEvents.clear();
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
        _context = context;
        
        if (_data?.events.isEmpty ?? true) {
          return _buildEmptyState(context);
        }
        
        return Column(
          children: [
            _buildPlaybackControls(context),
            Expanded(
              child: _buildMap(context, onEventTap, onEventLongPress),
            ),
            _buildTimelineBar(context, onDateTap),
          ],
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Location Data',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add events with locations to see them on the map',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaybackControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline Playback',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getPlaybackStatus(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPlayPauseButton(context),
              _buildSpeedButton(context),
              _buildMapTypeButton(context),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _playbackDate?.millisecondsSinceEpoch.toDouble() ?? 
                         _data!.earliestDate.millisecondsSinceEpoch.toDouble(),
                  min: _data!.earliestDate.millisecondsSinceEpoch.toDouble(),
                  max: _data!.latestDate.millisecondsSinceEpoch.toDouble(),
                  onChanged: (value) {
                    _setPlaybackDate(DateTime.fromMillisecondsSinceEpoch(value.round()));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatDate(_playbackDate ?? _data!.earliestDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayPauseButton(BuildContext context) {
    return IconButton.filled(
      onPressed: _togglePlayback,
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      tooltip: _isPlaying ? 'Pause' : 'Play',
    );
  }
  
  Widget _buildSpeedButton(BuildContext context) {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.speed),
      tooltip: 'Playback Speed',
      onSelected: (speed) {
        _playbackSpeed = speed;
        if (_isPlaying) {
          _restartPlayback();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 1.0, child: Text('1x')),
        const PopupMenuItem(value: 2.0, child: Text('2x')),
        const PopupMenuItem(value: 5.0, child: Text('5x')),
      ],
    );
  }
  
  Widget _buildMapTypeButton(BuildContext context) {
    return PopupMenuButton<MapType>(
      icon: const Icon(Icons.layers),
      tooltip: 'Map Type',
      onSelected: (type) {
        _mapType = type;
        _updateMapStyle();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: MapType.normal, child: Text('Normal')),
        const PopupMenuItem(value: MapType.satellite, child: Text('Satellite')),
        const PopupMenuItem(value: MapType.hybrid, child: Text('Hybrid')),
        const PopupMenuItem(value: MapType.terrain, child: Text('Terrain')),
      ],
    );
  }
  
  Widget _buildMap(BuildContext context, TimelineEventCallback? onEventTap, TimelineEventCallback? onEventLongPress) {
    final locationEvents = _sortedEvents.where((e) => e.location != null).toList();
    
    if (locationEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Location Events',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Events without locations won\'t appear on the map',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    
    // Calculate bounds for all locations
    final bounds = _calculateBounds(locationEvents);
    
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMarkers();
        if (bounds != null) {
          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        }
      },
      initialCameraPosition: CameraPosition(
        target: _getCenterPoint(locationEvents),
        zoom: 10,
      ),
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      mapType: _mapType,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      onTap: (position) {
        // Handle map tap
      },
    );
  }
  
  Widget _buildTimelineBar(BuildContext context, TimelineDateCallback? onDateTap) {
    final locationEvents = _sortedEvents.where((e) => e.location != null).toList();
    
    if (locationEvents.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${locationEvents.length} locations',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: locationEvents.length,
              itemBuilder: (context, index) {
                final event = locationEvents[index];
                final isActive = _playbackDate != null && 
                    _isSameDay(_playbackDate!, event.timestamp);
                
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      _setPlaybackDate(event.timestamp);
                      onDateTap?.call(event.timestamp);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatShortDate(event.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isActive 
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight: isActive ? FontWeight.bold : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          _getEventTypeIcon(event.eventType),
                          size: 16,
                          color: isActive 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }
  
  void _startPlayback() {
    if (_sortedEvents.isEmpty) return;
    
    _isPlaying = true;
    if (_playbackDate == null) {
      _playbackDate = _data!.earliestDate;
    }
    
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (100 / _playbackSpeed).round()),
      (timer) {
        if (_playbackDate != null && _playbackDate!.isAfter(_data!.latestDate)) {
          _pausePlayback();
          return;
        }
        
        _advancePlayback();
      },
    );
  }
  
  void _pausePlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
  }
  
  void _restartPlayback() {
    _pausePlayback();
    _startPlayback();
  }
  
  void _advancePlayback() {
    if (_playbackDate == null) return;
    
    // Advance by 1 hour scaled by playback speed
    _playbackDate = _playbackDate!.add(Duration(hours: (1 * _playbackSpeed).round()));
    _updateMarkersForDate();
  }
  
  void _setPlaybackDate(DateTime date) {
    _playbackDate = date;
    _updateMarkersForDate();
  }
  
  void _updateMarkersForDate() {
    _markers.clear();
    _circles.clear();
    
    if (_playbackDate == null) return;
    
    final eventsOnDate = _sortedEvents.where((event) {
      return event.location != null && _isSameDay(event.timestamp, _playbackDate!);
    }).toList();
    
    for (final event in eventsOnDate) {
      _addMarkerForEvent(event, isActive: true);
    }
    
    // Show events within 7 days as faded
    final nearbyEvents = _sortedEvents.where((event) {
      if (event.location == null) return false;
      final daysDiff = event.timestamp.difference(_playbackDate!).inDays.abs();
      return daysDiff <= 7 && daysDiff > 0;
    }).toList();
    
    for (final event in nearbyEvents) {
      _addMarkerForEvent(event, isActive: false);
    }
  }
  
  void _updateMarkers() {
    _markers.clear();
    _circles.clear();
    _polylines.clear();
    
    final locationEvents = _sortedEvents.where((e) => e.location != null).toList();
    
    for (final event in locationEvents) {
      _addMarkerForEvent(event);
    }
    
    if (_showEventTrail && locationEvents.length > 1) {
      _addEventTrail(locationEvents);
    }
  }
  
  void _addMarkerForEvent(TimelineEvent event, {bool isActive = true}) {
    if (event.location == null) return;
    
    final position = LatLng(event.location!.latitude, event.location!.longitude);
    
    _markers.add(Marker(
      markerId: MarkerId(event.id),
      position: position,
      infoWindow: InfoWindow(
        title: event.title ?? 'Event',
        snippet: _formatDate(event.timestamp),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isActive ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
      ),
      onTap: () {
        // Handle marker tap
      },
    ));
    
    if (isActive) {
      _circles.add(Circle(
        circleId: CircleId('${event.id}_circle'),
        center: position,
        radius: 100,
        strokeWidth: 2,
        strokeColor: _context != null ? Theme.of(_context!).colorScheme.primary.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
        fillColor: _context != null ? Theme.of(_context!).colorScheme.primary.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
      ));
    }
  }
  
  void _addEventTrail(List<TimelineEvent> locationEvents) {
    final sortedByDate = List<TimelineEvent>.from(locationEvents)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final points = sortedByDate
        .where((e) => e.location != null)
        .map((e) => LatLng(e.location!.latitude, e.location!.longitude))
        .toList();
    
    if (points.length < 2) return;
    
    _polylines.add(Polyline(
      polylineId: const PolylineId('timeline_trail'),
      points: points,
      color: _context != null ? Theme.of(_context!).colorScheme.primary.withOpacity(0.7) : Colors.blue.withOpacity(0.7),
      width: 3,
      patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    ));
  }
  
  void _updateMapStyle() {
    // Map style updates would go here
  }
  
  LatLngBounds? _calculateBounds(List<TimelineEvent> events) {
    final locations = events.where((e) => e.location != null).toList();
    if (locations.isEmpty) return null;
    
    double minLat = locations.first.location!.latitude;
    double maxLat = locations.first.location!.latitude;
    double minLng = locations.first.location!.longitude;
    double maxLng = locations.first.location!.longitude;
    
    for (final event in locations) {
      minLat = math.min(minLat, event.location!.latitude);
      maxLat = math.max(maxLat, event.location!.latitude);
      minLng = math.min(minLng, event.location!.longitude);
      maxLng = math.max(maxLng, event.location!.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  LatLng _getCenterPoint(List<TimelineEvent> events) {
    if (events.isEmpty) return const LatLng(0, 0);
    
    double totalLat = 0;
    double totalLng = 0;
    int count = 0;
    
    for (final event in events) {
      if (event.location != null) {
        totalLat += event.location!.latitude;
        totalLng += event.location!.longitude;
        count++;
      }
    }
    
    return count > 0 ? LatLng(totalLat / count, totalLng / count) : const LatLng(0, 0);
  }
  
  String _getPlaybackStatus() {
    if (!_isPlaying) {
      return 'Paused';
    }
    
    if (_playbackDate == null) {
      return 'Ready to play';
    }
    
    return 'Playing at ${_playbackSpeed}x speed';
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
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
  
  // Interface implementations
  @override
  List<TimelineEvent> getVisibleEvents() {
    if (_playbackDate == null) return _sortedEvents;
    
    return _sortedEvents.where((event) {
      return _isSameDay(event.timestamp, _playbackDate!);
    }).toList();
  }
  
  @override
  DateTimeRange? getVisibleDateRange() {
    if (_playbackDate == null) return null;
    
    return DateTimeRange(
      start: DateTime(_playbackDate!.year, _playbackDate!.month, _playbackDate!.day),
      end: DateTime(_playbackDate!.year, _playbackDate!.month, _playbackDate!.day, 23, 59, 59),
    );
  }
  
  @override
  Future<void> updateData(TimelineRenderData data) async {
    _data = data;
    _sortedEvents = List<TimelineEvent>.from(data.events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _updateMarkers();
  }
  
  @override
  Future<void> updateConfig(TimelineRenderConfig config) async {
    _config = config;
  }
  
  @override
  Future<void> navigateToDate(DateTime date) async {
    _setPlaybackDate(date);
    
    // Find events on that date and center map on them
    final eventsOnDate = _sortedEvents.where((event) {
      return event.location != null && _isSameDay(event.timestamp, date);
    }).toList();
    
    if (eventsOnDate.isNotEmpty && _mapController != null) {
      final bounds = _calculateBounds(eventsOnDate);
      if (bounds != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    }
  }
  
  @override
  Future<void> navigateToEvent(String eventId) async {
    final event = _sortedEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => _sortedEvents.first,
    );
    
    if (event.location != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(event.location!.latitude, event.location!.longitude),
            zoom: 15,
          ),
        ),
      );
      
      _setPlaybackDate(event.timestamp);
    }
  }
  
  @override
  Future<void> setZoomLevel(double level) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.zoomTo(level),
      );
    }
  }
  
  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation would capture map as image
    return null;
  }
}
