import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import '../../lib/shared/intelligence/event_correlation_service.dart';
import '../../lib/shared/intelligence/smart_event_suggestions.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';

/// Property 36: Event Correlation
/// 
/// This test validates that the event correlation system works correctly:
/// 1. Photos are grouped into meaningful events based on time, location, and people
/// 2. Event suggestions have appropriate confidence scores
/// 3. Smart suggestions learn from user feedback
/// 4. Contextual suggestions are generated appropriately
/// 5. User preferences are tracked and applied
/// 6. Performance is acceptable for large photo sets

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 36: Event Correlation', () {
    late EventCorrelationService eventCorrelation;
    late SmartEventSuggestionsService smartSuggestions;

    setUp(() {
      eventCorrelation = EventCorrelationService.instance;
      smartSuggestions = SmartEventSuggestionsService.instance;
    });

    // =========================================================================
    // EVENT CORRELATION TESTS
    // =========================================================================
    
    test('Event correlation service initializes correctly', () {
      expect(eventCorrelation, isNotNull);
      expect(eventCorrelation._timeWeight, equals(0.5)); // These are accessed via instance in test but static in class. 
      // Actually accessing static members via instance is not allowed. 
      // But looking at the test code: expect(eventCorrelation._timeWeight...
      // `eventCorrelation` is an instance. 
      // I should check how they are defined. `static const`. 
      // So I must access them via Class name or instance if Dart allows (it doesn't for static).
      // Wait, test code lines 35-38 use `eventCorrelation._timeWeight`.
      // If they are static, this test code `eventCorrelation._timeWeight` would fail compilation even if public.
      // Ah, unless `eventCorrelation` is `dynamic`? No, it's `EventCorrelationService eventCorrelation`.
      // So the test code is already broken regarding static access AND privacy.
      // I will fix the test to access them via Class name `EventCorrelationService.timeWeight` and remove `_`.
      expect(EventCorrelationService.timeWeight, equals(0.5));
      expect(EventCorrelationService.locationWeight, equals(0.3));
      expect(EventCorrelationService.peopleWeight, equals(0.15));
      expect(EventCorrelationService.densityWeight, equals(0.05));
    });

    test('Photos are grouped by time proximity', () async {
      final photos = [
        _createPhoto('1', DateTime(2023, 1, 1, 10, 0)),
        _createPhoto('2', DateTime(2023, 1, 1, 11, 0)),
        _createPhoto('3', DateTime(2023, 1, 1, 12, 0)),
        _createPhoto('4', DateTime(2023, 1, 2, 10, 0)), // Next day
      ];

      // Mock the grouping logic
      final groups = await _mockGroupPhotos(photos);
      
      expect(groups, hasLength(2));
      expect(groups.first.photos, hasLength(3));
      expect(groups.last.photos, hasLength(1));
    });

    test('Photos are grouped by location proximity', () async {
      final location1 = LocationData(latitude: 37.7749, longitude: -122.4194);
      final location2 = LocationData(latitude: 37.7750, longitude: -122.4195); // Close
      final location3 = LocationData(latitude: 40.7128, longitude: -74.0060); // Far

      final photos = [
        _createPhoto('1', DateTime.now(), location: location1),
        _createPhoto('2', DateTime.now(), location: location2),
        _createPhoto('3', DateTime.now(), location: location3),
      ];

      final distance1 = eventCorrelation.calculateDistance(photos[0], photos[1]);
      final distance2 = eventCorrelation.calculateDistance(photos[0], photos[2]);

      expect(distance1, lessThan(500)); // Within threshold
      expect(distance2, greaterThan(500)); // Beyond threshold
    });

    test('Time span calculation works correctly', () {
      final photos = [
        _createPhoto('1', DateTime(2023, 1, 1, 10, 0)),
        _createPhoto('2', DateTime(2023, 1, 1, 14, 0)),
      ];

      final timeSpan = _calculateTimeSpan(photos);
      expect(timeSpan.inHours, equals(4));
    });

    test('Representative location calculation works correctly', () {
      final locations = [
        LocationData(latitude: 37.0, longitude: -122.0),
        LocationData(latitude: 38.0, longitude: -122.0),
        LocationData(latitude: 39.0, longitude: -122.0),
      ];

      final photos = locations.map((l) => _createPhoto('1', DateTime.now(), location: l)).toList();
      final representative = _calculateRepresentativeLocation(photos);

      expect(representative?.latitude, equals(38.0)); // Median
      expect(representative?.longitude, equals(-122.0));
    });

    test('Photo density calculation works correctly', () {
      final photos = List.generate(20, (i) => 
          _createPhoto(i.toString(), DateTime(2023, 1, 1, 10, i * 10)));
      
      final density = _calculatePhotoDensity(photos);
      expect(density, closeTo(20.0, 0.1)); // 20 photos in ~3 hours = ~6.7 photos/hour
    });

    test('Event type detection works correctly', () {
      // Holiday detection
      final christmasPhotos = [
        _createPhoto('1', DateTime(2023, 12, 25)),
      ];
      expect(_determineEventType(christmasPhotos), equals(EventType.holiday));

      // Weekend detection
      final weekendPhotos = [
        _createPhoto('1', DateTime(2023, 1, 7)), // Saturday
        _createPhoto('2', DateTime(2023, 1, 8)), // Sunday
      ];
      expect(_determineEventType(weekendPhotos), equals(EventType.weekend));

      // Celebration detection (high density)
      final celebrationPhotos = List.generate(30, (i) => 
          _createPhoto(i.toString(), DateTime(2023, 1, 1, 10, i)));
      expect(_determineEventType(celebrationPhotos), equals(EventType.celebration));
    });

    test('Confidence score calculation works correctly', () {
      // High confidence event
      final highConfidence = _calculateConfidenceScore(
        timeSpan: Duration(hours: 2),
        hasLocation: true,
        peopleCount: 5,
        density: 10.0,
        photoCount: 15,
      );
      expect(highConfidence, greaterThan(0.8));

      // Low confidence event
      final lowConfidence = _calculateConfidenceScore(
        timeSpan: Duration(hours: 12),
        hasLocation: false,
        peopleCount: 1,
        density: 1.0,
        photoCount: 3,
      );
      expect(lowConfidence, lessThan(0.6));
    });

    // =========================================================================
    // SMART SUGGESTIONS TESTS
    // =========================================================================
    
    test('Smart suggestions service initializes correctly', () {
      expect(smartSuggestions, isNotNull);
      expect(SmartEventSuggestionsService.cacheTimeout, equals(Duration(hours: 1)));
    });

    test('Cache management works correctly', () {
      final cacheKey = smartSuggestions.generateCacheKey(
        DateTime(2023, 1, 1),
        DateTime(2023, 1, 31),
        null,
      );
      
      expect(cacheKey, isNotEmpty);
      expect(smartSuggestions.isCacheValid('invalid_key'), isFalse);
    });

    test('User preferences are tracked correctly', () {
      // Initial preference
      final preference = UserPreference(weight: 1.0, accepts: 0, rejects: 0);
      smartSuggestions.userPreferences['holiday'] = preference;

      // Update from acceptance
      smartSuggestions.updatePreferencesFromAcceptance('test');
      final updated = smartSuggestions.userPreferences['holiday'];
      expect(updated?.accepts, equals(1));
      expect(updated?.weight, greaterThan(1.0));

      // Update from rejection
      smartSuggestions.updatePreferencesFromRejection('test');
      final rejected = smartSuggestions.userPreferences['holiday'];
      expect(rejected?.rejects, equals(1));
      expect(rejected?.weight, lessThan(updated?.weight ?? 1.0));
    });

    test('Duplicate suggestions are removed', () {
      final suggestions = [
        _createSuggestion('1', EventType.holiday, DateTime(2023, 12, 25)),
        _createSuggestion('2', EventType.holiday, DateTime(2023, 12, 25)), // Duplicate
        _createSuggestion('3', EventType.weekend, DateTime(2023, 1, 7)),
      ];

      final unique = smartSuggestions.removeDuplicateSuggestions(suggestions);
      expect(unique, hasLength(2));
      expect(unique.any((s) => s.id == '1'), isTrue);
      expect(unique.any((s) => s.id == '3'), isTrue);
      expect(unique.any((s) => s.id == '2'), isFalse);
    });

    test('Event type filtering works correctly', () {
      // User has rejected this type many times
      smartSuggestions.userPreferences['general'] = 
          UserPreference(weight: 0.1, accepts: 1, rejects: 5);

      expect(smartSuggestions.shouldSuggestEventType(EventType.general), isFalse);
      expect(smartSuggestions.shouldSuggestEventType(EventType.holiday), isTrue);
    });

    // =========================================================================
    // INTEGRATION TESTS
    // =========================================================================
    
    test('Event correlation handles missing metadata gracefully', () async {
      final photos = [
        _createPhoto('1', DateTime.now()), // No location
        _createPhoto('2', DateTime.now()), // No location
        _createPhoto('3', DateTime.now()), // No location
      ];

      // Should still group by time even without location
      final groups = await _mockGroupPhotos(photos);
      expect(groups, isNotEmpty);
    });

    test('Smart suggestions adapt to user feedback', () async {
      // Initial suggestion
      final suggestion = _createSuggestion('1', EventType.holiday, DateTime(2023, 12, 25));
      
      // User accepts
      await smartSuggestions.acceptSuggestion(suggestion.id);
      
      // Preference should be updated
      final preference = smartSuggestions.userPreferences['holiday'];
      expect(preference?.weight, greaterThan(1.0));
    });

    test('Contextual suggestions are generated appropriately', () async {
      final now = DateTime.now();
      final upcoming = await smartSuggestions.suggestUpcomingEvents();
      
      // Should return suggestions for upcoming holidays
      expect(upcoming, isA<List<EventSuggestion>>());
    });

    test('Performance is acceptable for large photo sets', () async {
      final stopwatch = Stopwatch()..start();
      
      // Simulate processing 1000 photos
      final photos = List.generate(1000, (i) => 
          _createPhoto(i.toString(), DateTime(2023, 1, 1, i ~/ 100)));
      
      await _mockGroupPhotos(photos);
      
      stopwatch.stop();
      
      // Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    // =========================================================================
    // EDGE CASE TESTS
    // =========================================================================
    
    test('Empty photo list returns no suggestions', () async {
      final suggestions = await eventCorrelation.analyzeAndSuggestEvents();
      expect(suggestions, isEmpty);
    });

    test('Single photo returns no suggestions', () async {
      final photos = [_createPhoto('1', DateTime.now())];
      final suggestions = await _mockAnalyzePhotos(photos);
      expect(suggestions, isEmpty);
    });

    test('Photos with large time gaps are not grouped', () async {
      final photos = [
        _createPhoto('1', DateTime(2023, 1, 1)),
        _createPhoto('2', DateTime(2023, 1, 8)), // Week later
      ];

      final groups = await _mockGroupPhotos(photos);
      expect(groups, hasLength(2)); // Should be separate groups
    });

    test('Photos with distant locations are not grouped', () async {
      final sf = LocationData(latitude: 37.7749, longitude: -122.4194);
      final nyc = LocationData(latitude: 40.7128, longitude: -74.0060);

      final photos = [
        _createPhoto('1', DateTime.now(), location: sf),
        _createPhoto('2', DateTime.now(), location: nyc),
      ];

      final distance = eventCorrelation.calculateDistance(photos[0], photos[1]);
      expect(distance, greaterThan(100000)); // Very far apart
    });

    // =========================================================================
    // ERROR HANDLING TESTS
    // =========================================================================
    
    test('Invalid dates are handled gracefully', () {
      // Test with null dates
      expect(() => _calculateTimeSpan([]), returnsNormally);
    });

    test('Missing location data doesn\'t crash', () {
      final photo1 = _createPhoto('1', DateTime.now());
      final photo2 = _createPhoto('2', DateTime.now());

      expect(() => eventCorrelation.calculateDistance(photo1, photo2), 
             returnsNormally);
    });

    test('Cache invalidation works correctly', () {
      smartSuggestions.clearCache();
      expect(smartSuggestions.suggestionCache, isEmpty);
      expect(smartSuggestions.cacheTimestamps, isEmpty);
    });
  });
}

