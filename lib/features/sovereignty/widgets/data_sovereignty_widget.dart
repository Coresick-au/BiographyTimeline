import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data_sovereignty_models.dart';
import '../services/data_sovereignty_service.dart';

/// Widget for displaying data sovereignty status and quick actions
class DataSovereigntyWidget extends ConsumerWidget {
  final String userId;
  final DataResidencyRegion? region;
  final bool showDetails;
  final VoidCallback? onTap;

  const DataSovereigntyWidget({
    super.key,
    required this.userId,
    this.region,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.watch(dataSovereigntyServiceProvider);
    
    if (region != null) {
      return _buildRegionalSovereigntyWidget(context, ref, region!);
    } else {
      return _buildGeneralSovereigntyWidget(context, ref);
    }
  }

  Widget _buildRegionalSovereigntyWidget(BuildContext context, WidgetRef ref, DataResidencyRegion region) {
    final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
    final policy = sovereigntyService.getApplicablePolicy(userId, region);
    final userRecords = sovereigntyService.getUserResidencyRecords(userId, region: region);
    final isCompliant = policy != null;

    return GestureDetector(
      onTap: onTap ?? () => _showSovereigntyDialog(context, ref, region),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getSovereigntyColor(isCompliant).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getSovereigntyColor(isCompliant).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSovereigntyIcon(isCompliant),
              size: 16,
              color: _getSovereigntyColor(isCompliant),
            ),
            const SizedBox(width: 6),
            Text(
              _getSovereigntyText(isCompliant, region),
              style: TextStyle(
                color: _getSovereigntyColor(isCompliant),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: _getSovereigntyColor(isCompliant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSovereigntyWidget(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
    final userRecords = sovereigntyService.getUserResidencyRecords(userId);
    final pendingTransfers = sovereigntyService.getTransferRequests(
      userId: userId, 
      status: CrossBorderTransferStatus.pending,
    ).length;
    final pendingRights = sovereigntyService.getRightsRequests(
      userId: userId, 
      status: DataSubjectRightsStatus.pending,
    ).length;

    return GestureDetector(
      onTap: onTap ?? () => _showSovereigntyManagement(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getOverallSovereigntyColor(pendingTransfers, pendingRights).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getOverallSovereigntyColor(pendingTransfers, pendingRights).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getOverallSovereigntyIcon(pendingTransfers, pendingRights),
              size: 16,
              color: _getOverallSovereigntyColor(pendingTransfers, pendingRights),
            ),
            const SizedBox(width: 6),
            Text(
              _getOverallSovereigntyText(pendingTransfers, pendingRights),
              style: TextStyle(
                color: _getOverallSovereigntyColor(pendingTransfers, pendingRights),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: _getOverallSovereigntyColor(pendingTransfers, pendingRights),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSovereigntyColor(bool isCompliant) {
    if (isCompliant) return Colors.green;
    return Colors.orange;
  }

  IconData _getSovereigntyIcon(bool isCompliant) {
    if (isCompliant) return Icons.verified;
    return Icons.warning;
  }

  String _getSovereigntyText(bool isCompliant, DataResidencyRegion region) {
    if (isCompliant) return '${region.flag} Compliant';
    return '${region.flag} Review Needed';
  }

  Color _getOverallSovereigntyColor(int pendingTransfers, int pendingRights) {
    if (pendingTransfers > 0 || pendingRights > 0) return Colors.orange;
    return Colors.green;
  }

  IconData _getOverallSovereigntyIcon(int pendingTransfers, int pendingRights) {
    if (pendingTransfers > 0 || pendingRights > 0) return Icons.notifications;
    return Icons.verified;
  }

  String _getOverallSovereigntyText(int pendingTransfers, int pendingRights) {
    final totalPending = pendingTransfers + pendingRights;
    if (totalPending > 0) return '$totalPending Pending';
    return 'Sovereign';
  }

  void _showSovereigntyDialog(BuildContext context, WidgetRef ref, DataResidencyRegion region) {
    showDialog(
      context: context,
      builder: (context) => _RegionalSovereigntyDialog(
        userId: userId,
        region: region,
      ),
    );
  }

  void _showSovereigntyManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/data-sovereignty');
  }
}

/// Dialog for regional sovereignty information
class _RegionalSovereigntyDialog extends ConsumerWidget {
  final String userId;
  final DataResidencyRegion region;

  const _RegionalSovereigntyDialog({
    required this.userId,
    required this.region,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.watch(dataSovereigntyServiceProvider);
    final policy = sovereigntyService.getApplicablePolicy(userId, region);
    final userRecords = sovereigntyService.getUserResidencyRecords(userId, region: region);

    return AlertDialog(
      title: Row(
        children: [
          Text('${region.flag} ${region.displayName}'),
          const Spacer(),
          if (policy != null)
            Icon(
              Icons.verified,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy != null) ...[
              Text(
                'Compliance Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text('✅ Compliant with ${policy.complianceFrameworks.map((f) => f.displayName).join(', ')}'),
              Text('✅ Data stored locally'),
              Text('✅ Encryption: ${policy.encryptionStandard}'),
              Text('✅ Retention: ${policy.dataRetentionPeriod.inDays} days'),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Compliance Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text('⚠️ No specific policy for this region'),
              Text('⚠️ Using global policy'),
              const SizedBox(height: 16),
            ],
            Text(
              'Your Data in ${region.displayName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (userRecords.isEmpty)
              const Text('No data stored in this region')
            else ...[
              Text('${userRecords.length} data records'),
              ...userRecords.take(5).map((record) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• ${record.dataType} (${record.classification.name})'),
              )),
              if (userRecords.length > 5)
                Text('... and ${userRecords.length - 5} more'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Regional Requirements',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._getRegionalRequirements(region),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/data-sovereignty');
          },
          child: const Text('Manage'),
        ),
      ],
    );
  }

  List<String> _getRegionalRequirements(DataResidencyRegion region) {
    switch (region) {
      case DataResidencyRegion.europeanUnion:
        return [
          '✅ Data must remain within EU',
          '✅ Explicit consent required',
          '✅ Right to be forgotten',
          '✅ Data portability enabled',
          '✅ GDPR compliant',
        ];
      case DataResidencyRegion.unitedStates:
        return [
          '✅ Data stored in US',
          '✅ CCPA compliant',
          '✅ Consumer rights enabled',
          '⚠️ Opt-out mechanism required',
        ];
      case DataResidencyRegion.unitedKingdom:
        return [
          '✅ Data stored in UK',
          '✅ UK DPA compliant',
          '✅ GDPR standards maintained',
        ];
      case DataResidencyRegion.canada:
        return [
          '✅ Data stored in Canada',
          '✅ PIPEDA compliant',
          '✅ Consent-based processing',
        ];
      case DataResidencyRegion.australia:
        return [
          '✅ Data stored in Australia',
          '✅ Privacy Act compliant',
          '✅ APP guidelines followed',
        ];
      default:
        return [
          '⚠️ Check local regulations',
          '⚠️ Verify compliance requirements',
          '⚠️ Review data protection laws',
        ];
    }
  }
}

/// Widget for displaying data residency indicator
class DataResidencyIndicator extends ConsumerWidget {
  final String userId;
  final DataResidencyRegion region;

  const DataResidencyIndicator({
    super.key,
    required this.userId,
    required this.region,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.watch(dataSovereigntyServiceProvider);
    final policy = sovereigntyService.getApplicablePolicy(userId, region);
    final isCompliant = policy != null;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getResidencyColor(isCompliant),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getResidencyColor(bool isCompliant) {
    if (isCompliant) return Colors.green;
    return Colors.orange;
  }
}

/// Widget for displaying cross-border transfer status
class CrossBorderTransferWidget extends ConsumerWidget {
  final String userId;
  final bool showDetails;

  const CrossBorderTransferWidget({
    super.key,
    required this.userId,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.watch(dataSovereigntyServiceProvider);
    final pendingTransfers = sovereigntyService.getTransferRequests(
      userId: userId,
      status: CrossBorderTransferStatus.pending,
    );
    final approvedTransfers = sovereigntyService.getTransferRequests(
      userId: userId,
      status: CrossBorderTransferStatus.approved,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/data-sovereignty'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getTransferColor(pendingTransfers.length).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getTransferColor(pendingTransfers.length).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTransferIcon(pendingTransfers.length),
              size: 16,
              color: _getTransferColor(pendingTransfers.length),
            ),
            const SizedBox(width: 6),
            Text(
              _getTransferText(pendingTransfers.length, approvedTransfers.length),
              style: TextStyle(
                color: _getTransferColor(pendingTransfers.length),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: _getTransferColor(pendingTransfers.length),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTransferColor(int pendingCount) {
    if (pendingCount > 0) return Colors.orange;
    return Colors.green;
  }

  IconData _getTransferIcon(int pendingCount) {
    if (pendingCount > 0) return Icons.swap_horiz;
    return Icons.check_circle;
  }

  String _getTransferText(int pendingCount, int approvedCount) {
    if (pendingCount > 0) return '$pendingCount Pending';
    if (approvedCount > 0) return '$approvedCount Approved';
    return 'No Transfers';
  }
}

/// Widget for displaying data subject rights status
class DataSubjectRightsWidget extends ConsumerWidget {
  final String userId;
  final bool showDetails;

  const DataSubjectRightsWidget({
    super.key,
    required this.userId,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.watch(dataSovereigntyServiceProvider);
    final pendingRights = sovereigntyService.getRightsRequests(
      userId: userId,
      status: DataSubjectRightsStatus.pending,
    );
    final processingRights = sovereigntyService.getRightsRequests(
      userId: userId,
      status: DataSubjectRightsStatus.processing,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/data-sovereignty'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getRightsColor(pendingRights.length, processingRights.length).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getRightsColor(pendingRights.length, processingRights.length).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getRightsIcon(pendingRights.length, processingRights.length),
              size: 16,
              color: _getRightsColor(pendingRights.length, processingRights.length),
            ),
            const SizedBox(width: 6),
            Text(
              _getRightsText(pendingRights.length, processingRights.length),
              style: TextStyle(
                color: _getRightsColor(pendingRights.length, processingRights.length),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: _getRightsColor(pendingRights.length, processingRights.length),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRightsColor(int pendingCount, int processingCount) {
    if (pendingCount > 0) return Colors.orange;
    if (processingCount > 0) return Colors.blue;
    return Colors.green;
  }

  IconData _getRightsIcon(int pendingCount, int processingCount) {
    if (pendingCount > 0) return Icons.gavel;
    if (processingCount > 0) return Icons.hourglass_empty;
    return Icons.verified_user;
  }

  String _getRightsText(int pendingCount, int processingCount) {
    if (pendingCount > 0) return '$pendingCount Pending';
    if (processingCount > 0) return '$processingCount Processing';
    return 'Rights Active';
  }
}

/// Banner for data sovereignty alerts and notifications
class DataSovereigntyBanner extends ConsumerWidget {
  final String userId;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  const DataSovereigntyBanner({
    super.key,
    required this.userId,
    this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sovereigntyService = ref.watch(dataSovereigntyServiceProvider);
    final pendingTransfers = sovereigntyService.getTransferRequests(
      userId: userId,
      status: CrossBorderTransferStatus.pending,
    );
    final pendingRights = sovereigntyService.getRightsRequests(
      userId: userId,
      status: DataSubjectRightsStatus.pending,
    );
    
    final totalPending = pendingTransfers.length + pendingRights.length;
    
    if (totalPending == 0) {
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
              Icon(Icons.policy, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data Sovereignty Action Required',
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
            'You have $totalPending pending data sovereignty item${totalPending > 1 ? 's' : ''}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (pendingTransfers.isNotEmpty) ...[
            Text('• ${pendingTransfers.length} cross-border transfer request${pendingTransfers.length > 1 ? 's' : ''}'),
          ],
          if (pendingRights.isNotEmpty) ...[
            Text('• ${pendingRights.length} data rights request${pendingRights.length > 1 ? 's' : ''}'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/data-sovereignty');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade700),
                  ),
                  child: Text(
                    'Review Items',
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
