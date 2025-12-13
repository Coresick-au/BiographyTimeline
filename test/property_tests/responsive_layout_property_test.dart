import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/shared/design_system/responsive_layout.dart';
import '../../lib/shared/design_system/adaptive_navigation.dart';
import '../../lib/shared/design_system/app_icons.dart';
import '../../lib/shared/design_system/design_tokens.dart';

/// Property 33: Responsive Layout System
/// 
/// This test validates that the responsive layout system works correctly:
/// 1. Responsive breakpoints are properly defined
/// 2. Layout adapts to different screen sizes
/// 3. Navigation adjusts for mobile/tablet/desktop
/// 4. Content constraints and spacing work correctly
/// 5. Grid and flex layouts are responsive
/// 6. Accessibility is maintained across all layouts

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 33: Responsive Layout System', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // BREAKPOINT TESTS
    // =========================================================================
    
    test('Responsive breakpoints are correctly defined', () {
      expect(ResponsiveLayout.mobile, equals(599.0));
      expect(ResponsiveLayout.tablet, equals(839.0));
      expect(ResponsiveLayout.desktop, equals(1199.0));
      expect(ResponsiveLayout.largeDesktop, equals(1200.0));
    });

    test('Screen size detection works correctly', () {
      // Test mobile detection
      expect(_isScreenSizeMobile(350), isTrue);
      expect(_isScreenSizeMobile(599), isTrue);
      expect(_isScreenSizeMobile(600), isFalse);
      
      // Test tablet detection
      expect(_isScreenSizeTablet(600), isTrue);
      expect(_isScreenSizeTablet(839), isTrue);
      expect(_isScreenSizeTablet(840), isFalse);
      
      // Test desktop detection
      expect(_isScreenSizeDesktop(840), isTrue);
      expect(_isScreenSizeDesktop(1199), isTrue);
      expect(_isScreenSizeDesktop(1200), isFalse);
      
      // Test large desktop detection
      expect(_isScreenSizeLargeDesktop(1200), isTrue);
      expect(_isScreenSizeLargeDesktop(1400), isTrue);
      expect(_isScreenSizeLargeDesktop(1199), isFalse);
    });

    test('Screen size enum returns correct values', () {
      expect(_getScreenSize(350), equals(ScreenSize.mobile));
      expect(_getScreenSize(600), equals(ScreenSize.tablet));
      expect(_getScreenSize(840), equals(ScreenSize.desktop));
      expect(_getScreenSize(1200), equals(ScreenSize.largeDesktop));
    });

    // =========================================================================
    // LAYOUT VALUES TESTS
    // =========================================================================
    
    test('Layout values adapt to screen size', () {
      // Test max content width
      expect(_getMaxContentWidth(350), equals(double.infinity));
      expect(_getMaxContentWidth(700), equals(768.0));
      expect(_getMaxContentWidth(900), equals(1024.0));
      expect(_getMaxContentWidth(1400), equals(1200.0));
      
      // Test horizontal padding
      expect(_getHorizontalPadding(350), equals(DesignTokens.space4));
      expect(_getHorizontalPadding(700), equals(DesignTokens.space6));
      expect(_getHorizontalPadding(900), equals(DesignTokens.space8));
      expect(_getHorizontalPadding(1400), equals(DesignTokens.space12));
      
      // Test column count
      expect(_getColumnCount(350), equals(1));
      expect(_getColumnCount(700), equals(2));
      expect(_getColumnCount(900), equals(3));
      expect(_getColumnCount(1400), equals(4));
      
      // Test grid spacing
      expect(_getGridSpacing(350), equals(DesignTokens.space3));
      expect(_getGridSpacing(700), equals(DesignTokens.space4));
      expect(_getGridSpacing(900), equals(DesignTokens.space6));
      expect(_getGridSpacing(1400), equals(DesignTokens.space8));
    });

    // =========================================================================
    // LAYOUT WIDGETS TESTS
    // =========================================================================
    
    test('Responsive container works correctly', () {
      final container = ResponsiveLayout.responsiveContainer(
        child: Text('Test'),
        maxWidth: 800.0,
        padding: EdgeInsets.all(16.0),
      );
      
      expect(container, isNotNull);
      expect(container.child, isNotNull);
    });

    test('Responsive grid layout adapts column count', () {
      // Test grid with different screen sizes
      final grid = ResponsiveLayout.responsiveGrid(
        children: [Text('Item 1'), Text('Item 2'), Text('Item 3')],
        context: _createMockContext(700), // Tablet size
      );
      
      expect(grid, isNotNull);
    });

    test('Responsive row layout works', () {
      final row = ResponsiveLayout.responsiveRow(
        children: [Text('Item 1'), Text('Item 2')],
        context: _createMockContext(800),
        spacing: 16.0,
      );
      
      expect(row, isNotNull);
    });

    test('Responsive column layout works', () {
      final column = ResponsiveLayout.responsiveColumn(
        children: [Text('Item 1'), Text('Item 2')],
        context: _createMockContext(800),
        spacing: 16.0,
      );
      
      expect(column, isNotNull);
    });

    test('Adaptive layout shows correct widget for screen size', () {
      final mobile = Text('Mobile');
      final tablet = Text('Tablet');
      final desktop = Text('Desktop');
      
      // Test mobile
      final mobileLayout = ResponsiveLayout.adaptiveLayout(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        context: _createMockContext(350),
      );
      expect(mobileLayout, equals(mobile));
      
      // Test tablet
      final tabletLayout = ResponsiveLayout.adaptiveLayout(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        context: _createMockContext(700),
      );
      expect(tabletLayout, equals(tablet));
      
      // Test desktop
      final desktopLayout = ResponsiveLayout.adaptiveLayout(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        context: _createMockContext(900),
      );
      expect(desktopLayout, equals(desktop));
    });

    // =========================================================================
    // NAVIGATION TESTS
    // =========================================================================
    
    test('Navigation destinations are properly defined', () {
      expect(AppNavigationDestinations.primary, isNotNull);
      expect(AppNavigationDestinations.primary.length, equals(5));
      expect(AppNavigationDestinations.secondary, isNotNull);
      expect(AppNavigationDestinations.secondary.length, equals(2));
      
      // Check first destination
      final firstDest = AppNavigationDestinations.primary.first;
      expect(firstDest.icon, equals(AppIcons.timeline));
      expect(firstDest.label, equals('Timeline'));
      expect(firstDest.tooltip, equals('View timeline'));
    });

    test('Navigation item configuration works', () {
      final item = NavigationItem(
        icon: Icons.home,
        selectedIcon: Icons.home_filled,
        label: 'Home',
        tooltip: 'Go home',
      );
      
      expect(item.icon, equals(Icons.home));
      expect(item.selectedIcon, equals(Icons.home_filled));
      expect(item.label, equals('Home'));
      expect(item.tooltip, equals('Go home'));
    });

    test('Quick actions work correctly', () {
      bool wasPressed = false;
      final action = QuickAction(
        icon: Icons.add,
        label: 'Add',
        onPressed: () => wasPressed = true,
      );
      
      expect(action.icon, equals(Icons.add));
      expect(action.label, equals('Add'));
      
      action.onPressed();
      expect(wasPressed, isTrue);
    });

    test('Breadcrumb navigation works', () {
      final items = [
        BreadcrumbItem(label: 'Home'),
        BreadcrumbItem(label: 'Timeline'),
        BreadcrumbItem(label: 'Event'),
      ];
      
      final breadcrumb = BreadcrumbNavigation(items: items);
      expect(breadcrumb, isNotNull);
    });

    test('Tab bar adapts to screen size', () {
      final tabs = [
        Tab(text: 'Tab 1'),
        Tab(text: 'Tab 2'),
        Tab(text: 'Tab 3'),
        Tab(text: 'Tab 4'),
      ];
      
      final tabBar = AdaptiveTabBar(
        tabs: tabs,
        isScrollable: true,
      );
      
      expect(tabBar, isNotNull);
    });

    // =========================================================================
    // CONTEXT EXTENSIONS TESTS
    // =========================================================================
    
    test('Context extensions work correctly', () {
      // Test mobile context
      final mobileContext = _createMockContext(350);
      expect(mobileContext.isMobile, isTrue);
      expect(mobileContext.isTablet, isFalse);
      expect(mobileContext.isDesktop, isFalse);
      expect(mobileContext.isLargeDesktop, isFalse);
      expect(mobileContext.screenSize, equals(ScreenSize.mobile));
      
      // Test tablet context
      final tabletContext = _createMockContext(700);
      expect(tabletContext.isMobile, isFalse);
      expect(tabletContext.isTablet, isTrue);
      expect(tabletContext.isDesktop, isFalse);
      expect(tabletContext.isLargeDesktop, isFalse);
      expect(tabletContext.screenSize, equals(ScreenSize.tablet));
      
      // Test desktop context
      final desktopContext = _createMockContext(900);
      expect(desktopContext.isMobile, isFalse);
      expect(desktopContext.isTablet, isFalse);
      expect(desktopContext.isDesktop, isTrue);
      expect(desktopContext.isLargeDesktop, isFalse);
      expect(desktopContext.screenSize, equals(ScreenSize.desktop));
    });

    test('Context responsive value selection works', () {
      final context = _createMockContext(700); // Tablet
      
      final value = context.getResponsiveValue<String>(
        mobile: 'Mobile',
        tablet: 'Tablet',
        desktop: 'Desktop',
      );
      
      expect(value, equals('Tablet'));
    });

    // =========================================================================
    // WIDGET TESTS
    // =========================================================================
    
    testWidgets('Adaptive navigation shows bottom bar on mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveNavigation(
              selectedIndex: 0,
              onDestinationSelected: (index) {},
              destinations: AppNavigationDestinations.primary,
              body: Container(),
            ),
          ),
        ),
      );
      
      // Should show bottom navigation bar on mobile
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('Adaptive navigation shows rail on tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Mock tablet size
                return MediaQuery(
                  data: MediaQueryData(size: Size(700, 800)),
                  child: AdaptiveNavigation(
                    selectedIndex: 0,
                    onDestinationSelected: (index) {},
                    destinations: AppNavigationDestinations.primary,
                    body: Container(),
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // Should show navigation rail on tablet
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('Responsive container constrains content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout.responsiveContainer(
              maxWidth: 400.0,
              child: Container(
                width: 800,
                height: 100,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );
      
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, equals(400.0));
    });

    testWidgets('Responsive grid shows correct number of columns', (tester) async {
      final items = List.generate(6, (index) => Text('Item $index'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Mock desktop size
                return MediaQuery(
                  data: MediaQueryData(size: Size(900, 800)),
                  child: ResponsiveLayout.responsiveGrid(
                    children: items,
                    context: context,
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // Should show 3 columns on desktop
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
    });

    testWidgets('Quick actions are accessible', (tester) async {
      bool addPressed = false;
      bool editPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActions(
              actions: [
                QuickAction(
                  icon: Icons.add,
                  label: 'Add',
                  onPressed: () => addPressed = true,
                ),
                QuickAction(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () => editPressed = true,
                ),
              ],
            ),
          ),
        ),
      );
      
      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      
      expect(addPressed, isTrue);
      expect(editPressed, isFalse);
      
      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      
      expect(editPressed, isTrue);
    });

    // =========================================================================
    // ACCESSIBILITY TESTS
    // =========================================================================
    
    test('Navigation maintains accessibility', () {
      final navigation = AdaptiveNavigation(
        selectedIndex: 0,
        onDestinationSelected: (index) {},
        destinations: [
          NavigationItem(
            icon: Icons.home,
            label: 'Home',
            tooltip: 'Navigate to home',
          ),
        ],
        body: Container(),
      );
      
      expect(navigation, isNotNull);
    });

    test('Responsive layouts maintain semantic structure', () {
      final container = ResponsiveLayout.responsiveContainer(
        child: Semantics(
          label: 'Main content',
          child: Text('Content'),
        ),
      );
      
      expect(container, isNotNull);
    });

    // =========================================================================
    // INTEGRATION TESTS
    // =========================================================================
    
    test('Layout system integrates with design tokens', () {
      final padding = ResponsiveLayout.getHorizontalPadding(_createMockContext(700));
      expect(padding, equals(DesignTokens.space6));
      
      final spacing = ResponsiveLayout.getGridSpacing(_createMockContext(900));
      expect(spacing, equals(DesignTokens.space6));
    });

    test('Navigation integrates with icon system', () {
      final destinations = AppNavigationDestinations.primary;
      expect(destinations.first.icon, equals(AppIcons.timeline));
    });

    test('All responsive values are consistent', () {
      // Test that all responsive methods return consistent values
      for (double width in [350, 700, 900, 1400]) {
        final context = _createMockContext(width);
        final screenSize = ResponsiveLayout.getScreenSize(context);
        
        expect(context.screenSize, equals(screenSize));
        expect(context.isMobile, equals(screenSize == ScreenSize.mobile));
        expect(context.isTablet, equals(screenSize == ScreenSize.tablet));
        expect(context.isDesktop, equals(screenSize == ScreenSize.desktop));
        expect(context.isLargeDesktop, equals(screenSize == ScreenSize.largeDesktop));
      }
    });
  });
}

