import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_system.dart';
import 'theme_engine.dart';

/// Interaction feedback system that provides haptic feedback, animations, 
/// and loading states while respecting accessibility preferences
class InteractionFeedback {
  // Private constructor to prevent instantiation
  InteractionFeedback._();

  // ===========================================================================
  // HAPTIC FEEDBACK
  // ===========================================================================
  
  /// Haptic feedback intensity levels
  enum HapticIntensity {
    none,
    light,
    medium,
    heavy,
  }

  /// Trigger haptic feedback with specified intensity
  static Future<void> haptic(
    HapticIntensity intensity, {
    BuildContext? context,
  }) async {
    // Check if haptic feedback is disabled
    if (context != null) {
      final config = context.accessibilityConfig;
      if (config?.reducedMotion ?? false) {
        return; // Respect reduced motion preference
      }
    }
    
    switch (intensity) {
      case HapticIntensity.none:
        break;
      case HapticIntensity.light:
        await HapticFeedback.selectionClick();
        break;
      case HapticIntensity.medium:
        await HapticFeedback.lightImpact();
        break;
      case HapticIntensity.heavy:
        await HapticFeedback.mediumImpact();
        break;
    }
  }

  /// Haptic feedback for specific interactions
  static Future<void> tap() => haptic(HapticIntensity.light);
  static Future<void> select() => haptic(HapticIntensity.light);
  static Future<void> longPress() => haptic(HapticIntensity.medium);
  static Future<void> success() => haptic(HapticIntensity.medium);
  static Future<void> error() => haptic(HapticIntensity.heavy);
  static Future<void> milestone() => haptic(HapticIntensity.heavy);

  // ===========================================================================
  // ANIMATION HELPERS
  // ===========================================================================
  
  /// Get animation duration respecting reduced motion
  static Duration getAnimationDuration(
    Duration baseDuration, {
    BuildContext? context,
  }) {
    if (context != null) {
      return AccessibilitySystem.getAnimationDuration(
        baseDuration,
        context.isReducedMotion,
      );
    }
    return baseDuration;
  }

  /// Get animation curve respecting reduced motion
  static Curve getAnimationCurve({
    BuildContext? context,
    Curve? defaultCurve,
  }) {
    if (context != null && context.isReducedMotion) {
      return Curves.linear;
    }
    return defaultCurve ?? Curves.easeInOut;
  }

