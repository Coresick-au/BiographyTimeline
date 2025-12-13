import 'package:flutter/material.dart';

/// Shimmer loading effect for modern UI
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _animation.value, 0.0),
              end: Alignment(1.0 + _animation.value, 0.0),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loading card
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableShimmer;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.padding,
    this.margin,
    this.enableShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final skeleton = Container(
      width: width,
      height: height ?? 120,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (enableShimmer) {
      return ShimmerLoading(
        child: skeleton,
      );
    }

    return skeleton;
  }
}

/// Skeleton loading for timeline events
class TimelineEventSkeleton extends StatelessWidget {
  final bool showAvatar;
  final bool showDate;
  final bool showDescription;
  final EdgeInsetsGeometry? margin;

  const TimelineEventSkeleton({
    super.key,
    this.showAvatar = true,
    this.showDate = true,
    this.showDescription = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            SkeletonCard(
              width: 48,
              height: 48,
              borderRadius: 24,
              enableShimmer: true,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate) ...[
                  SkeletonCard(
                    width: 120,
                    height: 14,
                    borderRadius: 7,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                ],
                SkeletonCard(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 8,
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                if (showDescription) ...[
                  SkeletonCard(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 7,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  SkeletonCard(
                    width: 200,
                    height: 14,
                    borderRadius: 7,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading for list items
class ListItemSkeleton extends StatelessWidget {
  final bool showLeading;
  final bool showTrailing;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const ListItemSkeleton({
    super.key,
    this.showLeading = true,
    this.showTrailing = true,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: height ?? 72,
      child: Row(
        children: [
          if (showLeading) ...[
            SkeletonCard(
              width: 40,
              height: 40,
              borderRadius: 20,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonCard(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 8,
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                SkeletonCard(
                  width: 150,
                  height: 12,
                  borderRadius: 6,
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 16),
            SkeletonCard(
              width: 24,
              height: 24,
              borderRadius: 12,
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton loading for cards with content
class CardSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showImage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showFooter;
  final EdgeInsetsGeometry? margin;

  const CardSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.showImage = true,
    this.showTitle = true,
    this.showSubtitle = true,
    this.showFooter = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ShimmerLoading(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showImage) ...[
                SkeletonCard(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 8,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
              ],
              if (showTitle) ...[
                SkeletonCard(
                  width: double.infinity,
                  height: 20,
                  borderRadius: 10,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
              ],
              if (showSubtitle) ...[
                SkeletonCard(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 7,
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                SkeletonCard(
                  width: 250,
                  height: 14,
                  borderRadius: 7,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
              ],
              if (showFooter) ...[
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonCard(
                      width: 80,
                      height: 12,
                      borderRadius: 6,
                    ),
                    SkeletonCard(
                      width: 60,
                      height: 12,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated loading indicator with modern design
class ModernLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final Duration duration;

  const ModernLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 4.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ModernLoadingIndicator> createState() => _ModernLoadingIndicatorState();
}

class _ModernLoadingIndicatorState extends State<ModernLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: color.withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }
}

/// Pulse loading container
class PulseLoadingContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseLoadingContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseLoadingContainer> createState() => _PulseLoadingContainerState();
}

class _PulseLoadingContainerState extends State<PulseLoadingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
