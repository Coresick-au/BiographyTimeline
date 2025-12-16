# BACKLOG.md - Legacy Flow Prioritized Work Items

> **Last updated:** 2025-12-16

---

## P0: Critical (Crashes/Broken Flows)

### ITEM-001: Fix Test Compilation - contextId Parameter
**Acceptance Criteria:**
- [ ] All 7 test files compile without `contextId` error
- [ ] `flutter test` runs (may still have test failures, but compiles)

**Files:**
- `test/property_tests/collaborative_editing_property_test.dart`
- `test/property_tests/river_visualization_property_test.dart`
- `test/property_tests/visualization_completeness_property_test.dart`

**Test Plan:** `flutter test --no-pub` compiles successfully

---

### ITEM-002: Fix Null Safety - consent_management_screen.dart
**Acceptance Criteria:**
- [ ] `flutter analyze` shows no error at line 218
- [ ] Consent management screen loads without crash

**Files:**
- `lib/features/consent/screens/consent_management_screen.dart`

**Test Plan:** Navigate to consent screen in running app

---

### ITEM-003: Fix AppTheme.of() - onboarding_widget.dart
**Acceptance Criteria:**
- [ ] `flutter analyze` shows no `undefined_method` error
- [ ] Onboarding flow completes without crash

**Files:**
- `lib/features/onboarding/widgets/onboarding_widget.dart`

**Test Plan:** Launch app fresh, complete onboarding

---

## P1: Core User Journey Gaps

### ITEM-004: Fix ParentDataWidget Layout Errors
**Acceptance Criteria:**
- [ ] No `ParentDataWidget` errors in console during normal use
- [ ] No `RenderFlex overflow` errors on main timeline screen

**Files:**
- Timeline renderers (likely `life_stream_timeline_renderer.dart` or similar)
- Potentially `bento_grid_timeline_renderer.dart`

**Test Plan:** Run `flutter run -d chrome`, navigate all views, check console

---

### ITEM-005: Verify Timeline Empty State
**Acceptance Criteria:**
- [ ] Empty timeline shows friendly message, not error
- [ ] Add event flow works from empty state

**Files:**
- `lib/features/timeline/renderers/life_stream_timeline_renderer.dart`

**Test Plan:** Clear sample data, verify UI

---

## P2: Medium Priority

### ITEM-006: Add iOS Platform Support
**Acceptance Criteria:**
- [ ] `ios/` directory exists
- [ ] `flutter build ios` succeeds (on macOS)

**Files:**
- Run `flutter create --platforms ios .`

**Test Plan:** Build verification

---

### ITEM-007: Accessibility Audit
**Acceptance Criteria:**
- [ ] All interactive elements have semantic labels
- [ ] Color contrast meets WCAG AA

**Files:**
- All screen and widget files

**Test Plan:** Flutter Accessibility Inspector

---

## P3: Low Priority (Tech Debt)

### ITEM-008: Bulk Lint Cleanup
**Acceptance Criteria:**
- [ ] Reduce `flutter analyze` issues by 50%+
- [ ] Remove all unused imports

**Files:**
- Entire `lib/` directory

**Test Plan:** `flutter analyze` count reduction

---

### ITEM-009: Deep Linking / Router Upgrade
**Acceptance Criteria:**
- [ ] URL-based navigation works on web
- [ ] Back button behavior is correct

**Files:**
- Navigation system

**Test Plan:** Manual navigation testing

---

## Implementation Order

1. ITEM-001 (unblocks test suite)
2. ITEM-002 (fixes crash)
3. ITEM-003 (fixes crash)
4. ITEM-004 (fixes UI stability)
5. Stop after these 4 items
