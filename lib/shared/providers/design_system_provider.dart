import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/design_system.dart';

/// Provider for the global ThemeManager instance
final themeManagerProvider = Provider<ThemeManager>((ref) {
  return themeManager;
});

/// Provider for the current app theme
final currentAppThemeProvider = StreamProvider<AppTheme>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return manager.themeStream;
});

/// Provider for the current Flutter ThemeData
final appThemeDataProvider = Provider<ThemeData>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return manager.getThemeData();
});

/// Provider for theme initialization
final themeInitializationProvider = FutureProvider<void>((ref) async {
  final manager = ref.watch(themeManagerProvider);
  await manager.initialize();
});

/// Provider for high contrast mode
final highContrastProvider = StateNotifierProvider<HighContrastNotifier, bool>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return HighContrastNotifier(manager);
});

/// Provider for reduced motion mode
final reducedMotionProvider = StateNotifierProvider<ReducedMotionNotifier, bool>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return ReducedMotionNotifier(manager);
});

/// Provider for available themes
final availableThemesProvider = Provider<List<AppTheme>>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return manager.availableThemes;
});

/// Provider for accent color palette
final accentColorPaletteProvider = Provider<List<Color>>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return manager.accentColorPalette;
});

/// Notifier for high contrast mode
class HighContrastNotifier extends StateNotifier<bool> {
  final ThemeManager _themeManager;

  HighContrastNotifier(this._themeManager) : super(_themeManager.highContrastEnabled);

  Future<void> toggle() async {
    await _themeManager.setHighContrast(!state);
    state = _themeManager.highContrastEnabled;
  }

  Future<void> set(bool enabled) async {
    await _themeManager.setHighContrast(enabled);
    state = _themeManager.highContrastEnabled;
  }
}

/// Notifier for reduced motion mode
class ReducedMotionNotifier extends StateNotifier<bool> {
  final ThemeManager _themeManager;

  ReducedMotionNotifier(this._themeManager) : super(_themeManager.reducedMotionEnabled);

  Future<void> toggle() async {
    await _themeManager.setReducedMotion(!state);
    state = _themeManager.reducedMotionEnabled;
  }

  Future<void> set(bool enabled) async {
    await _themeManager.setReducedMotion(enabled);
    state = _themeManager.reducedMotionEnabled;
  }
}

/// Actions for theme management
class ThemeActions {
  final ThemeManager _themeManager;

  ThemeActions(this._themeManager);

  /// Set a new theme
  Future<void> setTheme(AppTheme theme) async {
    await _themeManager.setTheme(theme);
  }

  /// Set a custom accent color
  Future<void> setAccentColor(Color color) async {
    await _themeManager.setAccentColor(color);
  }

  /// Clear custom accent color
  Future<void> clearAccentColor() async {
    await _themeManager.clearAccentColor();
  }

  /// Toggle between light and dark theme
  Future<void> toggleBrightness() async {
    await _themeManager.toggleBrightness();
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    await _themeManager.resetToDefault();
  }

  /// Create a custom theme
  AppTheme createCustomTheme({
    required String name,
    required Color accentColor,
    required Brightness brightness,
  }) {
    return _themeManager.createCustomTheme(
      name: name,
      accentColor: accentColor,
      brightness: brightness,
    );
  }
}

/// Provider for theme actions
final themeActionsProvider = Provider<ThemeActions>((ref) {
  final manager = ref.watch(themeManagerProvider);
  return ThemeActions(manager);
});
