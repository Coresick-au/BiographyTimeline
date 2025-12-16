import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'color_palettes.dart';

/// Manages theme state and persistence for the Users Timeline app
class ThemeManager extends ChangeNotifier {
  static const String _themeIdKey = 'selected_theme_id';
  static const String _accentColorKey = 'custom_accent_color';
  static const String _highContrastKey = 'high_contrast_enabled';
  static const String _reducedMotionKey = 'reduced_motion_enabled';

  AppTheme _currentTheme = AppThemes.defaultTheme;
  Color? _customAccentColor;
  bool _highContrastEnabled = false;
  bool _reducedMotionEnabled = false;
  SharedPreferences? _prefs;

  /// Stream controller for theme changes
  final StreamController<AppTheme> _themeController = StreamController<AppTheme>.broadcast();

  /// Current active theme
  AppTheme get currentTheme => _currentTheme;

  /// Stream of theme changes
  Stream<AppTheme> get themeStream => _themeController.stream;

  /// Whether high contrast mode is enabled
  bool get highContrastEnabled => _highContrastEnabled;

  /// Whether reduced motion is enabled
  bool get reducedMotionEnabled => _reducedMotionEnabled;

  /// Custom accent color (if any)
  Color? get customAccentColor => _customAccentColor;

  /// Available accent colors for customization
  List<Color> get accentColorPalette => ColorPalettes.accentColors;

