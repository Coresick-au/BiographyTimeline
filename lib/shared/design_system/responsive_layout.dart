import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Responsive layout system that adapts to different screen sizes
/// Provides consistent breakpoints and layout patterns
class ResponsiveLayout {
  // Private constructor to prevent instantiation
  ResponsiveLayout._();

  // ===========================================================================
  // BREAKPOINTS
  // ===========================================================================
  
  /// Mobile portrait (up to 599px)
  static const double mobile = 599.0;
  
  /// Mobile landscape and tablet portrait (600px to 839px)
  static const double tablet = 839.0;
  
  /// Tablet landscape and small desktop (840px to 1199px)
  static const double desktop = 1199.0;
  
  /// Large desktop and above (1200px and up)
  static const double largeDesktop = 1200.0;

  // ===========================================================================
  // SCREEN SIZE DETECTION
  // ===========================================================================
  
  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }
  
  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= desktop && width < largeDesktop;
  }
  
  /// Check if screen is large desktop size
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }
  
  /// Get screen size type
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobile) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    if (width < largeDesktop) return ScreenSize.desktop;
    return ScreenSize.largeDesktop;
  }

  // ===========================================================================
  // LAYOUT VALUES
  // ===========================================================================
  
  /// Get maximum content width for current screen size
  static double getMaxContentWidth(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 768.0;
      case ScreenSize.desktop:
        return 1024.0;
      case ScreenSize.largeDesktop:
        return 1200.0;
    }
  }
  
  /// Get horizontal padding for current screen size
  static double getHorizontalPadding(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return DesignTokens.space4;
      case ScreenSize.tablet:
        return DesignTokens.space6;
      case ScreenSize.desktop:
        return DesignTokens.space8;
      case ScreenSize.largeDesktop:
        return DesignTokens.space12;
    }
  }
  
  /// Get number of columns for grid layout
  static int getColumnCount(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return 1;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.desktop:
        return 3;
      case ScreenSize.largeDesktop:
        return 4;
    }
  }
  
  /// Get spacing between grid items
  static double getGridSpacing(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return DesignTokens.space3;
      case ScreenSize.tablet:
        return DesignTokens.space4;
      case ScreenSize.desktop:
        return DesignTokens.space6;
      case ScreenSize.largeDesktop:
        return DesignTokens.space8;
    }
  }

  // ===========================================================================
  // LAYOUT WIDGETS
  // ===========================================================================
  
  /// Responsive container that constrains width and applies padding
  static Widget responsiveContainer({
    required Widget child,
    BuildContext? context,
    double? maxWidth,
    EdgeInsets? padding,
    Alignment alignment = Alignment.topCenter,
  }) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? (context != null ? getMaxContentWidth(context) : double.infinity),
        ),
        child: Padding(
          padding: padding ?? (context != null ? 
            EdgeInsets.symmetric(horizontal: getHorizontalPadding(context)) : 
            EdgeInsets.all(DesignTokens.space4)),
          child: child,
        ),
      ),
    );
  }
  
  /// Responsive grid layout
  static Widget responsiveGrid({
    required List<Widget> children,
    required BuildContext context,
    int? columnCount,
    double? spacing,
    double? runSpacing,
    EdgeInsets? padding,
  }) {
    final columns = columnCount ?? getColumnCount(context);
    final itemSpacing = spacing ?? getGridSpacing(context);
    final itemRunSpacing = runSpacing ?? spacing ?? itemSpacing;
    
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: getHorizontalPadding(context)),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: itemSpacing,
          mainAxisSpacing: itemRunSpacing,
          childAspectRatio: 1.0,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
  
  /// Responsive row layout
  static Widget responsiveRow({
    required List<Widget> children,
    required BuildContext context,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double? spacing,
  }) {
    final itemSpacing = spacing ?? DesignTokens.space4;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getHorizontalPadding(context)),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, itemSpacing),
      ),
    );
  }
  
  /// Responsive column layout
  static Widget responsiveColumn({
    required List<Widget> children,
    required BuildContext context,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double? spacing,
  }) {
    final itemSpacing = spacing ?? DesignTokens.space3;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getHorizontalPadding(context)),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, itemSpacing, isVertical: true),
      ),
    );
  }
  
  /// Responsive stack layout
  static Widget responsiveStack({
    required List<Widget> children,
    required BuildContext context,
    Alignment alignment = Alignment.center,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: getHorizontalPadding(context)),
      child: Stack(
        alignment: alignment,
        children: children,
      ),
    );
  }

  // ===========================================================================
  // ADAPTIVE WIDGETS
  // ===========================================================================
  
  /// Widget that shows different children based on screen size
  static Widget adaptiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
    required BuildContext context,
  }) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
  
  /// Responsive navigation rail or bottom navigation
  static Widget adaptiveNavigation({
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    required List<NavigationDestination> destinations,
    required BuildContext context,
    Color? backgroundColor,
  }) {
    if (isMobile(context)) {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        backgroundColor: backgroundColor,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      );
    } else {
      // Convert NavigationDestination to NavigationRailDestination
      final railDestinations = destinations.map((dest) => 
        NavigationRailDestination(
          icon: dest.icon,
          selectedIcon: dest.selectedIcon,
          label: Text(dest.label),
        )
      ).toList();
      
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: railDestinations,
        backgroundColor: backgroundColor,
        extended: isDesktop(context) || isLargeDesktop(context),
      );
    }
  }
  
  /// Responsive app bar
  static PreferredSizeWidget adaptiveAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    BuildContext? context,
    double? elevation,
  }) {
    if (context != null && !isMobile(context)) {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        elevation: elevation ?? DesignTokens.elevation0,
        titleSpacing: DesignTokens.space6,
        toolbarHeight: 64.0,
      );
    }
    
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation ?? DesignTokens.elevation0,
    );
  }
  
  /// Responsive drawer
  static Widget adaptiveDrawer({
    required Widget child,
    required BuildContext context,
    double? width,
    EdgeInsets? padding,
  }) {
    final drawerWidth = width ?? (isTablet(context) ? 320.0 : 280.0);
    
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: Padding(
          padding: padding ?? EdgeInsets.all(DesignTokens.space4),
          child: child,
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================
  
  /// Add spacing between widgets
  static List<Widget> _addSpacing(List<Widget> children, double spacing, {bool isVertical = false}) {
    if (children.isEmpty) return [];
    
    final List<Widget> spacedChildren = [];
    
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      
      if (i < children.length - 1) {
        spacedChildren.add(
          isVertical ? SizedBox(height: spacing) : SizedBox(width: spacing)
        );
      }
    }
    
    return spacedChildren;
  }
  
  /// Get value based on screen size
  static T getValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
    required BuildContext context,
  }) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
  
  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: DesignTokens.space4,
    );
  }
  
  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: DesignTokens.space4,
    );
  }
}

