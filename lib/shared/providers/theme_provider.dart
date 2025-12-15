import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/app_theme.dart';

/// Timeline-specific theme definitions
/// Add new themes here - they'll automatically appear in the theme switcher!
class TimelineThemes {
  TimelineThemes._();

  /// Midnight Blue - Dark theme with blue accents (like your screenshots)
  static const AppTheme midnightBlue = AppTheme(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    description: 'Dark theme with vibrant blue accents',
    mode: ThemeMode.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF667EEA),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF764BA2),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFCF6679),
      onError: Color(0xFF000000),
      background: Color(0xFF121212),
      onBackground: Color(0xFFE1E1E1),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE1E1E1),
      surfaceVariant: Color(0xFF2C2C2C),
      onSurfaceVariant: Color(0xFFB0B0B0),
      outline: Color(0xFF3D3D3D),
      outlineVariant: Color(0xFF2A2A2A),
    ),
    accentColor: Color(0xFF667EEA),
  );

  /// Forest Green - Dark theme with green accents
  static const AppTheme forestGreen = AppTheme(
    id: 'forest_green',
    name: 'Forest Green',
    description: 'Dark theme with calming green tones',
    mode: ThemeMode.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF10B981),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF34D399),
      onSecondary: Color(0xFF000000),
      error: Color(0xFFEF4444),
      onError: Color(0xFFFFFFFF),
      background: Color(0xFF0F1419),
      onBackground: Color(0xFFE5E7EB),
      surface: Color(0xFF1A1F26),
      onSurface: Color(0xFFE5E7EB),
      surfaceVariant: Color(0xFF252B33),
      onSurfaceVariant: Color(0xFF9CA3AF),
      outline: Color(0xFF374151),
      outlineVariant: Color(0xFF1F2937),
    ),
    accentColor: Color(0xFF10B981),
  );

  /// Sunset Orange - Warm dark theme
  static const AppTheme sunsetOrange = AppTheme(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    description: 'Warm dark theme with orange accents',
    mode: ThemeMode.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFF59E0B),
      onPrimary: Color(0xFF000000),
      secondary: Color(0xFFFB923C),
      onSecondary: Color(0xFF000000),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      background: Color(0xFF1A1410),
      onBackground: Color(0xFFFAF5F0),
      surface: Color(0xFF2A1F1A),
      onSurface: Color(0xFFFAF5F0),
      surfaceVariant: Color(0xFF3A2A20),
      onSurfaceVariant: Color(0xFFD4C4B4),
      outline: Color(0xFF4A3A30),
      outlineVariant: Color(0xFF2A1F1A),
    ),
    accentColor: Color(0xFFF59E0B),
  );

  /// Ocean Blue - Light theme with blue accents
  static const AppTheme oceanBlue = AppTheme(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    description: 'Clean light theme with ocean blue tones',
    mode: ThemeMode.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0EA5E9),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF06B6D4),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      background: Color(0xFFF8FAFC),
      onBackground: Color(0xFF0F172A),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      surfaceVariant: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
    ),
    accentColor: Color(0xFF0EA5E9),
  );

  /// Cherry Blossom - Light theme with pink accents
  static const AppTheme cherryBlossom = AppTheme(
    id: 'cherry_blossom',
    name: 'Cherry Blossom',
    description: 'Soft light theme with pink accents',
    mode: ThemeMode.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFEC4899),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFF472B6),
      onSecondary: Color(0xFF000000),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      background: Color(0xFFFDF2F8),
      onBackground: Color(0xFF1F2937),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1F2937),
      surfaceVariant: Color(0xFFFCE7F3),
      onSurfaceVariant: Color(0xFF6B7280),
      outline: Color(0xFFF9A8D4),
      outlineVariant: Color(0xFFFBCFE8),
    ),
    accentColor: Color(0xFFEC4899),
  );

  /// All available timeline themes
  /// 🎨 ADD NEW THEMES HERE - they'll automatically show up in the theme switcher!
  static const List<AppTheme> allThemes = [
    midnightBlue,
    forestGreen,
    sunsetOrange,
    oceanBlue,
    cherryBlossom,
    // Add your custom themes here!
  ];

  /// Get theme by ID
  static AppTheme? getThemeById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Default theme
  static AppTheme get defaultTheme => midnightBlue;
}

/// Notifier for managing the current theme
class ThemeNotifier extends StateNotifier<AppTheme> {
  static const String _themeKey = 'selected_theme_id';
  
  ThemeNotifier() : super(TimelineThemes.defaultTheme) {
    _loadSavedTheme();
  }

  /// Load saved theme from preferences
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString(_themeKey);
      
      if (themeId != null) {
        final theme = TimelineThemes.getThemeById(themeId);
        if (theme != null) {
          state = theme;
        }
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  /// Change the current theme
  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.id);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  /// Cycle to next theme
  void nextTheme() {
    final currentIndex = TimelineThemes.allThemes.indexOf(state);
    final nextIndex = (currentIndex + 1) % TimelineThemes.allThemes.length;
    setTheme(TimelineThemes.allThemes[nextIndex]);
  }

  /// Cycle to previous theme
  void previousTheme() {
    final currentIndex = TimelineThemes.allThemes.indexOf(state);
    final previousIndex = 
        (currentIndex - 1 + TimelineThemes.allThemes.length) % TimelineThemes.allThemes.length;
    setTheme(TimelineThemes.allThemes[previousIndex]);
  }
}

/// Provider for the current theme
final currentThemeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

/// Provider for the ThemeData (what MaterialApp uses)
final themeDataProvider = Provider<ThemeData>((ref) {
  final appTheme = ref.watch(currentThemeProvider);
  return appTheme.toThemeData();
});
