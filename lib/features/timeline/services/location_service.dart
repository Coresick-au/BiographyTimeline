import 'package:flutter/material.dart';
import '../../../shared/models/geo_location.dart';

/// Abstract interface for location services
/// Allows easy switching between Google Maps, OpenStreetMap, etc.
abstract class LocationService {
  /// Pick a location using the map interface
  Future<GeoLocation?> pickLocation(BuildContext context, {GeoLocation? initialLocation});
  
  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude);
  
  /// Search for locations by query
  Future<List<LocationSearchResult>> searchLocations(String query);
}

/// Result from location search
class LocationSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const LocationSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  
  GeoLocation toGeoLocation() {
    return GeoLocation(
      latitude: latitude,
      longitude: longitude,
      locationName: name,
    );
  }
}
