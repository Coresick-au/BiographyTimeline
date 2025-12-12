# Technology Stack

## Framework & Platform

- **Primary Framework**: Flutter 3.x with Dart for cross-platform mobile development
- **Target Platforms**: iOS and Android with mobile-first design approach
- **Architecture Pattern**: Feature-based architecture with offline-first data synchronization

## Core Dependencies

### Mobile Application
- **State Management**: Riverpod or Bloc pattern for reactive state management
- **Local Database**: SQLite with sqflite package for offline-first data storage
- **Media Processing**: photo_manager package for gallery access and EXIF extraction
- **Rich Text Editing**: flutter_quill for story creation and block-based editing
- **Maps Integration**: Google Maps SDK or Mapbox for geographic timeline visualization
- **Face Detection**: google_mlkit_face_detection for on-device face clustering
- **Vector Search**: sqlite-vec extension for semantic content search

### Backend Services
- **Runtime**: Node.js with Express.js or Python with FastAPI
- **Database**: PostgreSQL with Prisma ORM for relational data
- **Sync Engine**: PowerSync SDK for offline-first SQLite replication
- **Authentication**: Firebase Auth or Auth0 for user management
- **File Storage**: AWS S3 with CloudFront CDN for media assets
- **Caching**: Redis for session management and performance optimization

### Infrastructure
- **Deployment**: Docker containers on AWS ECS or Google Cloud Run
- **CDN**: CloudFront or Google Cloud CDN for global media delivery
- **Monitoring**: Sentry for error tracking, DataDog for performance metrics
- **CI/CD**: GitHub Actions or GitLab CI for automated testing and deployment

## Development Commands

### Setup
```bash
# Install Flutter dependencies
flutter pub get

# Generate code (for data models and serialization)
flutter packages pub run build_runner build

# Run code generation in watch mode during development
flutter packages pub run build_runner watch
```

### Testing
```bash
# Run all tests including property-based tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run property-based tests specifically (minimum 100 iterations each)
flutter test test/property_tests/

# Run integration tests
flutter test integration_test/
```

### Building
```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for development/debugging
flutter build apk --debug
flutter build ios --debug
```

### Database Management
```bash
# Generate database migrations
dart run drift_dev schema generate

# Apply database migrations (handled automatically in app)
# Migrations are applied on app startup through SQLite schema versioning
```

## Code Quality Tools

- **Linting**: flutter_lints package with custom rules for timeline-specific patterns
- **Formatting**: dart format with 80-character line length
- **Analysis**: dart analyze with strict analysis options
- **Testing**: Minimum 100 iterations for each property-based test using faker package

## Performance Considerations

- **Image Loading**: Lazy loading with intelligent caching for large photo collections
- **Timeline Rendering**: CustomPainter for efficient visualization rendering
- **Memory Management**: Proper disposal of image streams and animation controllers
- **Offline Storage**: Configurable local storage limits with selective sync options