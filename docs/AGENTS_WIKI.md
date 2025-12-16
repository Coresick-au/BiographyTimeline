# Agents Wiki - Legacy Flow

> **Last updated:** 2025-12-16

This document contains coding standards, conventions, folder responsibilities, and gotchas for AI agents working on this codebase.

---

## Quick Reference

```bash
# Standard development workflow
flutter pub get                    # Install dependencies
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter analyze                    # Check for issues
flutter test                       # Run tests
flutter run -d chrome              # Run on web
flutter run                        # Run on default device
```

---

## Coding Standards

### Dart/Flutter Conventions
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart/style) style guide
- Use `const` constructors wherever possible
- Add type annotations to all variables and functions
- Document all public APIs with `///` doc comments
- Use meaningful, descriptive names

### File Naming
- Use `snake_case` for file names: `timeline_event.dart`
- Suffix generated files with `.g.dart`: `timeline_event.g.dart`
- Test files end with `_test.dart`

### Import Organization
```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Local imports (relative)
import '../models/timeline_event.dart';
```

---

## Architecture Patterns

### Feature-Based Structure
Each feature module follows this structure:
```
lib/features/your_feature/
├── models/           # Feature-specific models
├── providers/        # Riverpod providers
├── screens/          # Full-page screens
├── services/         # Business logic
└── widgets/          # Reusable widgets
```

### State Management (Riverpod)
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for UI
- Define providers in dedicated `providers/` folder
- Prefer `ref.watch()` for reactive updates
- Use `ref.read()` only in callbacks

```dart
// Good: Provider definition
final timelineEventsProvider = FutureProvider<List<TimelineEvent>>((ref) async {
  final service = ref.watch(timelineDataServiceProvider);
  return service.getEvents();
});

// Good: Consuming in widget
class TimelineScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(timelineEventsProvider);
    return eventsAsync.when(
      data: (events) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

### Renderer Pattern
Timeline views use a pluggable renderer pattern:
- All renderers implement `ITimelineRenderer`
- Factory creates renderers: `TimelineRendererFactory`
- Renderers are cached and reused

```dart
// To add a new timeline view:
// 1. Create renderer in lib/features/timeline/renderers/
// 2. Implement ITimelineRenderer interface
// 3. Register in TimelineRendererFactory
// 4. Add to TimelineViewMode enum
```

---

## Folder Responsibilities

| Path | Responsibility | Modify When |
|------|----------------|-------------|
| `lib/main.dart` | App entry, platform init | Changing startup logic |
| `lib/app/` | App-level config, navigation | Changing nav structure |
| `lib/core/` | Cross-cutting utilities | Adding infrastructure |
| `lib/features/timeline/` | Timeline feature | Timeline changes |
| `lib/features/stories/` | Rich text stories | Story editing |
| `lib/features/media/` | Media library | Media handling |
| `lib/shared/models/` | Core data models | Data structure changes |
| `lib/shared/providers/` | Shared Riverpod providers | New shared state |
| `lib/shared/widgets/` | Reusable UI components | New shared UI |
| `lib/shared/design_system/` | Theme, colors, typography | Styling changes |

---

## How We Do Things Here

### Adding a New Timeline Renderer

1. Create file in `lib/features/timeline/renderers/`:
```dart
class MyTimelineRenderer implements ITimelineRenderer {
  @override
  TimelineViewMode get viewMode => TimelineViewMode.myView;
  
  @override
  Widget build({...}) { /* implementation */ }
  
  // Implement all interface methods
}
```

2. Add to `TimelineViewMode` enum (if new mode)
3. Register in `TimelineRendererFactory`
4. Add icon to `AppIcons` if needed

### Adding a New Screen

1. Create in appropriate `features/<feature>/screens/`
2. Use `ConsumerWidget` or `ConsumerStatefulWidget`
3. Add route in `main_navigation.dart` if top-level

### Adding a New Model

1. Create in `lib/shared/models/` or feature-specific `models/`
2. Use `freezed` for immutable models:
```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => 
    _$MyModelFromJson(json);
}
```
3. Run `flutter packages pub run build_runner build --delete-conflicting-outputs`

### Adding Properties to AppIcons

If you need an icon that doesn't exist in `AppIcons`:
1. Edit `lib/shared/design_system/app_icons.dart`
2. Add static property using Material Icons:
```dart
static const IconData myIcon = Icons.my_icon_name;
```

---

## Common Gotchas

### 1. Code Generation Required
After modifying `@freezed` or `@JsonSerializable` models:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```
**Symptom**: Missing `.g.dart` file errors, type mismatch errors

### 2. Map View on Web
Google Maps requires API key in `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY"></script>
```
**Fallback**: App shows fallback UI if API unavailable

### 3. Desktop SQLite
Desktop platforms (Windows/macOS/Linux) need `sqflite_ffi`:
- Already initialized in `main.dart`
- Don't remove the platform check

### 4. Unused Code Warnings
Project has many analysis warnings (mostly unused imports/code)
- This is known and tracked
- Focus on fixing errors, not warnings
- Run `flutter analyze` before committing

### 5. Stub Renderers
Some renderers are stubs redirecting to others:
- `GridTimelineRenderer` → redirects to `BentoGridTimelineRenderer`
- `EnhancedVerticalTimelineRenderer` → redirects to `LifeStreamTimelineRenderer`

### 6. Theme System
Theme is managed via Riverpod:
- Provider: `themeDataProvider`
- Location: `lib/shared/providers/theme_provider.dart`
- Modes: Neutral, Dark, Light, Sepia

### 7. Empty State Handling
When timeline has no events:
- Show user-friendly empty state, NOT error
- Check `LifeStreamTimelineRenderer` for example implementation

---

## Testing Guidelines

### Property-Based Testing
All features should include property-based tests:
```dart
test('Property: Description for any input', () {
  for (int i = 0; i < 100; i++) {
    final input = generateRandomInput();
    final result = systemUnderTest(input);
    expect(result, satisfiesProperty);
  }
});
```

### Test Location
- Unit tests: `test/<feature>_test.dart` or `test/features/`
- Property tests: `test/property_tests/`
- Integration tests: `test/integration/`

### Running Tests
```bash
flutter test                           # All tests
flutter test test/specific_test.dart   # Specific test
flutter test --coverage                # With coverage
```

---

## Commit Message Format

```
type(scope): description

[optional body]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(timeline): add swimlane visualization
fix(map): resolve API key loading issue
docs(readme): update installation steps
```

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies, app version |
| `analysis_options.yaml` | Linter configuration |
| `lib/main.dart` | Entry point |
| `lib/app/app.dart` | Root MaterialApp |
| `lib/shared/design_system/modern_dark_theme.dart` | Dark theme config |
| `lib/features/timeline/services/timeline_integration_service.dart` | Central coordinator |
| `lib/features/timeline/services/timeline_data_service.dart` | Data operations |
| `lib/features/timeline/renderers/life_stream_timeline_renderer.dart` | Primary renderer |

---

## When Stuck

1. **Build errors**: `flutter clean && flutter pub get`
2. **Missing generated files**: Run build_runner
3. **Type mismatches**: Check model definitions and generated files
4. **UI not updating**: Verify using `ref.watch()` not `ref.read()`
5. **Navigation issues**: Check `main_navigation.dart`
