/// Comprehensive serialization tests for all data models
import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

import 'package:legacy_flow/shared/models/context.dart';
import 'package:legacy_flow/shared/models/timeline_event.dart';
import 'package:legacy_flow/shared/models/timeline_theme.dart';
import 'package:legacy_flow/shared/models/user.dart';
import 'package:legacy_flow/shared/models/fuzzy_date.dart';
import 'package:legacy_flow/shared/models/geo_location.dart';
import 'package:legacy_flow/shared/models/media_asset.dart';
import 'package:legacy_flow/shared/models/story.dart';
import 'package:legacy_flow/shared/models/relationship.dart';
import 'package:legacy_flow/shared/models/exif_data.dart';

void main() {
  group('Data Model Serialization Tests', () {
    final faker = Faker();

    test('Context serialization round-trip', () {
      final context = Context.create(
        id: faker.guid.guid(),
        ownerId: faker.guid.guid(),
        type: ContextType.person,
        name: faker.person.name(),
        description: faker.lorem.sentence(),
      );

      final json = context.toJson();
      final deserialized = Context.fromJson(json);

      expect(deserialized, equals(context));
    });

    test('User serialization round-trip', () {
      final user = User(
        id: faker.guid.guid(),
        email: faker.internet.email(),
        displayName: faker.person.name(),
        profileImageUrl: faker.internet.httpUrl(),
        privacySettings: const PrivacySettings(
          allowTimelineMerging: true,
          allowLocationSharing: false,
          allowFaceDetection: true,
          defaultEventIsPrivate: true,
        ),
        contextIds: [faker.guid.guid(), faker.guid.guid()],
        createdAt: faker.date.dateTime(),
        lastActiveAt: faker.date.dateTime(),
      );

      final json = user.toJson();
      final deserialized = User.fromJson(json);

      expect(deserialized, equals(user));
    });

    test('FuzzyDate serialization round-trip', () {
      final fuzzyDate = FuzzyDate.year(2023);

      final json = fuzzyDate.toJson();
      final deserialized = FuzzyDate.fromJson(json);

      expect(deserialized, equals(fuzzyDate));
    });

    test('GeoLocation serialization round-trip', () {
      final geoLocation = GeoLocation(
        latitude: faker.geo.latitude(),
        longitude: faker.geo.longitude(),
        altitude: faker.randomGenerator.decimal(scale: 1000),
        locationName: faker.address.city(),
        city: faker.address.city(),
        country: faker.address.country(),
        accuracy: faker.randomGenerator.decimal(scale: 100),
      );

      final json = geoLocation.toJson();
      final deserialized = GeoLocation.fromJson(json);

      expect(deserialized, equals(geoLocation));
    });

    test('ExifData serialization round-trip', () {
      final exifData = ExifData(
        dateTimeOriginal: faker.date.dateTime(),
        gpsLocation: GeoLocation(
          latitude: faker.geo.latitude(),
          longitude: faker.geo.longitude(),
        ),
        timezone: '+05:30',
        cameraMake: 'Canon',
        cameraModel: 'EOS R5',
        focalLength: 85.0,
        aperture: 2.8,
        iso: '400',
        shutterSpeed: 0.008,
        orientation: 1,
        rawExifData: {'custom': 'data'},
      );

      final json = exifData.toJson();
      final deserialized = ExifData.fromJson(json);

      expect(deserialized, equals(exifData));
    });

    test('MediaAsset serialization round-trip', () {
      final mediaAsset = MediaAsset.photo(
        id: faker.guid.guid(),
        eventId: faker.guid.guid(),
        localPath: '/path/to/photo.jpg',
        cloudUrl: faker.internet.httpUrl(),
        caption: faker.lorem.sentence(),
        createdAt: faker.date.dateTime(),
        isKeyAsset: true,
        width: 1920,
        height: 1080,
        fileSizeBytes: 2048576,
      );

      final json = mediaAsset.toJson();
      final deserialized = MediaAsset.fromJson(json);

      expect(deserialized, equals(mediaAsset));
    });

    test('StoryBlock serialization round-trip', () {
      final storyBlock = StoryBlock.text(
        id: faker.guid.guid(),
        text: faker.lorem.sentences(3).join(' '),
        styling: {'fontSize': 16.0, 'color': '#000000'},
        scrollTriggerPosition: 0.5,
      );

      final json = storyBlock.toJson();
      final deserialized = StoryBlock.fromJson(json);

      expect(deserialized, equals(storyBlock));
    });

    test('Story serialization round-trip', () {
      final story = Story.empty(
        id: faker.guid.guid(),
        eventId: faker.guid.guid(),
        authorId: faker.guid.guid(),
      );

      final json = story.toJson();
      final deserialized = Story.fromJson(json);

      expect(deserialized, equals(story));
    });

    test('PermissionScope serialization round-trip', () {
      final permissionScope = PermissionScope.fullCollaboration();

      final json = permissionScope.toJson();
      final deserialized = PermissionScope.fromJson(json);

      expect(deserialized, equals(permissionScope));
    });

    test('Relationship serialization round-trip', () {
      final relationship = Relationship.create(
        id: faker.guid.guid(),
        userAId: faker.guid.guid(),
        userBId: faker.guid.guid(),
        type: RelationshipType.friend,
        sharedContextIds: [faker.guid.guid()],
        contextPermissions: {
          'context1': PermissionScope.viewOnly(),
        },
      );

      final json = relationship.toJson();
      final deserialized = Relationship.fromJson(json);

      expect(deserialized, equals(relationship));
    });

    test('TimelineTheme serialization round-trip', () {
      final theme = TimelineTheme.forContextType(ContextType.person);

      final json = theme.toJson();
      final deserialized = TimelineTheme.fromJson(json);

      expect(deserialized.toJson(), equals(theme.toJson()));
    });

    test('TimelineEvent serialization round-trip', () {
      final timelineEvent = TimelineEvent.create(
        id: faker.guid.guid(),
        ownerId: faker.guid.guid(),
        timestamp: faker.date.dateTime(),
        eventType: 'photo',
        customAttributes: {'test': 'value'},
        title: faker.lorem.words(3).join(' '),
        description: faker.lorem.sentence(),
      );

      final json = timelineEvent.toJson();
      final deserialized = TimelineEvent.fromJson(json);

      expect(deserialized, equals(timelineEvent));
    });

    test('Complex nested serialization', () {
      // Test a complex object with nested relationships
      final geoLocation = GeoLocation(
        latitude: faker.geo.latitude(),
        longitude: faker.geo.longitude(),
        city: faker.address.city(),
        country: faker.address.country(),
      );

      final exifData = ExifData(
        dateTimeOriginal: faker.date.dateTime(),
        gpsLocation: geoLocation,
        timezone: '+00:00',
        cameraMake: 'Sony',
        cameraModel: 'A7R IV',
      );

      final mediaAsset = MediaAsset.photo(
        id: faker.guid.guid(),
        eventId: faker.guid.guid(),
        localPath: '/path/to/complex_photo.jpg',
        exifData: exifData,
        caption: faker.lorem.sentence(),
        createdAt: faker.date.dateTime(),
      );

      final timelineEvent = TimelineEvent.create(
        id: faker.guid.guid(),
        ownerId: faker.guid.guid(),
        timestamp: faker.date.dateTime(),
        location: geoLocation,
        eventType: 'photo',
        assets: [mediaAsset],
        customAttributes: {
          'photographer': faker.person.name(),
          'weather': 'sunny',
          'temperature': 22.5,
        },
        title: faker.lorem.words(4).join(' '),
        description: faker.lorem.sentences(2).join(' '),
      );

      final json = timelineEvent.toJson();
      final deserialized = TimelineEvent.fromJson(json);

      expect(deserialized, equals(timelineEvent));
      expect(deserialized.assets.first.exifData?.gpsLocation, equals(geoLocation));
    });
  });
}
