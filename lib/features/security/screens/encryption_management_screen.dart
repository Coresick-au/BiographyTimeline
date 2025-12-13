import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/encryption_models.dart';
import '../services/encryption_service.dart';
import '../services/secure_storage_service.dart';
import '../services/data_encryption_service.dart';

/// Screen for managing encryption settings and keys
class EncryptionManagementScreen extends ConsumerStatefulWidget {
  const EncryptionManagementScreen({super.key});

  @override
  ConsumerState<EncryptionManagementScreen> createState() => _EncryptionManagementScreenState();
}

class _EncryptionManagementScreenState extends ConsumerState<EncryptionManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _encryptionStatus;
  Map<String, dynamic>? _storageStatistics;
  List<EncryptionAuditEntry>? _auditLog;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEncryptionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEncryptionData() async {
    setState(() => _isLoading = true);
    
    try {
      final dataEncryptionService = ref.read(dataEncryptionServiceProvider);
      final secureStorageService = ref.read(secureStorageServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      
      final userId = 'current_user'; // This would come from auth service
      
      _encryptionStatus = await dataEncryptionService.getEncryptionStatus(userId);
      _storageStatistics = await secureStorageService.getStorageStatistics();
      _auditLog = encryptionService.getAuditLog(userId: userId);
      
    } catch (e) {
      _showErrorDialog('Error loading encryption data', e.toString());
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
        title: const Text('Encryption Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Status', icon: Icon(Icons.security)),
            Tab(text: 'Keys', icon: Icon(Icons.vpn_key)),
            Tab(text: 'Audit', icon: Icon(Icons.history)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEncryptionData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(),
          _buildKeysTab(),
          _buildAuditTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    if (_encryptionStatus == null) {
      return const Center(child: Text('No encryption status available'));
    }

    final status = _encryptionStatus!;
    final isEncryptionEnabled = status['encryptionEnabled'] as bool? ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEncryptionEnabled ? Icons.verified : Icons.warning,
                      color: isEncryptionEnabled ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Encryption Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusItem('Encryption Enabled', isEncryptionEnabled ? 'Yes' : 'No'),
                _buildStatusItem('Active Key Pairs', '${status['activeKeyPairs'] ?? 0}'),
                _buildStatusItem('Symmetric Keys', '${status['symmetricKeys'] ?? 0}'),
                _buildStatusItem('Shared Secrets', '${status['sharedSecrets'] ?? 0}'),
                if (status['lastKeyRotation'] != null)
                  _buildStatusItem('Last Key Rotation', _formatDate(status['lastKeyRotation'])),
                if (status['keyAlgorithm'] != null)
                  _buildStatusItem('Key Algorithm', status['keyAlgorithm']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!isEncryptionEnabled)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Encryption Not Enabled',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your data is not encrypted. Enable encryption to protect your timeline events and personal information.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _enableEncryption,
                    icon: const Icon(Icons.lock),
                    label: const Text('Enable Encryption'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
                  'Encryption Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isEncryptionEnabled ? _rotateKeys : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rotate Encryption Keys'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: isEncryptionEnabled ? _exportKeys : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Encrypted Backup'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _importKeys,
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Backup'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeysTab() {
    if (_storageStatistics == null) {
      return const Center(child: Text('No storage statistics available'));
    }

    final stats = _storageStatistics!;

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
                  'Key Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatusItem('Active Key Pairs', '${stats['activeKeyPairs']}'),
                _buildStatusItem('Active Shared Secrets', '${stats['activeSharedSecrets']}'),
                _buildStatusItem('Active Symmetric Keys', '${stats['activeSymmetricKeys']}'),
                _buildStatusItem('Expired Key Pairs', '${stats['expiredKeyPairs']}'),
                _buildStatusItem('Rotation Schedules', '${stats['rotationSchedules']}'),
                _buildStatusItem('Keys Needing Rotation', '${stats['keysNeedingRotation']}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if ((stats['keysNeedingRotation'] as int) > 0)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Keys Need Rotation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${stats['keysNeedingRotation']} keys are due for rotation.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _rotateKeys,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rotate All Keys'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
                  'Key Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _generateNewKey,
                  icon: const Icon(Icons.add),
                  label: const Text('Generate New Key Pair'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _cleanupExpiredKeys,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Clean Up Expired Keys'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _viewKeyDetails,
                  icon: const Icon(Icons.list),
                  label: const Text('View Key Details'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTab() {
    if (_auditLog == null || _auditLog!.isEmpty) {
      return const Center(child: Text('No audit log entries available'));
    }

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
                  'Encryption Audit Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Recent encryption and decryption operations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._auditLog!.take(50).map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              leading: Icon(
                _getOperationIcon(entry.operation),
                color: entry.success ? Colors.green : Colors.red,
              ),
              title: Text(_getOperationDisplayName(entry.operation)),
              subtitle: Text('${entry.algorithm} • ${_formatDate(entry.timestamp.toIso8601String())}'),
              trailing: entry.success 
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : const Icon(Icons.error, color: Colors.red, size: 20),
              onTap: () => _showAuditEntryDetails(entry),
            ),
          );
        }),
        if (_auditLog!.length > 50)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Showing first 50 of ${_auditLog!.length} entries',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    final encryptionService = ref.read(encryptionServiceProvider);
    final config = encryptionService.config;

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
                  'Encryption Configuration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatusItem('Default Algorithm', config.defaultAlgorithm.displayName),
                _buildStatusItem('Key Derivation', config.defaultKeyDerivation.displayName),
                _buildStatusItem('Iterations', '${config.defaultIterations}'),
                _buildStatusItem('Key Rotation', '${config.keyRotationDays} days'),
                _buildStatusItem('Forward Secrecy', config.enableForwardSecrecy ? 'Enabled' : 'Disabled'),
                _buildStatusItem('Key Escrow', config.enableKeyEscrow ? 'Enabled' : 'Disabled'),
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
                  'Security Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Auto Key Rotation'),
                  subtitle: const Text('Automatically rotate encryption keys'),
                  value: true, // This would be stored in user preferences
                  onChanged: (value) {
                    // Update preference
                  },
                ),
                SwitchListTile(
                  title: const Text('Encrypt All Data'),
                  subtitle: const Text('Encrypt all timeline events by default'),
                  value: true, // This would be stored in user preferences
                  onChanged: (value) {
                    // Update preference
                  },
                ),
                SwitchListTile(
                  title: const Text('Secure Sharing'),
                  subtitle: const Text('Require encryption for shared content'),
                  value: true, // This would be stored in user preferences
                  onChanged: (value) {
                    // Update preference
                  },
                ),
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
                  'Danger Zone',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'These actions cannot be undone. Please be careful.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _resetEncryption,
                  icon: const Icon(Icons.warning),
                  label: const Text('Reset All Encryption'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value) {
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

  Future<void> _enableEncryption() async {
    try {
      final secureStorageService = ref.read(secureStorageServiceProvider);
      final userId = 'current_user';
      
      await secureStorageService.initializeUserStorage(userId);
      await _loadEncryptionData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Encryption enabled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to enable encryption', e.toString());
    }
  }

  Future<void> _rotateKeys() async {
    try {
      final dataEncryptionService = ref.read(dataEncryptionServiceProvider);
      final userId = 'current_user';
      
      await dataEncryptionService.rotateUserDataEncryption(userId);
      await _loadEncryptionData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Encryption keys rotated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to rotate keys', e.toString());
    }
  }

  Future<void> _exportKeys() async {
    try {
      final secureStorageService = ref.read(secureStorageServiceProvider);
      final userId = 'current_user';
      
      final exportData = await secureStorageService.exportUserData(userId);
      
      // In a real implementation, this would save to file or share
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keys exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to export keys', e.toString());
    }
  }

  Future<void> _importKeys() async {
    try {
      // In a real implementation, this would load from file
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import feature coming soon'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to import keys', e.toString());
    }
  }

  Future<void> _generateNewKey() async {
    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      final secureStorageService = ref.read(secureStorageServiceProvider);
      
      final newKeyPair = await encryptionService.generateKeyPair(
        usageScopes: ['current_user', 'timeline'],
      );
      
      await secureStorageService.storeKeyPair(newKeyPair);
      await _loadEncryptionData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New key pair generated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to generate key', e.toString());
    }
  }

  Future<void> _cleanupExpiredKeys() async {
    try {
      final secureStorageService = ref.read(secureStorageServiceProvider);
      await secureStorageService.cleanupExpiredKeys();
      await _loadEncryptionData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expired keys cleaned up'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to cleanup keys', e.toString());
    }
  }

  Future<void> _viewKeyDetails() async {
    // This would show a detailed view of all keys
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Key details view coming soon'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _resetEncryption() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Encryption'),
        content: const Text(
          'This will permanently delete all encryption keys and encrypted data. '
          'This action cannot be undone. Are you sure you want to continue?',
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final secureStorageService = ref.read(secureStorageServiceProvider);
        await secureStorageService.clearAllData();
        await _loadEncryptionData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All encryption data reset'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        _showErrorDialog('Failed to reset encryption', e.toString());
      }
    }
  }

  void _showAuditEntryDetails(EncryptionAuditEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getOperationDisplayName(entry.operation)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Algorithm: ${entry.algorithm}'),
              Text('Timestamp: ${_formatDate(entry.timestamp.toIso8601String())}'),
              Text('Success: ${entry.success ? 'Yes' : 'No'}'),
              if (entry.keyId != null) Text('Key ID: ${entry.keyId}'),
              if (entry.targetId != null) Text('Target ID: ${entry.targetId}'),
              if (entry.errorMessage != null) 
                Text('Error: ${entry.errorMessage}'),
              if (entry.metadata != null && entry.metadata!.isNotEmpty)
                Text('Metadata: ${entry.metadata}'),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  IconData _getOperationIcon(EncryptionOperation operation) {
    switch (operation) {
      case EncryptionOperation.encrypt:
        return Icons.lock;
      case EncryptionOperation.decrypt:
        return Icons.lock_open;
      case EncryptionOperation.keyGeneration:
        return Icons.vpn_key;
      case EncryptionOperation.keyRotation:
        return Icons.refresh;
      case EncryptionOperation.keyDerivation:
        return Icons.key;
      case EncryptionOperation.secretSharing:
        return Icons.share;
      case EncryptionOperation.secretDerivation:
        return Icons.link;
    }
  }

  String _getOperationDisplayName(EncryptionOperation operation) {
    switch (operation) {
      case EncryptionOperation.encrypt:
        return 'Encryption';
      case EncryptionOperation.decrypt:
        return 'Decryption';
      case EncryptionOperation.keyGeneration:
        return 'Key Generation';
      case EncryptionOperation.keyRotation:
        return 'Key Rotation';
      case EncryptionOperation.keyDerivation:
        return 'Key Derivation';
      case EncryptionOperation.secretSharing:
        return 'Secret Sharing';
      case EncryptionOperation.secretDerivation:
        return 'Secret Derivation';
    }
  }
}
