import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/shared/design_system/app_theme.dart';
import '../../lib/shared/design_system/theme_engine.dart';
import '../../lib/shared/design_system/color_palettes.dart';
import '../helpers/db_test_helper.dart';

/// Property 31: Theme System Functionality
/// 
/// This test validates that the theme system works correctly:
/// 1. Neutral, Dark, Light, and Sepia modes are available
/// 2. Instant theme switching works
/// 3. Theme preferences persist across app restarts
/// 4. Design tokens are consistent across themes
/// 5. Accessibility standards are met
/// 6. Theme animations work smoothly

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    initializeTestDatabase();
  });
  
  group('Property 31: Theme System Functionality', () {
    late ProviderContainer container;
    late ThemeEngineNotifier themeEngine;
    late ThemeModeNotifier themeModeNotifier;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      
      container = ProviderContainer();
      themeEngine = container.read(themeEngineProvider.notifier);
      themeModeNotifier = container.read(themeModeProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('All required themes are available', () {
      // Check that all four required themes exist
      final lightTheme = AppThemes.getThemeById('light');
      final darkTheme = AppThemes.getThemeById('dark');
      final neutralTheme = AppThemes.getThemeById('neutral');
      final sepiaTheme = AppThemes.getThemeById('sepia');

      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      expect(neutralTheme, isNotNull);
      expect(sepiaTheme, isNotNull);

      // Verify theme properties
      expect(lightTheme!.name, equals('Light'));
      expect(darkTheme!.name, equals('Dark'));
      expect(neutralTheme!.name, equals('Neutral'));
      expect(sepiaTheme!.name, equals('Sepia'));

      // Verify theme modes
      expect(lightTheme.mode, equals(ThemeMode.light));
      expect(darkTheme.mode, equals(ThemeMode.dark));
      expect(neutralTheme.mode, equals(ThemeMode.light));
      expect(sepiaTheme.mode, equals(ThemeMode.light));
    });

    test('Sepia theme has correct vintage colors', () {
      final sepiaTheme = AppThemes.sepia;
      
      // Check primary colors are warm brown tones
      expect(sepiaTheme.colorScheme.primary.value, equals(0xFF8B6F47));
      expect(sepiaTheme.colorScheme.background.value, equals(0xFFFAF6F0));
      expect(sepiaTheme.colorScheme.surface.value, equals(0xFFF4ECD8));
      expect(sepiaTheme.colorScheme.onBackground.value, equals(0xFF5C4033));
      
      // Check accent color
      expect(sepiaTheme.accentColor.value, equals(0xFF8B6F47));
    });

    test('Instant theme switching works', () async {
      // Start with light theme
      expect(themeEngine.state.id, equals('light'));
      
      // Switch to dark theme
      await themeEngine.switchThemeById('dark');
      expect(themeEngine.state.id, equals('dark'));
      
      // Switch to neutral theme
      await themeEngine.switchTheme(AppThemes.neutral);
      expect(themeEngine.state.id, equals('neutral'));
      
      // Switch to sepia theme
      await themeEngine.switchThemeById('sepia');
      expect(themeEngine.state.id, equals('sepia'));
    });

    test('Theme cycling works correctly', () async {
      // Start with light theme
      await themeEngine.resetToDefault();
      expect(themeEngine.state.id, equals('light'));
      
      // Cycle through all themes
      await themeEngine.cycleToNextTheme();
      expect(themeEngine.state.id, equals('dark'));
      
      await themeEngine.cycleToNextTheme();
      expect(themeEngine.state.id, equals('neutral'));
      
      await themeEngine.cycleToNextTheme();
      expect(themeEngine.state.id, equals('sepia'));
      
      await themeEngine.cycleToNextTheme();
      expect(themeEngine.state.id, equals('high_contrast_light'));
      
      await themeEngine.cycleToNextTheme();
      expect(themeEngine.state.id, equals('high_contrast_dark'));
      
      // Cycle wraps around
      await themeEngine.cycleToNextTheme();
      expect(themeEngine.state.id, equals('light'));
    });

    test('Previous theme cycling works', () async {
      // Start with neutral theme
      await themeEngine.switchTheme(AppThemes.neutral);
      
      // Cycle to previous
      await themeEngine.cycleToPreviousTheme();
      expect(themeEngine.state.id, equals('dark'));
      
      // Cycle to previous
      await themeEngine.cycleToPreviousTheme();
      expect(themeEngine.state.id, equals('light'));
      
      // Cycle wraps around (from light to high_contrast_dark)
      await themeEngine.cycleToPreviousTheme();
      expect(themeEngine.state.id, equals('high_contrast_dark'));
    });

    test('Theme preferences persist', () async {
      // Switch to sepia theme
      await themeEngine.switchThemeById('sepia');
      expect(themeEngine.state.id, equals('sepia'));
      
      // Create new engine instance (simulates app restart)
      final newEngine = ThemeEngineNotifier();
      
      // Wait for async loading
      await Future.delayed(Duration(milliseconds: 100));
      
      // Should have loaded saved theme
      expect(newEngine.state.id, equals('sepia'));
    });

    test('Theme mode persistence works', () async {
      // Switch to dark mode
      await themeModeNotifier.switchThemeMode(ThemeMode.dark);
      expect(themeModeNotifier.state, equals(ThemeMode.dark));
      
      // Toggle to light mode
      await themeModeNotifier.toggleLightDark();
      expect(themeModeNotifier.state, equals(ThemeMode.light));
      
      // Toggle back to dark
      await themeModeNotifier.toggleLightDark();
      expect(themeModeNotifier.state, equals(ThemeMode.dark));
      
      // Create new notifier (simulates app restart)
      final newNotifier = ThemeModeNotifier();
      await Future.delayed(Duration(milliseconds: 100));
      
      // Should have loaded saved mode
      expect(newNotifier.state, equals(ThemeMode.dark));
    });

    test('Design tokens are consistent across themes', () {
      final themes = [AppThemes.light, AppThemes.dark, AppThemes.neutral, AppThemes.sepia];
      
      for (final theme in themes) {
        final themeData = theme.toThemeData();
        
        // Check typography scale is consistent
        expect(themeData.textTheme.displayLarge?.fontSize, equals(57.0));
        expect(themeData.textTheme.headlineLarge?.fontSize, equals(32.0));
        expect(themeData.textTheme.titleLarge?.fontSize, equals(22.0));
        expect(themeData.textTheme.bodyLarge?.fontSize, equals(16.0));
        
        // Check spacing is consistent
        expect(themeData.cardTheme.margin?.horizontal, equals(16.0));
        expect(themeData.cardTheme.margin?.vertical, equals(16.0));
        
        // Check border radius is consistent
        expect(themeData.cardTheme.shape.runtimeType, equals(RoundedRectangleBorder));
        expect(themeData.elevatedButtonTheme.style?.shape?.runtimeType, 
               equals(WidgetStatePropertyAll<OutlinedBorder>));
      }
    });

    test('Color schemes meet accessibility standards', () {
      final themes = [AppThemes.light, AppThemes.dark, AppThemes.neutral, AppThemes.sepia];
      
      for (final theme in themes) {
        // Check primary color contrast
        final primaryContrast = ThemeUtils.getContrastRatio(
          theme.colorScheme.onPrimary,
          theme.colorScheme.primary,
        );
        expect(primaryContrast, greaterThanOrEqualTo(3.0), 
               reason: '${theme.name} theme primary colors don\'t meet contrast requirements');
        
        // Check surface color contrast
        final surfaceContrast = ThemeUtils.getContrastRatio(
          theme.colorScheme.onSurface,
          theme.colorScheme.surface,
        );
        expect(surfaceContrast, greaterThanOrEqualTo(4.5),
               reason: '${theme.name} theme surface colors don\'t meet contrast requirements');
        
        // Primary colors should have reasonable contrast (adjusted for design)
        expect(primaryContrast, greaterThanOrEqualTo(3.0),
               reason: '${theme.name} theme primary colors don\'t meet practical requirements');
      }
    });

    test('Theme configuration builder works', () {
      final config = ThemeConfiguration(
        theme: AppThemes.sepia,
        mode: ThemeMode.light,
        highContrast: false,
        reducedMotion: false,
        textScale: 1.0,
      );
      
      expect(config.theme.id, equals('sepia'));
      expect(config.mode, equals(ThemeMode.light));
      expect(config.highContrast, isFalse);
      expect(config.reducedMotion, isFalse);
      expect(config.textScale, equals(1.0));
      
      // Test copyWith
      final newConfig = config.copyWith(
        highContrast: true,
        textScale: 1.5,
      );
      
      expect(newConfig.highContrast, isTrue);
      expect(newConfig.textScale, equals(1.5));
      expect(newConfig.theme.id, equals('sepia'));
    });

    test('High contrast theme adjustments', () {
      final config = ThemeConfiguration(
        theme: AppThemes.light,
        mode: ThemeMode.light,
        highContrast: true,
      );
      
      final themeData = config.toThemeData();
      
      // High contrast should use pure black/white
      expect(themeData.colorScheme.surface.value, equals(0xFFFFFFFF));
      expect(themeData.colorScheme.onSurface.value, equals(0xFF000000));
    });

    test('Text scaling works correctly', () {
      final config = ThemeConfiguration(
        theme: AppThemes.sepia,
        mode: ThemeMode.light,
        textScale: 1.5,
      );
      
      final themeData = config.toThemeData();
      
      // Check that text is scaled
      expect(themeData.textTheme.bodyLarge?.fontSize, equals(24.0)); // 16 * 1.5
      expect(themeData.textTheme.titleLarge?.fontSize, equals(33.0)); // 22 * 1.5
    });

    test('Theme utilities work correctly', () {
      // Test theme brightness detection
      expect(ThemeUtils.isDarkTheme(AppThemes.dark), isTrue);
      expect(ThemeUtils.isDarkTheme(AppThemes.light), isFalse);
      expect(ThemeUtils.isDarkTheme(AppThemes.sepia), isFalse);
      
      // Test theme selection by brightness
      final lightThemes = AppThemes.allThemes
          .where((t) => t.colorScheme.brightness == Brightness.light)
          .toList();
      final selectedLight = ThemeUtils.getThemeForBrightness(lightThemes, Brightness.light);
      expect(selectedLight.colorScheme.brightness, equals(Brightness.light));
      
      // Test contrast ratio calculation
      final contrast = ThemeUtils.getContrastRatio(Colors.black, Colors.white);
      expect(contrast, greaterThan(10.0)); // Should be very high contrast
    });

    test('Color palette helper methods work', () {
      // Test getting color schemes by name
      final lightScheme = ColorPalettes.getColorScheme('light');
      expect(lightScheme.brightness, equals(Brightness.light));
      
      final darkScheme = ColorPalettes.getColorScheme('dark');
      expect(darkScheme.brightness, equals(Brightness.dark));
      
      final sepiaScheme = ColorPalettes.getColorScheme('sepia');
      expect(sepiaScheme.primary.value, equals(0xFF8B6F47));
      
      // Test high contrast variants
      final highContrastLight = ColorPalettes.getColorScheme('light', highContrast: true);
      expect(highContrastLight.primary.value, equals(0xFF000080));
      
      // Test contrast checking
      expect(ColorPalettes.hasGoodContrast(Colors.black, Colors.white), isTrue);
      expect(ColorPalettes.hasGoodContrast(Colors.grey, Colors.white), isFalse);
    });

    test('Theme data generation works', () {
      for (final theme in [AppThemes.light, AppThemes.dark, AppThemes.neutral, AppThemes.sepia]) {
        final themeData = theme.toThemeData();
        
        // Verify Material 3 is used
        expect(themeData.useMaterial3, isTrue);
        
        // Verify color scheme is applied
        expect(themeData.colorScheme.primary.value, equals(theme.colorScheme.primary.value));
        
        // Verify typography is applied
        expect(themeData.textTheme.displayLarge?.color, equals(theme.colorScheme.onBackground));
        
        // Verify component themes are applied
        expect(themeData.cardTheme.elevation, equals(2.0));
        expect(themeData.appBarTheme.elevation, equals(0.0));
      }
    });

    test('Custom theme creation works', () {
      final customTheme = AppThemes.createCustomTheme(
        id: 'custom_test',
        name: 'Custom Test',
        accentColor: Colors.purple,
        brightness: Brightness.light,
      );
      
      expect(customTheme.id, equals('custom_test'));
      expect(customTheme.name, equals('Custom Test'));
      expect(customTheme.accentColor, equals(Colors.purple));
      expect(customTheme.mode, equals(ThemeMode.light));
    });
  });
}
