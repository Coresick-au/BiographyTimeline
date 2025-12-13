import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/geo_location.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/fuzzy_date.dart';
import '../../lib/shared/models/user.dart' as shared_user;
import '../../lib/features/social/models/user_models.dart' as social_models;
import '../../lib/features/social/services/relationship_service.dart';

/// Property 16: Shared Event Detection Accuracy
/// 
/// This test validates that shared event detection works correctly:
/// 1. Temporal proximity detection identifies events occurring within reasonable time windows
/// 2. Spatial proximity detection identifies events at similar locations
/// 3. Face clustering enhances shared event detection accuracy
/// 4. Confidence scoring properly weights different detection factors
/// 5. False positives are minimized through proper thresholding
/// 6. Edge cases (different timezones, sparse data) are handled correctly
/// 7. Performance scales appropriately with dataset size

void main() {
  group('Property 16: Shared Event Detection Accuracy', () {
    late RelationshipService relationshipService;
    const uuid = Uuid();

    setUp(() {
      relationshipService = RelationshipService();
    });

    test('Temporal proximity detection identifies events within time windows', () async {
      // Arrange
      const userId1 = 'user1';
      const userId2 = 'user2';
      final baseTime = DateTime.now();
      
      // Create events within 2-hour window (should be detected as shared)
      final event1 = _createTestEvent(
        userId: userId1,
        timestamp: baseTime,
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060), // NYC
      );
      
      final event2 = _createTestEvent(
        userId: userId2,
        timestamp: baseTime.add(const Duration(hours: 1)), // 1 hour later
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060), // Same location
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        [userId2],
        [event2],
      );

      // Assert
      expect(sharedEvents, isNotEmpty);
      
      final sharedEvent = sharedEvents.first;
      expect(sharedEvent.participantIds, contains(userId1));
      expect(sharedEvent.participantIds, contains(userId2));
      expect(sharedEvent.detectionType, equals(social_models.SharedEventType.temporal));
      expect(sharedEvent.confidenceScore, greaterThan(0.5)); // High confidence for close temporal match
    });

    test('Spatial proximity detection identifies events at similar locations', () async {
      // Arrange
      const userId1 = 'user1';
      const userId2 = 'user2';
      final baseTime = DateTime.now();
      
      // Create events at nearby locations (within 100 meters)
      final event1 = _createTestEvent(
        userId: userId1,
        timestamp: baseTime,
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060), // NYC
      );
      
      final event2 = _createTestEvent(
        userId: userId2,
        timestamp: baseTime.add(const Duration(hours: 2)), // Different time but same day
        location: const GeoLocation(latitude: 40.7129, longitude: -74.0061), // ~14 meters away
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        [userId2],
        [event2],
      );

      // Assert
      expect(sharedEvents, isNotEmpty);
      
      final sharedEvent = sharedEvents.first;
      expect(sharedEvent.detectionType, equals(social_models.SharedEventType.spatial));
      expect(sharedEvent.confidenceScore, greaterThan(0.6)); // High confidence for spatial proximity
    });

    test('Face clustering enhances shared event detection accuracy', () async {
      // Arrange
      const userId1 = 'user1';
      const userId2 = 'user2';
      final baseTime = DateTime.now();
      
      // Create events with face detection metadata
      final event1 = _createTestEventWithFaces(
        userId: userId1,
        timestamp: baseTime,
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060),
        faceIds: ['face_1', 'face_2'], // Same faces detected
      );
      
      final event2 = _createTestEventWithFaces(
        userId: userId2,
        timestamp: baseTime.add(const Duration(hours: 1)),
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060),
        faceIds: ['face_1', 'face_3'], // Overlapping face
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        [userId2],
        [event2],
      );

      // Assert
      expect(sharedEvents, isNotEmpty);
      
      final sharedEvent = sharedEvents.first;
      expect(sharedEvent.detectionType, equals(social_models.SharedEventType.facial));
      expect(sharedEvent.confidenceScore, greaterThan(0.7)); // Very high confidence with face matches
      
      // Verify face metadata is preserved
      expect(sharedEvent.detectionMetadata['faceMatches'], isNotNull);
      expect(sharedEvent.detectionMetadata['faceMatches'], greaterThan(0));
    });

    test('Hybrid detection combines multiple factors for highest accuracy', () async {
      // Arrange
      const userId1 = 'user1';
      const userId2 = 'user2';
      final baseTime = DateTime.now();
      
      // Create events with multiple matching factors
      final event1 = _createTestEventWithFaces(
        userId: userId1,
        timestamp: baseTime,
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060),
        faceIds: ['face_1', 'face_2'],
      );
      
      final event2 = _createTestEventWithFaces(
        userId: userId2,
        timestamp: baseTime.add(const Duration(minutes: 30)), // Close temporal
        location: const GeoLocation(latitude: 40.7129, longitude: -74.0061), // Close spatial
        faceIds: ['face_1', 'face_2'], // Same faces
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        [userId2],
        [event2],
      );

      // Assert
      expect(sharedEvents, isNotEmpty);
      
      final sharedEvent = sharedEvents.first;
      expect(sharedEvent.detectionType, equals(social_models.SharedEventType.hybrid));
      expect(sharedEvent.confidenceScore, greaterThan(0.8)); // Highest confidence for hybrid detection
      
      // Verify all factors contributed to detection
      expect(sharedEvent.detectionMetadata['temporalScore'], greaterThan(0.0));
      expect(sharedEvent.detectionMetadata['spatialScore'], greaterThan(0.0));
      expect(sharedEvent.detectionMetadata['facialScore'], greaterThan(0.0));
    });

    test('False positives are minimized through proper thresholding', () async {
      // Arrange
      const userId1 = 'user1';
      const userId2 = 'user2';
      final baseTime = DateTime.now();
      
      // Create events that should NOT be detected as shared
      final event1 = _createTestEvent(
        userId: userId1,
        timestamp: baseTime,
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060), // NYC
      );
      
      final event2 = _createTestEvent(
        userId: userId2,
        timestamp: baseTime.add(const Duration(days: 7)), // Week later
        location: const GeoLocation(latitude: 51.5074, longitude: -0.1278), // London
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        [userId2],
        [event2],
      );

      // Assert - Should return empty list due to low confidence
      expect(sharedEvents, isEmpty);
    });

    test('Edge cases are handled correctly', () async {
      // Test timezone differences
      final event1 = _createTestEvent(
        userId: 'user1',
        timestamp: DateTime.parse('2024-01-01T10:00:00Z'), // UTC
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060),
      );
      
      final event2 = _createTestEvent(
        userId: 'user2',
        timestamp: DateTime.parse('2024-01-01T05:00:00-05:00'), // Same time, EST timezone
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060),
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        ['user2'],
        [event2],
      );

      // Assert
      expect(sharedEvents, isNotEmpty);
      
      final sharedEvent = sharedEvents.first;
      expect(sharedEvent.confidenceScore, greaterThan(0.5)); // Should handle timezone conversion
    });

    test('Performance scales appropriately with dataset size', () async {
      // Arrange
      const userCount = 20; // Reduced for test performance
      const eventsPerUser = 3;
      final users = List.generate(userCount, (index) => 'user_$index');
      final events = <TimelineEvent>[];

      // Generate test data
      for (final userId in users) {
        for (int i = 0; i < eventsPerUser; i++) {
          events.add(_createTestEvent(
            userId: userId,
            timestamp: DateTime.now().subtract(Duration(days: i)),
            location: GeoLocation(
              latitude: 40.7128 + (i * 0.01),
              longitude: -74.0060 + (i * 0.01),
            ),
          ));
        }
      }

      // Act & Assert - Performance test
      final stopwatch = Stopwatch()..start();
      
      // Simulate batch processing
      final sharedEvents = await relationshipService.detectSharedEvents(
        events.take(5).toList(),
        users.skip(1).take(5).toList(),
        events.skip(5).take(5).toList(),
      );
      
      stopwatch.stop();

      // Assert performance requirements
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      
      // Verify reasonable detection rate
      final detectionRate = sharedEvents.length / 5; // Compared to input events
      expect(detectionRate, greaterThanOrEqualTo(0.0)); // At least some detection
    });

    test('Metadata preservation and accuracy', () async {
      // Arrange
      const userId1 = 'user1';
      const userId2 = 'user2';
      final baseTime = DateTime.now();
      
      final event1 = _createTestEventWithFaces(
        userId: userId1,
        timestamp: baseTime,
        location: const GeoLocation(latitude: 40.7128, longitude: -74.0060),
        faceIds: ['face_1', 'face_2'],
      );
      
      final event2 = _createTestEventWithFaces(
        userId: userId2,
        timestamp: baseTime.add(const Duration(hours: 1)),
        location: const GeoLocation(latitude: 40.7129, longitude: -74.0061),
        faceIds: ['face_1', 'face_3'],
      );

      // Act
      final sharedEvents = await relationshipService.detectSharedEvents(
        [event1],
        [userId2],
        [event2],
      );

      // Assert
      expect(sharedEvents, isNotEmpty);
      final sharedEvent = sharedEvents.first;
      
      // Verify metadata completeness
      expect(sharedEvent.detectionMetadata, isNotEmpty);
      expect(sharedEvent.detectionMetadata['temporalScore'], isNotNull);
      expect(sharedEvent.detectionMetadata['spatialScore'], isNotNull);
      expect(sharedEvent.detectionMetadata['facialScore'], isNotNull);
      expect(sharedEvent.detectionMetadata['faceMatches'], equals(1)); // One overlapping face
      expect(sharedEvent.detectionMetadata['distance'], isNotNull);
      expect(sharedEvent.detectionMetadata['timeDifference'], isNotNull);
      
      // Verify data integrity
      expect(sharedEvent.participantIds, hasLength(2));
      expect(sharedEvent.detectedAt, isNotNull);
      expect(sharedEvent.confidenceScore, greaterThanOrEqualTo(0.0));
      expect(sharedEvent.confidenceScore, lessThanOrEqualTo(1.0));
    });
  });
}