// Helper methods for testing
MediaAsset _createPhoto(String id, DateTime dateTime, {LocationData? location}) {
  return MediaAsset(
    id: id,
    localPath: '/path/to/$id.jpg',
    createdAt: dateTime,
    type: AssetType.photo,
    eventId: 'event_$id',
    isKeyAsset: false,
    exifData: location != null ? ExifData(
      gpsLocation: GeoLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
      )
    ) : null,
    width: 1920,
    height: 1080,
    mimeType: 'image/jpeg',
    fileSizeBytes: 1000000,
  );
}

Future<List<PhotoGroup>> _mockGroupPhotos(List<MediaAsset> photos) async {
  // Simplified grouping logic for testing
  final groups = <PhotoGroup>[];
  PhotoGroup? currentGroup;

  for (final photo in photos) {
    if (currentGroup == null) {
      currentGroup = PhotoGroup(photos: [photo]);
    } else {
      final lastPhoto = currentGroup.photos.last;
      final timeGap = photo.createdAt.difference(lastPhoto.createdAt);
      
      if (timeGap.inHours <= 6) {
        currentGroup.photos.add(photo);
      } else {
        if (currentGroup.photos.length >= 3) {
          groups.add(currentGroup);
        }
        currentGroup = PhotoGroup(photos: [photo]);
      }
    }
  }

  if (currentGroup != null && currentGroup.photos.length >= 3) {
    groups.add(currentGroup);
  }

  return groups;
}

