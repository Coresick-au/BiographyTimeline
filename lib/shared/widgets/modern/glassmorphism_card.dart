import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism card with blur effect and transparency
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color backgroundColor;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableAnimation;
  final Duration animationDuration;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.backgroundColor = Colors.white,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
    this.onTap,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: blur,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return enableAnimation
          ? _AnimatedGlassCard(
              onTap: onTap!,
              duration: animationDuration,
              child: card,
            )
          : GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// Animated glass card with hover and press effects
class _AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;

  const _AnimatedGlassCard({
    required this.child,
    required this.onTap,
    required this.duration,
  });

  @override
  State<_AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<_AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Neumorphic container with soft shadows
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isPressed;
  final VoidCallback? onTap;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.backgroundColor = const Color(0xFFE0E5EC),
    this.padding,
    this.margin,
    this.isPressed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(2, 2),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(-2, -2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(8, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(-8, -8),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// Gradient card with beautiful color transitions
class GradientCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableAnimation;
  final Duration animationDuration;

  const GradientCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    required this.gradient,
    this.padding,
    this.margin,
    this.boxShadow,
    this.onTap,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return enableAnimation
          ? _AnimatedGradientCard(
              onTap: onTap!,
              duration: animationDuration,
              child: card,
            )
          : GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// Animated gradient card with shimmer effects
class _AnimatedGradientCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;

  const _AnimatedGradientCard({
    required this.child,
    required this.onTap,
    required this.duration,
  });

  @override
  State<_AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<_AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