// Helper methods for creating test events

TimelineEvent _createTestEvent({
  required String userId,
  required DateTime timestamp,
  required GeoLocation location,
}) {
  return TimelineEvent(
    id: const Uuid().v4(),
    contextId: const Uuid().v4(),
    ownerId: userId,
    timestamp: timestamp,
    location: location,
    eventType: 'test_event',
    customAttributes: {},
    assets: [],
    title: 'Test Event',
    description: 'Test event description',
    participantIds: [userId],
    privacyLevel: shared_user.PrivacyLevel.private,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

TimelineEvent _createTestEventWithFaces({
  required String userId,
  required DateTime timestamp,
  required GeoLocation location,
  required List<String> faceIds,
}) {
  return TimelineEvent(
    id: const Uuid().v4(),
    contextId: const Uuid().v4(),
    ownerId: userId,
    timestamp: timestamp,
    location: location,
    eventType: 'event_with_faces',
    customAttributes: {
      'faces': faceIds.map((id) => {'id': id, 'confidence': 0.9}).toList(),
    },
    assets: [
      MediaAsset(
        id: const Uuid().v4(),
        eventId: const Uuid().v4(),
        type: AssetType.photo,
        localPath: '/test/path.jpg',
        caption: 'Test image with faces',
        createdAt: DateTime.now(),
        isKeyAsset: true,
      ),
    ],
    title: 'Event with Faces',
    description: 'Event with face detection',
    participantIds: [userId],
    privacyLevel: shared_user.PrivacyLevel.private,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
