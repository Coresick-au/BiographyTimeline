import 'dart:math' as math;
import 'package:json_annotation/json_annotation.dart';

part 'geo_location.g.dart';

@JsonSerializable()
class GeoLocation {
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? locationName;
  final String? city;
  final String? country;
  final double? accuracy;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.locationName,
    this.city,
    this.country,
    this.accuracy,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) =>
      _$GeoLocationFromJson(json);
  Map<String, dynamic> toJson() => _$GeoLocationToJson(this);

  /// Calculate distance to another location in meters
  double distanceTo(GeoLocation other) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = latitude * (math.pi / 180);
    final double lat2Rad = other.latitude * (math.pi / 180);
    final double deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    final double deltaLngRad = (other.longitude - longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Check if this location is within a certain distance of another location
  bool isWithinDistance(GeoLocation other, double maxDistanceMeters) {
    return distanceTo(other) <= maxDistanceMeters;
  }

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    String? locationName,
    String? city,
    String? country,
    double? accuracy,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      locationName: locationName ?? this.locationName,
      city: city ?? this.city,
      country: country ?? this.country,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          altitude == other.altitude &&
          locationName == other.locationName &&
          city == other.city &&
          country == other.country &&
          accuracy == other.accuracy;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      altitude.hashCode ^
      locationName.hashCode ^
      city.hashCode ^
      country.hashCode ^
      accuracy.hashCode;

  @override
  String toString() {
    if (locationName != null) return locationName!;
    if (city != null && country != null) return '$city, $country';
    if (city != null) return city!;
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}