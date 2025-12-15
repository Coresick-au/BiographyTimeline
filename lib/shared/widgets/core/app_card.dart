import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

enum AppCardVariant {
  elevated,
  outlined,
  glass,
}

/// A standardized Card suitable for all surfaces in the app.
/// 
/// Consistently uses [AppRadii] and [AppSpacing] tokens.
/// Supports [AppCardVariant.glass] for the modern look.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPadding = const EdgeInsets.all(AppSpacing.lg);
    final defaultMargin = EdgeInsets.zero; // margins are usually handled by parent layout (ListView/Grid)

    Widget cardContent = Padding(
      padding: padding ?? defaultPadding,
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: cardContent,
      );
    }

    switch (variant) {
      case AppCardVariant.glass:
        return _buildGlassCard(context, cardContent, defaultMargin);
      case AppCardVariant.outlined:
        return _buildOutlinedCard(context, cardContent, defaultMargin);
      case AppCardVariant.elevated:
      default:
        return _buildElevatedCard(context, cardContent, defaultMargin);
    }
  }

  Widget _buildElevatedCard(BuildContext context, Widget content, EdgeInsetsGeometry localMargin) {
    return Card(
      elevation: elevation ?? DesignTokens.elevation2,
      margin: margin ?? localMargin,
      color: backgroundColor, // Theme defaults will apply if null
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: content,
    );
  }

  Widget _buildOutlinedCard(BuildContext context, Widget content, EdgeInsetsGeometry localMargin) {
    return Card(
      elevation: 0,
      margin: margin ?? localMargin,
      color: backgroundColor ?? Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: border?.top ?? BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: content,
    );
  }

  Widget _buildGlassCard(BuildContext context, Widget content, EdgeInsetsGeometry localMargin) {
    // Glassmorphism - toned down for better grounding
    final surfaceColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    
    return Container(
      margin: margin ?? localMargin,
      decoration: BoxDecoration(
        // Increased opacity for better grounding (was 0.1)
        color: surfaceColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
        // Subtle shadow instead of pure glass float
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: BackdropFilter(
          // Reduced blur for less floaty feel (was 10)
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: content,
        ),
      ),
    );
  }
}
