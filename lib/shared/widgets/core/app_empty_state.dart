import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';
import 'app_scaffold.dart';

/// A standardized widget for displaying empty states, error states, or "no results".
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.onRetry,
    this.retryLabel,
  });

  /// Factory constructor for generic error state
  factory AppEmptyState.error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      title: 'Something went wrong',
      subtitle: message,
      icon: Icons.error_outline,
      onRetry: onRetry,
      retryLabel: 'Try Again',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64, // Hero size
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null || onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action ??
                  FilledButton.tonal(
                    onPressed: onRetry,
                    child: Text(retryLabel ?? 'Retry'),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