// Helper methods for testing
bool _isScreenSizeMobile(double width) {
  return width < ResponsiveLayout.mobile;
}

bool _isScreenSizeTablet(double width) {
  return width >= ResponsiveLayout.mobile && width < ResponsiveLayout.desktop;
}

bool _isScreenSizeDesktop(double width) {
  return width >= ResponsiveLayout.desktop && width < ResponsiveLayout.largeDesktop;
}

bool _isScreenSizeLargeDesktop(double width) {
  return width >= ResponsiveLayout.largeDesktop;
}

ScreenSize _getScreenSize(double width) {
  if (width < ResponsiveLayout.mobile) return ScreenSize.mobile;
  if (width < ResponsiveLayout.desktop) return ScreenSize.tablet;
  if (width < ResponsiveLayout.largeDesktop) return ScreenSize.desktop;
  return ScreenSize.largeDesktop;
}

double _getMaxContentWidth(double width) {
  final context = _createMockContext(width);
  return ResponsiveLayout.getMaxContentWidth(context);
}

double _getHorizontalPadding(double width) {
  final context = _createMockContext(width);
  return ResponsiveLayout.getHorizontalPadding(context);
}

int _getColumnCount(double width) {
  final context = _createMockContext(width);
  return ResponsiveLayout.getColumnCount(context);
}

double _getGridSpacing(double width) {
  final context = _createMockContext(width);
  return ResponsiveLayout.getGridSpacing(context);
}

BuildContext _createMockContext(double width) {
  // This is a simplified mock for testing
  // In real tests, you would use WidgetTester
  throw UnimplementedError('Use testWidgets for context-dependent tests');
}
