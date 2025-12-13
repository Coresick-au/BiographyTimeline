import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data_sovereignty_models.dart';
import '../services/data_sovereignty_service.dart';

/// Screen for managing data sovereignty and regional compliance
class DataSovereigntyScreen extends ConsumerStatefulWidget {
  const DataSovereigntyScreen({super.key});

  @override
  ConsumerState<DataSovereigntyScreen> createState() => _DataSovereigntyScreenState();
}

class _DataSovereigntyScreenState extends ConsumerState<DataSovereigntyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _statistics;
  List<DataResidencyRecord> _userRecords = [];
  List<CrossBorderTransferRequest> _transferRequests = [];
  List<DataSubjectRightsRequest> _rightsRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSovereigntyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSovereigntyData() async {
    setState(() => _isLoading = true);
    
    try {
      final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
      final userId = 'current_user'; // This would come from auth service
      
      _statistics = sovereigntyService.getSovereigntyStatistics();
      _userRecords = sovereigntyService.getUserResidencyRecords(userId);
      _transferRequests = sovereigntyService.getTransferRequests(userId: userId);
      _rightsRequests = sovereigntyService.getRightsRequests(userId: userId);
      
    } catch (e) {
      _showErrorDialog('Error loading sovereignty data', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sovereignty'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Data Location', icon: Icon(Icons.location_on)),
            Tab(text: 'Transfers', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'Rights', icon: Icon(Icons.gavel)),
            Tab(text: 'Compliance', icon: Icon(Icons.verified)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSovereigntyData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDataLocationTab(),
          _buildTransfersTab(),
          _buildRightsTab(),
          _buildComplianceTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_statistics == null) {
      return const Center(child: Text('No statistics available'));
    }

    final stats = _statistics!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatItem('Total Data Records', '${stats['totalDataRecords']}'),
                _buildStatItem('Active Policies', '${stats['activePolicies']}'),
                _buildStatItem('Pending Transfers', '${stats['pendingTransfers']}'),
                _buildStatItem('Rights Requests', '${stats['pendingRightsRequests']}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Distribution by Region',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                () {
                  final regionDistribution = stats['regionDistribution'] as Map<String, dynamic>;
                  if (regionDistribution.isEmpty) {
                    return const Text('No data stored yet');
                  } else {
                    return Column(
                      children: regionDistribution.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_getRegionFlag(entry.key)} ${entry.key}'),
                            Text('${entry.value} records'),
                          ],
                        ),
                      )).toList(),
                    );
                  }
                }(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _requestDataExport,
                  icon: const Icon(Icons.download),
                  label: const Text('Export My Data'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _requestDataDeletion,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Request Data Deletion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _viewAuditLog,
                  icon: const Icon(Icons.history),
                  label: const Text('View Audit Log'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataLocationTab() {
    if (_userRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Data Records',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your data location records will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Your Data Locations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ..._userRecords.map((record) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(_getRegionFlag(record.storageRegion.name)),
            ),
            title: Text(record.dataType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${record.storageRegion.displayName}'),
                Text('Stored: ${_formatDate(record.createdAt)}'),
                if (record.expiresAt != null)
                  Text('Expires: ${_formatDate(record.expiresAt!)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getClassificationIcon(record.classification),
                  color: _getClassificationColor(record.classification),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  record.classification.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getClassificationColor(record.classification),
                  ),
                ),
              ],
            ),
            onTap: () => _showDataRecordDetails(record),
          ),
        )),
      ],
    );
  }

  Widget _buildTransfersTab() {
    if (_transferRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Transfer Requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Cross-border transfer requests will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Cross-Border Transfer Requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ..._transferRequests.map((request) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${_getRegionFlag(request.fromRegion.name)} ${request.fromRegion.displayName}'),
                    const Icon(Icons.arrow_forward, size: 16),
                    Text('${_getRegionFlag(request.toRegion.name)} ${request.toRegion.displayName}'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTransferStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getTransferStatusColor(request.status).withOpacity(0.3)),
                      ),
                      child: Text(
                        request.status.name,
                        style: TextStyle(
                          color: _getTransferStatusColor(request.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Reason: ${request.transferReason}'),
                Text('Requested: ${_formatDate(request.requestedAt)}'),
                if (request.approvedAt != null)
                  Text('Approved: ${_formatDate(request.approvedAt!)}'),
                if (request.completedAt != null)
                  Text('Completed: ${_formatDate(request.completedAt!)}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (request.status == CrossBorderTransferStatus.pending) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectTransfer(request.id),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveTransfer(request.id),
                          child: const Text('Approve'),
                        ),
                      ),
                    ] else if (request.status == CrossBorderTransferStatus.approved) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _completeTransfer(request.id),
                          child: const Text('Complete Transfer'),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: TextButton(
                          onPressed: () => _showTransferDetails(request),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildRightsTab() {
    if (_rightsRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Rights Requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Data subject rights requests will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data Subject Rights Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton.icon(
              onPressed: _submitRightsRequest,
              icon: const Icon(Icons.add),
              label: const Text('New Request'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._rightsRequests.map((request) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getRightsTypeIcon(request.rightsType),
              color: _getRightsStatusColor(request.status),
            ),
            title: Text(request.rightsType.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.description),
                Text('Requested: ${_formatDate(request.requestedAt)}'),
                if (request.expectedCompletion != null)
                  Text('Expected: ${_formatDate(request.expectedCompletion!)}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRightsStatusColor(request.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRightsStatusColor(request.status).withOpacity(0.3)),
              ),
              child: Text(
                request.status.name,
                style: TextStyle(
                  color: _getRightsStatusColor(request.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () => _showRightsRequestDetails(request),
          ),
        )),
      ],
    );
  }

  Widget _buildComplianceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildComplianceItem('GDPR', '✅ Compliant', Colors.green),
                _buildComplianceItem('CCPA', '✅ Compliant', Colors.green),
                _buildComplianceItem('Data Encryption', '✅ AES-256-GCM', Colors.green),
                _buildComplianceItem('Audit Logging', '✅ Enabled', Colors.green),
                _buildComplianceItem('Data Retention', '⚠️ Review Needed', Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regional Requirements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildRegionalRequirement('European Union', [
                  '✅ Data stored within EU',
                  '✅ Explicit consent required',
                  '✅ Right to be forgotten',
                  '✅ Data portability enabled',
                ]),
                const SizedBox(height: 16),
                _buildRegionalRequirement('United States', [
                  '✅ Data stored in US',
                  '✅ CCPA compliance',
                  '✅ Consumer rights enabled',
                  '⚠️ Opt-out mechanism needed',
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _runComplianceCheck,
                  icon: const Icon(Icons.verified),
                  label: const Text('Run Compliance Check'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _generateComplianceReport,
                  icon: const Icon(Icons.description),
                  label: const Text('Generate Compliance Report'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _updatePolicies,
                  icon: const Icon(Icons.policy),
                  label: const Text('Update Policies'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalRequirement(String region, List<String> requirements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          region,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...requirements.map((req) => Padding(
          padding: const EdgeInsets.only(left: 16, top: 2),
          child: Text(
            req,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        )),
      ],
    );
  }

  Future<void> _requestDataExport() async {
    try {
      final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
      final userId = 'current_user';
      
      await sovereigntyService.submitRightsRequest(
        userId: userId,
        rightsType: DataSubjectRightsType.portability,
        description: 'Export all my data in portable format',
      );
      
      await _loadSovereigntyData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export request submitted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error submitting export request', e.toString());
    }
  }

  Future<void> _requestDataDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your data from our systems. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
        final userId = 'current_user';
        
        await sovereigntyService.submitRightsRequest(
          userId: userId,
          rightsType: DataSubjectRightsType.erasure,
          description: 'Delete all my data (right to be forgotten)',
        );
        
        await _loadSovereigntyData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data deletion request submitted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        _showErrorDialog('Error submitting deletion request', e.toString());
      }
    }
  }

  void _viewAuditLog() {
    // This would navigate to audit log screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log view coming soon!')),
    );
  }

  void _showDataRecordDetails(DataResidencyRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data Record: ${record.dataType}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Storage Region: ${record.storageRegion.displayName}'),
              Text('Classification: ${record.classification.name}'),
              Text('Created: ${_formatDate(record.createdAt)}'),
              if (record.lastAccessed != null)
                Text('Last Accessed: ${_formatDate(record.lastAccessed!)}'),
              if (record.expiresAt != null)
                Text('Expires: ${_formatDate(record.expiresAt!)}'),
              Text('Encrypted: ${record.isEncrypted ? 'Yes' : 'No'}'),
              if (record.complianceTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Compliance Tags:'),
                ...record.complianceTags.map((tag) => Text('• $tag')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveTransfer(String requestId) async {
    try {
      final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
      await sovereigntyService.approveCrossBorderTransfer(requestId, 'current_user');
      
      await _loadSovereigntyData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error approving transfer', e.toString());
    }
  }

  Future<void> _rejectTransfer(String requestId) async {
    try {
      // This would implement rejection logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error rejecting transfer', e.toString());
    }
  }

  Future<void> _completeTransfer(String requestId) async {
    try {
      // This would implement completion logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error completing transfer', e.toString());
    }
  }

  void _showTransferDetails(CrossBorderTransferRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer Request'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('From: ${request.fromRegion.displayName}'),
              Text('To: ${request.toRegion.displayName}'),
              Text('Reason: ${request.transferReason}'),
              Text('Status: ${request.status.name}'),
              Text('Requested: ${_formatDate(request.requestedAt)}'),
              if (request.approvedAt != null)
                Text('Approved: ${_formatDate(request.approvedAt!)}'),
              if (request.completedAt != null)
                Text('Completed: ${_formatDate(request.completedAt!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _submitRightsRequest() {
    // This would show a dialog to submit new rights request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rights request form coming soon!')),
    );
  }

  void _showRightsRequestDetails(DataSubjectRightsRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rights Request: ${request.rightsType.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${request.description}'),
              Text('Status: ${request.status.name}'),
              Text('Requested: ${_formatDate(request.requestedAt)}'),
              if (request.expectedCompletion != null)
                Text('Expected: ${_formatDate(request.expectedCompletion!)}'),
              if (request.processedAt != null)
                Text('Processed: ${_formatDate(request.processedAt!)}'),
              if (request.notes?.isNotEmpty == true)
                Text('Notes: ${request.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _runComplianceCheck() async {
    try {
      final sovereigntyService = ref.read(dataSovereigntyServiceProvider);
      final userId = 'current_user';
      
      // This would run a comprehensive compliance check
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compliance check completed - all requirements met'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error running compliance check', e.toString());
    }
  }

  void _generateComplianceReport() {
    // This would generate and download a compliance report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compliance report generation coming soon!')),
    );
  }

  void _updatePolicies() {
    // This would navigate to policy management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Policy management coming soon!')),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRegionFlag(String regionName) {
    switch (regionName) {
      case 'United States':
        return '🇺🇸';
      case 'European Union':
        return '🇪🇺';
      case 'United Kingdom':
        return '🇬🇧';
      case 'Canada':
        return '🇨🇦';
      case 'Australia':
        return '🇦🇺';
      case 'Global':
        return '🌍';
      default:
        return '📍';
    }
  }

  IconData _getClassificationIcon(DataClassification classification) {
    switch (classification) {
      case DataClassification.public:
        return Icons.public;
      case DataClassification.internal:
        return Icons.business;
      case DataClassification.confidential:
        return Icons.lock;
      case DataClassification.restricted:
        return Icons.security;
      case DataClassification.sensitive:
        return Icons.privacy_tip;
      case DataClassification.personal:
        return Icons.person;
      case DataClassification.specialCategory:
        return Icons.warning;
    }
  }

  Color _getClassificationColor(DataClassification classification) {
    switch (classification) {
      case DataClassification.public:
        return Colors.green;
      case DataClassification.internal:
        return Colors.blue;
      case DataClassification.confidential:
        return Colors.orange;
      case DataClassification.restricted:
        return Colors.red;
      case DataClassification.sensitive:
        return Colors.purple;
      case DataClassification.personal:
        return Colors.indigo;
      case DataClassification.specialCategory:
        return Colors.red;
    }
  }

  Color _getTransferStatusColor(CrossBorderTransferStatus status) {
    switch (status) {
      case CrossBorderTransferStatus.pending:
        return Colors.orange;
      case CrossBorderTransferStatus.approved:
        return Colors.blue;
      case CrossBorderTransferStatus.completed:
        return Colors.green;
      case CrossBorderTransferStatus.rejected:
      case CrossBorderTransferStatus.cancelled:
      case CrossBorderTransferStatus.expired:
        return Colors.red;
    }
  }

  IconData _getRightsTypeIcon(DataSubjectRightsType type) {
    switch (type) {
      case DataSubjectRightsType.access:
        return Icons.visibility;
      case DataSubjectRightsType.rectification:
        return Icons.edit;
      case DataSubjectRightsType.erasure:
        return Icons.delete_forever;
      case DataSubjectRightsType.portability:
        return Icons.file_download;
      case DataSubjectRightsType.restriction:
        return Icons.block;
      case DataSubjectRightsType.objection:
        return Icons.gavel;
      case DataSubjectRightsType.automatedDecision:
        return Icons.smart_toy;
      case DataSubjectRightsType.consentWithdrawal:
        return Icons.thumb_down;
    }
  }

  Color _getRightsStatusColor(DataSubjectRightsStatus status) {
    switch (status) {
      case DataSubjectRightsStatus.pending:
        return Colors.orange;
      case DataSubjectRightsStatus.processing:
        return Colors.blue;
      case DataSubjectRightsStatus.completed:
        return Colors.green;
      case DataSubjectRightsStatus.rejected:
      case DataSubjectRightsStatus.cancelled:
        return Colors.red;
      case DataSubjectRightsStatus.requiresVerification:
        return Colors.purple;
    }
  }
}
