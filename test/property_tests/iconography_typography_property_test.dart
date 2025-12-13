import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/shared/design_system/app_icons.dart';
import '../../lib/shared/design_system/responsive_typography.dart';
import '../../lib/shared/design_system/accessibility_system.dart';
import '../../lib/shared/design_system/design_tokens.dart';

/// Property 32: Iconography and Typography System
/// 
/// This test validates that the iconography and typography systems work correctly:
/// 1. Consistent icon set for different content types
/// 2. Responsive typography hierarchy
/// 3. Accessibility support for different screen sizes and preferences
/// 4. Integration with the theme system
/// 5. Semantic meaning and visual hierarchy
/// 6. Cross-platform compatibility

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 32: Iconography and Typography System', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // ICONOGRAPHY TESTS
    // =========================================================================
    
    test('All required content type icons are available', () {
      // Event icons
      expect(AppIcons.event, isNotNull);
      expect(AppIcons.eventNote, isNotNull);
      expect(AppIcons.eventAvailable, isNotNull);
      expect(AppIcons.eventBusy, isNotNull);
      
      // Media icons
      expect(AppIcons.photo, isNotNull);
      expect(AppIcons.videocam, isNotNull);
      expect(AppIcons.musicNote, isNotNull);
      expect(AppIcons.audioFile, isNotNull);
      
      // Milestone icons
      expect(AppIcons.star, isNotNull);
      expect(AppIcons.grade, isNotNull);
      expect(AppIcons.emojiEvents, isNotNull);
      
      // People icons
      expect(AppIcons.person, isNotNull);
      expect(AppIcons.people, isNotNull);
      expect(AppIcons.group, isNotNull);
      
      // Location icons
      expect(AppIcons.locationOn, isNotNull);
      expect(AppIcons.place, isNotNull);
      expect(AppIcons.home, isNotNull);
    });

    test('Icon size presets are consistent', () {
      expect(AppIcons.sizeXS, equals(16.0));
      expect(AppIcons.sizeS, equals(20.0));
      expect(AppIcons.sizeM, equals(24.0));
      expect(AppIcons.sizeL, equals(32.0));
      expect(AppIcons.sizeXL, equals(48.0));
      expect(AppIcons.sizeXXL, equals(64.0));
    });

    test('Icon helper methods work correctly', () {
      // Test getIcon method
      final icon = AppIcons.getIcon(Icons.star, size: 32.0, color: Colors.red);
      expect(icon.icon, equals(Icons.star));
      expect(icon.size, equals(32.0));
      expect(icon.color, equals(Colors.red));
      
      // Test getIconForContentType
      expect(AppIcons.getIconForContentType('event'), equals(Icons.event));
      expect(AppIcons.getIconForContentType('photo'), equals(Icons.photo));
      expect(AppIcons.getIconForContentType('video'), equals(Icons.videocam));
      expect(AppIcons.getIconForContentType('unknown'), equals(Icons.description));
      
      // Test getThemedIcon
      final lightIcon = AppIcons.getThemedIcon(Icons.star, brightness: Brightness.light);
      expect(lightIcon.color, equals(Colors.black87));
      
      final darkIcon = AppIcons.getThemedIcon(Icons.star, brightness: Brightness.dark);
      expect(darkIcon.color, equals(Colors.white));
    });

    test('Icon button creation works', () {
      bool wasPressed = false;
      
      final button = AppIcons.createIconButton(
        icon: Icons.favorite,
        onPressed: () => wasPressed = true,
        size: AppIcons.sizeL,
        color: Colors.red,
        tooltip: 'Like',
      );
      
      expect(button.icon, isNotNull);
      expect(button.tooltip, equals('Like'));
    });

    test('IconData extension works', () {
      final icon = Icons.star.toIcon(size: 32.0, color: Colors.blue);
      expect(icon.icon, equals(Icons.star));
      expect(icon.size, equals(32.0));
      expect(icon.color, equals(Colors.blue));
      
      final themedIcon = Icons.star.themed(brightness: Brightness.dark);
      expect(themedIcon.color, equals(Colors.white));
    });

    // =========================================================================
    // TYPOGRAPHY TESTS
    // =========================================================================
    
    test('Responsive typography styles are available', () {
      // All base styles should be available
      expect(ResponsiveTypography.displayLarge, isNotNull);
      expect(ResponsiveTypography.displayMedium, isNotNull);
      expect(ResponsiveTypography.displaySmall, isNotNull);
      expect(ResponsiveTypography.headlineLarge, isNotNull);
      expect(ResponsiveTypography.headlineMedium, isNotNull);
      expect(ResponsiveTypography.headlineSmall, isNotNull);
      expect(ResponsiveTypography.titleLarge, isNotNull);
      expect(ResponsiveTypography.titleMedium, isNotNull);
      expect(ResponsiveTypography.titleSmall, isNotNull);
      expect(ResponsiveTypography.bodyLarge, isNotNull);
      expect(ResponsiveTypography.bodyMedium, isNotNull);
      expect(ResponsiveTypography.bodySmall, isNotNull);
      expect(ResponsiveTypography.labelLarge, isNotNull);
      expect(ResponsiveTypography.labelMedium, isNotNull);
      expect(ResponsiveTypography.labelSmall, isNotNull);
    });

    test('Context-specific typography styles are appropriate', () {
      // Event title should be bold and prominent
      final eventTitle = ResponsiveTypography.eventTitle;
      expect(eventTitle.fontWeight, equals(FontWeight.w600));
      expect(eventTitle.fontSize, greaterThan(28.0));
      
      // Event date should be gray and medium weight
      final eventDate = ResponsiveTypography.eventDate;
      expect(eventDate.fontWeight, equals(FontWeight.w500));
      expect(eventDate.color, equals(Colors.grey[600]));
      
      // Milestone title should be prominent with amber color
      final milestoneTitle = ResponsiveTypography.milestoneTitle;
      expect(milestoneTitle.fontWeight, equals(FontWeight.w700));
      expect(milestoneTitle.color, equals(Colors.amber[700]));
      
      // Media caption should be italic and gray
      final mediaCaption = ResponsiveTypography.mediaCaption;
      expect(mediaCaption.fontStyle, equals(FontStyle.italic));
      expect(mediaCaption.color, equals(Colors.grey[600]));
      
      // Quote should be italic with increased height
      final quote = ResponsiveTypography.quote;
      expect(quote.fontStyle, equals(FontStyle.italic));
      expect(quote.height, equals(1.8));
    });

    test('Responsive breakpoints are correctly defined', () {
      expect(ResponsiveTypography.breakpointXS, equals(360.0));
      expect(ResponsiveTypography.breakpointS, equals(600.0));
      expect(ResponsiveTypography.breakpointM, equals(840.0));
      expect(ResponsiveTypography.breakpointL, equals(1200.0));
      expect(ResponsiveTypography.breakpointXL, equals(1600.0));
    });

    test('Font scale factors are appropriate', () {
      final factors = ResponsiveTypography._fontScaleFactors;
      expect(factors[ResponsiveTypography.breakpointXS], equals(0.85));
      expect(factors[ResponsiveTypography.breakpointS], equals(0.9));
      expect(factors[ResponsiveTypography.breakpointM], equals(1.0));
      expect(factors[ResponsiveTypography.breakpointL], equals(1.1));
      expect(factors[ResponsiveTypography.breakpointXL], equals(1.2));
    });

    test('Accessibility typography adjustments work', () {
      final baseStyle = DesignTokens.bodyLarge;
      
      // Test large print
      final largePrint = ResponsiveTypography.getAccessibleStyle(
        baseStyle,
        textScaleFactor: 1.3,
        increasedSpacing: true,
      );
      expect(largePrint.fontSize, equals(baseStyle.fontSize! * 1.3));
      expect(largePrint.height, equals(baseStyle.height! * 1.5));
      
      // Test high contrast
      final highContrast = ResponsiveTypography.getAccessibleStyle(
        baseStyle,
        highContrast: true,
      );
      expect(highContrast.fontWeight, equals(FontWeight.w600));
      expect(highContrast.letterSpacing, 
             equals(baseStyle.letterSpacing! + 0.5));
      
      // Test large print preset
      final largePrintPreset = ResponsiveTypography.largePrint;
      expect(largePrintPreset.fontSize, greaterThan(baseStyle.fontSize!));
      
      // Test high contrast preset
      final highContrastPreset = ResponsiveTypography.highContrast;
      expect(highContrastPreset.fontWeight, equals(FontWeight.w600));
    });

    test('TextStyle extensions work correctly', () {
      final baseStyle = DesignTokens.bodyLarge;
      
      // Test responsive extension
      final responsive = baseStyle.responsive();
      expect(responsive, isNotNull);
      
      // Test accessible extension
      final accessible = baseStyle.accessible(
        textScaleFactor: 1.2,
        highContrast: true,
      );
      expect(accessible.fontSize, equals(baseStyle.fontSize! * 1.2));
      expect(accessible.fontWeight, equals(FontWeight.w600));
      
      // Test dark mode extension
      final darkMode = baseStyle.darkMode();
      expect(darkMode.color?.opacity, equals(0.87));
      
      // Test sepia extension
      final sepia = baseStyle.sepia();
      expect(sepia.color, equals(Color(0xFF5C4033)));
    });

    // =========================================================================
    // ACCESSIBILITY TESTS
    // =========================================================================
    
    test('Accessibility configuration works', () {
      final config = AccessibilitySystem.AccessibilityConfig(
        textScaleFactor: 1.5,
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
        largePrint: true,
        increasedSpacing: true,
        colorBlindFriendly: true,
      );
      
      expect(config.textScaleFactor, equals(1.5));
      expect(config.highContrast, isTrue);
      expect(config.reducedMotion, isTrue);
      expect(config.screenReader, isTrue);
      expect(config.largePrint, isTrue);
      expect(config.increasedSpacing, isTrue);
      expect(config.colorBlindFriendly, isTrue);
      
      // Test copyWith
      final newConfig = config.copyWith(textScaleFactor: 2.0);
      expect(newConfig.textScaleFactor, equals(2.0));
      expect(newConfig.highContrast, isTrue); // Should preserve other values
      
      // Test to/from map
      final map = config.toMap();
      final fromMap = AccessibilitySystem.AccessibilityConfig.fromMap(map);
      expect(fromMap.textScaleFactor, equals(config.textScaleFactor));
      expect(fromMap.highContrast, equals(config.highContrast));
    });

    test('Screen size adaptations work', () {
      // Test very small screen adaptation
      final smallScreenAdaptation = AccessibilitySystem.getScreenSizeAdjustments(
        _createTestContext(Size(350, 600)),
      );
      expect(smallScreenAdaptation.textScaleFactor, equals(0.9));
      expect(smallScreenAdaptation.increasedSpacing, isFalse);
      
      // Test very large screen adaptation
      final largeScreenAdaptation = AccessibilitySystem.getScreenSizeAdjustments(
        _createTestContext(Size(1400, 900)),
      );
      expect(largeScreenAdaptation.textScaleFactor, equals(1.1));
      expect(largeScreenAdaptation.increasedSpacing, isTrue);
    });

    test('Color adaptations work correctly', () {
      final lightScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      
      // Test color blind friendly adaptation
      final colorBlindScheme = AccessibilitySystem.getColorBlindFriendlyScheme(lightScheme);
      expect(colorBlindScheme.error, equals(Colors.red.shade700));
      
      // Test high contrast light adaptation
      final highContrastLight = AccessibilitySystem.getHighContrastScheme(lightScheme);
      expect(highContrastLight.primary, equals(Colors.black));
      expect(highContrastLight.onPrimary, equals(Colors.white));
      
      // Test high contrast dark adaptation
      final darkScheme = ColorScheme.dark();
      final highContrastDark = AccessibilitySystem.getHighContrastScheme(darkScheme);
      expect(highContrastDark.primary, equals(Colors.white));
      expect(highContrastDark.onPrimary, equals(Colors.black));
    });

    test('Motion adaptations work', () {
      final baseDuration = Duration(milliseconds: 300);
      
      // Test reduced motion
      final reducedDuration = AccessibilitySystem.getAnimationDuration(
        baseDuration, 
        true, // reducedMotion
      );
      expect(reducedDuration, equals(Duration.zero));
      
      // Test normal motion
      final normalDuration = AccessibilitySystem.getAnimationDuration(
        baseDuration, 
        false, // reducedMotion
      );
      expect(normalDuration, equals(baseDuration));
      
      // Test curves
      final reducedCurve = AccessibilitySystem.getAnimationCurve(true);
      expect(reducedCurve, equals(Curves.linear));
      
      final normalCurve = AccessibilitySystem.getAnimationCurve(false);
      expect(normalCurve, equals(Curves.easeInOut));
    });

    test('Semantic widgets are properly configured', () {
      // Test accessible button
      bool wasPressed = false;
      final button = AccessibilitySystem.accessibleButton(
        onPressed: () => wasPressed = true,
        child: Text('Test'),
        semanticLabel: 'Test Button',
        tooltip: 'Test',
      );
      expect(button, isNotNull);
      
      // Test accessible text field
      final controller = TextEditingController();
      final textField = AccessibilitySystem.accessibleTextField(
        controller: controller,
        label: 'Test Field',
        hint: 'Enter text',
      );
      expect(textField, isNotNull);
      
      // Test accessible image
      final image = AccessibilitySystem.accessibleImage(
        image: AssetImage('test.png'),
        semanticLabel: 'Test Image',
      );
      expect(image, isNotNull);
    });

    test('Context extensions work correctly', () {
      final context = _createTestContext(Size(800, 600));
      
      // Test accessibility config getters
      expect(context.isHighContrast, isFalse); // Default value
      expect(context.isReducedMotion, isFalse);
      expect(context.isScreenReader, isFalse);
      expect(context.isLargePrint, isFalse);
      
      // Test text scale factor
      expect(context.textScaleFactor, isNotNull);
      expect(context.textScaleFactor, greaterThan(0.0));
      
      // Test accessible text style
      final baseStyle = DesignTokens.bodyLarge;
      final accessibleStyle = context.getAccessibleTextStyle(baseStyle);
      expect(accessibleStyle, isNotNull);
    });

    // =========================================================================
    // INTEGRATION TESTS
    // =========================================================================
    
    testWidgets('Responsive typography provider works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveTypographyProvider(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ResponsiveTypography.responsiveText(
                    'Test Text',
                    style: ResponsiveTypography.headlineLarge,
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      expect(find.text('Test Text'), findsOneWidget);
    });

    testWidgets('Accessibility provider works', (tester) async {
      final config = AccessibilitySystem.AccessibilityConfig(
        textScaleFactor: 1.2,
        highContrast: true,
      );
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AccessibilitySystem.AccessibilityProvider(
              config: config,
              child: Builder(
                builder: (context) {
                  final currentConfig = context.accessibilityConfig;
                  return Scaffold(
                    body: Text('Config: ${currentConfig?.textScaleFactor}'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Config: 1.2'), findsOneWidget);
    });

    test('Icon and typography integration works', () {
      // Test that icons and typography work together
      final icon = AppIcons.getIconForContentType('event');
      final textStyle = ResponsiveTypography.eventTitle;
      
      expect(icon, equals(Icons.event));
      expect(textStyle.fontWeight, equals(FontWeight.w600));
      
      // Test themed combinations
      final themedIcon = AppIcons.getThemedIcon(icon, brightness: Brightness.dark);
      final themedText = textStyle.darkMode();
      
      expect(themedIcon.color, equals(Colors.white));
      expect(themedText.color?.opacity, equals(0.87));
    });
  });
}

/// Helper method to create a test context
BuildContext _createTestContext(Size size) {
  // This is a simplified mock for testing
  // In real tests, you would use WidgetTester
  throw UnimplementedError('Use testWidgets for context-dependent tests');
}