/// Enum for screen size types
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveContextExtension on BuildContext {
  /// Check if screen is mobile
  bool get isMobile => ResponsiveLayout.isMobile(this);
  
  /// Check if screen is tablet
  bool get isTablet => ResponsiveLayout.isTablet(this);
  
  /// Check if screen is desktop
  bool get isDesktop => ResponsiveLayout.isDesktop(this);
  
  /// Check if screen is large desktop
  bool get isLargeDesktop => ResponsiveLayout.isLargeDesktop(this);
  
  /// Get screen size type
  ScreenSize get screenSize => ResponsiveLayout.getScreenSize(this);
  
  /// Get max content width
  double get maxContentWidth => ResponsiveLayout.getMaxContentWidth(this);
  
  /// Get horizontal padding
  double get horizontalPadding => ResponsiveLayout.getHorizontalPadding(this);
  
  /// Get column count
  int get columnCount => ResponsiveLayout.getColumnCount(this);
  
  /// Get grid spacing
  double get gridSpacing => ResponsiveLayout.getGridSpacing(this);
  
  /// Get responsive margin
  EdgeInsets get responsiveMargin => ResponsiveLayout.getResponsiveMargin(this);
  
  /// Get responsive padding
  EdgeInsets get responsivePadding => ResponsiveLayout.getResponsivePadding(this);
  
  /// Get value based on screen size
  T getResponsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    return ResponsiveLayout.getValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
      context: this,
    );
  }
}

/// Widget that provides responsive layout to its children
class ResponsiveLayoutProvider extends StatelessWidget {
  final Widget child;
  
  const ResponsiveLayoutProvider({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return child;
      },
    );
  }
}
