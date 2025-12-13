import 'package:flutter/material.dart';

/// Modern animated button with gradient background and effects
class ModernAnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool isLoading;
  final Widget? icon;
  final Duration animationDuration;
  final bool enableShadow;
  final bool enableGradient;

  const ModernAnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primaryColor,
    this.secondaryColor,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.textStyle,
    this.isLoading = false,
    this.icon,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableShadow = true,
    this.enableGradient = true,
  });

  @override
  State<ModernAnimatedButton> createState() => _ModernAnimatedButtonState();
}

class _ModernAnimatedButtonState extends State<ModernAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientRotationAnimation;
  late Animation<double> _shadowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));

    _gradientRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse().then((_) {
        if (mounted) widget.onPressed();
      });
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    final secondaryColor = widget.secondaryColor ?? primaryColor.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.enableGradient
                  ? LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(_gradientRotationAnimation.value * 3.14159),
                    )
                  : null,
              color: widget.enableGradient ? null : primaryColor,
              boxShadow: widget.enableShadow
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3 * _shadowAnimation.value),
                        blurRadius: 20 * _shadowAnimation.value,
                        spreadRadius: 2 * _shadowAnimation.value,
                        offset: Offset(0, 8 * _shadowAnimation.value),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                child: Center(
                  child: widget.isLoading
                      ? _buildLoadingIndicator()
                      : _buildButtonContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.icon!,
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: widget.textStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: widget.textStyle ??
          const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}

/// Modern floating action button with rotation and scale effects
class ModernFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool enableRotation;
  final bool enablePulse;
  final Duration animationDuration;
  final List<BoxShadow>? boxShadow;

  const ModernFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56.0,
    this.enableRotation = true,
    this.enablePulse = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.boxShadow,
  });

  @override
  State<ModernFloatingActionButton> createState() => _ModernFloatingActionButtonState();
}

class _ModernFloatingActionButtonState extends State<ModernFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enablePulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Theme.of(context).primaryColor;
    final foregroundColor = widget.foregroundColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enablePulse ? _pulseAnimation.value : _scaleAnimation.value,
          child: Transform.rotate(
            angle: widget.enableRotation ? _rotationAnimation.value * 2 * 3.14159 : 0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: widget.boxShadow ?? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  onTap: () {
                    if (!widget.enablePulse) {
                      _controller.forward().then((_) {
                        _controller.reverse();
                      });
                    }
                    widget.onPressed();
                  },
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(
                        color: foregroundColor,
                        size: widget.size * 0.4,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Outline button with modern styling
class ModernOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderWidth;
  final double borderRadius;
  final TextStyle? textStyle;
  final Duration animationDuration;
  final Widget? icon;

  const ModernOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.width,
    this.height,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 250),
    this.icon,
  });

  @override
  State<ModernOutlineButton> createState() => _ModernOutlineButtonState();
}

class _ModernOutlineButtonState extends State<ModernOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _borderAnimation = Tween<double>(
      begin: widget.borderWidth,
      end: widget.borderWidth * 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    final borderColor = widget.borderColor ?? Theme.of(context).primaryColor;
    _colorAnimation = ColorTween(
      begin: borderColor,
      end: borderColor.withOpacity(0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      if (mounted) widget.onPressed();
    });
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ?? Theme.of(context).primaryColor;
    final textColor = widget.textColor ?? borderColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _colorAnimation.value ?? borderColor,
                width: _borderAnimation.value,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: widget.onPressed,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                child: Center(
                  child: widget.icon != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconTheme(
                              data: IconThemeData(
                                color: textColor,
                                size: 18,
                              ),
                              child: widget.icon!,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.text,
                              style: widget.textStyle ??
                                  TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        )
                      : Text(
                          widget.text,
                          style: widget.textStyle ??
                              TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
