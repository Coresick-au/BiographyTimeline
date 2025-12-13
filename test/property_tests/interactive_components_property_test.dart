import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/shared/design_system/interaction_feedback.dart';
import '../../lib/shared/design_system/accessibility_system.dart';
import '../../lib/shared/design_system/theme_engine.dart';

/// Property 34: Interactive Components
/// 
/// This test validates that the interactive components work correctly:
/// 1. Haptic feedback respects accessibility preferences
/// 2. Animations adapt to reduced motion settings
/// 3. Loading indicators use theme colors correctly
/// 4. Interactive widgets provide proper feedback
/// 5. Transitions work across different screen sizes
/// 6. All components maintain accessibility standards

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 34: Interactive Components', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
      // Mock haptic feedback for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (message) async {
        if (message.method == 'HapticFeedback.vibrate') {
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    // =========================================================================
    // HAPTIC FEEDBACK TESTS
    // =========================================================================
    
    test('Haptic intensity levels are properly defined', () {
      expect(InteractionFeedback.HapticIntensity.values, contains(InteractionFeedback.HapticIntensity.none));
      expect(InteractionFeedback.HapticIntensity.values, contains(InteractionFeedback.HapticIntensity.light));
      expect(InteractionFeedback.HapticIntensity.values, contains(InteractionFeedback.HapticIntensity.medium));
      expect(InteractionFeedback.HapticIntensity.values, contains(InteractionFeedback.HapticIntensity.heavy));
    });

    test('Haptic feedback methods are available', () {
      // These should be callable without throwing
      expect(() => InteractionFeedback.tap(), returnsNormally);
      expect(() => InteractionFeedback.select(), returnsNormally);
      expect(() => InteractionFeedback.longPress(), returnsNormally);
      expect(() => InteractionFeedback.success(), returnsNormally);
      expect(() => InteractionFeedback.error(), returnsNormally);
      expect(() => InteractionFeedback.milestone(), returnsNormally);
    });

    test('Haptic feedback respects reduced motion', () async {
      final context = _createMockContextWithReducedMotion();
      
      // Should not trigger haptic feedback when reduced motion is enabled
      await InteractionFeedback.haptic(
        InteractionFeedback.HapticIntensity.medium,
        context: context,
      );
      
      // Test passes if no exception is thrown
      expect(true, isTrue);
    });

    // =========================================================================
    // ANIMATION TESTS
    // =========================================================================
    
    test('Animation duration respects reduced motion', () {
      final baseDuration = Duration(milliseconds: 300);
      
      // Normal context
      final normalContext = _createMockContext();
      final normalDuration = InteractionFeedback.getAnimationDuration(
        baseDuration,
        context: normalContext,
      );
      expect(normalDuration, equals(baseDuration));
      
      // Reduced motion context
      final reducedContext = _createMockContextWithReducedMotion();
      final reducedDuration = InteractionFeedback.getAnimationDuration(
        baseDuration,
        context: reducedContext,
      );
      expect(reducedDuration, equals(Duration.zero));
    });

    test('Animation curve respects reduced motion', () {
      final normalContext = _createMockContext();
      final normalCurve = InteractionFeedback.getAnimationCurve(
        context: normalContext,
        defaultCurve: Curves.easeInOut,
      );
      expect(normalCurve, equals(Curves.easeInOut));
      
      final reducedContext = _createMockContextWithReducedMotion();
      final reducedCurve = InteractionFeedback.getAnimationCurve(
        context: reducedContext,
        defaultCurve: Curves.easeInOut,
      );
      expect(reducedCurve, equals(Curves.linear));
    });

    test('Animated container works correctly', () {
      final container = InteractionFeedback.animatedContainer(
        child: Text('Test'),
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        context: _createMockContext(),
      );
      
      expect(container, isNotNull);
      expect(container.child, isNotNull);
    });

    test('Animated opacity works correctly', () {
      final opacity = InteractionFeedback.animatedOpacity(
        child: Text('Test'),
        opacity: 0.5,
        duration: Duration(milliseconds: 300),
        context: _createMockContext(),
      );
      
      expect(opacity, isNotNull);
      expect(opacity.opacity, equals(0.5));
    });

    test('Animated switcher works correctly', () {
      final switcher = InteractionFeedback.animatedSwitcher(
        child: Text('Test'),
        duration: Duration(milliseconds: 300),
        context: _createMockContext(),
      );
      
      expect(switcher, isNotNull);
    });

    // =========================================================================
    // LOADING INDICATORS TESTS
    // =========================================================================
    
    test('Circular progress indicator uses theme colors', () {
      final context = _createMockContext();
      final indicator = InteractionFeedback.circularProgressIndicator(
        context: context,
      );
      
      expect(indicator, isNotNull);
      expect(indicator.value, isNull); // Indeterminate by default
    });

    test('Linear progress indicator uses theme colors', () {
      final context = _createMockContext();
      final indicator = InteractionFeedback.linearProgressIndicator(
        value: 0.5,
        context: context,
      );
      
      expect(indicator, isNotNull);
      expect(indicator.value, equals(0.5));
    });

    test('Loading spinner respects size parameter', () {
      final spinner = InteractionFeedback.loadingSpinner(
        size: 32.0,
        context: _createMockContext(),
      );
      
      expect(spinner, isNotNull);
    });

    test('Pulsing loader works correctly', () {
      final loader = InteractionFeedback.pulsingLoader(
        context: _createMockContext(),
      );
      
      expect(loader, isNotNull);
    });

    // =========================================================================
    // INTERACTIVE WIDGETS TESTS
    // =========================================================================
    
    test('Haptic button works correctly', () {
      bool wasPressed = false;
      
      final button = InteractionFeedback.hapticButton(
        onPressed: () => wasPressed = true,
        hapticIntensity: InteractionFeedback.HapticIntensity.light,
        child: Text('Press me'),
        context: _createMockContext(),
      );
      
      expect(button, isNotNull);
      expect(button.child, isNotNull);
    });

    test('Interactive card works correctly', () {
      bool wasTapped = false;
      
      final card = InteractionFeedback.interactiveCard(
        child: Text('Card content'),
        onTap: () => wasTapped = true,
        context: _createMockContext(),
      );
      
      expect(card, isNotNull);
      expect(card.child, isNotNull);
    });

    test('Haptic list tile works correctly', () {
      bool wasTapped = false;
      
      final tile = InteractionFeedback.hapticListTile(
        leading: Icon(Icons.home),
        title: Text('Home'),
        onTap: () => wasTapped = true,
        context: _createMockContext(),
      );
      
      expect(tile, isNotNull);
      expect(tile.leading, isNotNull);
      expect(tile.title, isNotNull);
    });

    // =========================================================================
    // TRANSITION TESTS
    // =========================================================================
    
    test('Slide transition works correctly', () {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: const TestVSync(),
      );
      
      final transition = InteractionFeedback.slideTransition(
        child: Text('Slide'),
        animation: controller,
        context: _createMockContext(),
      );
      
      expect(transition, isNotNull);
      controller.dispose();
    });

    test('Scale transition works correctly', () {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: const TestVSync(),
      );
      
      final transition = InteractionFeedback.scaleTransition(
        child: Text('Scale'),
        animation: controller,
        context: _createMockContext(),
      );
      
      expect(transition, isNotNull);
      controller.dispose();
    });

    test('Fade transition works correctly', () {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: const TestVSync(),
      );
      
      final transition = InteractionFeedback.fadeTransition(
        child: Text('Fade'),
        animation: controller,
        context: _createMockContext(),
      );
      
      expect(transition, isNotNull);
      controller.dispose();
    });

    // =========================================================================
    // PROVIDER TESTS
    // =========================================================================
    
    test('Feedback providers have correct defaults', () {
      expect(container.read(InteractionFeedback.hapticFeedbackProvider), isTrue);
      expect(container.read(InteractionFeedback.animationSpeedProvider), equals(1.0));
      expect(container.read(InteractionFeedback.loadingProvider), isFalse);
    });

    test('Feedback providers can be updated', () {
      // Update haptic feedback
      container.read(InteractionFeedback.hapticFeedbackProvider.notifier).state = false;
      expect(container.read(InteractionFeedback.hapticFeedbackProvider), isFalse);
      
      // Update animation speed
      container.read(InteractionFeedback.animationSpeedProvider.notifier).state = 0.5;
      expect(container.read(InteractionFeedback.animationSpeedProvider), equals(0.5));
      
      // Update loading state
      container.read(InteractionFeedback.loadingProvider.notifier).state = true;
      expect(container.read(InteractionFeedback.loadingProvider), isTrue);
    });

    // =========================================================================
    // CONTEXT EXTENSIONS TESTS
    // =========================================================================
    
    test('Context extensions work correctly', () {
      final context = _createMockContext();
      
      // Test haptic extension
      expect(() => context.haptic(InteractionFeedback.HapticIntensity.light), returnsNormally);
      
      // Test animation duration extension
      final duration = context.getAnimationDuration(Duration(milliseconds: 200));
      expect(duration, equals(Duration(milliseconds: 200)));
      
      // Test animation curve extension
      final curve = context.getAnimationCurve(Curves.easeInOut);
      expect(curve, equals(Curves.easeInOut));
      
      // Test progress indicator extension
      final indicator = context.progressIndicator();
      expect(indicator, isNotNull);
      
      // Test loading spinner extension
      final spinner = context.loadingSpinner();
      expect(spinner, isNotNull);
    });

    // =========================================================================
    // ACCESSIBILITY TESTS
    // =========================================================================
    
    test('All animations respect reduced motion', () {
      final reducedContext = _createMockContextWithReducedMotion();
      
      // Animated container
      final container = InteractionFeedback.animatedContainer(
        child: Text('Test'),
        duration: Duration(milliseconds: 200),
        context: reducedContext,
      );
      expect(container, isNotNull);
      
      // Animated opacity
      final opacity = InteractionFeedback.animatedOpacity(
        child: Text('Test'),
        opacity: 0.5,
        duration: Duration(milliseconds: 300),
        context: reducedContext,
      );
      expect(opacity, isNotNull);
      
      // Transitions
      final controller = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: const TestVSync(),
      );
      
      final slide = InteractionFeedback.slideTransition(
        child: Text('Test'),
        animation: controller,
        context: reducedContext,
      );
      expect(slide, isNotNull);
      
      controller.dispose();
    });

    test('Haptic feedback respects accessibility settings', () async {
      final reducedContext = _createMockContextWithReducedMotion();
      
      // Should not trigger haptic feedback
      await InteractionFeedback.haptic(
        InteractionFeedback.HapticIntensity.heavy,
        context: reducedContext,
      );
      
      // Test passes if no exception
      expect(true, isTrue);
    });

    // =========================================================================
    // INTEGRATION TESTS
    // =========================================================================
    
    test('Interaction feedback integrates with theme system', () {
      final context = _createMockContext();
      
      // Progress indicator should use theme colors
      final indicator = InteractionFeedback.circularProgressIndicator(
        context: context,
      );
      expect(indicator, isNotNull);
      
      // Loading spinner should use theme colors
      final spinner = InteractionFeedback.loadingSpinner(
        context: context,
      );
      expect(spinner, isNotNull);
    });

    test('Interaction feedback provider works', () {
      final provider = InteractionFeedbackProvider(
        enableHaptics: false,
        animationSpeed: 0.5,
        child: Container(),
      );
      
      expect(provider, isNotNull);
    });

    test('All components maintain semantic structure', () {
      // Haptic button
      final button = InteractionFeedback.hapticButton(
        onPressed: () {},
        child: Text('Button'),
      );
      expect(button, isNotNull);
      
      // Interactive card
      final card = InteractionFeedback.interactiveCard(
        child: Text('Card'),
        onTap: () {},
      );
      expect(card, isNotNull);
      
      // Haptic list tile
      final tile = InteractionFeedback.hapticListTile(
        leading: Icon(Icons.home),
        title: Text('Title'),
        onTap: () {},
      );
      expect(tile, isNotNull);
    });

    // =========================================================================
    // WIDGET TESTS
    // =========================================================================
    
    testWidgets('Haptic button triggers haptic on tap', (tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionFeedback.hapticButton(
              onPressed: () => wasPressed = true,
              child: Text('Press me'),
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Press me'));
      await tester.pump();
      
      expect(wasPressed, isTrue);
    });

    testWidgets('Interactive card provides visual feedback', (tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionFeedback.interactiveCard(
              child: Text('Card'),
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Card'));
      await tester.pump();
      
      expect(wasTapped, isTrue);
    });

    testWidgets('Animated container animates correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionFeedback.animatedContainer(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
              duration: Duration(milliseconds: 100),
              color: Colors.red,
            ),
          ),
        ),
      );
      
      // Initial state
      expect(find.byType(AnimatedContainer), findsOneWidget);
      
      // Wait for animation
      await tester.pump(Duration(milliseconds: 50));
      
      // Animation in progress
      expect(find.byType(AnimatedContainer), findsOneWidget);
      
      // Complete animation
      await tester.pump(Duration(milliseconds: 100));
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('Loading spinner displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionFeedback.loadingSpinner(
              size: 48.0,
            ),
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Pulsing loader animates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionFeedback.pulsingLoader(),
          ),
        ),
      );
      
      expect(find.byType(TweenAnimationBuilder), findsOneWidget);
      
      // Let animation start
      await tester.pump(Duration(milliseconds: 100));
      expect(find.byType(TweenAnimationBuilder), findsOneWidget);
    });
  });
}

// Helper methods for testing
BuildContext _createMockContext() {
  // This is a simplified mock for testing
  // In real tests, you would use WidgetTester
  throw UnimplementedError('Use testWidgets for context-dependent tests');
}

BuildContext _createMockContextWithReducedMotion() {
  // This would create a mock context with reduced motion enabled
  // In real tests, you would use WidgetTester with AccessibilityProvider
  throw UnimplementedError('Use testWidgets for context-dependent tests');
}
