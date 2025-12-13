import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'design_tokens.dart';

/// Provider for the theme engine
final themeEngineProvider = StateNotifierProvider<ThemeEngineNotifier, AppTheme>((ref) {
  return ThemeEngineNotifier();
});

/// Provider for the theme mode (light/dark/system)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Provider for the current ThemeData
final currentThemeProvider = Provider<ThemeData>((ref) {
  final theme = ref.watch(themeEngineProvider);
  return theme.toThemeData();
});

/// Theme engine notifier for managing theme state
class ThemeEngineNotifier extends StateNotifier<AppTheme> {
  ThemeEngineNotifier() : super(AppThemes.defaultTheme) {
    _loadSavedTheme();
  }

  static const String _themeKey = 'selected_theme';

  /// Switch to a new theme instantly
  Future<void> switchTheme(AppTheme newTheme) async {
    state = newTheme;
    await _saveTheme(newTheme.id);
  }

  /// Switch theme by ID
  Future<void> switchThemeById(String themeId) async {
    final theme = AppThemes.getThemeById(themeId);
    if (theme != null) {
      await switchTheme(theme);
    }
  }

  /// Get the next theme in the list
  AppTheme getNextTheme() {
    final currentIndex = AppThemes.allThemes.indexWhere((t) => t.id == state.id);
    final nextIndex = (currentIndex + 1) % AppThemes.allThemes.length;
    return AppThemes.allThemes[nextIndex];
  }

  /// Cycle to the next theme
  Future<void> cycleToNextTheme() async {
    await switchTheme(getNextTheme());
  }

  /// Get the previous theme in the list
  AppTheme getPreviousTheme() {
    final currentIndex = AppThemes.allThemes.indexWhere((t) => t.id == state.id);
    final prevIndex = (currentIndex - 1 + AppThemes.allThemes.length) % AppThemes.allThemes.length;
    return AppThemes.allThemes[prevIndex];
  }

  /// Cycle to the previous theme
  Future<void> cycleToPreviousTheme() async {
    await switchTheme(getPreviousTheme());
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    await switchTheme(AppThemes.defaultTheme);
  }

  /// Load saved theme from preferences
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeId = prefs.getString(_themeKey);
      
      if (savedThemeId != null) {
        final savedTheme = AppThemes.getThemeById(savedThemeId);
        if (savedTheme != null) {
          state = savedTheme;
        }
      }
    } catch (e) {
      // If loading fails, keep the default theme
      print('Failed to load saved theme: $e');
    }
  }

  /// Save theme ID to preferences
  Future<void> _saveTheme(String themeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeId);
    } catch (e) {
      print('Failed to save theme: $e');
    }
  }

  /// Clear saved theme
  Future<void> clearSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
    } catch (e) {
      print('Failed to clear saved theme: $e');
    }
  }
}

/// Theme mode notifier for managing light/dark/system mode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  /// Switch theme mode
  Future<void> switchThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode(mode.name);
  }

  /// Toggle between light and dark
  Future<void> toggleLightDark() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await switchThemeMode(newMode);
  }

  /// Load saved theme mode
  Future<void> _loadSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeName = prefs.getString(_themeModeKey);
      
      if (savedModeName != null) {
        final savedMode = ThemeMode.values.firstWhere(
          (m) => m.name == savedModeName,
          orElse: () => ThemeMode.system,
        );
        state = savedMode;
      }
    } catch (e) {
      print('Failed to load saved theme mode: $e');
    }
  }

  /// Save theme mode
  Future<void> _saveThemeMode(String modeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, modeName);
    } catch (e) {
      print('Failed to save theme mode: $e');
    }
  }
}

/// Theme configuration with additional settings
class ThemeConfiguration {
  final AppTheme theme;
  final ThemeMode mode;
  final bool highContrast;
  final bool reducedMotion;
  final double textScale;

  const ThemeConfiguration({
    required this.theme,
    required this.mode,
    this.highContrast = false,
    this.reducedMotion = false,
    this.textScale = 1.0,
  });

  /// Create a copy with updated values
  ThemeConfiguration copyWith({
    AppTheme? theme,
    ThemeMode? mode,
    bool? highContrast,
    bool? reducedMotion,
    double? textScale,
  }) {
    return ThemeConfiguration(
      theme: theme ?? this.theme,
      mode: mode ?? this.mode,
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      textScale: textScale ?? this.textScale,
    );
  }

  /// Convert to ThemeData
  ThemeData toThemeData() {
    var themeData = theme.toThemeData();
    
    // Apply high contrast if needed
    if (highContrast) {
      themeData = _applyHighContrast(themeData);
    }
    
    // Apply text scale
    themeData = themeData.copyWith(
      textTheme: themeData.textTheme.apply(
        fontSizeFactor: textScale,
        fontSizeDelta: 0,
      ),
    );
    
    return themeData;
  }

  /// Apply high contrast adjustments
  ThemeData _applyHighContrast(ThemeData themeData) {
    final colorScheme = themeData.colorScheme;
    
    return themeData.copyWith(
      colorScheme: colorScheme.copyWith(
        primary: colorScheme.primary.computeLuminance() > 0.5 
            ? Colors.black 
            : Colors.white,
        onPrimary: colorScheme.primary.computeLuminance() > 0.5 
            ? Colors.white 
            : Colors.black,
        surface: colorScheme.brightness == Brightness.light 
            ? Colors.white 
            : Colors.black,
        onSurface: colorScheme.brightness == Brightness.light 
            ? Colors.black 
            : Colors.white,
      ),
    );
  }
}

/// Theme animation controller for smooth transitions
class ThemeAnimationController {
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeInOut;

  /// Create an animated theme transition
  static Widget animatedThemeTransition({
    required Widget child,
    required ThemeData newTheme,
    required ThemeData oldTheme,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedTheme(
      data: newTheme,
      duration: duration ?? _animationDuration,
      curve: curve ?? _animationCurve,
      child: child,
    );
  }
}

/// Theme utilities
class ThemeUtils {
  /// Get the appropriate theme for current brightness
  static AppTheme getThemeForBrightness(
    List<AppTheme> themes, 
    Brightness brightness
  ) {
    return themes.firstWhere(
      (theme) => theme.colorScheme.brightness == brightness,
      orElse: () => themes.first,
    );
  }

  /// Check if theme is dark
  static bool isDarkTheme(AppTheme theme) {
    return theme.colorScheme.brightness == Brightness.dark;
  }

  /// Get theme contrast ratio
  static double getContrastRatio(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final ratio = (luminance1 > luminance2)
        ? (luminance1 + 0.05) / (luminance2 + 0.05)
        : (luminance2 + 0.05) / (luminance1 + 0.05);
    return ratio;
  }

  /// Check if theme meets accessibility standards
  static bool meetsAccessibilityStandards(AppTheme theme) {
    // Check primary colors contrast
    final primaryContrast = getContrastRatio(
      theme.colorScheme.onPrimary,
      theme.colorScheme.primary,
    );
    
    // Check surface colors contrast
    final surfaceContrast = getContrastRatio(
      theme.colorScheme.onSurface,
      theme.colorScheme.surface,
    );
    
    return primaryContrast >= 4.5 && surfaceContrast >= 4.5;
  }
}
