import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/collaborative_models.dart';
import '../models/user_models.dart';
import '../services/collaborative_editing_service.dart';
import '../../../shared/models/timeline_event.dart';

/// Screen for collaborative editing of shared events
class CollaborativeEditingScreen extends StatefulWidget {
  final TimelineEvent event;
  final String currentUserId;
  final String currentUserName;

  const CollaborativeEditingScreen({
    Key? key,
    required this.event,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<CollaborativeEditingScreen> createState() => _CollaborativeEditingScreenState();
}

class _CollaborativeEditingScreenState extends State<CollaborativeEditingScreen> {
  late CollaborativeEditingService _collaborativeService;
  late List<EventContribution> _contributions;
  late List<EditConflict> _conflicts;
  late List<EventVersion> _versions;
  late ContentAttribution? _attribution;
  late CollaborativeSession? _currentSession;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _collaborativeService = CollaborativeEditingService();
    _initializeData();
    _setupListeners();
  }

  @override
  void dispose() {
    _collaborativeService.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _titleController.text = widget.event.title ?? '';
    _descriptionController.text = widget.event.description ?? '';
    
    // Load existing data
    _contributions = _collaborativeService.getContributionsForEvent(widget.event.id);
    _conflicts = _collaborativeService.getConflictsForEvent(widget.event.id);
    _versions = _collaborativeService.getVersionsForEvent(widget.event.id);
    _attribution = _collaborativeService.getAttributionForContent(widget.event.id);
    
    setState(() {
      _isLoading = false;
    });
  }

  void _setupListeners() {
    _collaborativeService.contributionsStream.listen((contributions) {
      setState(() {
        _contributions = contributions.where((c) => c.eventId == widget.event.id).toList();
      });
    });

    _collaborativeService.conflictsStream.listen((conflicts) {
      setState(() {
        _conflicts = conflicts.where((c) => c.eventId == widget.event.id).toList();
      });
    });

    _collaborativeService.versionsStream.listen((versions) {
      setState(() {
        _versions = versions.where((v) => v.eventId == widget.event.id).toList();
      });
    });

    _collaborativeService.attributionsStream.listen((attributions) {
      setState(() {
        _attribution = attributions.firstWhere(
          (a) => a.contentId == widget.event.id,
          orElse: () => ContentAttribution(
            contentId: widget.event.id,
            contentType: 'timeline_event',
            contributors: [],
            createdAt: DateTime.now(),
            lastModifiedAt: DateTime.now(),
            totalContributions: 0,
            contributionCounts: {},
          ),
        );
      });
    });
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
        title: Text('Collaborative Editing'),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveChanges,
            ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _showVersionHistory,
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: _showAttribution,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentSession != null) _buildActiveSessionBar(),
          if (_conflicts.isNotEmpty) _buildConflictsBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventDetails(),
                  SizedBox(height: 24),
                  _buildContributionsSection(),
                  SizedBox(height: 24),
                  _buildActivityFeed(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startCollaborativeSession,
        child: Icon(Icons.group_add),
        tooltip: 'Start Collaborative Session',
      ),
    );
  }

  Widget _buildActiveSessionBar() {
    if (_currentSession == null) return SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Colors.green.shade50,
      child: Row(
        children: [
          Icon(Icons.group, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active collaborative session with ${_currentSession!.activeEditorIds.length} editors',
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
          TextButton(
            onPressed: _endSession,
            child: Text('End Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictsBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_conflicts.length} conflicts need resolution',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
          TextButton(
            onPressed: _showConflictResolution,
            child: Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _hasUnsavedChanges = true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => setState(() => _hasUnsavedChanges = true),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasUnsavedChanges ? _saveTitleChanges : null,
                    child: Text('Save Changes'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addStoryContribution,
                    child: Text('Add Story'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Contributions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            if (_contributions.isEmpty)
              Text('No contributions yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _contributions.length,
                itemBuilder: (context, index) {
                  final contribution = _contributions[index];
                  return _buildContributionItem(contribution);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionItem(EventContribution contribution) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(contribution.contributorName[0].toUpperCase()),
      ),
      title: Text(_getContributionDescription(contribution)),
      subtitle: Text(
        'by ${contribution.contributorName} • ${_formatTime(contribution.timestamp)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contribution.isApproved)
            Icon(Icons.check_circle, color: Colors.green, size: 20)
          else if (contribution.conflictsWith.isNotEmpty)
            Icon(Icons.warning, color: Colors.orange, size: 20)
          else
            Icon(Icons.pending, color: Colors.grey, size: 20),
          PopupMenuButton<String>(
            onSelected: (action) => _handleContributionAction(contribution, action),
            itemBuilder: (context) => [
              if (!contribution.isApproved)
                PopupMenuItem(value: 'approve', child: Text('Approve')),
              if (!contribution.isApproved)
                PopupMenuItem(value: 'reject', child: Text('Reject')),
              PopupMenuItem(value: 'details', child: Text('View Details')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Feed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            if (_versions.isEmpty)
              Text('No activity yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _versions.length,
                itemBuilder: (context, index) {
                  final version = _versions.reversed.toList()[index];
                  return _buildVersionItem(version);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionItem(EventVersion version) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(version.createdByName[0].toUpperCase()),
      ),
      title: Text('Version ${version.versionNumber}'),
      subtitle: Text(
        'by ${version.createdByName} • ${_formatTime(version.createdAt)}',
      ),
      trailing: version.isCurrent 
          ? Chip(label: Text('Current'), backgroundColor: Colors.green.shade100)
          : null,
      onTap: () => _showVersionDetails(version),
    );
  }

  String _getContributionDescription(EventContribution contribution) {
    switch (contribution.type) {
      case ContributionType.titleEdit:
        return 'Updated title';
      case ContributionType.descriptionEdit:
        return 'Updated description';
      case ContributionType.storyAddition:
        return 'Added story content';
      case ContributionType.storyEdit:
        return 'Edited story';
      case ContributionType.mediaAddition:
        return 'Added media';
      case ContributionType.mediaRemoval:
        return 'Removed media';
      case ContributionType.locationUpdate:
        return 'Updated location';
      case ContributionType.attributeChange:
        return 'Updated attributes';
      case ContributionType.participantAdd:
        return 'Added participant';
      case ContributionType.participantRemove:
        return 'Removed participant';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _saveChanges() async {
    try {
      await _saveTitleChanges();
      await _saveDescriptionChanges();
      setState(() => _hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  Future<void> _saveTitleChanges() async {
    if (_titleController.text != widget.event.title) {
      await _collaborativeService.addContribution(
        eventId: widget.event.id,
        contributorId: widget.currentUserId,
        contributorName: widget.currentUserName,
        type: ContributionType.titleEdit,
        changes: {'title': _titleController.text},
        sessionId: _currentSession?.id,
      );
    }
  }

  Future<void> _saveDescriptionChanges() async {
    if (_descriptionController.text != widget.event.description) {
      await _collaborativeService.addContribution(
        eventId: widget.event.id,
        contributorId: widget.currentUserId,
        contributorName: widget.currentUserName,
        type: ContributionType.descriptionEdit,
        changes: {'description': _descriptionController.text},
        sessionId: _currentSession?.id,
      );
    }
  }

  void _addStoryContribution() {
    showDialog(
      context: context,
      builder: (context) => _StoryContributionDialog(
        eventId: widget.event.id,
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
        onAdd: (story) async {
          await _collaborativeService.addContribution(
            eventId: widget.event.id,
            contributorId: widget.currentUserId,
            contributorName: widget.currentUserName,
            type: ContributionType.storyAddition,
            changes: {'story': story},
            sessionId: _currentSession?.id,
          );
        },
      ),
    );
  }

  void _startCollaborativeSession() async {
    try {
      final participantIds = widget.event.participantIds;
      final session = await _collaborativeService.startCollaborativeSession(
        eventId: widget.event.id,
        participantIds: participantIds,
        initiatedBy: widget.currentUserId,
      );
      setState(() => _currentSession = session);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collaborative session started')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting session: $e')),
      );
    }
  }

  void _endSession() {
    setState(() => _currentSession = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Collaborative session ended')),
    );
  }

  void _showVersionHistory() {
    showDialog(
      context: context,
      builder: (context) => _VersionHistoryDialog(
        versions: _versions,
        onRestore: (version) {
          // Implement version restoration
        },
      ),
    );
  }

  void _showAttribution() {
    showDialog(
      context: context,
      builder: (context) => _AttributionDialog(attribution: _attribution),
    );
  }

  void _showConflictResolution() {
    showDialog(
      context: context,
      builder: (context) => _ConflictResolutionDialog(
        conflicts: _conflicts,
        onResolve: (conflictId, resolution, note) async {
          try {
            await _collaborativeService.resolveConflict(
              conflictId: conflictId,
              resolvedBy: widget.currentUserId,
              resolution: resolution,
              resolutionNote: note,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Conflict resolved')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error resolving conflict: $e')),
            );
          }
        },
      ),
    );
  }

  void _handleContributionAction(EventContribution contribution, String action) {
    switch (action) {
      case 'approve':
        _approveContribution(contribution);
        break;
      case 'reject':
        _rejectContribution(contribution);
        break;
      case 'details':
        _showContributionDetails(contribution);
        break;
    }
  }

  void _approveContribution(EventContribution contribution) async {
    try {
      await _collaborativeService.approveContribution(
        contributionId: contribution.id,
        approvedBy: widget.currentUserId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contribution approved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving contribution: $e')),
      );
    }
  }

  void _rejectContribution(EventContribution contribution) {
    // Remove contribution from list
    setState(() {
      _contributions.removeWhere((c) => c.id == contribution.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contribution rejected')),
    );
  }

  void _showContributionDetails(EventContribution contribution) {
    showDialog(
      context: context,
      builder: (context) => _ContributionDetailsDialog(contribution: contribution),
    );
  }

  void _showVersionDetails(EventVersion version) {
    showDialog(
      context: context,
      builder: (context) => _VersionDetailsDialog(version: version),
    );
  }
}

/// Dialog for adding story contributions
class _StoryContributionDialog extends StatefulWidget {
  final String eventId;
  final String currentUserId;
  final String currentUserName;
  final Function(String) onAdd;

  const _StoryContributionDialog({
    required this.eventId,
    required this.currentUserId,
    required this.currentUserName,
    required this.onAdd,
  });

  @override
  State<_StoryContributionDialog> createState() => _StoryContributionDialogState();
}

class _StoryContributionDialogState extends State<_StoryContributionDialog> {
  final _storyController = TextEditingController();

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Story Contribution'),
      content: TextField(
        controller: _storyController,
        decoration: InputDecoration(
          labelText: 'Story Content',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_storyController.text.isNotEmpty) {
              widget.onAdd(_storyController.text);
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

/// Dialog for showing version history
class _VersionHistoryDialog extends StatelessWidget {
  final List<EventVersion> versions;
  final Function(EventVersion) onRestore;

  const _VersionHistoryDialog({
    required this.versions,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Version History'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: versions.length,
          itemBuilder: (context, index) {
            final version = versions[versions.length - 1 - index];
            return ListTile(
              title: Text('Version ${version.versionNumber}'),
              subtitle: Text('by ${version.createdByName} • ${version.createdAt}'),
              trailing: version.isCurrent 
                  ? Chip(label: Text('Current'))
                  : TextButton(
                      onPressed: () => onRestore(version),
                      child: Text('Restore'),
                    ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog for showing content attribution
class _AttributionDialog extends StatelessWidget {
  final ContentAttribution? attribution;

  const _AttributionDialog({required this.attribution});

  @override
  Widget build(BuildContext context) {
    if (attribution == null) {
      return AlertDialog(
        title: Text('Content Attribution'),
        content: Text('No attribution data available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Content Attribution'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Contributions: ${attribution!.totalContributions}'),
            SizedBox(height: 16),
            Text('Contributors:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: attribution!.contributors.length,
                itemBuilder: (context, index) {
                  final contributor = attribution!.contributors[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(contributor.userName[0].toUpperCase()),
                    ),
                    title: Text(contributor.userName),
                    subtitle: Text('${contributor.contributionCount} contributions'),
                    trailing: contributor.isPrimaryContributor 
                        ? Chip(label: Text('Primary'), backgroundColor: Colors.blue.shade100)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog for resolving conflicts
class _ConflictResolutionDialog extends StatefulWidget {
  final List<EditConflict> conflicts;
  final Function(String, ConflictResolution, String?) onResolve;

  const _ConflictResolutionDialog({
    required this.conflicts,
    required this.onResolve,
  });

  @override
  State<_ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<_ConflictResolutionDialog> {
  final _noteController = TextEditingController();
  ConflictResolution _selectedResolution = ConflictResolution.manualResolution;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Resolve Conflicts'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conflict Type: ${conflict.type.toString()}'),
                          Text('Detected: ${conflict.detectedAt}'),
                          Text('Status: ${conflict.status.toString()}'),
                          SizedBox(height: 8),
                          Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(conflict.conflictDetails.toString()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text('Resolution Strategy:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<ConflictResolution>(
              value: _selectedResolution,
              onChanged: (value) => setState(() => _selectedResolution = value!),
              items: ConflictResolution.values.map((resolution) {
                return DropdownMenuItem(
                  value: resolution,
                  child: Text(resolution.toString().split('.').last),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Resolution Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.conflicts.isNotEmpty) {
              widget.onResolve(
                widget.conflicts.first.id,
                _selectedResolution,
                _noteController.text.isEmpty ? null : _noteController.text,
              );
              Navigator.pop(context);
            }
          },
          child: Text('Resolve'),
        ),
      ],
    );
  }
}

/// Dialog for showing contribution details
class _ContributionDetailsDialog extends StatelessWidget {
  final EventContribution contribution;

  const _ContributionDetailsDialog({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contribution Details'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Contributor: ${contribution.contributorName}'),
            Text('Type: ${contribution.type.toString()}'),
            Text('Timestamp: ${contribution.timestamp}'),
            Text('Approved: ${contribution.isApproved ? 'Yes' : 'No'}'),
            if (contribution.approvedBy != null)
              Text('Approved By: ${contribution.approvedBy}'),
            SizedBox(height: 16),
            Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(contribution.changes.toString()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog for showing version details
class _VersionDetailsDialog extends StatelessWidget {
  final EventVersion version;

  const _VersionDetailsDialog({required this.version});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Version Details'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Version: ${version.versionNumber}'),
            Text('Created By: ${version.createdByName}'),
            Text('Created At: ${version.createdAt}'),
            Text('Current: ${version.isCurrent ? 'Yes' : 'No'}'),
            SizedBox(height: 16),
            Text('Contributors:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...version.contributorNames.map((name) => Text('• $name')),
            SizedBox(height: 16),
            Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(version.changeSummary.toString()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
