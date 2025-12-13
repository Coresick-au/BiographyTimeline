import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Responsive typography system that adapts to different screen sizes
/// and user preferences while maintaining visual hierarchy
class ResponsiveTypography {
  // Private constructor to prevent instantiation
  ResponsiveTypography._();

  // ===========================================================================
  // BREAKPOINTS
  // ===========================================================================
  
  /// Extra small screens (phones in portrait)
  static const double breakpointXS = 360.0;
  
  /// Small screens (large phones in portrait)
  static const double breakpointS = 600.0;
  
  /// Medium screens (tablets in portrait, large phones in landscape)
  static const double breakpointM = 840.0;
  
  /// Large screens (tablets in landscape, small desktops)
  static const double breakpointL = 1200.0;
  
  /// Extra large screens (desktops and large displays)
  static const double breakpointXL = 1600.0;

  // ===========================================================================
  // RESPONSIVE FONT SIZE FACTORS
  // ===========================================================================
  
  /// Font scale factors for different breakpoints
  static const Map<double, double> _fontScaleFactors = {
    breakpointXS: 0.85,
    breakpointS: 0.9,
    breakpointM: 1.0,
    breakpointL: 1.1,
    breakpointXL: 1.2,
  };

  // ===========================================================================
  // RESPONSIVE TEXT STYLES
  // ===========================================================================
  
  /// Get responsive display large style
  static TextStyle get displayLarge {
    return _getResponsiveTextStyle(DesignTokens.displayLarge);
  }
  
  /// Get responsive display medium style
  static TextStyle get displayMedium {
    return _getResponsiveTextStyle(DesignTokens.displayMedium);
  }
  
  /// Get responsive display small style
  static TextStyle get displaySmall {
    return _getResponsiveTextStyle(DesignTokens.displaySmall);
  }
  
  /// Get responsive headline large style
  static TextStyle get headlineLarge {
    return _getResponsiveTextStyle(DesignTokens.headlineLarge);
  }
  
  /// Get responsive headline medium style
  static TextStyle get headlineMedium {
    return _getResponsiveTextStyle(DesignTokens.headlineMedium);
  }
  
  /// Get responsive headline small style
  static TextStyle get headlineSmall {
    return _getResponsiveTextStyle(DesignTokens.headlineSmall);
  }
  
  /// Get responsive title large style
  static TextStyle get titleLarge {
    return _getResponsiveTextStyle(DesignTokens.titleLarge);
  }
  
  /// Get responsive title medium style
  static TextStyle get titleMedium {
    return _getResponsiveTextStyle(DesignTokens.titleMedium);
  }
  
  /// Get responsive title small style
  static TextStyle get titleSmall {
    return _getResponsiveTextStyle(DesignTokens.titleSmall);
  }
  
  /// Get responsive body large style
  static TextStyle get bodyLarge {
    return _getResponsiveTextStyle(DesignTokens.bodyLarge);
  }
  
  /// Get responsive body medium style
  static TextStyle get bodyMedium {
    return _getResponsiveTextStyle(DesignTokens.bodyMedium);
  }
  
  /// Get responsive body small style
  static TextStyle get bodySmall {
    return _getResponsiveTextStyle(DesignTokens.bodySmall);
  }
  
  /// Get responsive label large style
  static TextStyle get labelLarge {
    return _getResponsiveTextStyle(DesignTokens.labelLarge);
  }
  
  /// Get responsive label medium style
  static TextStyle get labelMedium {
    return _getResponsiveTextStyle(DesignTokens.labelMedium);
  }
  
  /// Get responsive label small style
  static TextStyle get labelSmall {
    return _getResponsiveTextStyle(DesignTokens.labelSmall);
  }

  // ===========================================================================
  // CONTEXT-SPECIFIC TYPOGRAPHY
  // ===========================================================================
  
