import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';

/// A modern card component with consistent styling, hover effects, and animations
/// 
/// This card follows the design system tokens and provides:
/// - Consistent elevation and shadows
/// - Smooth hover and press animations
/// - Theme-aware styling
/// - Accessibility support
/// - Customizable content and interactions
class ModernCard extends StatefulWidget {
  /// The widget to display inside the card
  final Widget child;
  
  /// Callback when the card is tapped
  final VoidCallback? onTap;
  
  /// Callback when the card is long pressed
  final VoidCallback? onLongPress;
  
  /// Custom elevation (defaults to design token value)
  final double? elevation;
  
  /// Custom padding inside the card
  final EdgeInsets? padding;
  
  /// Custom border radius
  final BorderRadius? borderRadius;
  
  /// Custom background color (overrides theme)
  final Color? backgroundColor;
  
  /// Whether the card should show hover effects
  final bool enableHoverEffects;
  
  /// Whether the card should show press animations
  final bool enablePressAnimations;
  
  /// Custom margin around the card
  final EdgeInsets? margin;
  
  /// Custom border
  final Border? border;
  
  /// Whether the card is selected (shows selection styling)
  final bool isSelected;
  
  /// Custom width
  final double? width;
  
  /// Custom height
  final double? height;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.enableHoverEffects = true,
    this.enablePressAnimations = true,
    this.margin,
    this.border,
    this.isSelected = false,
    this.width,
    this.height,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveStandard,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? DesignTokens.elevation2,
      end: (widget.elevation ?? DesignTokens.elevation2) + 2,
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
    if (widget.enablePressAnimations) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePressAnimations) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enablePressAnimations) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (widget.enableHoverEffects) {
      setState(() => _isHovered = true);
    }
  }

  void _handleHoverExit(PointerExitEvent event) {
    if (widget.enableHoverEffects) {
      setState(() => _isHovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate effective elevation
    double effectiveElevation = widget.elevation ?? DesignTokens.elevation2;
    if (_isHovered && widget.enableHoverEffects) {
      effectiveElevation += 2;
    }
    if (widget.isSelected) {
      effectiveElevation += 1;
    }

    // Calculate effective background color
    Color effectiveBackgroundColor = widget.backgroundColor ?? colorScheme.surface;
    if (widget.isSelected) {
      effectiveBackgroundColor = Color.alphaBlend(
        colorScheme.primary.withOpacity(0.08),
        effectiveBackgroundColor,
      );
    }

    // Calculate effective border
    Border? effectiveBorder = widget.border;
    if (widget.isSelected) {
      effectiveBorder = Border.all(
        color: colorScheme.primary,
        width: 2.0,
      );
    }

    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? EdgeInsets.all(DesignTokens.space2),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: widget.borderRadius ?? 
            BorderRadius.circular(DesignTokens.radiusMedium),
        border: effectiveBorder,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: effectiveElevation * 2,
            offset: Offset(0, effectiveElevation),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? 
            BorderRadius.circular(DesignTokens.radiusMedium),
        child: Padding(
          padding: widget.padding ?? EdgeInsets.all(DesignTokens.space4),
          child: widget.child,
        ),
      ),
    );

    // Wrap with animations if enabled
    if (widget.enablePressAnimations) {
      cardContent = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: cardContent,
      );
    }

    // Wrap with hover detection if enabled
    if (widget.enableHoverEffects) {
      cardContent = MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        child: cardContent,
      );
    }

    // Wrap with gesture detection if interactive
    if (widget.onTap != null || widget.onLongPress != null) {
      cardContent = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: cardContent,
      );
    }

    // Add semantic labels for accessibility
    return Semantics(
      button: widget.onTap != null,
      selected: widget.isSelected,
      child: cardContent,
    );
  }
}

/// A specialized card for displaying statistics with animated numbers
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;
  final bool isPositiveTrend;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colorScheme.primary,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (showTrend && trendValue != null) ...[
                Icon(
                  isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                  color: isPositiveTrend ? Colors.green : Colors.red,
                  size: 16,
                ),
                SizedBox(width: DesignTokens.space1),
                Text(
                  '${trendValue!.toStringAsFixed(1)}%',
                  style: DesignTokens.labelSmall.copyWith(
                    color: isPositiveTrend ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: DesignTokens.space3),
          Text(
            value,
            style: DesignTokens.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignTokens.space1),
          Text(
            title,
            style: DesignTokens.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: DesignTokens.space1),
            Text(
              subtitle!,
              style: DesignTokens.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A card specifically designed for timeline events
class TimelineEventCard extends StatelessWidget {
  final String title;
  final String? description;
  final DateTime timestamp;
  final IconData eventIcon;
  final Color? eventColor;
  final String? location;
  final int? mediaCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Widget? trailing;

  const TimelineEventCard({
    super.key,
    required this.title,
    this.description,
    required this.timestamp,
    required this.eventIcon,
    this.eventColor,
    this.location,
    this.mediaCount,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      onTap: onTap,
      onLongPress: onLongPress,
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and timestamp
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: (eventColor ?? colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Icon(
                  eventIcon,
                  color: eventColor ?? colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesignTokens.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: DesignTokens.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          
          // Description
          if (description != null) ...[
            SizedBox(height: DesignTokens.space3),
            Text(
              description!,
              style: DesignTokens.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Footer with location and media count
          if (location != null || mediaCount != null) ...[
            SizedBox(height: DesignTokens.space3),
            Row(
              children: [
                if (location != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: DesignTokens.space1),
                  Expanded(
                    child: Text(
                      location!,
                      style: DesignTokens.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (mediaCount != null && mediaCount! > 0) ...[
                  if (location != null) SizedBox(width: DesignTokens.space3),
                  Icon(
                    Icons.photo_library,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: DesignTokens.space1),
                  Text(
                    '$mediaCount',
                    style: DesignTokens.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}