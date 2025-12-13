import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consent_models.dart';
import '../services/consent_service.dart';

/// Widget for displaying consent status and quick actions
class ConsentWidget extends ConsumerWidget {
  final String userId;
  final ConsentType? consentType;
  final String? featureId;
  final bool showDetails;
  final VoidCallback? onTap;

  const ConsentWidget({
    super.key,
    required this.userId,
    this.consentType,
    this.featureId,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentService = ref.watch(consentServiceProvider);
    
    if (consentType != null) {
      return _buildSpecificConsentWidget(context, ref, consentType!);
    } else {
      return _buildGeneralConsentWidget(context, ref);
    }
  }

  Widget _buildSpecificConsentWidget(BuildContext context, WidgetRef ref, ConsentType type) {
    final consentService = ref.read(consentServiceProvider);
    final hasConsent = consentService.hasConsent(userId, type, featureId: featureId);
    final pendingRequests = consentService.getPendingRequests(userId)
        .where((r) => r.consentType == type)
        .toList();

    return GestureDetector(
      onTap: onTap ?? () => _showConsentDialog(context, ref, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getConsentColor(hasConsent, pendingRequests.isNotEmpty).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getConsentColor(hasConsent, pendingRequests.isNotEmpty).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getConsentIcon(hasConsent, pendingRequests.isNotEmpty),
              size: 16,
              color: _getConsentColor(hasConsent, pendingRequests.isNotEmpty),
            ),
            const SizedBox(width: 6),
            Text(
              _getConsentText(hasConsent, pendingRequests.isNotEmpty),
              style: TextStyle(
                color: _getConsentColor(hasConsent, pendingRequests.isNotEmpty),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: _getConsentColor(hasConsent, pendingRequests.isNotEmpty),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralConsentWidget(BuildContext context, WidgetRef ref) {
    final consentService = ref.read(consentServiceProvider);
    final userConsents = consentService.getUserConsents(userId);
    final pendingRequests = consentService.getPendingRequests(userId);
    final activeConsents = userConsents.where((c) => c.status == ConsentStatus.granted).length;

    return GestureDetector(
      onTap: onTap ?? () => _showConsentManagement(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getOverallConsentColor(activeConsents, pendingRequests.length).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getOverallConsentColor(activeConsents, pendingRequests.length).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getOverallConsentIcon(activeConsents, pendingRequests.length),
              size: 16,
              color: _getOverallConsentColor(activeConsents, pendingRequests.length),
            ),
            const SizedBox(width: 6),
            Text(
              _getOverallConsentText(activeConsents, pendingRequests.length),
              style: TextStyle(
                color: _getOverallConsentColor(activeConsents, pendingRequests.length),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: _getOverallConsentColor(activeConsents, pendingRequests.length),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConsentColor(bool hasConsent, bool hasPending) {
    if (hasPending) return Colors.orange;
    if (hasConsent) return Colors.green;
    return Colors.red;
  }

  IconData _getConsentIcon(bool hasConsent, bool hasPending) {
    if (hasPending) return Icons.pending;
    if (hasConsent) return Icons.check_circle;
    return Icons.error;
  }

  String _getConsentText(bool hasConsent, bool hasPending) {
    if (hasPending) return 'Pending';
    if (hasConsent) return 'Granted';
    return 'Required';
  }

  Color _getOverallConsentColor(int activeConsents, int pendingCount) {
    if (pendingCount > 0) return Colors.orange;
    if (activeConsents > 0) return Colors.green;
    return Colors.red;
  }

  IconData _getOverallConsentIcon(int activeConsents, int pendingCount) {
    if (pendingCount > 0) return Icons.notifications;
    if (activeConsents > 0) return Icons.verified;
    return Icons.warning;
  }

  String _getOverallConsentText(int activeConsents, int pendingCount) {
    if (pendingCount > 0) return '$pendingCount Pending';
    if (activeConsents > 0) return '$activeConsents Active';
    return 'Action Required';
  }

  void _showConsentDialog(BuildContext context, WidgetRef ref, ConsentType type) {
    showDialog(
      context: context,
      builder: (context) => _ConsentRequestDialog(
        userId: userId,
        consentType: type,
        featureId: featureId,
      ),
    );
  }

  void _showConsentManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/consent-management');
  }
}

/// Dialog for requesting consent
class _ConsentRequestDialog extends ConsumerStatefulWidget {
  final String userId;
  final ConsentType consentType;
  final String? featureId;

  const _ConsentRequestDialog({
    required this.userId,
    required this.consentType,
    this.featureId,
  });

  @override
  ConsumerState<_ConsentRequestDialog> createState() => _ConsentRequestDialogState();
}

class _ConsentRequestDialogState extends ConsumerState<_ConsentRequestDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getConsentTypeIcon(widget.consentType)),
          const SizedBox(width: 8),
          Text(widget.consentType.displayName),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getConsentRequestMessage(widget.consentType),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            _getConsentDetailedDescription(widget.consentType),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can manage your consent preferences at any time in Settings.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => _respondToConsent(ConsentStatus.denied),
          child: const Text('Deny'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _respondToConsent(ConsentStatus.granted),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Grant'),
        ),
      ],
    );
  }

  Future<void> _respondToConsent(ConsentStatus response) async {
    setState(() => _isLoading = true);
    
    try {
      final consentService = ref.read(consentServiceProvider);
      
      // Create a consent request first
      final request = await consentService.requestConsent(
        userId: widget.userId,
        templateId: _getTemplateIdForType(widget.consentType),
        featureId: widget.featureId,
      );
      
      // Respond to the request
      await consentService.respondToConsentRequest(
        requestId: request.id,
        response: response,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consent ${response.displayName.toLowerCase()}'),
            backgroundColor: response == ConsentStatus.granted ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getTemplateIdForType(ConsentType type) {
    switch (type) {
      case ConsentType.dataProcessing:
        return 'data_processing';
      case ConsentType.analytics:
        return 'analytics';
      case ConsentType.locationTracking:
        return 'location_tracking';
      case ConsentType.collaborativeFeatures:
        return 'collaborative_features';
      default:
        return 'data_processing';
    }
  }

  String _getConsentRequestMessage(ConsentType type) {
    switch (type) {
      case ConsentType.dataProcessing:
        return 'We need your consent to process your personal data to provide timeline services.';
      case ConsentType.analytics:
        return 'Help us improve by allowing us to collect anonymous usage analytics.';
      case ConsentType.locationTracking:
        return 'Allow location tracking to enhance your timeline with location data.';
      case ConsentType.collaborativeFeatures:
        return 'Enable collaborative features to share and edit timelines with others.';
      default:
        return 'We need your consent to provide this feature.';
    }
  }

  String _getConsentDetailedDescription(ConsentType type) {
    switch (type) {
      case ConsentType.dataProcessing:
        return 'This includes storing your timeline events, personal information, and preferences to provide you with a personalized experience.';
      case ConsentType.analytics:
        return 'We collect anonymous data about how you use the app to improve our services and user experience.';
      case ConsentType.locationTracking:
        return 'We can automatically add location information to your timeline events when you enable location services.';
      case ConsentType.collaborativeFeatures:
        return 'Collaborative features allow you to share timeline events, co-edit stories, and connect with other users.';
      default:
        return 'This consent enables us to provide you with the full functionality of this feature.';
    }
  }

  IconData _getConsentTypeIcon(ConsentType type) {
    switch (type) {
      case ConsentType.dataProcessing:
        return Icons.storage;
      case ConsentType.analytics:
        return Icons.analytics;
      case ConsentType.locationTracking:
        return Icons.location_on;
      case ConsentType.collaborativeFeatures:
        return Icons.groups;
      default:
        return Icons.privacy_tip;
    }
  }
}

/// Widget for displaying consent status in a compact form
class ConsentIndicator extends ConsumerWidget {
  final String userId;
  final ConsentType consentType;
  final String? featureId;

  const ConsentIndicator({
    super.key,
    required this.userId,
    required this.consentType,
    this.featureId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentService = ref.watch(consentServiceProvider);
    final hasConsent = consentService.hasConsent(userId, consentType, featureId: featureId);
    final pendingRequests = consentService.getPendingRequests(userId)
        .where((r) => r.consentType == consentType)
        .toList();

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getConsentColor(hasConsent, pendingRequests.isNotEmpty),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getConsentColor(bool hasConsent, bool hasPending) {
    if (hasPending) return Colors.orange;
    if (hasConsent) return Colors.green;
    return Colors.red;
  }
}

/// Widget for displaying consent banner when action is required
class ConsentBanner extends ConsumerWidget {
  final String userId;
  final ConsentType? specificConsentType;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  const ConsentBanner({
    super.key,
    required this.userId,
    this.specificConsentType,
    this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentService = ref.watch(consentServiceProvider);
    final pendingRequests = consentService.getPendingRequests(userId);
    
    if (specificConsentType != null) {
      pendingRequests.retainWhere((r) => r.consentType == specificConsentType);
    }
    
    if (pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Action Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  color: Colors.orange.shade700,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have ${pendingRequests.length} pending consent request${pendingRequests.length > 1 ? 's' : ''}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/consent-management');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade700),
                  ),
                  child: Text(
                    'Review Requests',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Take Action'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