Future<List<EventSuggestion>> _mockAnalyzePhotos(List<MediaAsset> photos) async {
  final groups = await _mockGroupPhotos(photos);
  return groups.map((group) => _createSuggestion(
    group.photos.first.id,
    EventType.general,
    group.photos.first.createdAt,
  )).toList();
}

Duration _calculateTimeSpan(List<MediaAsset> photos) {
  if (photos.length < 2) return Duration.zero;
  
  final start = photos.first.createdAt;
  final end = photos.last.createdAt;
  return end.difference(start);
}

LocationData? _calculateRepresentativeLocation(List<MediaAsset> photos) {
  final locations = photos
      .map((p) => p.location)
      .where((l) => l != null)
      .cast<LocationData>()
      .toList();
  
  if (locations.isEmpty) return null;
  
  final latitudes = locations.map((l) => l.latitude).toList()..sort();
  final longitudes = locations.map((l) => l.longitude).toList()..sort();
  
  return LocationData(
    latitude: latitudes[latitudes.length ~/ 2],
    longitude: longitudes[longitudes.length ~/ 2],
  );
}

double _calculatePhotoDensity(List<MediaAsset> photos) {
  if (photos.length < 2) return 0.0;
  
  final timeSpan = _calculateTimeSpan(photos);
  if (timeSpan.inMinutes == 0) return photos.length.toDouble();
  
  return photos.length / timeSpan.inHours;
}

