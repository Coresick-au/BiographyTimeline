/// Test configuration and utilities for the Users Timeline project
library test_config;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:users_timeline/shared/models/context.dart';
import 'package:users_timeline/shared/models/fuzzy_date.dart';
import 'package:users_timeline/shared/models/media_asset.dart';

/// Global test configuration
class TestConfig {
  /// Number of iterations for property-based tests
  static const int propertyTestIterations = 100;
  
  /// Faker instance for generating test data
  static final Faker faker = Faker();
  
  /// Sets up common test environment
  static void setUp() {
    // Initialize any global test setup here
  }
  
  /// Tears down test environment
  static void tearDown() {
    // Clean up any global test resources here
  }
}

/// Utilities for property-based testing
class PropertyTestUtils {
  /// Generates a random string with specified length
  static String randomString(int length) {
    return TestConfig.faker.randomGenerator.string(length);
  }
  
  /// Generates a random DateTime within a reasonable range
  static DateTime randomDateTime() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365 * 10)); // 10 years ago
    final end = now.add(const Duration(days: 365)); // 1 year from now
    
    final range = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    final randomMs = (Random().nextDouble() * range).floor();
    
    return DateTime.fromMillisecondsSinceEpoch(
      start.millisecondsSinceEpoch + randomMs,
    );
  }
  
  /// Generates a random GPS coordinate pair
  static (double latitude, double longitude) randomGpsCoordinates() {
    return (
      TestConfig.faker.geo.latitude(),
      TestConfig.faker.geo.longitude(),
    );
  }
  
  /// Generates a random timezone offset string
  static String randomTimezoneOffset() {
    final offset = TestConfig.faker.randomGenerator.integer(24, min: -12);
    final sign = offset >= 0 ? '+' : '';
    return '$sign${offset.toString().padLeft(2, '0')}:00';
  }
  
  /// Generates a random context type
  static ContextType randomContextType() {
    final types = ContextType.values;
    return types[TestConfig.faker.randomGenerator.integer(types.length)];
  }
  
  /// Generates a random fuzzy date
  static FuzzyDate randomFuzzyDate() {
    final granularities = FuzzyDateGranularity.values;
    final granularity = granularities[TestConfig.faker.randomGenerator.integer(granularities.length)];
    final year = TestConfig.faker.date.dateTime().year;
    
    switch (granularity) {
      case FuzzyDateGranularity.decade:
        return FuzzyDate.decade(year - (year % 10));
      case FuzzyDateGranularity.year:
        return FuzzyDate.year(year);
      case FuzzyDateGranularity.season:
        final seasons = Season.values;
        final season = seasons[TestConfig.faker.randomGenerator.integer(seasons.length)];
        return FuzzyDate.season(year, season);
      case FuzzyDateGranularity.month:
        final month = TestConfig.faker.randomGenerator.integer(12, min: 1);
        return FuzzyDate.month(year, month);
      case FuzzyDateGranularity.day:
        final month = TestConfig.faker.randomGenerator.integer(12, min: 1);
        final day = TestConfig.faker.randomGenerator.integer(28, min: 1); // Safe day range
        return FuzzyDate(
          year: year,
          month: month,
          day: day,
          granularity: FuzzyDateGranularity.day,
        );
    }
  }
  
  /// Generates a random boolean value
  static bool randomBool() {
    return TestConfig.faker.randomGenerator.boolean();
  }
  
  /// Generates a random media asset
  static MediaAsset randomMediaAsset() {
    final types = AssetType.values;
    final type = types[TestConfig.faker.randomGenerator.integer(types.length)];
    
    return MediaAsset(
      id: randomString(10),
      eventId: randomString(10),
      type: type,
      localPath: '/fake/path/${randomString(8)}.jpg',
      cloudUrl: null,
      exifData: null,
      caption: randomString(50),
      createdAt: randomDateTime(),
      isKeyAsset: randomBool(),
    );
  }
}

/// Custom matchers for timeline-specific testing
class TimelineMatchers {
  /// Matcher for validating timeline event structure
  static Matcher isValidTimelineEvent() {
    return predicate<dynamic>((event) {
      return event != null &&
             event.id != null &&
             event.contextId != null &&
             event.ownerId != null &&
             event.timestamp != null &&
             event.eventType != null &&
             event.customAttributes != null &&
             event.assets != null &&
             event.participantIds != null &&
             event.privacyLevel != null &&
             event.createdAt != null &&
             event.updatedAt != null;
    }, 'is a valid timeline event');
  }
  
  /// Matcher for validating EXIF data structure
  static Matcher isValidExifData() {
    return predicate<dynamic>((exif) {
      return exif != null;
    }, 'is valid EXIF data');
  }
  
  /// Matcher for validating media asset structure
  static Matcher isValidMediaAsset() {
    return predicate<dynamic>((asset) {
      return asset != null &&
             asset.id != null &&
             asset.eventId != null &&
             asset.type != null &&
             asset.localPath != null &&
             asset.createdAt != null &&
             asset.isKeyAsset != null;
    }, 'is a valid media asset');
  }
}