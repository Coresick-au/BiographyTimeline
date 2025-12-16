# AUDIT.md - Legacy Flow Deep Inspection

> **Last updated:** 2025-12-16  
> **Flutter:** 3.38.5 | **Dart:** 3.10.4 | **State:** Riverpod 2.4+ | **DB:** SQLite + PowerSync

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Web Build** | ✅ Succeeded (37.6s) |
| **Tests** | ❌ Compilation errors |
| **flutter analyze** | ⚠️ ~2700 issues (mostly info) |
| **Critical Errors** | 3-4 blocking issues |
| **Runtime Errors** | ParentDataWidget layout issues |

---

## Gap Analysis

| Area | Expected Behavior | Current Behavior | Gap | Fix Plan | Priority |
|------|-------------------|------------------|-----|----------|----------|
| **Tests** | All tests compile and run | Tests fail to compile: `contextId` param doesn't exist on `TimelineEvent` | **BUG** | Remove/update `contextId` in 7 test files | **P0** |
| **Consent Screen** | Null-safe access to properties | `consent_management_screen.dart:218` - accessing `.isNotEmpty` on nullable | **BUG** | Add null check before accessing `.isNotEmpty` | **P0** |
| **Onboarding** | Theme access via valid API | `onboarding_widget.dart` - calls `AppTheme.of()` which doesn't exist | **BUG** | Use correct theme access pattern (Riverpod provider) | **P0** |
| **UI Layout** | No overflow errors | `ParentDataWidget` and `RenderFlex overflow by 4.0 pixels` errors at runtime | **BUG** | Fix layout constraints in affected widgets | **P1** |
| **Unused Code** | Clean analyze output | ~2700 info/warning issues (unused imports, prefer_const) | **PARTIAL** | Batch cleanup of unused imports; low priority | **P3** |
| **iOS Support** | iOS build target available | `ios/` directory missing | **MISSING** | Run `flutter create --platforms ios .` if needed | **P2** |
| **Data Model** | Tests match model signature | Tests use deprecated `contextId` parameter | **BUG** | Update test event factories to match current `TimelineEvent` | **P0** |
| **Persistence** | Offline-first with sync | SQLite + PowerSync configured but sync not tested | **PARTIAL** | Add integration tests for offline scenarios | **P2** |
| **Routing** | Deep links and navigation | Basic navigation works; no deep linking | **PARTIAL** | Implement GoRouter or Navigator 2.0 if needed | **P3** |
| **Accessibility** | WCAG 2.1 AA compliance | Not verified | **UNKNOWN** | Audit with Accessibility Inspector | **P2** |

---

## Critical Issues Detail

### P0-001: Test Compilation Failure - contextId Parameter

**Files Affected:**
- `test/property_tests/collaborative_editing_property_test.dart:461`
- `test/property_tests/river_visualization_property_test.dart:320,336,352,381,408`
- `test/property_tests/visualization_completeness_property_test.dart:302`

**Symptom:** `No named parameter with the name 'contextId'`

**Root Cause:** `TimelineEvent` model signature changed; tests not updated.

**Fix:** Update test factories to use current `TimelineEvent` constructor parameters.

---

### P0-002: Null Safety Error - consent_management_screen.dart

**File:** `lib/features/consent/screens/consent_management_screen.dart:218`

**Symptom:** `The property 'isNotEmpty' can't be unconditionally accessed because the receiver can be 'null'`

**Fix:** Add null check: `?.isNotEmpty ?? false` or `!= null && .isNotEmpty`

---

### P0-003: Undefined Method - onboarding_widget.dart

**File:** `lib/features/onboarding/widgets/onboarding_widget.dart`

**Symptom:** `The method 'of' isn't defined for the type 'AppTheme'`

**Fix:** Replace with Riverpod theme provider pattern: `ref.watch(themeDataProvider)`

---

### P1-001: ParentDataWidget Runtime Errors

**Symptom:** 
```
Incorrect use of ParentDataWidget
RenderFlex overflowed by 4.0 pixels on the bottom
```

**Root Cause:** Widget tree has incorrect parent-child widget combinations (likely `Expanded` or `Flexible` outside `Row`/`Column`).

**Fix:** Audit widget trees in timeline renderers. Use Flutter Inspector to identify affected widgets.

---

## Recommendations

1. **Immediate (P0):** Fix 3 compilation errors to restore test and build health
2. **Short-term (P1):** Fix runtime layout errors for stable UI
3. **Medium-term (P2):** Add iOS support, accessibility audit
4. **Long-term (P3):** Bulk lint cleanup, routing improvements