  /// Create animated container with accessibility considerations
  static Widget animatedContainer({
    required Widget child,
    Duration? duration,
    Curve? curve,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    Decoration? decoration,
    double? width,
    double? height,
    Alignment? alignment,
    BuildContext? context,
  }) {
    return AnimatedContainer(
      duration: getAnimationDuration(duration ?? const Duration(milliseconds: 200), context: context),
      curve: getAnimationCurve(context: context, defaultCurve: curve),
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }

  /// Create animated opacity with accessibility considerations
  static Widget animatedOpacity({
    required Widget child,
    required double opacity,
    Duration? duration,
    Curve? curve,
    BuildContext? context,
    VoidCallback? onEnd,
  }) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: getAnimationDuration(duration ?? const Duration(milliseconds: 300), context: context),
      curve: getAnimationCurve(context: context, defaultCurve: curve),
      onEnd: onEnd,
      child: child,
    );
  }

  /// Create animated switcher with accessibility considerations
  static Widget animatedSwitcher({
    required Widget child,
    Duration? duration,
    Curve? curve,
    BuildContext? context,
    AnimatedSwitcherTransitionBuilder? transitionBuilder,
    AnimatedSwitcherLayoutBuilder? layoutBuilder,
  }) {
    return AnimatedSwitcher(
      duration: getAnimationDuration(duration ?? const Duration(milliseconds: 300), context: context),
      curve: getAnimationCurve(context: context, defaultCurve: curve),
      transitionBuilder: transitionBuilder,
      layoutBuilder: layoutBuilder,
      child: child,
    );
  }

  // ===========================================================================
  // LOADING INDICATORS
  // ===========================================================================
  
  /// Themed circular progress indicator
  static Widget circularProgressIndicator({
    double? value,
    Color? color,
    double? strokeWidth,
    BuildContext? context,
  }) {
    final indicatorColor = color ?? 
        context?.theme.colorScheme.primary ?? 
        Colors.blue;
    
    return CircularProgressIndicator(
      value: value,
      color: indicatorColor,
      strokeWidth: strokeWidth ?? 4.0,
    );
  }

  /// Themed linear progress indicator
  static Widget linearProgressIndicator({
    double? value,
    Color? color,
    BuildContext? context,
  }) {
    final indicatorColor = color ?? 
        context?.theme.colorScheme.primary ?? 
        Colors.blue;
    
    return LinearProgressIndicator(
      value: value,
      color: indicatorColor,
    );
  }

  /// Custom loading spinner with theme integration
  static Widget loadingSpinner({
    double size = 24.0,
    Color? color,
    BuildContext? context,
  }) {
    final spinnerColor = color ?? 
        context?.theme.colorScheme.primary ?? 
        Colors.blue;
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: spinnerColor,
        strokeWidth: size / 8,
      ),
    );
  }

  /// Pulsing loading indicator
  static Widget pulsingLoader({
    Widget? child,
    Color? color,
    BuildContext? context,
  }) {
    final loaderColor = color ?? 
        context?.theme.colorScheme.primary ?? 
        Colors.blue;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: getAnimationDuration(
        const Duration(milliseconds: 1000),
        context: context,
      ),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child ?? loadingSpinner(color: loaderColor),
        );
      },
    );
  }

  // ===========================================================================
  // INTERACTION WIDGETS
  // ===========================================================================
  
  /// Button with haptic feedback
  static Widget hapticButton({
    required Widget child,
    required VoidCallback onPressed,
    HapticIntensity hapticIntensity = HapticIntensity.light,
    ButtonStyle? style,
    BuildContext? context,
  }) {
    return ElevatedButton(
      style: style,
      onPressed: () {
        haptic(hapticIntensity, context: context);
        onPressed();
      },
      child: child,
    );
  }

  /// Card with press feedback
  static Widget interactiveCard({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    HapticIntensity tapHaptic = HapticIntensity.light,
    HapticIntensity longPressHaptic = HapticIntensity.medium,
    Color? color,
    EdgeInsets? margin,
    BuildContext? context,
  }) {
    return Card(
      color: color,
      margin: margin,
      child: InkWell(
        onTap: onTap != null
            ? () {
                haptic(tapHaptic, context: context);
                onTap();
              }
            : null,
        onLongPress: onLongPress != null
            ? () {
                haptic(longPressHaptic, context: context);
                onLongPress();
              }
            : null,
        child: child,
      ),
    );
  }

  /// List tile with haptic feedback
  static Widget hapticListTile({
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    VoidCallback? onTap,
    HapticIntensity hapticIntensity = HapticIntensity.light,
    BuildContext? context,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onTap != null
          ? () {
              haptic(hapticIntensity, context: context);
              onTap();
            }
          : null,
    );
  }

  // ===========================================================================
  // TRANSITION HELPERS
  // ===========================================================================
  
  /// Slide transition with accessibility considerations
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    BuildContext? context,
  }) {
    if (context != null && context.isReducedMotion) {
      return child; // Skip animation if reduced motion
    }
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(context: context),
      )),
      child: child,
    );
  }

  /// Scale transition with accessibility considerations
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    BuildContext? context,
  }) {
    if (context != null && context.isReducedMotion) {
      return child; // Skip animation if reduced motion
    }
    
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(context: context),
      )),
      child: child,
    );
  }

  /// Fade transition with accessibility considerations
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    BuildContext? context,
  }) {
    if (context != null && context.isReducedMotion) {
      return child; // Skip animation if reduced motion
    }
    
    return FadeTransition(
      opacity: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: getAnimationCurve(context: context),
      )),
      child: child,
    );
  }

  // ===========================================================================
  // FEEDBACK PROVIDERS
  // ===========================================================================
  
  /// Provider for haptic feedback enabled state
  static final hapticFeedbackProvider = StateProvider<bool>((ref) => true);
  
  /// Provider for animation speed multiplier
  static final animationSpeedProvider = StateProvider<double>((ref) => 1.0);
  
  /// Provider for loading state
  static final loadingProvider = StateProvider<bool>((ref) => false);
}

/// Extension on BuildContext for interaction feedback utilities
extension InteractionFeedbackContextExtension on BuildContext {
  /// Trigger haptic feedback
  Future<void> haptic(InteractionFeedback.HapticIntensity intensity) {
    return InteractionFeedback.haptic(intensity, context: this);
  }
  
  /// Get animation duration
  Duration getAnimationDuration(Duration baseDuration) {
    return InteractionFeedback.getAnimationDuration(baseDuration, context: this);
  }
  
  /// Get animation curve
  Curve getAnimationCurve([Curve? defaultCurve]) {
    return InteractionFeedback.getAnimationCurve(context: this, defaultCurve: defaultCurve);
  }
  
  /// Create themed progress indicator
  Widget progressIndicator({double? value, Color? color}) {
    return InteractionFeedback.circularProgressIndicator(
      value: value,
      color: color,
      context: this,
    );
  }
  
  /// Create themed loading spinner
  Widget loadingSpinner({double size = 24.0, Color? color}) {
    return InteractionFeedback.loadingSpinner(
      size: size,
      color: color,
      context: this,
    );
  }
}

/// Widget that provides interaction feedback to its children
class InteractionFeedbackProvider extends StatelessWidget {
  final Widget child;
  final bool enableHaptics;
  final double animationSpeed;
  
  const InteractionFeedbackProvider({
    Key? key,
    required this.child,
    this.enableHaptics = true,
    this.animationSpeed = 1.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        InteractionFeedback.hapticFeedbackProvider.overrideWithValue(enableHaptics),
        InteractionFeedback.animationSpeedProvider.overrideWithValue(animationSpeed),
      ],
      child: child,
    );
  }
}
