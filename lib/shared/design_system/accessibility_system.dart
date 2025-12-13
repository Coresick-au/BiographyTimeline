import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'responsive_typography.dart';

/// Accessibility system for the Timeline Biography app
/// Provides comprehensive support for different user preferences and needs
class AccessibilitySystem {
  // Private constructor to prevent instantiation
  AccessibilitySystem._();

  // ===========================================================================
  // ACCESSIBILITY PROVIDERS
  // ===========================================================================
  
  /// Provider for text scale factor
  static final textScaleFactorProvider = StateProvider<double>((ref) => 1.0);
  
  /// Provider for high contrast mode
  static final highContrastProvider = StateProvider<bool>((ref) => false);
  
  /// Provider for reduced motion
  static final reducedMotionProvider = StateProvider<bool>((ref) => false);
  
  /// Provider for screen reader support
  static final screenReaderProvider = StateProvider<bool>((ref) => false);
  
  /// Provider for large print mode
  static final largePrintProvider = StateProvider<bool>((ref) => false);
  
  /// Provider for increased spacing
  static final increasedSpacingProvider = StateProvider<bool>((ref) => false);
  
  /// Provider for color blind friendly mode
  static final colorBlindFriendlyProvider = StateProvider<bool>((ref) => false);

  // ===========================================================================
  // ACCESSIBILITY CONFIGURATION
  // ===========================================================================
  
  /// Complete accessibility configuration
  class AccessibilityConfig {
    final double textScaleFactor;
    final bool highContrast;
    final bool reducedMotion;
    final bool screenReader;
    final bool largePrint;
    final bool increasedSpacing;
    final bool colorBlindFriendly;
    
    const AccessibilityConfig({
      this.textScaleFactor = 1.0,
      this.highContrast = false,
      this.reducedMotion = false,
      this.screenReader = false,
      this.largePrint = false,
      this.increasedSpacing = false,
      this.colorBlindFriendly = false,
    });
    
    /// Create a copy with updated values
    AccessibilityConfig copyWith({
      double? textScaleFactor,
      bool? highContrast,
      bool? reducedMotion,
      bool? screenReader,
      bool? largePrint,
      bool? increasedSpacing,
      bool? colorBlindFriendly,
    }) {
      return AccessibilityConfig(
        textScaleFactor: textScaleFactor ?? this.textScaleFactor,
        highContrast: highContrast ?? this.highContrast,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        screenReader: screenReader ?? this.screenReader,
        largePrint: largePrint ?? this.largePrint,
        increasedSpacing: increasedSpacing ?? this.increasedSpacing,
        colorBlindFriendly: colorBlindFriendly ?? this.colorBlindFriendly,
      );
    }
    
    /// Convert to map for persistence
    Map<String, dynamic> toMap() {
      return {
        'textScaleFactor': textScaleFactor,
        'highContrast': highContrast,
        'reducedMotion': reducedMotion,
        'screenReader': screenReader,
        'largePrint': largePrint,
        'increasedSpacing': increasedSpacing,
        'colorBlindFriendly': colorBlindFriendly,
      };
    }
    
    /// Create from map
    factory AccessibilityConfig.fromMap(Map<String, dynamic> map) {
      return AccessibilityConfig(
        textScaleFactor: map['textScaleFactor']?.toDouble() ?? 1.0,
        highContrast: map['highContrast'] ?? false,
        reducedMotion: map['reducedMotion'] ?? false,
        screenReader: map['screenReader'] ?? false,
        largePrint: map['largePrint'] ?? false,
        increasedSpacing: map['increasedSpacing'] ?? false,
        colorBlindFriendly: map['colorBlindFriendly'] ?? false,
      );
    }
  }

  // ===========================================================================
  // SCREEN SIZE ADAPTATIONS
  // ===========================================================================
  
