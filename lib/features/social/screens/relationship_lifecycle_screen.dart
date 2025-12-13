import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../services/relationship_service.dart';

/// Provider for relationship service
final relationshipServiceProvider = Provider((ref) => RelationshipService());

/// Screen for managing relationship lifecycle and termination
class RelationshipLifecycleScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? targetUserId;
  final String? relationshipId;

  const RelationshipLifecycleScreen({
    super.key,
    required this.userId,
    this.targetUserId,
    this.relationshipId,
  });

  @override
  ConsumerState<RelationshipLifecycleScreen> createState() => _RelationshipLifecycleScreenState();
}

class _RelationshipLifecycleScreenState extends ConsumerState<RelationshipLifecycleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Relationship> _activeRelationships = [];
  List<RelationshipTerminationRequest> _terminationRequests = [];
  List<ContentManagementResult> _contentResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final relationshipService = ref.read(relationshipServiceProvider);
      
      // Load active relationships
      _activeRelationships = relationshipService.relationships
          .where((rel) => rel.status == RelationshipStatus.active)
          .where((rel) => rel.userId == widget.userId || rel.targetUserId == widget.userId)
          .toList();
      
      // Load termination requests
      _terminationRequests = relationshipService.getTerminationRequestsForUser(widget.userId);
      
      // Load content management results
      _contentResults = relationshipService.getContentManagementResultsForUser(widget.userId);
      
    } catch (e) {
      _showErrorDialog('Error loading data', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relationship Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.people)),
            Tab(text: 'Termination', icon: Icon(Icons.warning)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveRelationshipsTab(),
                _buildTerminationTab(),
                _buildHistoryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTerminationDialog,
        child: const Icon(Icons.add),
        tooltip: 'Initiate Termination',
      ),
    );
  }

  Widget _buildActiveRelationshipsTab() {
    if (_activeRelationships.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active relationships',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Connect with others to see them here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeRelationships.length,
      itemBuilder: (context, index) {
        final relationship = _activeRelationships[index];
        final isInitiator = relationship.userId == widget.userId;
        final otherUserId = isInitiator ? relationship.targetUserId : relationship.userId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(_getDisplayName(otherUserId)[0]),
            ),
            title: Text(_getDisplayName(otherUserId)),
            subtitle: Text('${_getRelationshipTypeDisplayName(relationship.type)} • '
                        'Since ${_formatDate(relationship.createdAt)}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'terminate',
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Terminate Relationship'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'terminate') {
                  _showTerminationOptionsDialog(relationship);
                }
              },
            ),
            onTap: () => _showRelationshipDetails(relationship),
          ),
        );
      },
    );
  }

  Widget _buildTerminationTab() {
    final pendingRequests = _terminationRequests.where((req) => !req.isProcessed).toList();
    
    if (pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No pending terminations',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'All relationship changes are processed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        final isInitiator = request.initiatedByUserId == widget.userId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              _getTerminationOptionIcon(request.option),
              color: _getTerminationOptionColor(request.option),
            ),
            title: Text(_getDisplayName(isInitiator ? request.targetUserId : request.initiatedByUserId)),
            subtitle: Text('${_getTerminationOptionDisplayName(request.option)} • '
                        '${_formatDate(request.createdAt)}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.reason != null) ...[
                      Text('Reason:', style: Theme.of(context).textTheme.titleSmall),
                      Text(request.reason!),
                      const SizedBox(height: 12),
                    ],
                    Text('Content Management Option:', style: Theme.of(context).textTheme.titleSmall),
                    Text(_getTerminationOptionDescription(request.option)),
                    const SizedBox(height: 16),
                    if (isInitiator) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _cancelTerminationRequest(request.id),
                              child: const Text('Cancel Request'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _processTerminationRequest(request.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Process Termination'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _processTerminationRequest(request.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Acknowledge & Process'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final processedRequests = _terminationRequests.where((req) => req.isProcessed).toList();
    final allResults = _contentResults;
    
    if (processedRequests.isEmpty && allResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No history available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Processed terminations will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: processedRequests.length + allResults.length,
      itemBuilder: (context, index) {
        if (index < processedRequests.length) {
          final request = processedRequests[index];
          final isInitiator = request.initiatedByUserId == widget.userId;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              title: Text('Terminated with ${_getDisplayName(isInitiator ? request.targetUserId : request.initiatedByUserId)}'),
              subtitle: Text('${_getTerminationOptionDisplayName(request.option)} • '
                          'Processed ${_formatDate(request.processedAt ?? DateTime.now())}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTerminationDetails(request),
            ),
          );
        } else {
          final resultIndex = index - processedRequests.length;
          final result = allResults[resultIndex];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                result.isSuccess ? Icons.check_circle : Icons.error,
                color: result.isSuccess ? Colors.green : Colors.red,
              ),
              title: Text(result.isSuccess ? 'Content Management Successful' : 'Content Management Failed'),
              subtitle: Text('${_getTerminationOptionDisplayName(result.option)} • '
                          '${_formatDate(result.createdAt)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResultDetails(result),
            ),
          );
        }
      },
    );
  }

  void _showTerminationDialog() {
    if (_activeRelationships.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active relationships to terminate')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initiate Relationship Termination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a relationship to terminate and choose how to handle shared content.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Relationship',
                border: OutlineInputBorder(),
              ),
              items: _activeRelationships.map((relationship) {
                final isInitiator = relationship.userId == widget.userId;
                final otherUserId = isInitiator ? relationship.targetUserId : relationship.userId;
                return DropdownMenuItem(
                  value: relationship.id,
                  child: Text(_getDisplayName(otherUserId)),
                );
              }).toList(),
              onChanged: (value) {
                Navigator.of(context).pop();
                if (value != null) {
                  final relationship = _activeRelationships.firstWhere((rel) => rel.id == value);
                  _showTerminationOptionsDialog(relationship);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTerminationOptionsDialog(Relationship relationship) {
    final isInitiator = relationship.userId == widget.userId;
    final otherUserId = isInitiator ? relationship.targetUserId : relationship.userId;
    RelationshipTerminationOption? selectedOption;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Terminate with ${_getDisplayName(otherUserId)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose how to handle shared content:'),
                const SizedBox(height: 16),
                ...RelationshipTerminationOption.values.map((option) => RadioListTile<RelationshipTerminationOption>(
                  title: Text(_getTerminationOptionDisplayName(option)),
                  subtitle: Text(_getTerminationOptionDescription(option)),
                  value: option,
                  groupValue: selectedOption,
                  onChanged: (value) {
                    setState(() => selectedOption = value);
                  },
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedOption == null ? null : () {
                Navigator.of(context).pop();
                _initiateTermination(relationship.id, selectedOption!, reasonController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Initiate Termination'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateTermination(String relationshipId, RelationshipTerminationOption option, String reason) async {
    try {
      final relationshipService = ref.read(relationshipServiceProvider);
      await relationshipService.initiateRelationshipTermination(
        initiatedByUserId: widget.userId,
        targetUserId: _getOtherUserId(relationshipId),
        option: option,
        reason: reason.isEmpty ? null : reason,
      );
      
      await _loadData();
      _showSuccessMessage('Termination request initiated successfully');
    } catch (e) {
      _showErrorDialog('Error initiating termination', e.toString());
    }
  }

  Future<void> _processTerminationRequest(String requestId) async {
    try {
      final relationshipService = ref.read(relationshipServiceProvider);
      await relationshipService.processRelationshipTermination(
        requestId: requestId,
        processedByUserId: widget.userId,
      );
      
      await _loadData();
      _showSuccessMessage('Termination processed successfully');
    } catch (e) {
      _showErrorDialog('Error processing termination', e.toString());
    }
  }

  Future<void> _cancelTerminationRequest(String requestId) async {
    // Implementation for canceling termination request
    _showSuccessMessage('Termination request cancelled');
    await _loadData();
  }

  void _showRelationshipDetails(Relationship relationship) {
    final isInitiator = relationship.userId == widget.userId;
    final otherUserId = isInitiator ? relationship.targetUserId : relationship.userId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getDisplayName(otherUserId)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getRelationshipTypeDisplayName(relationship.type)}'),
            Text('Status: ${_getRelationshipStatusDisplayName(relationship.status)}'),
            Text('Started: ${_formatDate(relationship.createdAt)}'),
            if (relationship.updatedAt != null)
              Text('Updated: ${_formatDate(relationship.updatedAt!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showTerminationOptionsDialog(relationship);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
  }

  void _showTerminationDetails(RelationshipTerminationRequest request) {
    final isInitiator = request.initiatedByUserId == widget.userId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termination Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('With: ${_getDisplayName(isInitiator ? request.targetUserId : request.initiatedByUserId)}'),
            Text('Option: ${_getTerminationOptionDisplayName(request.option)}'),
            Text('Initiated: ${_formatDate(request.createdAt)}'),
            Text('Processed: ${_formatDate(request.processedAt ?? DateTime.now())}'),
            if (request.reason != null) ...[
              const SizedBox(height: 8),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(request.reason!),
            ],
          ],
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

  void _showResultDetails(ContentManagementResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.isSuccess ? 'Content Management Success' : 'Content Management Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Option: ${_getTerminationOptionDisplayName(result.option)}'),
            Text('Processed: ${_formatDate(result.createdAt)}'),
            Text('Status: ${result.isSuccess ? 'Success' : 'Failed'}'),
            if (result.errorMessage != null) ...[
              const SizedBox(height: 8),
              const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(result.errorMessage!),
            ],
            const SizedBox(height: 8),
            const Text('Affected Content:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Events: ${result.affectedEvents.values.fold(0, (sum, list) => sum + list.length)}'),
            Text('Contexts: ${result.affectedContexts.values.fold(0, (sum, list) => sum + list.length)}'),
          ],
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

  String _getOtherUserId(String relationshipId) {
    final relationship = _activeRelationships.firstWhere((rel) => rel.id == relationshipId);
    return relationship.userId == widget.userId ? relationship.targetUserId : relationship.userId;
  }

  String _getDisplayName(String userId) {
    // This would typically fetch from user service
    return userId.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join(' ');
  }

  String _getRelationshipTypeDisplayName(RelationshipType type) {
    switch (type) {
      case RelationshipType.friend:
        return 'Friend';
      case RelationshipType.family:
        return 'Family';
      case RelationshipType.colleague:
        return 'Colleague';
      case RelationshipType.acquaintance:
        return 'Acquaintance';
    }
  }

  String _getRelationshipStatusDisplayName(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.pending:
        return 'Pending';
      case RelationshipStatus.active:
        return 'Active';
      case RelationshipStatus.terminated:
        return 'Terminated';
    }
  }

  String _getTerminationOptionDisplayName(RelationshipTerminationOption option) {
    switch (option) {
      case RelationshipTerminationOption.archive:
        return 'Archive Content';
      case RelationshipTerminationOption.redact:
        return 'Redact Content';
      case RelationshipTerminationOption.bifurcate:
        return 'Bifurcate Content';
      case RelationshipTerminationOption.delete:
        return 'Delete Content';
    }
  }

  String _getTerminationOptionDescription(RelationshipTerminationOption option) {
    switch (option) {
      case RelationshipTerminationOption.archive:
        return 'Keep shared content but remove access to it';
      case RelationshipTerminationOption.redact:
        return 'Remove user\'s content from shared events';
      case RelationshipTerminationOption.bifurcate:
        return 'Create separate copies of shared content';
      case RelationshipTerminationOption.delete:
        return 'Completely remove all shared content';
    }
  }

  IconData _getTerminationOptionIcon(RelationshipTerminationOption option) {
    switch (option) {
      case RelationshipTerminationOption.archive:
        return Icons.archive;
      case RelationshipTerminationOption.redact:
        return Icons.content_cut;
      case RelationshipTerminationOption.bifurcate:
        return Icons.call_split;
      case RelationshipTerminationOption.delete:
        return Icons.delete_forever;
    }
  }

  Color _getTerminationOptionColor(RelationshipTerminationOption option) {
    switch (option) {
      case RelationshipTerminationOption.archive:
        return Colors.blue;
      case RelationshipTerminationOption.redact:
        return Colors.orange;
      case RelationshipTerminationOption.bifurcate:
        return Colors.purple;
      case RelationshipTerminationOption.delete:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
}
