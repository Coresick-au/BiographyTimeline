# Timeline Biography App - Code Cleanup and Completion

> **Run 3rd** | Created: 2025-12-15

## Overview
Continue work on the Timeline Biography App after system crash. Address 2577 analysis issues and complete remaining features.

---

## Tasks

### Phase 1: Analysis and Assessment
- [ ] Review recent commits and git history
- [ ] Check for TODOs and FIXMEs in codebase
- [ ] Run `flutter analyze` to identify issues (found 2577 issues)
- [ ] Review project status and implementation plan
- [ ] Create detailed implementation plan
- [ ] Identify root causes:
  - Missing AppIcons properties (camera, timeline, offline)
  - Stub renderer implementations
  - Unused imports and declarations

### Phase 2: Fix Critical AppIcons Errors
- [ ] Add missing `AppIcons.camera` property
- [ ] Add missing `AppIcons.timeline` property
- [ ] Add missing `AppIcons.offline` property
- [ ] Add missing `_showWelcomeDialog` method
- [ ] Verify app compiles and runs

### Phase 3: Clean Up Unused Code
- [ ] Remove unused methods from `app.dart`
- [ ] Remove unused imports from `notification_service.dart`
- [ ] Remove unused `timeline_theme` imports

### Phase 4: Complete Stub Renderers
- [ ] Redirect `GridTimelineRenderer` to `BentoGridTimelineRenderer`
- [ ] Redirect `EnhancedVerticalTimelineRenderer` to `LifeStreamTimelineRenderer`
- [ ] Test renderer switching functionality

### Phase 5: Address Remaining Linting Issues
- [ ] Run `flutter analyze` and fix remaining warnings
- [ ] Clean up any additional unused code
- [ ] Verify code compiles without errors

### Phase 6: Final Verification
- [ ] Run `flutter analyze` (target: 0 errors)
- [ ] Run `flutter test`
- [ ] Manual test: Timeline view switching
- [ ] Manual test: Onboarding flow
- [ ] Build verification: `flutter build web`
- [ ] Push changes to GitHub

---

## Additional Features (If Time Permits)
- [ ] Add `VerticalCardOverlay`
- [ ] Add `HorizontalCardOverlay`
- [ ] Add toggles: Orientation, Minimal/Maximal
- [ ] Implement semantic zoom tiers using pixelsPerDay mapping and bucket thresholds
- [ ] Ensure 10k events stays smooth (memoize, avoid rebuild storms)