  /// Get accessibility adjustments for screen size
  static AccessibilityConfig getScreenSizeAdjustments(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    // Adjust for very small screens
    if (width < 360) {
      return AccessibilityConfig(
        textScaleFactor: 0.9,
        increasedSpacing: false, // Less spacing on small screens
      );
    }
    
    // Adjust for very large screens
    if (width > 1200) {
      return AccessibilityConfig(
        textScaleFactor: 1.1,
        increasedSpacing: true,
      );
    }
    
    // Default adjustments
    return const AccessibilityConfig();
  }
  
  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = size.width * size.width + size.height * size.height;
    return diagonal > 900000; // Rough tablet detection
  }
  
  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // ===========================================================================
  // COLOR ADAPTATIONS
  // ===========================================================================
  
  /// Get color blind friendly color scheme
  static ColorScheme getColorBlindFriendlyScheme(ColorScheme baseScheme) {
    return baseScheme.copyWith(
      primary: _adjustForColorBlindness(baseScheme.primary),
      secondary: _adjustForColorBlindness(baseScheme.secondary),
      tertiary: _adjustForColorBlindness(baseScheme.tertiary),
      error: Colors.red.shade700, // Use standard red for errors
      surface: baseScheme.brightness == Brightness.dark 
          ? Colors.grey.shade800 
          : Colors.grey.shade100,
    );
  }
  
  /// Adjust color for color blindness
  static Color _adjustForColorBlindness(Color color) {
    // Simple conversion to ensure sufficient contrast
    final hsl = HSLColor.fromColor(color);
    
    // Adjust hue to avoid problematic colors
    double adjustedHue = hsl.hue;
    
    // Avoid red-green combinations
    if ((adjustedHue >= 0 && adjustedHue <= 60) || 
        (adjustedHue >= 120 && adjustedHue <= 180)) {
      adjustedHue = 210; // Shift to blue
    }
    
    // Ensure sufficient saturation
    final adjustedSaturation = hsl.saturation < 0.3 ? 0.5 : hsl.saturation;
    
    // Ensure sufficient lightness for contrast
    final adjustedLightness = hsl.lightness < 0.3 ? 0.3 : 
                             hsl.lightness > 0.7 ? 0.7 : hsl.lightness;
    
    return hsl.withHue(adjustedHue)
              .withSaturation(adjustedSaturation)
              .withLightness(adjustedLightness)
              .toColor();
  }
  
  /// Get high contrast color scheme
  static ColorScheme getHighContrastScheme(ColorScheme baseScheme) {
    if (baseScheme.brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        tertiary: Colors.yellow,
        onTertiary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        background: Colors.black,
        onBackground: Colors.white,
        error: Colors.red.shade400,
        onError: Colors.black,
      );
    } else {
      return ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        tertiary: Colors.black,
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
        error: Colors.red.shade700,
        onError: Colors.white,
      );
    }
  }

  // ===========================================================================
  // MOTION ADAPTATIONS
  // ===========================================================================
  
  /// Get animation duration with reduced motion consideration
  static Duration getAnimationDuration(
    Duration baseDuration, 
    bool reducedMotion,
  ) {
    if (reducedMotion) {
      return Duration.zero;
    }
    return baseDuration;
  }
  
  /// Get curve with reduced motion consideration
  static Curve getAnimationCurve(bool reducedMotion) {
    if (reducedMotion) {
      return Curves.linear;
    }
    return Curves.easeInOut;
  }
  
  /// Create animated widget with motion considerations
  static Widget createAccessibleAnimation({
    required Widget child,
    required Animation<double> animation,
    bool reducedMotion = false,
    Curve? curve,
    Duration? duration,
  }) {
    if (reducedMotion) {
      return child;
    }
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return child;
      },
    );
  }

  // ===========================================================================
  // SEMANTIC WIDGETS
  // ===========================================================================
  
  /// Create accessible button with proper semantics
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
    String? tooltip,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? tooltip,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: child,
        ),
      ),
    );
  }
  
  /// Create accessible text field with proper semantics
  static Widget accessibleTextField({
    required TextEditingController controller,
    String? label,
    String? hint,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
  
  /// Create accessible image with proper semantics
  static Widget accessibleImage({
    required ImageProvider image,
    String? semanticLabel,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  // ===========================================================================
  // ACCESSIBILITY WIDGET
  // ===========================================================================
  
  /// Widget that provides accessibility settings to its descendants
  class AccessibilityProvider extends ConsumerWidget {
    final Widget child;
    final AccessibilityConfig? config;
    
    const AccessibilityProvider({
      Key? key,
      required this.child,
      this.config,
    }) : super(key: key);
    
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final currentConfig = config ?? _getCurrentConfig(ref);
      
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          accessibleNavigation: currentConfig.screenReader,
          disableAnimations: currentConfig.reducedMotion,
          highContrast: currentConfig.highContrast,
        ),
        child: _AccessibilityInheritedWidget(
          config: currentConfig,
          child: child,
        ),
      );
    }
    
    AccessibilityConfig _getCurrentConfig(WidgetRef ref) {
      return AccessibilityConfig(
        textScaleFactor: ref.watch(textScaleFactorProvider),
        highContrast: ref.watch(highContrastProvider),
        reducedMotion: ref.watch(reducedMotionProvider),
        screenReader: ref.watch(screenReaderProvider),
        largePrint: ref.watch(largePrintProvider),
        increasedSpacing: ref.watch(increasedSpacingProvider),
        colorBlindFriendly: ref.watch(colorBlindFriendlyProvider),
      );
    }
  }
  
  /// Inherited widget for accessibility configuration
  static class _AccessibilityInheritedWidget extends InheritedWidget {
    final AccessibilityConfig config;
    
    const _AccessibilityInheritedWidget({
      Key? key,
      required this.config,
      required Widget child,
    }) : super(key: key, child: child);
    
    static _AccessibilityInheritedWidget? of(BuildContext context) {
      return context.dependOnInheritedWidgetOfExactType<_AccessibilityInheritedWidget>();
    }
    
    @override
    bool updateShouldNotify(_AccessibilityInheritedWidget oldWidget) {
      return config != oldWidget.config;
    }
  }
  
  /// Get current accessibility configuration
  static AccessibilityConfig? getCurrentConfig(BuildContext context) {
    return _AccessibilityInheritedWidget.of(context)?.config;
  }
}

/// Extension on BuildContext for accessibility helpers
extension AccessibilityContextExtension on BuildContext {
  /// Get current accessibility configuration
  AccessibilityConfig? get accessibilityConfig {
    return AccessibilitySystem.getCurrentConfig(this);
  }
  
  /// Check if high contrast is enabled
  bool get isHighContrast {
    return accessibilityConfig?.highContrast ?? false;
  }
  
  /// Check if reduced motion is enabled
  bool get isReducedMotion {
    return accessibilityConfig?.reducedMotion ?? false;
  }
  
  /// Check if screen reader is active
  bool get isScreenReader {
    return accessibilityConfig?.screenReader ?? false;
  }
  
  /// Check if large print is enabled
  bool get isLargePrint {
    return accessibilityConfig?.largePrint ?? false;
  }
  
  /// Get adjusted text scale factor
  double get textScaleFactor {
    return accessibilityConfig?.textScaleFactor ?? 
           MediaQuery.of(this).textScaleFactor.clamp(0.8, 3.0);
  }
  
  /// Get accessible text style
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    final config = accessibilityConfig;
    if (config == null) return baseStyle;
    
    return ResponsiveTypography.getAccessibleStyle(
      baseStyle,
      textScaleFactor: config.textScaleFactor,
      highContrast: config.highContrast,
      increasedSpacing: config.increasedSpacing,
    );
  }
}
