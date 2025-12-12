import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/shared/models/exif_data.dart';
import '../../lib/shared/models/geo_location.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/user.dart';
import '../../lib/core/factories/timeline_event_factory.dart';

void main() {
  group('Data Model Integrity Property Tests', () {
    test('Property 5: Caption Preservation Integrity - **Feature: users-timeline, Property 5: Caption Preservation Integrity**', () {
      // **Validates: Requirements 1.5**
      
      final faker = Faker();
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random image with caption
        final originalCaption = faker.lorem.sentence();
        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          caption: originalCaption,
          createdAt: faker.date.dateTime(),
          exifData: ExifData(
            dateTimeOriginal: faker.date.dateTime(),
            gpsLocation: GeoLocation(
              latitude: faker.geo.latitude(),
              longitude: faker.geo.longitude(),
            ),
          ),
        );

        // Create timeline event with the media asset
        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
          title: faker.lorem.words(3).join(' '),
        );

        // Verify that the caption is preserved in the media asset
        final preservedAsset = timelineEvent.assets.first;
        expect(
          preservedAsset.caption,
          equals(originalCaption),
          reason: 'Caption should be preserved exactly as imported for iteration $i',
        );

        // Verify that the caption is not null or empty when it was originally provided
        expect(
          preservedAsset.caption,
          isNotNull,
          reason: 'Caption should not be null when originally provided for iteration $i',
        );
        
        expect(
          preservedAsset.caption!.isNotEmpty,
          isTrue,
          reason: 'Caption should not be empty when originally provided for iteration $i',
        );

        // Test serialization round-trip to ensure caption survives JSON conversion
        final assetJson = preservedAsset.toJson();
        final deserializedAsset = MediaAsset.fromJson(assetJson);
        
        expect(
          deserializedAsset.caption,
          equals(originalCaption),
          reason: 'Caption should survive JSON serialization round-trip for iteration $i',
        );
      }
    });

    test('Property 5: Caption Preservation with null captions', () {
      final faker = Faker();
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random image without caption (null)
        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          caption: null, // Explicitly null caption
          createdAt: faker.date.dateTime(),
        );

        // Create timeline event with the media asset
        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
        );

        // Verify that null captions remain null
        final preservedAsset = timelineEvent.assets.first;
        expect(
          preservedAsset.caption,
          isNull,
          reason: 'Null caption should remain null for iteration $i',
        );

        // Test serialization round-trip with null caption
        final assetJson = preservedAsset.toJson();
        final deserializedAsset = MediaAsset.fromJson(assetJson);
        
        expect(
          deserializedAsset.caption,
          isNull,
          reason: 'Null caption should survive JSON serialization round-trip for iteration $i',
        );
      }
    });

    test('Property 5: Caption Preservation with empty captions', () {
      final faker = Faker();
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random image with empty caption
        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          caption: '', // Empty string caption
          createdAt: faker.date.dateTime(),
        );

        // Create timeline event with the media asset
        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
        );

        // Verify that empty captions are preserved as empty strings
        final preservedAsset = timelineEvent.assets.first;
        expect(
          preservedAsset.caption,
          equals(''),
          reason: 'Empty caption should be preserved as empty string for iteration $i',
        );

        // Test serialization round-trip with empty caption
        final assetJson = preservedAsset.toJson();
        final deserializedAsset = MediaAsset.fromJson(assetJson);
        
        expect(
          deserializedAsset.caption,
          equals(''),
          reason: 'Empty caption should survive JSON serialization round-trip for iteration $i',
        );
      }
    });

    test('Property 5: Caption Preservation with special characters', () {
      final faker = Faker();
      const iterations = 50;
      
      // Test captions with special characters, unicode, etc.
      final specialCaptions = [
        'Caption with émojis 🎉📸✨',
        'Caption with "quotes" and \'apostrophes\'',
        'Caption with\nnewlines\nand\ttabs',
        'Caption with unicode: café, naïve, résumé',
        'Caption with symbols: @#\$%^&*()_+-=[]{}|;:,.<>?',
        'Very long caption: ${faker.lorem.sentences(20).join(' ')}',
      ];
      
      for (int i = 0; i < iterations; i++) {
        final originalCaption = specialCaptions[i % specialCaptions.length];
        
        final mediaAsset = MediaAsset.photo(
          id: faker.guid.guid(),
          eventId: faker.guid.guid(),
          localPath: '/path/to/image_$i.jpg',
          caption: originalCaption,
          createdAt: faker.date.dateTime(),
        );

        // Create timeline event with the media asset
        final timelineEvent = TimelineEventFactory.createPhotoEvent(
          id: faker.guid.guid(),
          contextId: faker.guid.guid(),
          ownerId: faker.guid.guid(),
          contextType: ContextType.person,
          photoAssets: [mediaAsset],
        );

        // Verify that special character captions are preserved exactly
        final preservedAsset = timelineEvent.assets.first;
        expect(
          preservedAsset.caption,
          equals(originalCaption),
          reason: 'Special character caption should be preserved exactly for iteration $i',
        );

        // Test serialization round-trip with special characters
        final assetJson = preservedAsset.toJson();
        final deserializedAsset = MediaAsset.fromJson(assetJson);
        
        expect(
          deserializedAsset.caption,
          equals(originalCaption),
          reason: 'Special character caption should survive JSON serialization round-trip for iteration $i',
        );
      }
    });
  });
}