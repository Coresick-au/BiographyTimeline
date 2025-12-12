import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/core/factories/timeline_event_factory.dart';

void main() {
  group('Timezone Handling Property Tests', () {
    test('Property 2: Timezone Round-Trip Consistency - **Feature: users-timeline, Property 2: Timezone Round-Trip Consistency**', () {
      // **Validates: Requirements 1.2**
      
      final faker = Faker();
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random timestamp with timezone information
        final originalDateTime = faker.date.dateTime();
        final timezoneOffset = faker.randomGenerator.integer(24, min: -12); // -12 to +12 hours
        final timezoneString = timezoneOffset >= 0 ? '+${timezoneOffset.toString().padLeft(2, '0')}:00' : '${timezoneOffset.toString().padLeft(3, '0')}:00';
        
        // Create EXIF data with timezone information
        final exifData = ExifData(
          dateTimeOriginal: originalDateTime,
          timezone: timezoneString,
          gpsLocation: GeoLocation(
            latitude: faker.geo.latitude(),
            longitude: faker.geo.longitude(),
          ),
        );

        // Create media asset with EXIF data
        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          exifData: exifData,
          createdAt: originalDateTime,
        );

        // Create timeline event using the factory
        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
        );

        // Verify that the normalized timestamp preserves temporal meaning
        final normalizedTimestamp = exifData.normalizedTimestamp;
        expect(
          normalizedTimestamp,
          isNotNull,
          reason: 'Normalized timestamp should not be null when timezone info is available for iteration $i',
        );

        // The normalized timestamp should be in UTC
        expect(
          normalizedTimestamp!.isUtc,
          isTrue,
          reason: 'Normalized timestamp should be in UTC for iteration $i',
        );

        // Test round-trip: convert back to local time and verify it matches original intent
        // Since we're storing in UTC, we need to verify the conversion preserves the original temporal meaning
        final storedTimestamp = timelineEvent.timestamp;
        
        // The stored timestamp should be the normalized (UTC) timestamp
        expect(
          storedTimestamp,
          equals(normalizedTimestamp),
          reason: 'Stored timestamp should match normalized UTC timestamp for iteration $i',
        );

        // Verify that the original timezone information is preserved in EXIF data
        final preservedExifData = timelineEvent.assets.first.exifData;
        expect(
          preservedExifData?.timezone,
          equals(timezoneString),
          reason: 'Original timezone information should be preserved in EXIF data for iteration $i',
        );

        expect(
          preservedExifData?.dateTimeOriginal,
          equals(originalDateTime),
          reason: 'Original datetime should be preserved in EXIF data for iteration $i',
        );
      }
    });

    test('Property 2: Timezone handling without timezone information', () {
      final faker = Faker();
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate timestamp without timezone information
        final originalDateTime = faker.date.dateTime();
        
        // Create EXIF data without timezone information
        final exifData = ExifData(
          dateTimeOriginal: originalDateTime,
          timezone: null, // No timezone info
          gpsLocation: GeoLocation(
            latitude: faker.geo.latitude(),
            longitude: faker.geo.longitude(),
          ),
        );

        // Create media asset with EXIF data
        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          exifData: exifData,
          createdAt: originalDateTime,
        );

        // Create timeline event using the factory
        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
        );

        // When no timezone info is available, the original timestamp should be used
        final normalizedTimestamp = exifData.normalizedTimestamp;
        expect(
          normalizedTimestamp,
          equals(originalDateTime),
          reason: 'When no timezone info is available, original timestamp should be used for iteration $i',
        );

        // The stored timestamp should match the original
        expect(
          timelineEvent.timestamp,
          equals(originalDateTime),
          reason: 'Stored timestamp should match original when no timezone conversion is needed for iteration $i',
        );

        // Verify that timezone field remains null
        final preservedExifData = timelineEvent.assets.first.exifData;
        expect(
          preservedExifData?.timezone,
          isNull,
          reason: 'Timezone should remain null when not provided for iteration $i',
        );
      }
    });

    test('Property 2: Timezone consistency across serialization', () {
      final faker = Faker();
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate timestamp with timezone
        final originalDateTime = faker.date.dateTime();
        final timezoneOffset = faker.randomGenerator.integer(24, min: -12);
        final timezoneString = timezoneOffset >= 0 ? '+${timezoneOffset.toString().padLeft(2, '0')}:00' : '${timezoneOffset.toString().padLeft(3, '0')}:00';
        
        final exifData = ExifData(
          dateTimeOriginal: originalDateTime,
          timezone: timezoneString,
        );

        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          exifData: exifData,
          createdAt: originalDateTime,
        );

        // Test JSON serialization round-trip
        final assetJson = mediaAsset.toJson();
        final deserializedAsset = MediaAsset.fromJson(assetJson);
        
        // Verify timezone information survives serialization
        expect(
          deserializedAsset.exifData?.timezone,
          equals(timezoneString),
          reason: 'Timezone information should survive JSON serialization for iteration $i',
        );

        expect(
          deserializedAsset.exifData?.dateTimeOriginal,
          equals(originalDateTime),
          reason: 'Original datetime should survive JSON serialization for iteration $i',
        );

        // Verify normalized timestamp consistency after deserialization
        final originalNormalized = exifData.normalizedTimestamp;
        final deserializedNormalized = deserializedAsset.exifData?.normalizedTimestamp;
        
        expect(
          deserializedNormalized,
          equals(originalNormalized),
          reason: 'Normalized timestamp should be consistent after serialization round-trip for iteration $i',
        );
      }
    });

    test('Property 2: Edge case timezone handling', () {
      final faker = Faker();
      
      // Test edge case timezones
      final edgeCaseTimezones = [
        '+00:00', // UTC
        '+12:00', // Maximum positive offset
        '-12:00', // Maximum negative offset
        '+05:30', // Half-hour offset (India)
        '-09:30', // Half-hour negative offset
        '+14:00', // Extreme positive (Line Islands)
        '-11:00', // Extreme negative (American Samoa)
      ];
      
      for (int i = 0; i < edgeCaseTimezones.length * 10; i++) {
        final timezoneString = edgeCaseTimezones[i % edgeCaseTimezones.length];
        final originalDateTime = faker.date.dateTime();
        
        final exifData = ExifData(
          dateTimeOriginal: originalDateTime,
          timezone: timezoneString,
        );

        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          exifData: exifData,
          createdAt: originalDateTime,
        );

        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
        );

        // Verify that edge case timezones are handled properly
        final normalizedTimestamp = exifData.normalizedTimestamp;
        expect(
          normalizedTimestamp,
          isNotNull,
          reason: 'Edge case timezone $timezoneString should produce valid normalized timestamp for iteration $i',
        );

        expect(
          normalizedTimestamp!.isUtc,
          isTrue,
          reason: 'Normalized timestamp should be UTC for edge case timezone $timezoneString for iteration $i',
        );

        // Verify original timezone is preserved
        final preservedExifData = timelineEvent.assets.first.exifData;
        expect(
          preservedExifData?.timezone,
          equals(timezoneString),
          reason: 'Edge case timezone $timezoneString should be preserved for iteration $i',
        );
      }
    });
  });
}