import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';

/// Interactive map view for displaying timeline events with location data
class InteractiveMapView extends StatefulWidget {
  final List<TimelineEvent> events;
  final Function(TimelineEvent)? onEventTap;
  final MapController? mapController;

  const InteractiveMapView({
    super.key,
    required this.events,
    this.onEventTap,
    this.mapController,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}

class _InteractiveMapViewState extends State<InteractiveMapView> {
  late MapController _mapController;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  bool _showHeatmap = false;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _processEvents();
  }

  @override
  void didUpdateWidget(InteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _processEvents();
    }
  }

  void _processEvents() {
    _markers.clear();
    _polylines.clear();

    final eventsWithLocation = widget.events
        .where((e) => e.location != null && e.location!['latitude'] != null)
        .toList();

    // Sort events by date to create chronological polylines
    eventsWithLocation.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Create markers for each event
    for (int i = 0; i < eventsWithLocation.length; i++) {
      final event = eventsWithLocation[i];
      final lat = event.location!['latitude'] as double;
      final lng = event.location!['longitude'] as double;
      final position = LatLng(lat, lng);

      _markers.add(_createEventMarker(event, position, i));

      // Create polylines between consecutive events
      if (i > 0) {
        final prevEvent = eventsWithLocation[i - 1];
        final prevLat = prevEvent.location!['latitude'] as double;
        final prevLng = prevEvent.location!['longitude'] as double;
        final prevPosition = LatLng(prevLat, prevLng);

        _polylines.add(Polyline(
          points: [prevPosition, position],
          strokeWidth: 3.0,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ));
      }
    }

    // Fit map to show all markers
    if (_markers.isNotEmpty) {
      _fitMapToMarkers();
    }
  }

  Marker _createEventMarker(TimelineEvent event, LatLng position, int index) {
    return Marker(
      point: position,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => widget.onEventTap?.call(event),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer circle with animation
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Event number
            CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // Date label
            Positioned(
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${event.timestamp.day}/${event.timestamp.month}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(
      _markers.map((m) => m.point).toList(),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _markers.isNotEmpty
                ? _markers.first.point
                : const LatLng(40.7128, -74.0060), // Default to NYC
            initialZoom: 13,
            minZoom: 2,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.timeline_biography',
              errorTileCallback: (tile, error, stackTrace) {
                print('Error loading tile: $error');
              },
            ),
            
            // Event markers
            MarkerLayer(markers: _markers),
            
            // Polylines connecting events
            PolylineLayer(polylines: _polylines),
            
            // Heatmap overlay (if enabled)
            if (_showHeatmap)
              _buildHeatmapLayer(),
          ],
        ),
        
        // Map controls overlay
        _buildMapControls(),
        
        // Event list overlay
        _buildEventList(),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Zoom controls
          Card(
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Layer toggle
          Card(
            child: IconButton(
              icon: Icon(
                _showHeatmap ? Icons.heat_pumping : Icons.map,
              ),
              onPressed: () {
                setState(() {
                  _showHeatmap = !_showHeatmap;
                });
              },
              tooltip: _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
            ),
          ),
          const SizedBox(height: 8),
          
          // Fit to markers
          Card(
            child: IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: _fitMapToMarkers,
              tooltip: 'Fit All Events',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final eventsWithLocation = widget.events
        .where((e) => e.location != null && e.location!['latitude'] != null)
        .toList();

    if (eventsWithLocation.isEmpty) {
      return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No events with location data available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 100,
      child: Card(
        child: SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: eventsWithLocation.length,
            itemBuilder: (context, index) {
              final event = eventsWithLocation[index];
              return _buildEventCard(event, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(TimelineEvent event, int index) {
    final mediaAssets = event.assets.take(3).toList();
    
    return Container(
      width: 200,
      margin: const EdgeInsets.all(8),
      child: Card(
        child: InkWell(
          onTap: () {
            // Center map on this event
            final lat = event.location!['latitude'] as double;
            final lng = event.location!['longitude'] as double;
            _mapController.move(LatLng(lat, lng), 15);
            widget.onEventTap?.call(event);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title ?? 'Event',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (mediaAssets.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: mediaAssets.map((asset) {
                      return Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(
                              asset.cloudUrl ?? asset.localPath,
                            ),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              // Show placeholder on error
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapLayer() {
    // Simplified heatmap visualization
    // In a real implementation, use a proper heatmap library
    return MarkerLayer(
      markers: _markers.map((marker) {
        return Marker(
          point: marker.point,
          width: 100,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.red.withOpacity(0.4),
                  Colors.red.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget for displaying a single event on the map
class MapEventPopup extends StatelessWidget {
  final TimelineEvent event;
  final VoidCallback? onTap;

  const MapEventPopup({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title ?? 'Event',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              event.description ?? '',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text('View Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
