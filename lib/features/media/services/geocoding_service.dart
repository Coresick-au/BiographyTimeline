import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/models/geo_location.dart';

/// Service responsible for reverse geocoding GPS coordinates to human-readable location names
class GeocodingService {
  static const String _baseUrl = 'https://api.openstreetmap.org/reverse';
  
  /// Performs reverse geocoding to get location name from coordinates
  /// Uses OpenStreetMap Nominatim API (free, no API key required)
  Future<GeoLocation?> reverseGeocode(GeoLocation location) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'format': 'json',
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'UsersTimeline/1.0.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseGeocodingResponse(location, data);
      } else {
        // Handle API errors gracefully
        return location; // Return original location without names
      }
    } catch (e) {
      // Handle network errors gracefully
      return location; // Return original location without names
    }
  }

  /// Parses the geocoding API response and creates an enhanced GeoLocation
  GeoLocation _parseGeocodingResponse(GeoLocation originalLocation, Map<String, dynamic> data) {
    try {
      final address = data['address'] as Map<String, dynamic>?;
      final displayName = data['display_name'] as String?;

      String? locationName;
      String? city;
      String? country;

      if (address != null) {
        // Extract city information (try multiple fields)
        city = address['city'] as String? ??
               address['town'] as String? ??
               address['village'] as String? ??
               address['municipality'] as String?;

        // Extract country
        country = address['country'] as String?;

        // Create a concise location name
        locationName = _createLocationName(address);
      }

      // Fall back to display name if we couldn't parse address components
      locationName ??= displayName;

      return originalLocation.copyWith(
        locationName: locationName,
        city: city,
        country: country,
      );
    } catch (e) {
      // If parsing fails, return original location
      return originalLocation;
    }
  }

  /// Creates a concise location name from address components
  String? _createLocationName(Map<String, dynamic> address) {
    // Priority order for location components
    final components = <String>[];

    // Add specific location (POI, building, etc.)
    final poi = address['amenity'] as String? ??
                address['shop'] as String? ??
                address['tourism'] as String? ??
                address['building'] as String?;
    if (poi != null) components.add(poi);

    // Add street/road
    final road = address['road'] as String? ??
                 address['pedestrian'] as String? ??
                 address['footway'] as String?;
    if (road != null) components.add(road);

    // Add neighborhood/suburb
    final neighborhood = address['neighbourhood'] as String? ??
                        address['suburb'] as String? ??
                        address['quarter'] as String?;
    if (neighborhood != null) components.add(neighborhood);

    // Add city
    final city = address['city'] as String? ??
                 address['town'] as String? ??
                 address['village'] as String?;
    if (city != null) components.add(city);

    // Return the most specific available information
    if (components.isNotEmpty) {
      return components.take(2).join(', '); // Limit to 2 components for brevity
    }

    return null;
  }

  /// Batch reverse geocoding for multiple locations
  /// Note: This implementation processes sequentially to respect API rate limits
  Future<List<GeoLocation>> batchReverseGeocode(List<GeoLocation> locations) async {
    final results = <GeoLocation>[];
    
    for (final location in locations) {
      final result = await reverseGeocode(location);
      results.add(result ?? location);
      
      // Add a small delay to respect API rate limits
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  /// Checks if a location has geocoding information
  bool hasGeocodingInfo(GeoLocation location) {
    return location.locationName != null || 
           location.city != null || 
           location.country != null;
  }
}