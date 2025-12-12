import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../services/timeline_renderer_interface.dart';

/// Renderer for Map View - animated playback with location clustering
class MapViewRenderer extends BaseTimelineRenderer {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _playbackTimer;
  DateTime? _currentPlaybackDate;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  int _currentEventIndex = 0;
  List<TimelineEvent> _locationEvents = [];

  MapViewRenderer(super.config, super.data) {
    _initializeMapData();
  }

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildControls(),
          _buildPlaybackTimeline(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _fitMapToMarkers();
      },
      initialCameraPosition: CameraPosition(
        target: _getInitialCenter(),
        zoom: 10.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildControlCard([
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayback,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: _stopPlayback,
              tooltip: 'Stop',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetPlayback,
              tooltip: 'Reset',
            ),
          ]),
          const SizedBox(height: 8),
          _buildSpeedControl(),
          const SizedBox(height: 8),
          _buildControlCard([
            IconButton(
              icon: Icon(Icons.zoom_in),
              onPressed: () => _zoomIn(),
              tooltip: 'Zoom In',
            ),
            IconButton(
              icon: Icon(Icons.zoom_out),
              onPressed: () => _zoomOut(),
              tooltip: 'Zoom Out',
            ),
            IconButton(
              icon: Icon(Icons.center_focus_strong),
              onPressed: _fitMapToMarkers,
              tooltip: 'Fit to All',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildControlCard(List<Widget> children) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              'Speed: ${_playbackSpeed}x',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: _playbackSpeed,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              onChanged: (value) {
                _playbackSpeed = value;
                _updatePlaybackSpeed();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackTimeline() {
    if (_locationEvents.isEmpty) {
      return const Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No location data available'),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timeline',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    _formatDate(_currentPlaybackDate ?? _locationEvents.first.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _currentEventIndex.toDouble(),
                min: 0,
                max: (_locationEvents.length - 1).toDouble(),
                onChanged: (value) {
                  _seekToEvent(value.toInt());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentEventIndex + 1}/${_locationEvents.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${((_currentEventIndex / _locationEvents.length) * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeMapData() {
    final filteredEvents = filterEvents(data.events);
    _locationEvents = filteredEvents.where((event) => event.location != null).toList();
    _locationEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    _createMarkers();
    _createPolylines();
    
    if (_locationEvents.isNotEmpty) {
      _currentPlaybackDate = _locationEvents.first.timestamp;
    }
  }

  void _createMarkers() {
    _markers.clear();
    
    for (int i = 0; i < _locationEvents.length; i++) {
      final event = _locationEvents[i];
      final location = event.location!;
      
      final marker = Marker(
        markerId: MarkerId(event.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: event.title ?? 'Event',
          snippet: _formatDate(event.timestamp),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == _currentEventIndex ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueBlue,
        ),
      );
      
      _markers.add(marker);
    }
  }

  void _createPolylines() {
    _polylines.clear();
    
    if (_locationEvents.length < 2) return;
    
    final points = _locationEvents.map((event) {
      final location = event.location!;
      return LatLng(location.latitude, location.longitude);
    }).toList();
    
    final polyline = Polyline(
      polylineId: const PolylineId('timeline_path'),
      points: points,
      color: Theme.of(context).colorScheme.primary,
      width: 3,
    );
    
    _polylines.add(polyline);
  }

  LatLng _getInitialCenter() {
    if (_locationEvents.isEmpty) {
      return const LatLng(37.7749, -122.4194); // San Francisco default
    }
    
    double totalLat = 0;
    double totalLng = 0;
    
    for (final event in _locationEvents) {
      final location = event.location!;
      totalLat += location.latitude;
      totalLng += location.longitude;
    }
    
    return LatLng(
      totalLat / _locationEvents.length,
      totalLng / _locationEvents.length,
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
    if (_locationEvents.isEmpty) return;
    
    _isPlaying = true;
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (1000 / _playbackSpeed).round()),
      _onPlaybackTick,
    );
  }

  void _pausePlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
  }

  void _stopPlayback() {
    _pausePlayback();
    _currentEventIndex = 0;
    _currentPlaybackDate = _locationEvents.isNotEmpty ? _locationEvents.first.timestamp : null;
    _updateMarkers();
  }

  void _resetPlayback() {
    _stopPlayback();
    _seekToEvent(0);
  }

  void _onPlaybackTick(Timer timer) {
    if (_currentEventIndex < _locationEvents.length - 1) {
      _currentEventIndex++;
      _currentPlaybackDate = _locationEvents[_currentEventIndex].timestamp;
      _updateMarkers();
      _animateToCurrentEvent();
    } else {
      _pausePlayback();
    }
  }

  void _seekToEvent(int index) {
    if (index < 0 || index >= _locationEvents.length) return;
    
    _currentEventIndex = index;
    _currentPlaybackDate = _locationEvents[index].timestamp;
    _updateMarkers();
    _animateToCurrentEvent();
  }

  void _updateMarkers() {
    _createMarkers();
  }

  void _animateToCurrentEvent() {
    if (_currentEventIndex >= _locationEvents.length) return;
    
    final event = _locationEvents[_currentEventIndex];
    final location = event.location!;
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        12.0,
      ),
    );
  }

  void _updatePlaybackSpeed() {
    if (_isPlaying) {
      _pausePlayback();
      _startPlayback();
    }
  }

  Future<void> _fitMapToMarkers() async {
    if (_markers.isEmpty) return;
    
    final bounds = _calculateBounds();
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds() {
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;
    
    for (final marker in _markers) {
      final pos = marker.position;
      minLat = math.min(minLat, pos.latitude);
      maxLat = math.max(maxLat, pos.latitude);
      minLng = math.min(minLng, pos.longitude);
      maxLng = math.max(maxLng, pos.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _zoomIn() async {
    await _mapController?.animateCamera(
      CameraUpdate.zoomIn(),
    );
  }

  Future<void> _zoomOut() async {
    await _mapController?.animateCamera(
      CameraUpdate.zoomOut(),
    );
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    final closestEvent = _locationEvents.reduce((a, b) {
      final aDiff = (a.timestamp.difference(date).inMilliseconds).abs();
      final bDiff = (b.timestamp.difference(date).inMilliseconds).abs();
      return aDiff < bDiff ? a : b;
    });
    
    _seekToEvent(_locationEvents.indexOf(closestEvent));
  }

  @override
  Future<void> navigateToEvent(String eventId) async {
    final eventIndex = _locationEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex != -1) {
      _seekToEvent(eventIndex);
    }
  }

  @override
  List<TimelineEvent> getVisibleEvents() {
    if (_currentEventIndex < _locationEvents.length) {
      return [_locationEvents[_currentEventIndex]];
    }
    return [];
  }

  @override
  DateTimeRange? getVisibleDateRange() {
    if (_currentPlaybackDate == null) return null;
    
    return DateTimeRange(
      start: _currentPlaybackDate!,
      end: _currentPlaybackDate!,
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _mapController = null;
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