  /// Typography for timeline event titles
  static TextStyle get eventTitle {
    return headlineLarge.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    );
  }
  
  /// Typography for timeline event dates
  static TextStyle get eventDate {
    return titleMedium.copyWith(
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
  }
  
  /// Typography for timeline event descriptions
  static TextStyle get eventDescription {
    return bodyLarge.copyWith(
      height: 1.6,
    );
  }
  
  /// Typography for milestone achievements
  static TextStyle get milestoneTitle {
    return displaySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.amber[700],
    );
  }
  
  /// Typography for media captions
  static TextStyle get mediaCaption {
    return bodySmall.copyWith(
      fontStyle: FontStyle.italic,
      color: Colors.grey[600],
    );
  }
  
  /// Typography for navigation labels
  static TextStyle get navigationLabel {
    return labelMedium.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }
  
  /// Typography for section headers
  static TextStyle get sectionHeader {
    return headlineMedium.copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Colors.grey[400],
      decorationThickness: 2.0,
    );
  }
  
  /// Typography for quotes
  static TextStyle get quote {
    return bodyLarge.copyWith(
      fontStyle: FontStyle.italic,
      height: 1.8,
      fontSize: bodyLarge.fontSize! * 1.1,
    );
  }
  
  /// Typography for code/monospace text
  static TextStyle get code {
    return bodyMedium.copyWith(
      fontFamily: 'monospace',
      backgroundColor: Colors.grey[200],
      fontSize: bodyMedium.fontSize! * 0.9,
    );
  }

  // ===========================================================================
  // ACCESSIBILITY TYPOGRAPHY
  // ===========================================================================
  
  /// Get text style with accessibility adjustments
  static TextStyle getAccessibleStyle(
    TextStyle baseStyle, {
    double textScaleFactor = 1.0,
    bool highContrast = false,
    bool increasedSpacing = false,
  }) {
    TextStyle adjustedStyle = baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * textScaleFactor,
      height: increasedSpacing ? (baseStyle.height ?? 1.0) * 1.5 : baseStyle.height,
    );
    
    if (highContrast) {
      adjustedStyle = adjustedStyle.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: (adjustedStyle.letterSpacing ?? 0) + 0.5,
      );
    }
    
    return adjustedStyle;
  }
  
  /// Get large print style for accessibility
  static TextStyle get largePrint {
    return getAccessibleStyle(
      bodyLarge,
      textScaleFactor: 1.3,
      increasedSpacing: true,
    );
  }
  
  /// Get high contrast style
  static TextStyle get highContrast {
    return getAccessibleStyle(
      bodyLarge,
      highContrast: true,
    );
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================
  
  /// Get responsive text style based on screen width
  static TextStyle _getResponsiveTextStyle(TextStyle baseStyle) {
    final context = _getCurrentContext();
    if (context == null) return baseStyle;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = _getFontScaleFactor(screenWidth);
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * scaleFactor,
      letterSpacing: baseStyle.letterSpacing != null 
          ? baseStyle.letterSpacing! * scaleFactor 
          : null,
      height: baseStyle.height,
    );
  }
  
  /// Get font scale factor for screen width
  static double _getFontScaleFactor(double screenWidth) {
    final sortedBreakpoints = _fontScaleFactors.keys.toList()..sort();
    
    for (int i = sortedBreakpoints.length - 1; i >= 0; i--) {
      final breakpoint = sortedBreakpoints[i];
      if (screenWidth >= breakpoint) {
        return _fontScaleFactors[breakpoint] ?? 1.0;
      }
    }
    
    return _fontScaleFactors[breakpointXS] ?? 0.85;
  }
  
  /// Get current build context (for responsive calculations)
  static BuildContext? _currentContext;
  
  /// Set the current context for responsive calculations
  static void setCurrentContext(BuildContext context) {
    _currentContext = context;
  }
  
  /// Get the current context
  static BuildContext? get _getCurrentContext => _currentContext;
  
  /// Clear the current context
  static void clearCurrentContext() {
    _currentContext = null;
  }
  
  /// Create a responsive text widget
  static Widget responsiveText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Builder(
      builder: (context) {
        setCurrentContext(context);
        final responsiveStyle = style ?? bodyLarge;
        return Text(
          text,
          style: responsiveStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
  
  /// Create a responsive heading widget
  static Widget responsiveHeading(
    String text, {
    required HeadingLevel level,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Builder(
      builder: (context) {
        setCurrentContext(context);
        TextStyle style;
        
        switch (level) {
          case HeadingLevel.h1:
            style = displayLarge;
            break;
          case HeadingLevel.h2:
            style = displayMedium;
            break;
          case HeadingLevel.h3:
            style = displaySmall;
            break;
          case HeadingLevel.h4:
            style = headlineLarge;
            break;
          case HeadingLevel.h5:
            style = headlineMedium;
            break;
          case HeadingLevel.h6:
            style = headlineSmall;
            break;
        }
        
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Heading levels for semantic hierarchy
enum HeadingLevel {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
}

/// Widget that provides responsive typography to its children
class ResponsiveTypographyProvider extends StatelessWidget {
  final Widget child;
  
  const ResponsiveTypographyProvider({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ResponsiveTypography.setCurrentContext(context);
        return child;
      },
    );
  }
}

/// Extension on TextStyle for responsive adjustments
extension TextStyleExtension on TextStyle {
  /// Apply responsive scaling
  TextStyle responsive({BuildContext? context}) {
    if (context != null) {
      ResponsiveTypography.setCurrentContext(context);
    }
    return ResponsiveTypography._getResponsiveTextStyle(this);
  }
  
  /// Apply accessibility adjustments
  TextStyle accessible({
    double textScaleFactor = 1.0,
    bool highContrast = false,
    bool increasedSpacing = false,
  }) {
    return ResponsiveTypography.getAccessibleStyle(
      this,
      textScaleFactor: textScaleFactor,
      highContrast: highContrast,
      increasedSpacing: increasedSpacing,
    );
  }
  
  /// Adjust for dark mode
  TextStyle darkMode() {
    return copyWith(
      color: color?.withOpacity(0.87),
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }
  
  /// Adjust for sepia theme
  TextStyle sepia() {
    return copyWith(
      color: Color(0xFF5C4033),
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }
}