  /// Initialize the theme manager and load saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedTheme();
  }

  /// Load saved theme from preferences
  Future<void> _loadSavedTheme() async {
    if (_prefs == null) return;

    // Load saved theme ID
    final savedThemeId = _prefs!.getString(_themeIdKey);
    if (savedThemeId != null) {
      final savedTheme = AppThemes.getThemeById(savedThemeId);
      if (savedTheme != null) {
        _currentTheme = savedTheme;
      }
    }

    // Load accessibility preferences
    _highContrastEnabled = _prefs!.getBool(_highContrastKey) ?? false;
    _reducedMotionEnabled = _prefs!.getBool(_reducedMotionKey) ?? false;

    // Load custom accent color
    final savedAccentColorValue = _prefs!.getInt(_accentColorKey);
    if (savedAccentColorValue != null) {
      _customAccentColor = Color(savedAccentColorValue);
      
      // Apply custom accent color to current theme
      if (_customAccentColor != null) {
        await _applyCustomAccentColor(_customAccentColor!);
      }
    }

    // Apply accessibility settings
    if (_highContrastEnabled) {
      await _applyHighContrast(true);
    }

    // Notify listeners of initial theme
    _notifyThemeChanged();
  }

  /// Set a new theme
  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme.id == theme.id) return;

    _currentTheme = theme;
    await _saveThemeId(theme.id);
    _notifyThemeChanged();
  }

  /// Set a custom accent color
  Future<void> setAccentColor(Color color) async {
    _customAccentColor = color;
    await _saveAccentColor(color);
    await _applyCustomAccentColor(color);
    _notifyThemeChanged();
  }

  /// Clear custom accent color and revert to theme default
  Future<void> clearAccentColor() async {
    _customAccentColor = null;
    await _prefs?.remove(_accentColorKey);
    
    // Revert to original theme
    final originalTheme = AppThemes.getThemeById(_currentTheme.id);
    if (originalTheme != null) {
      _currentTheme = originalTheme;
      _notifyThemeChanged();
    }
  }

  /// Toggle high contrast mode
  Future<void> setHighContrast(bool enabled) async {
    if (_highContrastEnabled == enabled) return;

    _highContrastEnabled = enabled;
    await _prefs?.setBool(_highContrastKey, enabled);
    await _applyHighContrast(enabled);
    _notifyThemeChanged();
  }

  /// Toggle reduced motion mode
  Future<void> setReducedMotion(bool enabled) async {
    if (_reducedMotionEnabled == enabled) return;

    _reducedMotionEnabled = enabled;
    await _prefs?.setBool(_reducedMotionKey, enabled);
    
    // Update current theme with reduced motion setting
    _currentTheme = _currentTheme.copyWith(reducedMotion: enabled);
    _notifyThemeChanged();
  }

  /// Apply custom accent color to current theme
  Future<void> _applyCustomAccentColor(Color accentColor) async {
    final colorScheme = ColorPalettes.generateAccentColorScheme(
      accentColor: accentColor,
      brightness: _currentTheme.colorScheme.brightness,
    );

    _currentTheme = _currentTheme.copyWith(
      accentColor: accentColor,
      colorScheme: colorScheme,
    );
  }

  /// Apply high contrast mode
  Future<void> _applyHighContrast(bool enabled) async {
    if (enabled) {
      // Switch to high contrast version of current theme
      final brightness = _currentTheme.colorScheme.brightness;
      final highContrastScheme = brightness == Brightness.light
          ? ColorPalettes.highContrastLightColorScheme
          : ColorPalettes.highContrastDarkColorScheme;

      _currentTheme = _currentTheme.copyWith(
        colorScheme: highContrastScheme,
        highContrast: true,
      );
    } else {
      // Revert to normal contrast
      final originalTheme = AppThemes.getThemeById(_currentTheme.id);
      if (originalTheme != null) {
        _currentTheme = originalTheme.copyWith(
          highContrast: false,
          reducedMotion: _reducedMotionEnabled,
        );

        // Reapply custom accent color if it exists
        if (_customAccentColor != null) {
          await _applyCustomAccentColor(_customAccentColor!);
        }
      }
    }
  }

  /// Save theme ID to preferences
  Future<void> _saveThemeId(String themeId) async {
    await _prefs?.setString(_themeIdKey, themeId);
  }

  /// Save accent color to preferences
  Future<void> _saveAccentColor(Color color) async {
    await _prefs?.setInt(_accentColorKey, color.value);
  }

  /// Notify listeners of theme changes
  void _notifyThemeChanged() {
    notifyListeners();
    _themeController.add(_currentTheme);
  }

  /// Get theme data for Flutter's ThemeData
  ThemeData getThemeData() {
    return _currentTheme.toThemeData();
  }

  /// Check if current theme is dark
  bool get isDarkTheme => _currentTheme.colorScheme.brightness == Brightness.dark;

  /// Check if current theme is light
  bool get isLightTheme => _currentTheme.colorScheme.brightness == Brightness.light;

  /// Get all available themes
  List<AppTheme> get availableThemes => AppThemes.allThemes;

  /// Create a custom theme with the given parameters
  AppTheme createCustomTheme({
    required String name,
    required Color accentColor,
    required Brightness brightness,
  }) {
    final customId = 'custom_${accentColor.value}_${brightness.name}';
    
    return AppThemes.createCustomTheme(
      id: customId,
      name: name,
      accentColor: accentColor,
      brightness: brightness,
      highContrast: _highContrastEnabled,
    );
  }

  /// Switch between light and dark variants of current theme
  Future<void> toggleBrightness() async {
    final currentBrightness = _currentTheme.colorScheme.brightness;
    final newBrightness = currentBrightness == Brightness.light 
        ? Brightness.dark 
        : Brightness.light;

    // Find corresponding theme with opposite brightness
    AppTheme? newTheme;
    
    if (_currentTheme.id.contains('light')) {
      newTheme = AppThemes.getThemeById(_currentTheme.id.replaceAll('light', 'dark'));
    } else if (_currentTheme.id.contains('dark')) {
      newTheme = AppThemes.getThemeById(_currentTheme.id.replaceAll('dark', 'light'));
    } else {
      // For themes without explicit light/dark in ID, create opposite
      newTheme = _currentTheme.id == 'light' 
          ? AppThemes.dark 
          : AppThemes.light;
    }

    if (newTheme != null) {
      await setTheme(newTheme);
    } else {
      // Create a new theme with opposite brightness
      final customTheme = createCustomTheme(
        name: '${_currentTheme.name} ${newBrightness.name}',
        accentColor: _currentTheme.accentColor,
        brightness: newBrightness,
      );
      await setTheme(customTheme);
    }
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    await clearAccentColor();
    await setHighContrast(false);
    await setReducedMotion(false);
    await setTheme(AppThemes.defaultTheme);
  }

  @override
  void dispose() {
    _themeController.close();
    super.dispose();
  }
}

/// Global theme manager instance
final ThemeManager themeManager = ThemeManager();
