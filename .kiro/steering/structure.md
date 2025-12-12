# Project Structure

## Overall Architecture

The Users Timeline project follows a **feature-based architecture** with clear separation of concerns and offline-first design principles. The codebase is organized around core features rather than technical layers.

## Directory Structure

```
lib/
├── main.dart                          # App entry point and initialization
├── app/                              # App-level configuration and routing
│   ├── app.dart                      # Main app widget and theme configuration
│   ├── router.dart                   # Navigation and routing logic
│   └── constants.dart                # App-wide constants and configuration
├── core/                             # Shared utilities and base classes
│   ├── database/                     # SQLite database setup and migrations
│   ├── services/                     # Shared services (sync, storage, etc.)
│   ├── utils/                        # Helper functions and extensions
│   └── widgets/                      # Reusable UI components
├── features/                         # Feature-based modules
│   ├── timeline/                     # Timeline visualization and management
│   │   ├── data/                     # Data models and repositories
│   │   ├── domain/                   # Business logic and use cases
│   │   ├── presentation/             # UI components and state management
│   │   └── services/                 # Feature-specific services
│   ├── stories/                      # Rich story creation and scrollytelling
│   ├── social/                       # User connections and timeline merging
│   ├── media/                        # Photo import and EXIF processing
│   ├── sync/                         # Offline-first synchronization
│   └── settings/                     # User preferences and privacy controls
└── shared/                           # Cross-feature shared code
    ├── models/                       # Shared data models
    ├── services/                     # Cross-cutting services
    └── widgets/                      # Common UI components

test/
├── unit_tests/                       # Specific behavior validation
├── property_tests/                   # Universal correctness properties
├── integration_tests/                # End-to-end user flows
└── helpers/                          # Test utilities and generators

assets/
├── images/                           # App icons and static images
├── fonts/                            # Custom typography assets
└── config/                           # Configuration files
```

## Feature Module Organization

Each feature follows a consistent internal structure:

```
features/[feature_name]/
├── data/
│   ├── models/                       # Data transfer objects and entities
│   ├── repositories/                 # Data access layer implementation
│   └── datasources/                  # Local and remote data sources
├── domain/
│   ├── entities/                     # Core business objects
│   ├── repositories/                 # Repository interfaces
│   └── usecases/                     # Business logic operations
├── presentation/
│   ├── pages/                        # Screen-level widgets
│   ├── widgets/                      # Feature-specific UI components
│   └── providers/                    # State management (Riverpod/Bloc)
└── services/
    └── [feature]_service.dart        # Feature-specific business services
```

## Key Architectural Patterns

### Data Flow
- **Offline-First**: Local SQLite database as source of truth
- **Repository Pattern**: Abstract data access with local/remote implementations
- **State Management**: Riverpod providers for reactive UI updates
- **Event Sourcing**: Immutable timeline events with append-only history

### Code Organization Principles
- **Feature Isolation**: Each feature is self-contained with minimal cross-dependencies
- **Dependency Injection**: Services injected through Riverpod providers
- **Interface Segregation**: Small, focused interfaces for testability
- **Single Responsibility**: Classes have one clear purpose and reason to change

### Testing Structure
- **Property-Based Tests**: Universal correctness properties with 100+ iterations
- **Unit Tests**: Specific behavior validation for individual components
- **Integration Tests**: End-to-end user flows and feature interactions
- **Test Generators**: Smart data generators using faker package for realistic test data

## File Naming Conventions

- **Dart Files**: snake_case (e.g., `timeline_event.dart`, `story_editor_page.dart`)
- **Classes**: PascalCase (e.g., `TimelineEvent`, `StoryEditorPage`)
- **Variables/Functions**: camelCase (e.g., `timelineEvents`, `createStory()`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_PHOTO_SIZE`, `DEFAULT_THEME`)
- **Test Files**: `*_test.dart` for unit tests, `*_property_test.dart` for property tests

## Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:io';

// 2. Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party package imports
import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';

// 4. Internal app imports (relative paths)
import '../../../core/database/database.dart';
import '../../domain/entities/timeline_event.dart';
import '../widgets/timeline_card.dart';
```

## Configuration Management

- **Environment Variables**: Stored in `.env` files for different environments
- **Feature Flags**: Controlled through remote config or local settings
- **Database Migrations**: Versioned schema changes in `core/database/migrations/`
- **Asset Management**: Organized by type with clear naming conventions

This structure supports the collaborative digital historiography platform's complexity while maintaining clear boundaries between features and enabling efficient development and testing workflows.