# Code Generation and Testing Infrastructure

This document describes the code generation setup and testing infrastructure for the Users Timeline project.

## Code Generation

### Overview
The project uses `json_serializable` to automatically generate JSON serialization code for data models. This ensures type-safe serialization/deserialization and reduces boilerplate code.

### Generated Files
The following `.g.dart` files are generated for data models:

- `lib/shared/models/context.g.dart` - Context model serialization
- `lib/shared/models/timeline_event.g.dart` - TimelineEvent model serialization  
- `lib/shared/models/timeline_theme.g.dart` - TimelineTheme model serialization
- `lib/shared/models/user.g.dart` - User model serialization
- `lib/shared/models/fuzzy_date.g.dart` - FuzzyDate model serialization
- `lib/shared/models/geo_location.g.dart` - GeoLocation model serialization
- `lib/shared/models/exif_data.g.dart` - ExifData model serialization
- `lib/shared/models/media_asset.g.dart` - MediaAsset model serialization
- `lib/shared/models/story.g.dart` - Story and StoryBlock model serialization
- `lib/shared/models/relationship.g.dart` - Relationship model serialization

### Configuration
Code generation is configured via `build.yaml`:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          include_if_null: false
          separate_outputs: true
          any_map: false
          checked: true
          nullable: true
```

### Running Code Generation
To regenerate the `.g.dart` files when Flutter/Dart is available:

```bash
# Install dependencies
flutter pub get

# Generate code (one-time)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Generate code (watch mode for development)
flutter packages pub run build_runner watch
```

## Testing Infrastructure

### Overview
The project uses a comprehensive testing approach combining:
- Unit tests for specific functionality
- Property-based tests for universal correctness properties
- Serialization tests for data integrity

### Test Configuration
- **Property Test Iterations**: 100 iterations per property test
- **Test Framework**: Flutter Test with faker package for data generation
- **Test Organization**: Feature-based test structure

### Test Files

#### Core Testing Infrastructure
- `test/test_config.dart` - Global test configuration and utilities
- `test/test_runner.dart` - Infrastructure verification tests
- `test/all_tests.dart` - Comprehensive test suite runner

#### Serialization Tests
- `test/serialization_test.dart` - JSON serialization round-trip tests for all models

#### Property-Based Tests
- `test/property_tests/data_model_integrity_property_test.dart` - Property 5: Caption Preservation Integrity
- `test/property_tests/timezone_handling_property_test.dart` - Property 2: Timezone Round-Trip Consistency

### Property Test Format
Each property-based test follows this format:

```dart
test('Property X: Description - **Feature: users-timeline, Property X: Description**', () {
  // **Validates: Requirements X.Y**
  
  final faker = Faker();
  const iterations = 100;
  
  for (int i = 0; i < iterations; i++) {
    // Generate random test data
    // Execute system under test
    // Assert property holds
  }
});
```

### Running Tests
When Flutter/Dart is available:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/serialization_test.dart

# Run property-based tests only
flutter test test/property_tests/

# Run with coverage
flutter test --coverage
```

### Test Utilities
The `PropertyTestUtils` class provides:
- `randomString(int length)` - Generate random strings
- `randomDateTime()` - Generate random dates within reasonable range
- `randomGpsCoordinates()` - Generate valid GPS coordinates
- `randomTimezoneOffset()` - Generate timezone offset strings

### Custom Matchers
The `TimelineMatchers` class provides:
- `isValidTimelineEvent()` - Validates timeline event structure
- `isValidExifData()` - Validates EXIF data structure  
- `isValidMediaAsset()` - Validates media asset structure

## Data Model Validation

### Serialization Integrity
All data models are tested for:
- JSON serialization round-trip consistency
- Null value handling
- Complex nested object serialization
- Enum value serialization

### Property-Based Validation
Key properties validated:
- **Caption Preservation**: Photo captions are preserved exactly during import and serialization
- **Timezone Consistency**: Timezone conversions maintain temporal meaning
- **Data Integrity**: All model fields survive serialization/deserialization

## Dependencies

### Core Dependencies
- `json_annotation: ^4.8.1` - Annotations for JSON serialization
- `faker: ^2.1.0` - Test data generation

### Dev Dependencies  
- `build_runner: ^2.4.7` - Code generation runner
- `json_serializable: ^6.7.1` - JSON serialization code generator
- `flutter_test` - Testing framework

## Maintenance

### Adding New Models
1. Create model class with `@JsonSerializable()` annotation
2. Add `part 'model_name.g.dart';` directive
3. Implement `fromJson()` and `toJson()` methods
4. Run code generation to create `.g.dart` file
5. Add serialization tests to `test/serialization_test.dart`

### Adding New Property Tests
1. Create test file in `test/property_tests/`
2. Follow property test format with proper tagging
3. Use minimum 100 iterations
4. Reference specific requirements being validated
5. Add to `test/all_tests.dart` import list

This infrastructure ensures type-safe data handling and comprehensive correctness validation across the entire Users Timeline system.