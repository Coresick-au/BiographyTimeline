import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/design_system/app_icons.dart';
import '../../../shared/design_system/interaction_feedback.dart';
import '../error_service.dart';

/// Widget for displaying user-friendly error messages
/// Shows different styles based on error severity
class ErrorMessageWidget extends ConsumerWidget {
  const ErrorMessageWidget({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
    this.showDetails = false,
  });

  final AppError error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  final bool showDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final errorService = ref.watch(errorServiceProvider);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme, error.severity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(theme, error.severity),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(
                _getErrorIcon(error.severity),
                color: _getIconColor(theme, error.severity),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getErrorTitle(error.severity),
                  style: theme.textStyles.titleMedium.copyWith(
                    color: _getTextColor(theme, error.severity),
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: () {
                    InteractionFeedback.trigger();
                    onDismiss!();
                  },
                  icon: Icon(
                    AppIcons.close,
                    color: _getTextColor(theme, error.severity),
                    size: 20,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Error message
          Text(
            errorService.getUserMessage(error),
            style: theme.textStyles.bodyMedium.copyWith(
              color: _getTextColor(theme, error.severity),
            ),
          ),
          
          // Context information
          if (error.context != null) ...[
            const SizedBox(height: 8),
            Text(
              'Context: ${error.context}',
              style: theme.textStyles.bodySmall.copyWith(
                color: _getTextColor(theme, error.severity).withOpacity(0.8),
              ),
            ),
          ],
          
          // Actions
          if (onRetry != null || error.severity == ErrorSeverity.critical) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onRetry != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        InteractionFeedback.trigger();
                        onRetry!();
                      },
                      icon: Icon(AppIcons.refresh, size: 16),
                      label: Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getTextColor(theme, error.severity),
                        side: BorderSide(
                          color: _getTextColor(theme, error.severity),
                        ),
                      ),
                    ),
                  ),
                ],
                
                if (error.severity == ErrorSeverity.critical && onRetry != null)
                  const SizedBox(width: 12),
                
                if (error.severity == ErrorSeverity.critical)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCriticalErrorDialog(context),
                      icon: Icon(AppIcons.bugReport, size: 16),
                      label: Text('Report'),
                    ),
                  ),
              ],
            ),
          ],
          
          // Details toggle
          if (showDetails) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text(
                'Technical Details',
                style: theme.textStyles.labelMedium.copyWith(
                  color: _getTextColor(theme, error.severity),
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              iconColor: _getTextColor(theme, error.severity),
              collapsedIconColor: _getTextColor(theme, error.severity),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        'Error: ${error.error}',
                        style: theme.textStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (error.metadata?.isNotEmpty == true) ...[
                        Text(
                          'Metadata:',
                          style: theme.textStyles.labelSmall,
                        ),
                        ...error.metadata!.entries.map(
                          (e) => Text(
                            '  ${e.key}: ${e.value}',
                            style: theme.textStyles.bodySmall.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Stack Trace:',
                        style: theme.textStyles.labelSmall,
                      ),
                      SelectableText(
                        error.stackTrace,
                        style: theme.textStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(AppTheme theme, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return theme.colors.warningContainer;
      case ErrorSeverity.error:
        return theme.colors.errorContainer;
      case ErrorSeverity.critical:
        return theme.colors.errorContainer.withOpacity(0.95);
    }
  }

  Color _getBorderColor(AppTheme theme, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return theme.colors.warning;
      case ErrorSeverity.error:
        return theme.colors.error;
      case ErrorSeverity.critical:
        return theme.colors.error;
    }
  }

  Color _getTextColor(AppTheme theme, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return theme.colors.onWarningContainer;
      case ErrorSeverity.error:
        return theme.colors.onErrorContainer;
      case ErrorSeverity.critical:
        return theme.colors.onErrorContainer;
    }
  }

  Color _getIconColor(AppTheme theme, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return theme.colors.warning;
      case ErrorSeverity.error:
        return theme.colors.error;
      case ErrorSeverity.critical:
        return theme.colors.error;
    }
  }

  IconData _getErrorIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return AppIcons.warning;
      case ErrorSeverity.error:
        return AppIcons.error;
      case ErrorSeverity.critical:
        return AppIcons.error;
    }
  }

  String _getErrorTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  void _showCriticalErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CriticalErrorDialog(error: error),
    );
  }
}

/// Dialog for critical error reporting
class CriticalErrorDialog extends StatelessWidget {
  const CriticalErrorDialog({
    super.key,
    required this.error,
  });

  final AppError error;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            AppIcons.bugReport,
            color: theme.colors.error,
          ),
          const SizedBox(width: 12),
          Text('Report Critical Error'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A critical error has occurred. Please help us improve by reporting this issue.',
            style: theme.textStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Error ID: ${error.id}',
            style: theme.textStyles.bodySmall.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Copy error details to clipboard
            // Implementation would copy to clipboard
            Navigator.of(context).pop();
          },
          child: Text('Copy Details'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Send crash report
            // Implementation would send report
            Navigator.of(context).pop();
          },
          icon: Icon(AppIcons.send, size: 16),
          label: Text('Send Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colors.error,
            foregroundColor: theme.colors.onError,
          ),
        ),
      ],
    );
  }
}

/// Recovery options widget
class RecoveryOptionsWidget extends ConsumerWidget {
  const RecoveryOptionsWidget({
    super.key,
    required this.recovery,
  });

  final ErrorRecovery recovery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.healing,
                color: theme.colors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recovery.title,
                  style: theme.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            recovery.description,
            style: theme.textStyles.bodyMedium.copyWith(
              color: theme.colors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                InteractionFeedback.trigger();
                recovery.onExecute?.call();
              },
              icon: Icon(AppIcons.settings, size: 16),
              label: Text(recovery.action),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error banner for snackbar-style messages
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    required this.severity,
    this.onAction,
    this.actionLabel,
  });

  final String message;
  final ErrorSeverity severity;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBannerColor(theme, severity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getBannerIcon(severity),
            color: theme.colors.onPrimary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textStyles.bodyMedium.copyWith(
                color: theme.colors.onPrimary,
              ),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: theme.textStyles.labelMedium.copyWith(
                  color: theme.colors.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBannerColor(AppTheme theme, ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return theme.colors.warning;
      case ErrorSeverity.error:
        return theme.colors.error;
      case ErrorSeverity.critical:
        return theme.colors.error;
    }
  }

  IconData _getBannerIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return AppIcons.warning;
      case ErrorSeverity.error:
        return AppIcons.error;
      case ErrorSeverity.critical:
        return AppIcons.error;
    }
  }
}
