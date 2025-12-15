import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consent_models.dart';
import '../services/consent_service.dart';

/// Screen for managing user consent preferences and requests
class ConsentManagementScreen extends ConsumerStatefulWidget {
  const ConsentManagementScreen({super.key});

  @override
  ConsumerState<ConsentManagementScreen> createState() => _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends ConsumerState<ConsentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ConsentPreferences? _userPreferences;
  List<ConsentRecord> _userConsents = [];
  List<ConsentRequest> _pendingRequests = [];
  List<ConsentTemplate> _templates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConsentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConsentData() async {
    setState(() => _isLoading = true);
    
    try {
      final consentService = ref.read(consentServiceProvider);
      final userId = 'current_user'; // This would come from auth service
      
      _userPreferences = consentService.getUserPreferences(userId);
      _userConsents = consentService.getUserConsents(userId);
      _pendingRequests = consentService.getPendingRequests(userId);
      _templates = consentService.getTemplates();
      
    } catch (e) {
      _showErrorDialog('Error loading consent data', e.toString());
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
        title: const Text('Consent Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Requests', icon: Icon(Icons.notifications)),
            Tab(text: 'Preferences', icon: Icon(Icons.settings)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConsentData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRequestsTab(),
          _buildPreferencesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final expiringConsents = _userConsents.where((c) => 
        c.status == ConsentStatus.granted && 
        c.expiresAt != null &&
        c.expiresAt!.difference(DateTime.now()).inDays <= 30);

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
                  'Consent Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildConsentStatusItem('Active Consents', 
                    _userConsents.where((c) => c.status == ConsentStatus.granted).length,
                    Colors.green),
                _buildConsentStatusItem('Pending Requests', 
                    _pendingRequests.length,
                    Colors.orange),
                _buildConsentStatusItem('Denied Consents', 
                    _userConsents.where((c) => c.status == ConsentStatus.denied).length,
                    Colors.red),
                _buildConsentStatusItem('Withdrawn Consents', 
                    _userConsents.where((c) => c.status == ConsentStatus.withdrawn).length,
                    Colors.grey),
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
                  onPressed: _showConsentCenter,
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Consents'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _exportConsentData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export My Data'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showPrivacySettings,
                  icon: const Icon(Icons.privacy_tip),
                  label: const Text('Privacy Settings'),
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
                  'Expiring Soon',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (expiringConsents.isEmpty)
                  const Text('No consents expiring soon')
                else
                  ...expiringConsents.map((consent) => ListTile(
                    leading: Icon(Icons.schedule, color: Colors.orange),
                    title: Text(consent.consentType.displayName),
                    subtitle: Text('Expires in ${consent.daysUntilExpiration} days'),
                    trailing: TextButton(
                      onPressed: () => _renewConsent(consent.id),
                      child: const Text('Renew'),
                    ),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Pending Requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
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
          'Pending Consent Requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ..._pendingRequests.map((request) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getConsentTypeIcon(request.consentType),
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.consentType.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (request.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  request.requestMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (request.detailedDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    request.detailedDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                if (request.requiredPermissions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Required Permissions:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ...request.requiredPermissions.map((permission) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• $permission',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToRequest(request.id, ConsentStatus.denied),
                        child: const Text('Deny'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToRequest(request.id, ConsentStatus.granted),
                        child: const Text('Grant'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPreferencesTab() {
    if (_userPreferences == null) {
      return const Center(child: Text('No preferences available'));
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
                  'Consent Preferences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Require Explicit Consent'),
                  subtitle: const Text('Always ask for consent before processing data'),
                  value: _userPreferences!.requireExplicitConsent,
                  onChanged: (value) {
                    _updatePreference('requireExplicitConsent', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-Renew Consents'),
                  subtitle: const Text('Automatically renew consents before they expire'),
                  value: _userPreferences!.autoRenewConsent,
                  onChanged: (value) {
                    _updatePreference('autoRenewConsent', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Granular Consent'),
                  subtitle: const Text('Enable detailed permission controls'),
                  value: _userPreferences!.allowGranularConsent,
                  onChanged: (value) {
                    _updatePreference('allowGranularConsent', value);
                  },
                ),
                ListTile(
                  title: const Text('Default Consent Duration'),
                  subtitle: Text('${(_userPreferences!.defaultConsentDuration.inDays)} days'),
                  trailing: DropdownButton<int>(
                    value: _userPreferences!.defaultConsentDuration.inDays,
                    items: [30, 90, 180, 365].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days days'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updatePreference('defaultConsentDuration', Duration(days: value));
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Consent Reminder'),
                  subtitle: Text('${_userPreferences!.consentReminderDays} days before expiration'),
                  trailing: DropdownButton<int>(
                    value: _userPreferences!.consentReminderDays,
                    items: [7, 14, 30, 60].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days days'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updatePreference('consentReminderDays', value);
                      }
                    },
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
                  'Default Consent Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...ConsentType.values.map((type) {
                  final currentStatus = _userPreferences!.defaultPreferences[type] ?? 
                                     ConsentStatus.pending;
                  return SwitchListTile(
                    title: Text(type.displayName),
                    subtitle: Text(type.description),
                    value: currentStatus == ConsentStatus.granted,
                    onChanged: (value) {
                      _updateDefaultConsent(type, value ? ConsentStatus.granted : ConsentStatus.denied);
                    },
                  );
                }),
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
                  'Blocked Consent Types',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'These consent types will be automatically denied',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ConsentType.values.map((type) {
                    final isBlocked = _userPreferences!.blockedConsentTypes.contains(type);
                    return FilterChip(
                      label: Text(type.displayName),
                      selected: isBlocked,
                      onSelected: (selected) {
                        _toggleBlockedConsentType(type, selected);
                      },
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: Colors.red.shade100,
                      checkmarkColor: Colors.red,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Consent History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ..._userConsents.map((consent) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getConsentTypeIcon(consent.consentType),
              color: consent.status.color,
            ),
            title: Text(consent.consentType.displayName),
            subtitle: Text('${_formatDate(consent.respondedAt ?? consent.requestedAt)} • ${consent.status.displayName}'),
            trailing: consent.status == ConsentStatus.granted && consent.expiresAt != null
                ? Text('${consent.daysUntilExpiration}d left')
                : null,
            onTap: () => _showConsentDetails(consent),
          ),
        )),
      ],
    );
  }

  Widget _buildConsentStatusItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToRequest(String requestId, ConsentStatus response) async {
    try {
      final consentService = ref.read(consentServiceProvider);
      await consentService.respondToConsentRequest(
        requestId: requestId,
        response: response,
      );
      
      await _loadConsentData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consent ${response.displayName.toLowerCase()}'),
            backgroundColor: response == ConsentStatus.granted ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error responding to request', e.toString());
    }
  }

  Future<void> _renewConsent(String consentId) async {
    try {
      final consentService = ref.read(consentServiceProvider);
      await consentService.renewConsent(consentId);
      
      await _loadConsentData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent renewed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error renewing consent', e.toString());
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    if (_userPreferences == null) return;
    
    try {
      final consentService = ref.read(consentServiceProvider);
      var updatedPreferences = _userPreferences!.copyWith();
      
      switch (key) {
        case 'requireExplicitConsent':
          updatedPreferences = updatedPreferences.copyWith(requireExplicitConsent: value as bool);
          break;
        case 'autoRenewConsent':
          updatedPreferences = updatedPreferences.copyWith(autoRenewConsent: value as bool);
          break;
        case 'allowGranularConsent':
          updatedPreferences = updatedPreferences.copyWith(allowGranularConsent: value as bool);
          break;
        case 'defaultConsentDuration':
          updatedPreferences = updatedPreferences.copyWith(defaultConsentDuration: value as Duration);
          break;
        case 'consentReminderDays':
          updatedPreferences = updatedPreferences.copyWith(consentReminderDays: value as int);
          break;
      }
      
      await consentService.updateUserPreferences(updatedPreferences);
      await _loadConsentData();
      
    } catch (e) {
      _showErrorDialog('Error updating preference', e.toString());
    }
  }

  Future<void> _updateDefaultConsent(ConsentType type, ConsentStatus status) async {
    if (_userPreferences == null) return;
    
    try {
      final consentService = ref.read(consentServiceProvider);
      final updatedPreferences = _userPreferences!.copyWith(
        defaultPreferences: Map.from(_userPreferences!.defaultPreferences)..[type] = status,
      );
      
      await consentService.updateUserPreferences(updatedPreferences);
      await _loadConsentData();
      
    } catch (e) {
      _showErrorDialog('Error updating default consent', e.toString());
    }
  }

  Future<void> _toggleBlockedConsentType(ConsentType type, bool isBlocked) async {
    if (_userPreferences == null) return;
    
    try {
      final consentService = ref.read(consentServiceProvider);
      var blockedTypes = List<ConsentType>.from(_userPreferences!.blockedConsentTypes);
      
      if (isBlocked) {
        blockedTypes.add(type);
      } else {
        blockedTypes.remove(type);
      }
      
      final updatedPreferences = _userPreferences!.copyWith(
        blockedConsentTypes: blockedTypes,
      );
      
      await consentService.updateUserPreferences(updatedPreferences);
      await _loadConsentData();
      
    } catch (e) {
      _showErrorDialog('Error updating blocked consent types', e.toString());
    }
  }

  void _showConsentDetails(ConsentRecord consent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(consent.consentType.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${consent.status.displayName}'),
              Text('Requested: ${_formatDate(consent.requestedAt)}'),
              if (consent.respondedAt != null)
                Text('Responded: ${_formatDate(consent.respondedAt!)}'),
              if (consent.expiresAt != null)
                Text('Expires: ${_formatDate(consent.expiresAt!)}'),
              if (consent.requestMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Request: ${consent.requestMessage}'),
              ],
              if (consent.responseDetails?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Response: ${consent.responseDetails}'),
              ],
            ],
          ),
        ),
        actions: [
          if (consent.status == ConsentStatus.granted) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _renewConsent(consent.id);
              },
              child: const Text('Renew'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _withdrawConsent(consent.id);
              },
              child: const Text('Withdraw'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _withdrawConsent(String consentId) async {
    try {
      final consentService = ref.read(consentServiceProvider);
      await consentService.withdrawConsent(consentId);
      
      await _loadConsentData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent withdrawn'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error withdrawing consent', e.toString());
    }
  }

  void _showConsentCenter() {
    // This would navigate to a comprehensive consent center
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consent center coming soon!')),
    );
  }

  void _exportConsentData() async {
    try {
      final consentService = ref.read(consentServiceProvider);
      final userId = 'current_user';
      final exportData = consentService.exportUserData(userId);
      
      // In a real implementation, this would save to file or share
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent data exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error exporting data', e.toString());
    }
  }

  void _showPrivacySettings() {
    // This would navigate to privacy settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings coming soon!')),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getConsentTypeIcon(ConsentType type) {
    switch (type) {
      case ConsentType.dataProcessing:
        return Icons.storage;
      case ConsentType.analytics:
        return Icons.analytics;
      case ConsentType.marketing:
        return Icons.campaign;
      case ConsentType.thirdPartySharing:
        return Icons.share;
      case ConsentType.locationTracking:
        return Icons.location_on;
      case ConsentType.biometricAuth:
        return Icons.fingerprint;
      case ConsentType.personalizedContent:
        return Icons.recommend;
      case ConsentType.researchParticipation:
        return Icons.science;
      case ConsentType.emergencyContacts:
        return Icons.emergency;
      case ConsentType.mediaAnalysis:
        return Icons.image_search;
      case ConsentType.collaborativeFeatures:
        return Icons.groups;
    }
  }
}
