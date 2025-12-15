import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../../../shared/models/geo_location.dart';
import '../../../core/templates/template_manager.dart';

/// Map-based timeline renderer with location clustering and temporal playback
class MapTimelineRenderer extends BaseTimelineRenderer {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Map<String, List<TimelineEvent>> _locationClusters = {};
  final TemplateManager _templateManager = TemplateManager();
  
  // Map configuration
  MapType _mapType = MapType.normal;
  bool _showHeatmap = false;
  bool _showPlayback = false;
  DateTime? _playbackDate;
  Timer? _playbackTimer;
  
  // Clustering configuration
  double _clusterRadius = 50.0; // meters
  int _minClusterSize = 3;

  MapTimelineRenderer(
    super.config, 
    super.data,
  ) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _templateManager.initialize();
    await _updateLocationClusters();
  }

  @override
  Widget build({
    BuildContext? context,
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    // Check if we're on web and Google Maps might not be configured
    if (kIsWeb) {
      return _buildWebFallback(onEventTap, onEventLongPress, onDateTap, onContextTap);
    }
    
    return _buildMapContent(onEventTap, onEventLongPress, onDateTap, onContextTap);
  }

  Widget _buildWebFallback(
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  ) {
    final eventsWithLocation = data.events.where((e) => e.location != null).toList();
    
    return Scaffold(
      body: Column(
        children: [
          _buildMapControls(onEventTap, onEventLongPress, onDateTap, onContextTap),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map View Not Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google Maps requires API configuration for web. Please use the mobile app or try a different view.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (eventsWithLocation.isNotEmpty) ...[
                    Text(
                      'Found ${eventsWithLocation.length} events with locations:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: eventsWithLocation.length,
                        itemBuilder: (context, index) {
                          final event = eventsWithLocation[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(Icons.location_on, color: Colors.blue),
                              title: Text(event.title ?? 'Untitled Event'),
                              subtitle: Text(event.location?.locationName ?? 'Unknown location'),
                              onTap: () => onEventTap?.call(event),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  ) {
    return StreamBuilder<Map<String, List<TimelineEvent>>>(
      stream: _getLocationClustersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final clusters = snapshot.data!;
        return _buildMapView(
          clusters,
          onEventTap: onEventTap,
          onEventLongPress: onEventLongPress,
          onDateTap: onDateTap,
          onContextTap: onContextTap,
        );
      },
    );
  }

  Widget _buildMapView(
    Map<String, List<TimelineEvent>> clusters, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  }) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _getInitialCameraPosition(),
          onMapCreated: _onMapCreated,
          markers: _markers,
          polylines: _polylines,
          mapType: _mapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onTap: _handleMapTap,
        ),
        _buildMapControls(onEventTap, onEventLongPress, onDateTap, onContextTap),
        if (_showPlayback) _buildPlaybackControls(),
        _buildEventInfoPanel(clusters),
      ],
    );
  }

  CameraPosition _getInitialCameraPosition() {
    if (data.events.isEmpty) {
      return const CameraPosition(
        target: LatLng(37.7749, -122.4194), // San Francisco
        zoom: 10,
      );
    }

    final eventsWithLocation = data.events
        .where((e) => e.location != null)
        .toList();

    if (eventsWithLocation.isEmpty) {
      return const CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 10,
      );
    }

    // Calculate center point of all events
    double totalLat = 0;
    double totalLng = 0;
    
    for (final event in eventsWithLocation) {
      totalLat += event.location!.latitude;
      totalLng += event.location!.longitude;
    }

    final centerLat = totalLat / eventsWithLocation.length;
    final centerLng = totalLng / eventsWithLocation.length;

    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 10,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapMarkers();
  }

  void _handleMapTap(LatLng position) {
    // Handle map tap - could show events near this location
    debugPrint('Map tapped at: ${position.latitude}, ${position.longitude}');
  }

  Widget _buildMapControls(
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  ) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildMapTypeButton(),
          const SizedBox(height: 8),
          _buildHeatmapButton(),
          const SizedBox(height: 8),
          _buildPlaybackButton(),
          const SizedBox(height: 8),
          _buildClusteringButton(),
        ],
      ),
    );
  }

  Widget _buildMapTypeButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _cycleMapType,
      child: Icon(_getMapTypeIcon()),
    );
  }

  Widget _buildHeatmapButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _toggleHeatmap,
      backgroundColor: _showHeatmap ? Colors.blue : null,
      child: const Icon(Icons.whatshot_outlined),
    );
  }

  Widget _buildPlaybackButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _togglePlayback,
      backgroundColor: _showPlayback ? Colors.blue : null,
      child: Icon(_showPlayback ? Icons.pause : Icons.play_arrow),
    );
  }

  Widget _buildClusteringButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _showClusteringOptions,
      child: const Icon(Icons.layers),
    );
  }

  Widget _buildPlaybackControls() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Timeline Playback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            if (_playbackDate != null)
              Text(
                _formatPlaybackDate(_playbackDate!),
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _rewindPlayback,
                  icon: const Icon(Icons.skip_previous),
                ),
                Expanded(
                  child: Slider(
                    value: _getPlaybackProgress(),
                    onChanged: _setPlaybackProgress,
                  ),
                ),
                IconButton(
                  onPressed: _fastForwardPlayback,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfoPanel(Map<String, List<TimelineEvent>> clusters) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Location Clusters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Text(
                  '${clusters.length} locations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${data.events.length} events with location data',
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

  void _cycleMapType() {
    setState(() {
      switch (_mapType) {
        case MapType.normal:
          _mapType = MapType.satellite;
          break;
        case MapType.satellite:
          _mapType = MapType.hybrid;
          break;
        case MapType.hybrid:
          _mapType = MapType.terrain;
          break;
        case MapType.terrain:
          _mapType = MapType.normal;
          break;
        case MapType.none:
          _mapType = MapType.normal;
          break;
      }
    });
  }

  void _toggleHeatmap() {
    setState(() {
      _showHeatmap = !_showHeatmap;
      _updateMapMarkers();
    });
  }

  void _togglePlayback() {
    setState(() {
      _showPlayback = !_showPlayback;
      if (_showPlayback) {
        _startPlayback();
      } else {
        _stopPlayback();
      }
    });
  }

  void _showClusteringOptions() {
    // This would need to be handled by the parent widget
    debugPrint('Show clustering options');
  }

  IconData _getMapTypeIcon() {
    switch (_mapType) {
      case MapType.normal:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite;
      case MapType.hybrid:
        return Icons.layers;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.none:
        return Icons.map;
    }
  }

  void _startPlayback() {
    if (data.events.isEmpty) return;

    final sortedEvents = data.events
        .where((e) => e.location != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sortedEvents.isEmpty) return;

    _playbackDate = sortedEvents.first.timestamp;
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentIndex = sortedEvents.indexWhere(
        (e) => e.timestamp.isAfter(_playbackDate!),
      );
      
      if (currentIndex != -1 && currentIndex < sortedEvents.length) {
        _playbackDate = sortedEvents[currentIndex].timestamp;
        _updateMapMarkers();
        
        // Move camera to current event location
        final currentEvent = sortedEvents[currentIndex];
        if (currentEvent.location != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                currentEvent.location!.latitude,
                currentEvent.location!.longitude,
              ),
              12,
            ),
          );
        }
      } else {
        _stopPlayback();
      }
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackDate = null;
  }

  void _rewindPlayback() {
    // Rewind playback by 10 events
    if (_playbackDate != null) {
      final sortedEvents = data.events
          .where((e) => e.location != null)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      final currentIndex = sortedEvents.indexWhere(
        (e) => e.timestamp.isAfter(_playbackDate!),
      );
      
      if (currentIndex > 10) {
        _playbackDate = sortedEvents[currentIndex - 10].timestamp;
        _updateMapMarkers();
      }
    }
  }

  void _fastForwardPlayback() {
    // Fast forward playback by 10 events
    if (_playbackDate != null) {
      final sortedEvents = data.events
          .where((e) => e.location != null)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      final currentIndex = sortedEvents.indexWhere(
        (e) => e.timestamp.isAfter(_playbackDate!),
      );
      
      if (currentIndex != -1 && currentIndex + 10 < sortedEvents.length) {
        _playbackDate = sortedEvents[currentIndex + 10].timestamp;
        _updateMapMarkers();
      }
    }
  }

  double _getPlaybackProgress() {
    if (_playbackDate == null || data.events.isEmpty) return 0.0;
    
    final sortedEvents = data.events
        .where((e) => e.location != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    if (sortedEvents.isEmpty) return 0.0;
    
    final currentIndex = sortedEvents.indexWhere(
      (e) => !e.timestamp.isBefore(_playbackDate!),
    );
    
    return currentIndex / sortedEvents.length;
  }

  void _setPlaybackProgress(double value) {
    final sortedEvents = data.events
        .where((e) => e.location != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    if (sortedEvents.isNotEmpty) {
      final index = (value * sortedEvents.length).floor().clamp(0, sortedEvents.length - 1);
      _playbackDate = sortedEvents[index].timestamp;
      _updateMapMarkers();
    }
  }

  String _formatPlaybackDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateLocationClusters() async {
    final eventsWithLocation = data.events
        .where((e) => e.location != null)
        .toList();

    _locationClusters.clear();
    
    // Simple clustering by proximity
    for (final event in eventsWithLocation) {
      final locationKey = _getLocationKey(event.location!);
      
      if (!_locationClusters.containsKey(locationKey)) {
        _locationClusters[locationKey] = [];
      }
      _locationClusters[locationKey]!.add(event);
    }

    // Filter clusters by minimum size
    _locationClusters.removeWhere((key, events) => 
        events.length < _minClusterSize);
  }

  String _getLocationKey(GeoLocation location) {
    // Simple grid-based clustering
    final latGrid = (location.latitude / _clusterRadius).floor();
    final lngGrid = (location.longitude / _clusterRadius).floor();
    return '${latGrid}_${lngGrid}';
  }

  Future<void> _updateMapMarkers() async {
    _markers.clear();
    _polylines.clear();

    for (final entry in _locationClusters.entries) {
      final events = entry.value;
      if (events.isEmpty) continue;

      final centerLocation = _getClusterCenter(events);
      final marker = await _createClusterMarker(centerLocation, events);
      _markers.add(marker);

      // Create polyline connecting events in chronological order
      if (events.length > 1) {
        final sortedEvents = events
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        final coordinates = sortedEvents
            .where((e) => e.location != null)
            .map((e) => LatLng(e.location!.latitude, e.location!.longitude))
            .toList();

        if (coordinates.length > 1) {
          final polyline = Polyline(
            polylineId: PolylineId(entry.key),
            points: coordinates,
            color: Colors.blue.withOpacity(0.7),
            width: 3,
          );
          _polylines.add(polyline);
        }
      }
    }
  }

  GeoLocation _getClusterCenter(List<TimelineEvent> events) {
    double totalLat = 0;
    double totalLng = 0;
    
    for (final event in events) {
      if (event.location != null) {
        totalLat += event.location!.latitude;
        totalLng += event.location!.longitude;
      }
    }

    return GeoLocation(
      latitude: totalLat / events.length,
      longitude: totalLng / events.length,
      locationName: null,
    );
  }

  Future<Marker> _createClusterMarker(GeoLocation location, List<TimelineEvent> events) async {
    final BitmapDescriptor icon = await _getClusterMarkerIcon(events);
    
    return Marker(
      markerId: MarkerId('${location.latitude}_${location.longitude}'),
      position: LatLng(location.latitude, location.longitude),
      icon: icon,
      infoWindow: InfoWindow(
        title: '${events.length} events',
        snippet: _getClusterDescription(events),
      ),
      onTap: () => _showClusterDetails(events),
    );
  }

  Future<BitmapDescriptor> _getClusterMarkerIcon(List<TimelineEvent> events) async {
    // Different icons based on cluster size and event types
    if (events.length >= 10) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (events.length >= 5) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  String _getClusterDescription(List<TimelineEvent> events) {
    final sortedEvents = events
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final earliest = sortedEvents.first;
    final latest = sortedEvents.last;
    
    return '${_formatDate(earliest.timestamp)} - ${_formatDate(latest.timestamp)}';
  }

  void _showClusterDetails(List<TimelineEvent> events) {
    // This would need to be handled by the parent widget
    debugPrint('Show cluster details for ${events.length} events');
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Stream<Map<String, List<TimelineEvent>>> _getLocationClustersStream() {
    return Stream.value(_locationClusters);
  }

  void setState(VoidCallback fn) {
    // This would typically be called in a StatefulWidget
    // For now, we'll just trigger a rebuild
    fn();
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    await super.updateData(data);
    await _updateLocationClusters();
    await _updateMapMarkers();
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Find events near this date and navigate to their location
    final nearbyEvents = data.events
        .where((e) => e.location != null)
        .where((e) => e.timestamp.isAfter(date.subtract(const Duration(days: 1))))
        .where((e) => e.timestamp.isBefore(date.add(const Duration(days: 1))))
        .toList();

    if (nearbyEvents.isNotEmpty && _mapController != null) {
      final targetEvent = nearbyEvents.first;
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            targetEvent.location!.latitude,
            targetEvent.location!.longitude,
          ),
          12,
        ),
      );
    }

    await super.navigateToDate(date);
  }

  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation for map export
    // This would capture the current map view as an image
    return null;
  }

  @override
  void dispose() {
    _stopPlayback();
    _mapController = null;
    super.dispose();
  }
}
