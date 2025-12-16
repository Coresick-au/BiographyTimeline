import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// A modern button component with smooth animations and consistent styling
/// 
/// This button follows the design system tokens and provides:
/// - Micro-animations on press
/// - Loading states with spinner
/// - Multiple style variants
/// - Accessibility support
/// - Consistent sizing and spacing
class ModernButton extends StatefulWidget {
  /// The text to display on the button
  final String text;
  
  /// Callback when the button is pressed
  final VoidCallback? onPressed;
  
  /// The button style variant
  final ModernButtonStyle style;
  
  /// Custom background color (overrides style default)
  final Color? backgroundColor;
  
  /// Custom text color (overrides style default)
  final Color? textColor;
  
  /// Custom icon to display before text
  final IconData? icon;
  
  /// Whether the button is in loading state
  final bool isLoading;
  
  /// Custom width (defaults to content width)
  final double? width;
  
  /// Custom height (defaults to design token value)
  final double? height;
  
  /// Custom padding (overrides default)
  final EdgeInsets? padding;
  
  /// Custom border radius (overrides style default)
  final BorderRadius? borderRadius;
  
  /// Whether the button should expand to fill available width
  final bool expandWidth;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = ModernButtonStyle.primary,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.expandWidth = false,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationXFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveStandard,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate colors based on style
    final colors = _getButtonColors(colorScheme);
    
    // Calculate effective dimensions
    final effectiveHeight = widget.height ?? 48.0;
    final effectivePadding = widget.padding ?? EdgeInsets.symmetric(
      horizontal: DesignTokens.space6,
      vertical: DesignTokens.space3,
    );
    final effectiveBorderRadius = widget.borderRadius ?? 
        BorderRadius.circular(DesignTokens.radiusSmall);

    Widget buttonContent = Row(
      mainAxisSize: widget.expandWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.textColor),
            ),
          ),
          SizedBox(width: DesignTokens.space2),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color: colors.textColor,
          ),
          SizedBox(width: DesignTokens.space2),
        ],
        Text(
          widget.text,
          style: DesignTokens.labelLarge.copyWith(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    Widget button = Container(
      width: widget.expandWidth ? double.infinity : widget.width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: effectiveBorderRadius,
        border: colors.borderColor != null 
            ? Border.all(color: colors.borderColor!, width: 1.5)
            : null,
        boxShadow: widget.style == ModernButtonStyle.primary
            ? [
                BoxShadow(
                  color: colors.backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: effectiveBorderRadius,
          child: Padding(
            padding: effectivePadding,
            child: buttonContent,
          ),
        ),
      ),
    );

    // Apply press animation
    button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: button,
    );

    // Add gesture detection for animations
    button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: button,
    );

    // Add semantic labels for accessibility
    return Semantics(
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      label: widget.text,
      child: button,
    );
  }

  _ButtonColors _getButtonColors(ColorScheme colorScheme) {
    final backgroundColor = widget.backgroundColor;
    final textColor = widget.textColor;

    switch (widget.style) {
      case ModernButtonStyle.primary:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? colorScheme.primary,
          textColor: textColor ?? colorScheme.onPrimary,
          borderColor: null,
        );
      
      case ModernButtonStyle.secondary:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? colorScheme.secondaryContainer,
          textColor: textColor ?? colorScheme.onSecondaryContainer,
          borderColor: null,
        );
      
      case ModernButtonStyle.outline:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? Colors.transparent,
          textColor: textColor ?? colorScheme.primary,
          borderColor: colorScheme.outline,
        );
      
      case ModernButtonStyle.text:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? Colors.transparent,
          textColor: textColor ?? colorScheme.primary,
          borderColor: null,
        );
      
      case ModernButtonStyle.danger:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? colorScheme.error,
          textColor: textColor ?? colorScheme.onError,
          borderColor: null,
        );
    }
  }
}

/// Button style variants
enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  text,
  danger,
}

/// Internal class for button colors
class _ButtonColors {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });
}

/// A floating action button with modern styling
class ModernFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool enableRotation;
  final String? tooltip;

  const ModernFloatingActionButton({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.enableRotation = false,
    this.tooltip,
  });

  @override
  State<ModernFloatingActionButton> createState() => _ModernFloatingActionButtonState();
}

class _ModernFloatingActionButtonState extends State<ModernFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.enableRotation) {
      _rotationController = AnimationController(
        duration: DesignTokens.durationMedium,
        vsync: this,
      );
      
      _rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 0.125, // 45 degrees (1/8 turn)
      ).animate(CurvedAnimation(
        parent: _rotationController,
        curve: DesignTokens.curveStandard,
      ));
    } else {
      _rotationController = AnimationController(vsync: this);
      _rotationAnimation = const AlwaysStoppedAnimation(0.0);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (widget.enableRotation) {
      if (_rotationController.isCompleted) {
        _rotationController.reverse();
      } else {
        _rotationController.forward();
      }
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget fab = FloatingActionButton(
      onPressed: _handlePress,
      backgroundColor: widget.backgroundColor ?? colorScheme.primary,
      foregroundColor: widget.foregroundColor ?? colorScheme.onPrimary,
      elevation: widget.elevation ?? DesignTokens.elevation3,
      tooltip: widget.tooltip,
      child: widget.child,
    );

    if (widget.enableRotation) {
      fab = AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
            child: child,
          );
        },
        child: fab,
      );
    }

    return fab;
  }
}

/// A modern outline button variant
class ModernOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const ModernOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.borderColor,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ModernButton(
      text: text,
      onPressed: onPressed,
      style: ModernButtonStyle.outline,
      textColor: textColor,
      icon: icon,
      isLoading: isLoading,
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
    );
  }
}

/// A modern text button variant
class ModernTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsets? padding;

  const ModernTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ModernButton(
      text: text,
      onPressed: onPressed,
      style: ModernButtonStyle.text,
      textColor: textColor,
      icon: icon,
      isLoading: isLoading,
      padding: padding,
    );
  }
}

/// A modern animated button specifically for the timeline
class ModernAnimatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? primaryColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool enableGradient;

  const ModernAnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.primaryColor,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.borderRadius,
    this.enableGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = primaryColor ?? colorScheme.primary;

    return ModernButton(
      text: text,
      onPressed: onPressed,
      style: ModernButtonStyle.primary,
      backgroundColor: effectiveColor,
      icon: icon,
      isLoading: isLoading,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
