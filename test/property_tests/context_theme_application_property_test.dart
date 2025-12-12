import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart' hide Color;

import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/timeline_theme.dart';
import '../../lib/features/context/services/theme_service.dart';

/// **Feature: users-timeline, Property 19: Context Theme Application**
/// **Validates: Requirements 9.5**
/// 
/// Property: For any context switch, the system should apply the appropriate Timeline_Theme 
/// including colors, icons, and interaction patterns specific to that context type
void main() {
  group('Context Theme Application Property Tests', () {
    late ThemeService themeService;
    final faker = Faker();

    setUp(() {
      themeService = ThemeService();
    });

    tearDown(() {
      themeService.dispose();
    });

    test('Property 19: Each context type has a unique and appropriate theme', () {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        final themes = <ContextType, TimelineTheme>{};
        
        // Collect themes for all context types
        for (final contextType in availableContexts) {
          final theme = themeService.getThemeForContextType(contextType);
          themes[contextType] = theme;
          
          // Property: Each context should have a non-null theme
          expect(theme, isNotNull,
              reason: 'Context $contextType should have a theme');
          
          // Property: Theme should have the correct context type
          expect(theme.contextType, equals(contextType),
              reason: 'Theme context type should match requested context type');
          
          // Property: Theme should have required properties
          expect(theme.id, isNotEmpty,
              reason: 'Theme should have a non-empty ID');
          expect(theme.name, isNotEmpty,
              reason: 'Theme should have a non-empty name');
          expect(theme.colorPalette, isNotEmpty,
              reason: 'Theme should have a color palette');
          expect(theme.iconSet, isNotEmpty,
              reason: 'Theme should have an icon set');
          expect(theme.widgetFactories, isNotEmpty,
              reason: 'Theme should have widget factories');
        }
        
        // Property: Each context should have a unique theme
        final themeIds = themes.values.map((t) => t.id).toSet();
        expect(themeIds.length, equals(themes.length),
            reason: 'Each context should have a unique theme ID');
        
        // Property: Themes should be context-appropriate
        expect(themes[ContextType.person]!.id, equals('personal_theme'),
            reason: 'Personal context should have personal theme');
        expect(themes[ContextType.pet]!.id, equals('pet_theme'),
            reason: 'Pet context should have pet theme');
        expect(themes[ContextType.project]!.id, equals('renovation_theme'),
            reason: 'Project context should have renovation theme');
        expect(themes[ContextType.business]!.id, equals('business_theme'),
            reason: 'Business context should have business theme');
      }
    });

    test('Property 19: Theme colors are context-appropriate and accessible', () {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final theme = themeService.getThemeForContextType(contextType);
          
          // Property: Theme should have required color keys
          final requiredColors = ['primary', 'secondary', 'background', 'surface', 'accent'];
          for (final colorKey in requiredColors) {
            expect(theme.colorPalette.containsKey(colorKey), isTrue,
                reason: 'Theme should have $colorKey color');
            
            final colorValue = theme.colorPalette[colorKey];

            expect(colorValue, isNotNull,
                reason: '$colorKey color should not be null');
            expect(colorValue, isA<int>(),
                reason: '$colorKey color should be stored as int');
            
            // Property: Color values should be valid
            final color = Color(colorValue!);
            expect(color.value, equals(colorValue),
                reason: 'Color value should be valid');
          }
          
          // Property: Context-specific color schemes should be appropriate
          final primaryColor = Color(theme.colorPalette['primary']!);
          switch (contextType) {
            case ContextType.person:
              // Personal themes typically use blue tones
              expect(primaryColor.blue, greaterThan(primaryColor.red),
                  reason: 'Personal theme should have blue-dominant primary color');
              break;
            case ContextType.pet:
              // Pet themes typically use green tones
              expect(primaryColor.green, greaterThan(primaryColor.red),
                  reason: 'Pet theme should have green-dominant primary color');
              break;
            case ContextType.project:
              // Project themes typically use orange/warm tones
              expect(primaryColor.red + primaryColor.green, greaterThan(primaryColor.blue * 2),
                  reason: 'Project theme should have warm-toned primary color');
              break;
            case ContextType.business:
              // Business themes typically use professional blue/indigo tones
              expect(primaryColor.blue, greaterThan(primaryColor.green),
                  reason: 'Business theme should have professional blue-toned primary color');
              break;
          }
        }
      }
    });

    test('Property 19: Theme features are context-appropriate', () {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final theme = themeService.getThemeForContextType(contextType);
          
          // Property: Ghost Camera should only be enabled for appropriate contexts
          switch (contextType) {
            case ContextType.pet:
            case ContextType.project:
              expect(theme.enableGhostCamera, isTrue,
                  reason: '$contextType context should enable Ghost Camera for progress comparison');
              break;
            case ContextType.person:
            case ContextType.business:
              expect(theme.enableGhostCamera, isFalse,
                  reason: '$contextType context should disable Ghost Camera');
              break;
          }
          
          // Property: Budget tracking should only be enabled for financial contexts
          switch (contextType) {
            case ContextType.project:
            case ContextType.business:
              expect(theme.enableBudgetTracking, isTrue,
                  reason: '$contextType context should enable budget tracking');
              break;
            case ContextType.person:
            case ContextType.pet:
              expect(theme.enableBudgetTracking, isFalse,
                  reason: '$contextType context should disable budget tracking');
              break;
          }
          
          // Property: Progress comparison should only be enabled for growth contexts
          switch (contextType) {
            case ContextType.pet:
            case ContextType.project:
              expect(theme.enableProgressComparison, isTrue,
                  reason: '$contextType context should enable progress comparison');
              break;
            case ContextType.person:
            case ContextType.business:
              expect(theme.enableProgressComparison, isFalse,
                  reason: '$contextType context should disable progress comparison');
              break;
          }
        }
      }
    });

    test('Property 19: Widget factories are context-specific', () {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final theme = themeService.getThemeForContextType(contextType);
          
          // Property: All contexts should have basic widgets
          expect(theme.isWidgetEnabled('milestoneCard'), isTrue,
              reason: 'All contexts should support milestone cards');
          expect(theme.isWidgetEnabled('photoGrid'), isTrue,
              reason: 'All contexts should support photo grids');
          
          // Property: Context-specific widgets should only be enabled for appropriate contexts
          switch (contextType) {
            case ContextType.person:
              expect(theme.isWidgetEnabled('locationCard'), isTrue,
                  reason: 'Personal context should enable location cards');
              expect(theme.isWidgetEnabled('storyCard'), isTrue,
                  reason: 'Personal context should enable story cards');
              
              // Should not have context-specific widgets from other contexts
              expect(theme.isWidgetEnabled('weightCard'), isFalse,
                  reason: 'Personal context should not have pet-specific widgets');
              expect(theme.isWidgetEnabled('costCard'), isFalse,
                  reason: 'Personal context should not have project-specific widgets');
              expect(theme.isWidgetEnabled('revenueCard'), isFalse,
                  reason: 'Personal context should not have business-specific widgets');
              break;
              
            case ContextType.pet:
              expect(theme.isWidgetEnabled('weightCard'), isTrue,
                  reason: 'Pet context should enable weight cards');
              expect(theme.isWidgetEnabled('vetCard'), isTrue,
                  reason: 'Pet context should enable vet cards');
              expect(theme.isWidgetEnabled('progressComparison'), isTrue,
                  reason: 'Pet context should enable progress comparison');
              
              // Should not have context-specific widgets from other contexts
              expect(theme.isWidgetEnabled('locationCard'), isFalse,
                  reason: 'Pet context should not have personal-specific widgets');
              expect(theme.isWidgetEnabled('costCard'), isFalse,
                  reason: 'Pet context should not have project-specific widgets');
              expect(theme.isWidgetEnabled('revenueCard'), isFalse,
                  reason: 'Pet context should not have business-specific widgets');
              break;
              
            case ContextType.project:
              expect(theme.isWidgetEnabled('costCard'), isTrue,
                  reason: 'Project context should enable cost cards');
              expect(theme.isWidgetEnabled('progressCard'), isTrue,
                  reason: 'Project context should enable progress cards');
              expect(theme.isWidgetEnabled('beforeAfterComparison'), isTrue,
                  reason: 'Project context should enable before/after comparison');
              
              // Should not have context-specific widgets from other contexts
              expect(theme.isWidgetEnabled('weightCard'), isFalse,
                  reason: 'Project context should not have pet-specific widgets');
              expect(theme.isWidgetEnabled('revenueCard'), isFalse,
                  reason: 'Project context should not have business-specific widgets');
              break;
              
            case ContextType.business:
              expect(theme.isWidgetEnabled('revenueCard'), isTrue,
                  reason: 'Business context should enable revenue cards');
              expect(theme.isWidgetEnabled('teamCard'), isTrue,
                  reason: 'Business context should enable team cards');
              expect(theme.isWidgetEnabled('metricsDashboard'), isTrue,
                  reason: 'Business context should enable metrics dashboard');
              
              // Should not have context-specific widgets from other contexts
              expect(theme.isWidgetEnabled('weightCard'), isFalse,
                  reason: 'Business context should not have pet-specific widgets');
              expect(theme.isWidgetEnabled('costCard'), isFalse,
                  reason: 'Business context should not have project-specific widgets');
              break;
          }
        }
      }
    });

    test('Property 19: Theme service correctly switches themes based on context', () {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          // Property: Setting theme for context should update current theme
          themeService.setThemeForContext(contextType);
          
          final currentTheme = themeService.currentTheme;
          expect(currentTheme, isNotNull,
              reason: 'Current theme should be set after context switch');
          expect(currentTheme!.contextType, equals(contextType),
              reason: 'Current theme should match the set context type');
          
          // Property: Feature checks should reflect current theme
          expect(themeService.isFeatureEnabled('ghostCamera'), 
                 equals(currentTheme.enableGhostCamera),
                 reason: 'Feature enablement should match current theme');
          expect(themeService.isFeatureEnabled('budgetTracking'), 
                 equals(currentTheme.enableBudgetTracking),
                 reason: 'Feature enablement should match current theme');
          expect(themeService.isFeatureEnabled('progressComparison'), 
                 equals(currentTheme.enableProgressComparison),
                 reason: 'Feature enablement should match current theme');
          
          // Property: Available widgets should reflect current theme
          final availableWidgets = themeService.getAvailableWidgets();
          for (final widget in availableWidgets) {
            expect(currentTheme.isWidgetEnabled(widget), isTrue,
                reason: 'Available widgets should all be enabled in current theme');
          }
        }
      }
    });

    testWidgets('Property 19: Flutter theme creation produces valid themes', (WidgetTester tester) async {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final timelineTheme = themeService.getThemeForContextType(contextType);
          final flutterTheme = themeService.createFlutterTheme(timelineTheme);
          
          // Property: Flutter theme should be valid
          expect(flutterTheme, isNotNull,
              reason: 'Flutter theme should be created successfully');
          expect(flutterTheme, isA<ThemeData>(),
              reason: 'Created theme should be valid ThemeData');
          
          // Property: Theme colors should match timeline theme
          final expectedPrimary = Color(timelineTheme.colorPalette['primary']!);
          expect(flutterTheme.primaryColor, equals(expectedPrimary),
              reason: 'Flutter theme primary color should match timeline theme');
          
          final expectedBackground = Color(timelineTheme.colorPalette['background']!);
          expect(flutterTheme.scaffoldBackgroundColor, equals(expectedBackground),
              reason: 'Flutter theme background should match timeline theme');
          
          // Property: Theme should be usable in widget tests
          await tester.pumpWidget(
            MaterialApp(
              theme: flutterTheme,
              home: const Scaffold(
                body: Text('Test'),
              ),
            ),
          );
          
          expect(find.text('Test'), findsOneWidget,
              reason: 'Theme should be usable in Flutter widgets');
        }
      }
    });

    test('Property 19: Theme consistency across multiple calls', () {
      // **Feature: users-timeline, Property 19: Context Theme Application**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          // Property: Multiple calls should return identical themes
          final theme1 = themeService.getThemeForContextType(contextType);
          final theme2 = themeService.getThemeForContextType(contextType);
          final theme3 = themeService.getThemeForContextType(contextType);
          
          expect(theme1.id, equals(theme2.id),
              reason: 'Theme ID should be consistent across calls');
          expect(theme2.id, equals(theme3.id),
              reason: 'Theme ID should be consistent across calls');
          
          expect(theme1.colorPalette, equals(theme2.colorPalette),
              reason: 'Color palette should be consistent across calls');
          expect(theme2.colorPalette, equals(theme3.colorPalette),
              reason: 'Color palette should be consistent across calls');
          
          expect(theme1.widgetFactories, equals(theme2.widgetFactories),
              reason: 'Widget factories should be consistent across calls');
          expect(theme2.widgetFactories, equals(theme3.widgetFactories),
              reason: 'Widget factories should be consistent across calls');
          
          // Property: Feature flags should be consistent
          expect(theme1.enableGhostCamera, equals(theme2.enableGhostCamera),
              reason: 'Feature flags should be consistent across calls');
          expect(theme1.enableBudgetTracking, equals(theme2.enableBudgetTracking),
              reason: 'Feature flags should be consistent across calls');
          expect(theme1.enableProgressComparison, equals(theme2.enableProgressComparison),
              reason: 'Feature flags should be consistent across calls');
        }
      }
    });
  });
}