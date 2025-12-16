import 'package:flutter/material.dart';

/// Core design tokens for the Users Timeline application
/// Provides consistent spacing, typography, colors, and other design values
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ============================================================================
  // SPACING SCALE (8px base unit system)
  // ============================================================================
  
  /// 4px - Half unit spacing
  static const double space1 = 4.0;
  
  /// 8px - Base unit spacing (1x)
  static const double space2 = 8.0;
  
  /// 12px - Small spacing (1.5x)
  static const double space3 = 12.0;
  
  /// 16px - Medium spacing (2x)
  static const double space4 = 16.0;
  
  /// 20px - Medium-large spacing (2.5x)
  static const double space5 = 20.0;
  
  /// 24px - Large spacing (3x)
  static const double space6 = 24.0;
  
  /// 32px - Extra large spacing (4x)
  static const double space8 = 32.0;
  
  /// 40px - XXL spacing (5x)
  static const double space10 = 40.0;
  
  /// 48px - XXXL spacing (6x)
  static const double space12 = 48.0;
  
  /// 64px - Huge spacing (8x)
  static const double space16 = 64.0;

  // ============================================================================
  // TYPOGRAPHY SCALE
  // ============================================================================
  
  /// Display Large - 57px, for hero text and major headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  /// Display Medium - 45px, for large headings
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.16,
  );
  
  /// Display Small - 36px, for medium headings
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.22,
  );
  
  /// Headline Large - 32px, for section headings
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.25,
  );
  
  /// Headline Medium - 28px, for subsection headings
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.29,
  );
  
  /// Headline Small - 24px, for card titles
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.33,
  );
  
  /// Title Large - 22px, for prominent titles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    height: 1.27,
  );
  
  /// Title Medium - 16px, for standard titles
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  /// Title Small - 14px, for small titles
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  /// Body Large - 16px, for primary body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  /// Body Medium - 14px, for standard body text
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  /// Body Small - 12px, for secondary body text
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  /// Label Large - 14px, for prominent labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  /// Label Medium - 12px, for standard labels
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  /// Label Small - 11px, for small labels
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================================================
  // BORDER RADIUS SCALE
  // ============================================================================
  
  /// 4px - Extra small radius for small elements
  static const double radiusXSmall = 4.0;
  
  /// 8px - Small radius for buttons and small cards
  static const double radiusSmall = 8.0;
  
  /// 12px - Medium radius for cards and containers
  static const double radiusMedium = 12.0;
  
  /// 16px - Large radius for prominent cards
  static const double radiusLarge = 16.0;
  
  /// 24px - Extra large radius for hero elements
  static const double radiusXLarge = 24.0;
  
  /// 32px - XXL radius for special elements
  static const double radiusXXLarge = 32.0;

  // ============================================================================
  // ELEVATION SCALE
  // ============================================================================
  
  /// Level 0 - No elevation (flat surfaces)
  static const double elevation0 = 0.0;
  
  /// Level 1 - Subtle elevation for cards
  static const double elevation1 = 1.0;
  
  /// Level 2 - Standard elevation for interactive cards
  static const double elevation2 = 2.0;
  
  /// Level 3 - Elevated elements like FABs
  static const double elevation3 = 3.0;
  
  /// Level 4 - Navigation drawers and modal surfaces
  static const double elevation4 = 4.0;
  
  /// Level 6 - Modal dialogs and overlays
  static const double elevation6 = 6.0;
  
  /// Level 8 - Tooltips and snackbars
  static const double elevation8 = 8.0;
  
  /// Level 12 - App bars and top-level surfaces
  static const double elevation12 = 12.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  
  /// 75ms - Extra fast animations for immediate feedback
  static const Duration durationXFast = Duration(milliseconds: 75);
  
  /// 150ms - Fast animations for micro-interactions
  static const Duration durationFast = Duration(milliseconds: 150);
  
  /// 300ms - Medium animations for transitions
  static const Duration durationMedium = Duration(milliseconds: 300);
  
  /// 500ms - Slow animations for complex transitions
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  /// 700ms - Extra slow animations for dramatic effects
  static const Duration durationXSlow = Duration(milliseconds: 700);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================
  
  /// Standard easing for most animations
  static const Curve curveStandard = Curves.easeInOut;
  
  /// Decelerated easing for entering elements
  static const Curve curveDecelerate = Curves.easeOut;
  
  /// Accelerated easing for exiting elements
  static const Curve curveAccelerate = Curves.easeIn;
  
  /// Emphasized easing for important transitions
  static const Curve curveEmphasized = Curves.easeInOutCubic;
  
  /// Spring easing for playful interactions
  static const Curve curveSpring = Curves.elasticOut;

  // ============================================================================
  // BREAKPOINTS FOR RESPONSIVE DESIGN
  // ============================================================================
  
  /// Mobile breakpoint - up to 600px
  static const double breakpointMobile = 600.0;
  
  /// Tablet breakpoint - 600px to 1024px
  static const double breakpointTablet = 1024.0;
  
  /// Desktop breakpoint - 1024px and above
  static const double breakpointDesktop = 1440.0;
  
  /// Large desktop breakpoint - 1440px and above
  static const double breakpointLargeDesktop = 1920.0;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get responsive spacing based on screen width
  static double getResponsiveSpacing(double screenWidth, double baseSpacing) {
    if (screenWidth >= breakpointDesktop) {
      return baseSpacing * 1.25; // 25% larger on desktop
    } else if (screenWidth >= breakpointTablet) {
      return baseSpacing * 1.1; // 10% larger on tablet
    }
    return baseSpacing; // Base size on mobile
  }
  
  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(double screenWidth, double baseFontSize) {
    if (screenWidth >= breakpointDesktop) {
      return baseFontSize * 1.1; // 10% larger on desktop
    } else if (screenWidth >= breakpointTablet) {
      return baseFontSize * 1.05; // 5% larger on tablet
    }
    return baseFontSize; // Base size on mobile
  }
  
  /// Check if screen size is mobile
  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  
  /// Check if screen size is tablet
  static bool isTablet(double screenWidth) => 
      screenWidth >= breakpointMobile && screenWidth < breakpointTablet;
  
  /// Check if screen size is desktop
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointTablet;
  
  /// Check if screen size is large desktop
  static bool isLargeDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
}
