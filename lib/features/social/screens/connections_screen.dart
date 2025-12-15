import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../services/relationship_service.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/design_system/components/components.dart';

/// Provider for relationship service
final relationshipServiceProvider = Provider((ref) => RelationshipService());

/// Provider for current user's connections
final userConnectionsProvider = StreamProvider<List<Relationship>>((ref) {
  final service = ref.watch(relationshipServiceProvider);
  return service.relationshipsStream;
});

/// Provider for pending connection requests
final pendingRequestsProvider = StreamProvider<List<ConnectionRequest>>((ref) {
  final service = ref.watch(relationshipServiceProvider);
  return service.connectionRequestsStream;
});

/// Provider for user activity feed
final activityFeedProvider = StreamProvider<List<UserActivity>>((ref) {
  final service = ref.watch(relationshipServiceProvider);
  return service.activitiesStream;
});

/// Screen for managing user connections
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(userConnectionsProvider);
    final requestsAsync = ref.watch(pendingRequestsProvider);
    final activityAsync = ref.watch(activityFeedProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Connections', icon: Icon(AppIcons.people)),
            Tab(text: 'Requests', icon: Icon(AppIcons.personAdd)),
            Tab(text: 'Activity', icon: Icon(AppIcons.timeline)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(AppIcons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(AppIcons.add),
            onPressed: _showAddConnectionDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionsTab(connectionsAsync),
          _buildRequestsTab(requestsAsync),
          _buildActivityTab(activityAsync),
        ],
      ),
    );
  }

  Widget _buildConnectionsTab(AsyncValue<List<Relationship>> connectionsAsync) {
    return connectionsAsync.when(
      data: (connections) {
        if (connections.isEmpty) {
          return _buildEmptyState(
            icon: AppIcons.peopleOutline,
            title: 'No Connections Yet',
            subtitle: 'Start connecting with others to share timelines',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final relationship = connections[index];
            return _buildConnectionCard(relationship);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load connections'),
    );
  }

  Widget _buildRequestsTab(AsyncValue<List<ConnectionRequest>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: AppIcons.inboxOutline,
            title: 'No Pending Requests',
            subtitle: 'You\'ll see connection requests here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load requests'),
    );
  }

  Widget _buildActivityTab(AsyncValue<List<UserActivity>> activityAsync) {
    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyState(
            icon: AppIcons.timelineOutlined,
            title: 'No Recent Activity',
            subtitle: 'Activity from your connections will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load activity'),
    );
  }

  Widget _buildConnectionCard(Relationship relationship) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => _showConnectionDetails(relationship),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.sm),
          leading: AppAvatar(
            name: _getRelationshipDisplayName(relationship),
            radius: 24,
          ),
          title: Text(
            _getRelationshipDisplayName(relationship),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Connected ${_formatDate(relationship.startDate)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(AppIcons.privacyTip),
                    SizedBox(width: AppSpacing.sm),
                    Text('Privacy Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'end',
                child: Row(
                  children: [
                    Icon(AppIcons.linkOff),
                    SizedBox(width: AppSpacing.sm),
                    Text('End Connection'),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleConnectionAction(relationship, value),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(ConnectionRequest request) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.sm),
          leading: AppAvatar(
            name: request.fromUserId,
            radius: 24,
          ),
          title: Text(
            'Connection Request',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From: ${request.fromUserId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (request.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    request.message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Sent ${_formatDate(request.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(AppIcons.check, color: Colors.green),
                onPressed: () => _acceptRequest(request),
              ),
              IconButton(
                icon: Icon(AppIcons.close, color: Colors.red),
                onPressed: () => _declineRequest(request),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(UserActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => _handleActivityTap(activity),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.sm),
          leading: AppAvatar(
            name: activity.userId,
            radius: 24,
          ),
          title: Text(
            _getActivityTitle(activity),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _formatDate(activity.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
    );
  }

  Widget _buildErrorState(String message) {
    return AppEmptyState.error(
      message: message, 
      onRetry: () => setState(() {}),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Users'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter name or email...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddConnectionDialog() {
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    RelationshipType selectedType = RelationshipType.friend;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'user@example.com',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RelationshipType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Relationship Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: RelationshipType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getRelationshipDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  prefixIcon: Icon(Icons.message),
                  hintText: 'Say hello...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email or username')),
                  );
                  return;
                }

                Navigator.pop(context);
                
                try {
                  final service = ref.read(relationshipServiceProvider);
                  // TODO: Replace with actual current user ID from auth
                  await service.sendConnectionRequest(
                    fromUserId: 'current-user-id',
                    toUserId: email, // In real app, would look up user by email
                    type: selectedType,
                    message: messageController.text.trim().isEmpty 
                        ? null 
                        : messageController.text.trim(),
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connection request sent!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRequest(ConnectionRequest request) async {
    try {
      final service = ref.read(relationshipServiceProvider);
      await service.acceptConnectionRequest(request.id, 'current-user-id');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request accepted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _declineRequest(ConnectionRequest request) async {
    try {
      final service = ref.read(relationshipServiceProvider);
      await service.declineConnectionRequest(request.id, 'current-user-id');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request declined')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleConnectionAction(Relationship relationship, String action) {
    switch (action) {
      case 'privacy':
        _showPrivacySettings(relationship);
        break;
      case 'end':
        _showEndConnectionDialog(relationship);
        break;
    }
  }

  void _showConnectionDetails(Relationship relationship) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getRelationshipDisplayName(relationship)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getRelationshipDisplayName(relationship.type)}'),
            Text('Status: ${_getStatusDisplayName(relationship.status)}'),
            Text('Started: ${_formatDate(relationship.startDate)}'),
            if (relationship.endDate != null)
              Text('Ended: ${_formatDate(relationship.endDate!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(Relationship relationship) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: const Text('Privacy settings configuration will go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEndConnectionDialog(Relationship relationship) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Connection'),
        content: Text(
          'Are you sure you want to end your connection with ${_getRelationshipDisplayName(relationship)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement end relationship
            },
            child: const Text('End Connection'),
          ),
        ],
      ),
    );
  }

  void _handleActivityTap(UserActivity activity) {
    // TODO: Handle activity tap based on type
  }

  // Helper methods

  IconData _getRelationshipIcon(RelationshipType type) {
    switch (type) {
      case RelationshipType.friend:
        return Icons.person;
      case RelationshipType.family:
        return Icons.family_restroom;
      case RelationshipType.partner:
        return Icons.favorite;
      case RelationshipType.colleague:
        return Icons.work;
      case RelationshipType.collaborator:
        return Icons.group_work;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.connectionRequest:
        return Icons.person_add;
      case ActivityType.connectionAccepted:
        return Icons.person_add_disabled;
      case ActivityType.connectionDeclined:
        return Icons.person_remove;
      case ActivityType.timelineShared:
        return Icons.share;
      case ActivityType.eventCommented:
        return Icons.comment;
      case ActivityType.eventLiked:
        return Icons.favorite;
      case ActivityType.contextCreated:
        return Icons.folder;
      case ActivityType.milestoneReached:
        return Icons.emoji_events;
      case ActivityType.relationshipTerminated:
        return Icons.warning;
      case ActivityType.contentArchived:
        return Icons.archive;
      case ActivityType.contentRedacted:
        return Icons.content_cut;
      case ActivityType.contentBifurcated:
        return Icons.call_split;
    }
  }

  String _getRelationshipDisplayName(dynamic relationshipOrType) {
    if (relationshipOrType is Relationship) {
      return '${relationshipOrType.userAId} & ${relationshipOrType.userBId}';
    } else if (relationshipOrType is RelationshipType) {
      switch (relationshipOrType) {
        case RelationshipType.friend:
          return 'Friend';
        case RelationshipType.family:
          return 'Family';
        case RelationshipType.partner:
          return 'Partner';
        case RelationshipType.colleague:
          return 'Colleague';
        case RelationshipType.collaborator:
          return 'Collaborator';
      }
    }
    return 'Unknown';
  }

  String _getStatusDisplayName(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.pending:
        return 'Pending';
      case RelationshipStatus.active:
        return 'Active';
      case RelationshipStatus.terminated:
        return 'Terminated';
      case RelationshipStatus.archived:
        return 'Archived';
      case RelationshipStatus.disconnected:
        return 'Disconnected';
    }
  }

  String _getActivityTitle(UserActivity activity) {
    switch (activity.type) {
      case ActivityType.connectionRequest:
        return 'New connection request';
      case ActivityType.connectionAccepted:
        return 'Connection accepted';
      case ActivityType.connectionDeclined:
        return 'Connection declined';
      case ActivityType.timelineShared:
        return 'Timeline shared';
      case ActivityType.eventCommented:
        return 'Event commented';
      case ActivityType.eventLiked:
        return 'Event liked';
      case ActivityType.contextCreated:
        return 'Context created';
      case ActivityType.milestoneReached:
        return 'Milestone reached';
      case ActivityType.relationshipTerminated:
        return 'Relationship terminated';
      case ActivityType.contentArchived:
        return 'Content archived';
      case ActivityType.contentRedacted:
        return 'Content redacted';
      case ActivityType.contentBifurcated:
        return 'Content bifurcated';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