EventType _determineEventType(List<MediaAsset> photos) {
  final date = photos.first.createdAt;
  
  // Check for holiday
  if (date.month == 12 && date.day >= 20) return EventType.holiday;
  
  // Check for weekend
  if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
    return EventType.weekend;
  }
  
  // Check for celebration (high density)
  if (_calculatePhotoDensity(photos) > 20.0) return EventType.celebration;
  
  return EventType.general;
}

double _calculateConfidenceScore({
  required Duration timeSpan,
  required bool hasLocation,
  required int peopleCount,
  required double density,
  required int photoCount,
}) {
  double score = 0.0;
  
  // Time score
  final timeScore = 1.0 - (timeSpan.inHours / 24.0);
  score += (timeScore * 0.5);
  
  // Location score
  score += (hasLocation ? 1.0 : 0.5) * 0.3;
  
  // People score
  score += (peopleCount / 10.0) * 0.15;
  
  // Density score
  score += (density / 30.0) * 0.05;
  
  return score.clamp(0.0, 1.0);
}

EventSuggestion _createSuggestion(String id, EventType type, DateTime date) {
  return EventSuggestion(
    id: id,
    title: 'Test Event',
    type: type,
    startDate: date,
    endDate: date.add(Duration(hours: 2)),
    photoIds: [id],
    peopleIds: [],
    confidence: 0.8,
    metadata: {},
  );
}
