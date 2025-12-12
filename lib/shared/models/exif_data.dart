import 'package:json_annotation/json_annotation.dart';
import 'geo_location.dart';

part 'exif_data.g.dart';

@JsonSerializable()
class ExifData {
  final DateTime? dateTimeOriginal;
  final GeoLocation? gpsLocation;
  final String? timezone;
  final String? cameraMake;
  final String? cameraModel;
  final double? focalLength;
  final double? aperture;
  final String? iso;
  final double? shutterSpeed;
  final int? orientation;
  final Map<String, dynamic>? rawExifData;

  const ExifData({
    this.dateTimeOriginal,
    this.gpsLocation,
    this.timezone,
    this.cameraMake,
    this.cameraModel,
    this.focalLength,
    this.aperture,
    this.iso,
    this.shutterSpeed,
    this.orientation,
    this.rawExifData,
  });

  factory ExifData.fromJson(Map<String, dynamic> json) =>
      _$ExifDataFromJson(json);
  Map<String, dynamic> toJson() => _$ExifDataToJson(this);

  /// Gets the normalized UTC timestamp for storage
  DateTime? get normalizedTimestamp {
    if (dateTimeOriginal == null) return null;
    
    // If we have timezone information, convert to UTC
    if (timezone != null) {
      // This is a simplified approach - in a real implementation,
      // you'd use a proper timezone library like timezone package
      return dateTimeOriginal!.toUtc();
    }
    
    // If no timezone info, assume the timestamp is already in the correct timezone
    return dateTimeOriginal;
  }

  /// Checks if this EXIF data has complete location information
  bool get hasCompleteLocationData {
    return gpsLocation != null && 
           gpsLocation!.latitude != 0 && 
           gpsLocation!.longitude != 0;
  }

  /// Checks if this EXIF data has complete timestamp information
  bool get hasCompleteTimestampData {
    return dateTimeOriginal != null;
  }

  /// Checks if this EXIF data is considered complete for timeline purposes
  bool get isComplete {
    return hasCompleteTimestampData;
  }

  ExifData copyWith({
    DateTime? dateTimeOriginal,
    GeoLocation? gpsLocation,
    String? timezone,
    String? cameraMake,
    String? cameraModel,
    double? focalLength,
    double? aperture,
    String? iso,
    double? shutterSpeed,
    int? orientation,
    Map<String, dynamic>? rawExifData,
  }) {
    return ExifData(
      dateTimeOriginal: dateTimeOriginal ?? this.dateTimeOriginal,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      timezone: timezone ?? this.timezone,
      cameraMake: cameraMake ?? this.cameraMake,
      cameraModel: cameraModel ?? this.cameraModel,
      focalLength: focalLength ?? this.focalLength,
      aperture: aperture ?? this.aperture,
      iso: iso ?? this.iso,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      orientation: orientation ?? this.orientation,
      rawExifData: rawExifData ?? this.rawExifData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExifData &&
          runtimeType == other.runtimeType &&
          dateTimeOriginal == other.dateTimeOriginal &&
          gpsLocation == other.gpsLocation &&
          timezone == other.timezone &&
          cameraMake == other.cameraMake &&
          cameraModel == other.cameraModel &&
          focalLength == other.focalLength &&
          aperture == other.aperture &&
          iso == other.iso &&
          shutterSpeed == other.shutterSpeed &&
          orientation == other.orientation &&
          _mapEquals(rawExifData, other.rawExifData);

  @override
  int get hashCode =>
      dateTimeOriginal.hashCode ^
      gpsLocation.hashCode ^
      timezone.hashCode ^
      cameraMake.hashCode ^
      cameraModel.hashCode ^
      focalLength.hashCode ^
      aperture.hashCode ^
      iso.hashCode ^
      shutterSpeed.hashCode ^
      orientation.hashCode ^
      rawExifData.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}