# Error Index - Legacy Flow

> **Last updated:** 2025-12-16

A catalog of recurring errors, their symptoms, likely causes, and proven fixes.

---

## Analysis Summary

| Metric | Value |
|--------|-------|
| **Total Issues** | ~2739 |
| **Critical Errors** | ~15-20 |
| **Warnings** | ~2700+ |
| **Primary Categories** | Unused imports, unused variables, prefer_const_constructors |

Most issues are linting warnings, not blocking errors.

---

## Critical Errors

### ERR-001: Missing AppIcons Properties

**Symptoms:**
```
Error: The getter 'camera' isn't defined for the class 'AppIcons'.
Error: The getter 'timeline' isn't defined for the class 'AppIcons'.
Error: The getter 'offline' isn't defined for the class 'AppIcons'.
```

**Likely Cause:** 
New renderers or screens reference icon properties not defined in `AppIcons`.

**Where to Look:** 
`lib/shared/design_system/app_icons.dart`

**Fix:**
```dart
// Add missing icon properties
class AppIcons {
  static const IconData camera = Icons.camera_alt;
  static const IconData timeline = Icons.timeline;
  static const IconData offline = Icons.cloud_off;
}
```

---

### ERR-002: Missing Generated Files (.g.dart)

**Symptoms:**
```
Error: Target of URI doesn't exist: 'timeline_event.g.dart'.
Error: The method 'toJson' isn't defined for the type 'TimelineEvent'.
```

**Likely Cause:** 
Code generation hasn't been run after model changes.

**Where to Look:** 
`lib/shared/models/` and any `@freezed` or `@JsonSerializable` classes

**Fix:**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

### ERR-003: Map View Not Working on Web

**Symptoms:**
- Map shows blank/gray area
- Browser console shows Google Maps API errors
- `TypeError` in console

**Likely Cause:** 
Google Maps API key not configured or invalid.

**Where to Look:** 
`web/index.html`

**Fix:**
1. Get valid API key from Google Cloud Console
2. Add to `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_VALID_KEY"></script>
```
3. Ensure script tag is properly formatted (no line breaks in URL)

**Note:** App has fallback UI when API unavailable.

---

### ERR-004: SQLite Initialization Failure (Desktop)

**Symptoms:**
```
MissingPluginException: No implementation found for method openDatabase
DatabaseException: unable to open database file
```

**Likely Cause:** 
sqflite_ffi not initialized on desktop platforms.

**Where to Look:** 
`lib/main.dart`

**Fix:**
Ensure platform check in `main()`:
```dart
if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

---

### ERR-005: Renderer Build Errors

**Symptoms:**
```
Error: The method 'build' must be declared with required parameters
Error: Missing implementation of ITimelineRenderer methods
```

**Likely Cause:** 
Renderer doesn't fully implement `ITimelineRenderer` interface.

**Where to Look:** 
- `lib/features/timeline/interfaces/timeline_renderer_interface.dart`
- The specific renderer file

**Fix:**
Implement all required interface methods. Check interface for current requirements.

---

### ERR-006: Timeline Shows Error Instead of Empty State

**Symptoms:**
- App shows error message when timeline has no events
- Red error icon displayed

**Likely Cause:** 
Renderer not handling empty event list gracefully.

**Where to Look:** 
Specific renderer's `build()` method

**Fix:**
Add empty state check at start of `build()`:
```dart
if (events.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timeline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No events yet'),
        Text('Add your first memory to get started'),
      ],
    ),
  );
}
```

---

## Common Warnings (Non-Blocking)

### WARN-001: Unused Imports

**Symptoms:**
```
info - Unused import: 'package:xxx/xxx.dart' - unused_import
```

**Fix:**
Remove the unused import line, or ignore if intentional.

---

### WARN-002: Prefer Const Constructors

**Symptoms:**
```
info - Use 'const' with the constructor to improve performance - prefer_const_constructors
```

**Fix:**
Add `const` keyword where possible:
```dart
// Before
child: Icon(Icons.home)

// After
child: const Icon(Icons.home)
```

---

### WARN-003: Unused Local Variables

**Symptoms:**
```
info - The value of the local variable 'xxx' isn't used - unused_local_variable
```

**Fix:**
- Remove the variable if not needed
- Use `_` prefix if intentionally unused: `final _ = someValue;`

---

### WARN-004: Avoid Print

**Symptoms:**
```
info - Don't invoke 'print' in production code - avoid_print
```

**Fix:**
Use proper logging or remove debug prints.

---

## Build & Runtime Errors

### BUILD-001: Flutter Build Fails After Dependency Update

**Symptoms:**
- Build fails after running `flutter pub get`
- Version conflict errors

**Fix:**
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

### BUILD-002: Web Build Fails

**Symptoms:**
```
Error: Compilation failed
Target dart2js failed
```

**Fix:**
1. Check for non-web-compatible packages
2. Ensure conditional imports for platform-specific code
3. Verify `kIsWeb` checks around platform-specific APIs

---

### RUNTIME-001: Provider Not Found

**Symptoms:**
```
ProviderNotFoundException: Could not find a provider of type X
Exception: Provider not initialized
```

**Likely Cause:** 
Either `ProviderScope` missing or provider accessed before initialization.

**Where to Look:** 
`lib/main.dart` and provider definitions

**Fix:**
Ensure `ProviderScope` wraps the app in `main()`:
```dart
runApp(
  const ProviderScope(
    child: UsersTimelineApp(),
  ),
);
```

---

### RUNTIME-002: State Not Updating

**Symptoms:**
- UI doesn't reflect data changes
- Widget doesn't rebuild

**Likely Cause:** 
Using `ref.read()` instead of `ref.watch()` for reactive updates.

**Fix:**
```dart
// Wrong - doesn't rebuild on changes
final events = ref.read(eventsProvider);

// Correct - rebuilds when provider updates
final events = ref.watch(eventsProvider);
```

---

## Test Failures

### TEST-001: Property Test Timeout

**Symptoms:**
```
Test timeout after 30s
Property test failed: concurrent operations
```

**Likely Cause:** 
Property test with too many iterations or slow operations.

**Fix:**
- Reduce iteration count
- Add timeout handling
- Mock slow dependencies

---

### TEST-002: Widget Test - No Material Ancestor

**Symptoms:**
```
No Material widget found.
No MediaQuery widget ancestor found.
```

**Fix:**
Wrap test widget in `MaterialApp`:
```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: MyWidget(),
    ),
  ),
);
```

---

## Known Issues

1. **~2700 linting warnings** - Mostly unused imports and prefer_const. Tracked but not blocking.

2. **Stub renderers** - `GridTimelineRenderer` and `EnhancedVerticalTimelineRenderer` are placeholder redirects.

3. **18 property test failures** - Edge cases in concurrent operations. Core functionality unaffected.

---

## Adding New Errors

When you discover and fix a new error:

1. Add an entry following this format:
```markdown
### ERR-XXX: Error Name

**Symptoms:**
[Exact error message]

**Likely Cause:** 
[Why this happens]

**Where to Look:** 
[File paths]

**Fix:**
[Solution with code example if applicable]
```

2. Update the "Last updated" date at the top.
