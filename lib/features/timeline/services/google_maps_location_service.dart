import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../shared/models/geo_location.dart';
import 'location_service.dart';

/// Google Maps implementation of LocationService
class GoogleMapsLocationService implements LocationService {
  @override
  Future<GeoLocation?> pickLocation(
    BuildContext context, {
    GeoLocation? initialLocation,
  }) async {
    final result = await Navigator.of(context).push<GeoLocation>(
      MaterialPageRoute(
        builder: (context) => _GoogleMapsLocationPicker(
          initialLocation: initialLocation,
        ),
      ),
    );
    
    return result;
  }

  @override
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // TODO: Implement geocoding API call
    // For now, return coordinates as string
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  @override
  Future<List<LocationSearchResult>> searchLocations(String query) async {
    // TODO: Implement Places API search
    return [];
  }
}

/// Google Maps location picker widget
class _GoogleMapsLocationPicker extends StatefulWidget {
  final GeoLocation? initialLocation;

  const _GoogleMapsLocationPicker({this.initialLocation});

  @override
  State<_GoogleMapsLocationPicker> createState() =>
      _GoogleMapsLocationPickerState();
}

class _GoogleMapsLocationPickerState
    extends State<_GoogleMapsLocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _nameController.text = widget.initialLocation!.locationName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _selectedPosition ??
        const LatLng(-33.8688, 151.2093); // Sydney default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: _selectedPosition == null ? null : _confirmLocation,
            child: const Text('DONE'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap anywhere on the map to select a location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location name input
          if (_selectedPosition != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Home, Office, Park',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _onMapTapped,
              markers: _selectedPosition != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedPosition!,
                        draggable: true,
                        onDragEnd: (newPosition) {
                          setState(() => _selectedPosition = newPosition);
                        },
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // Coordinates display
          if (_selectedPosition != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  void _confirmLocation() {
    if (_selectedPosition == null) return;

    final location = GeoLocation(
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      locationName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    Navigator.of(context).pop(location);
  }
}
