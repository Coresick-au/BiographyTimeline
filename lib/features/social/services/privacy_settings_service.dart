import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/user_models.dart';
import '../services/relationship_service.dart';

/// Provider for privacy settings service
final privacySettingsServiceProvider = Provider((ref) => PrivacySettingsService());

/// Privacy settings for timeline sharing
class TimelinePrivacySettings {
  final String userId;
  final PrivacyLevel defaultLevel;
  final Map<String, PrivacyLevel> relationshipOverrides;
  final Map<String, Set<String>> sharedEventIds;
  final Map<String, Set<String>> sharedContextIds;
  final bool allowEventRequests;
  final bool allowContextRequests;
  final DateTime? lastUpdated;

  const TimelinePrivacySettings({
    required this.userId,
    this.defaultLevel = PrivacyLevel.friends,
    this.relationshipOverrides = const {},
    this.sharedEventIds = const {},
    this.sharedContextIds = const {},
    this.allowEventRequests = true,
    this.allowContextRequests = true,
    this.lastUpdated,
  });

  TimelinePrivacySettings copyWith({
    String? userId,
    PrivacyLevel? defaultLevel,
    Map<String, PrivacyLevel>? relationshipOverrides,
    Map<String, Set<String>>? sharedEventIds,
    Map<String, Set<String>>? sharedContextIds,
    bool? allowEventRequests,
    bool? allowContextRequests,
    DateTime? lastUpdated,
  }) {
    return TimelinePrivacySettings(
      userId: userId ?? this.userId,
      defaultLevel: defaultLevel ?? this.defaultLevel,
      relationshipOverrides: relationshipOverrides ?? this.relationshipOverrides,
      sharedEventIds: sharedEventIds ?? this.sharedEventIds,
      sharedContextIds: sharedContextIds ?? this.sharedContextIds,
      allowEventRequests: allowEventRequests ?? this.allowEventRequests,
      allowContextRequests: allowContextRequests ?? this.allowContextRequests,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

/// Service for managing privacy settings
class PrivacySettingsService {
  final Map<String, TimelinePrivacySettings> _userSettings = {};
  final StreamController<TimelinePrivacySettings> _settingsController = 
      StreamController<TimelinePrivacySettings>.broadcast();

  Stream<TimelinePrivacySettings> get settingsStream => _settingsController.stream;

  /// Get privacy settings for a user
  TimelinePrivacySettings getSettings(String userId) {
    return _userSettings[userId] ?? TimelinePrivacySettings(userId: userId);
  }

  /// Update privacy settings for a user
  Future<void> updateSettings(String userId, TimelinePrivacySettings settings) async {
    _userSettings[userId] = settings;
    _settingsController.add(settings);
  }

  /// Check if a user can access another user's timeline
  bool canAccessTimeline(String viewerId, String targetId) {
    final settings = getSettings(targetId);
    final relationshipLevel = _getRelationshipLevel(viewerId, targetId);
    
    // Check default level
    if (_isPrivacyLevelSatisfied(relationshipLevel, settings.defaultLevel)) {
      return true;
    }

    // Check relationship override
    final overrideLevel = settings.relationshipOverrides[viewerId];
    if (overrideLevel != null && _isPrivacyLevelSatisfied(relationshipLevel, overrideLevel)) {
      return true;
    }

    return false;
  }

  /// Check if a user can access specific events
  Set<String> getAccessibleEvents(String viewerId, String targetId) {
    final settings = getSettings(targetId);
    
    if (!canAccessTimeline(viewerId, targetId)) {
      return {};
    }

    // Return explicitly shared events
    return settings.sharedEventIds[viewerId] ?? {};
  }

  /// Check if a user can access specific contexts
  Set<String> getAccessibleContexts(String viewerId, String targetId) {
    final settings = getSettings(targetId);
    
    if (!canAccessTimeline(viewerId, targetId)) {
      return {};
    }

    // Return explicitly shared contexts
    return settings.sharedContextIds[viewerId] ?? {};
  }

  /// Share specific events with a user
  Future<void> shareEvents(String userId, String targetId, Set<String> eventIds) async {
    final settings = getSettings(userId);
    final currentShared = Map<String, Set<String>>.from(settings.sharedEventIds);
    currentShared[targetId] = currentShared[targetId] ?? {}..addAll(eventIds);
    
    await updateSettings(userId, settings.copyWith(sharedEventIds: currentShared));
  }

  /// Unshare events with a user
  Future<void> unshareEvents(String userId, String targetId, Set<String> eventIds) async {
    final settings = getSettings(userId);
    final currentShared = Map<String, Set<String>>.from(settings.sharedEventIds);
    currentShared[targetId]?.removeAll(eventIds);
    
    await updateSettings(userId, settings.copyWith(sharedEventIds: currentShared));
  }

  /// Share specific contexts with a user
  Future<void> shareContexts(String userId, String targetId, Set<String> contextIds) async {
    final settings = getSettings(userId);
    final currentShared = Map<String, Set<String>>.from(settings.sharedContextIds);
    currentShared[targetId] = currentShared[targetId] ?? {}..addAll(contextIds);
    
    await updateSettings(userId, settings.copyWith(sharedContextIds: currentShared));
  }

  /// Unshare contexts with a user
  Future<void> unshareContexts(String userId, String targetId, Set<String> contextIds) async {
    final settings = getSettings(userId);
    final currentShared = Map<String, Set<String>>.from(settings.sharedContextIds);
    currentShared[targetId]?.removeAll(contextIds);
    
    await updateSettings(userId, settings.copyWith(sharedContextIds: currentShared));
  }

  /// Set privacy level for a specific relationship
  Future<void> setRelationshipPrivacyLevel(String userId, String targetId, PrivacyLevel level) async {
    final settings = getSettings(userId);
    final currentOverrides = Map<String, PrivacyLevel>.from(settings.relationshipOverrides);
    currentOverrides[targetId] = level;
    
    await updateSettings(userId, settings.copyWith(relationshipOverrides: currentOverrides));
  }

  /// Remove relationship privacy override
  Future<void> removeRelationshipPrivacyOverride(String userId, String targetUserId) async {
    final settings = _userSettings[userId];
    if (settings != null) {
      final updatedOverrides = Map<String, PrivacyLevel>.from(settings.relationshipOverrides);
      updatedOverrides.remove(targetUserId);
      
      _userSettings[userId] = settings.copyWith(
        relationshipOverrides: updatedOverrides,
      );
      
      _settingsController.add(settings);
    }
  }

  /// Revoke all access from target user to user's content
  Future<void> revokeAccess(String userId, String targetUserId) async {
    // Remove relationship override
    await removeRelationshipPrivacyOverride(userId, targetUserId);
    
    // Remove shared events and contexts
    await unshareEvents(userId, targetUserId, _userSettings[userId]?.sharedEventIds[targetUserId] ?? {});
    await unshareContexts(userId, targetUserId, _userSettings[userId]?.sharedContextIds[targetUserId] ?? {});
    
    // Update settings to reflect access revocation
    final settings = _userSettings[userId];
    if (settings != null) {
      _settingsController.add(settings);
    }
  }

  PrivacyLevel _getRelationshipLevel(String viewerId, String targetId) {
    // This would integrate with the relationship service
    // For now, return a default level
    return PrivacyLevel.friends;
  }

  bool _isPrivacyLevelSatisfied(PrivacyLevel relationshipLevel, PrivacyLevel requiredLevel) {
    switch (requiredLevel) {
      case PrivacyLevel.private:
        return relationshipLevel == PrivacyLevel.private;
      case PrivacyLevel.friends:
        return relationshipLevel.index >= PrivacyLevel.friends.index;
      case PrivacyLevel.family:
        return relationshipLevel.index >= PrivacyLevel.family.index;
      case PrivacyLevel.public:
        return true;
    }
  }

  void dispose() {
    _settingsController.close();
  }
}

/// Screen for managing privacy settings
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TimelinePrivacySettings? _settings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user'; // This would come from auth service
    final settings = service.getSettings(currentUserId);
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.privacy_tip)),
            Tab(text: 'Relationships', icon: Icon(Icons.people)),
            Tab(text: 'Shared Content', icon: Icon(Icons.share)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralSettings(),
          _buildRelationshipSettings(),
          _buildSharedContentSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
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
                  'Default Privacy Level',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This setting determines who can see your timeline by default.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PrivacyLevel>(
                  value: _settings!.defaultLevel,
                  decoration: const InputDecoration(
                    labelText: 'Default Level',
                    border: OutlineInputBorder(),
                  ),
                  items: PrivacyLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(_getPrivacyLevelDisplayName(level)),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await _updateDefaultPrivacyLevel(value);
                    }
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
                  'Request Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Allow Event Requests'),
                  subtitle: const Text('Others can request access to specific events'),
                  value: _settings!.allowEventRequests,
                  onChanged: (value) async {
                    await _updateEventRequests(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Context Requests'),
                  subtitle: const Text('Others can request access to specific contexts'),
                  value: _settings!.allowContextRequests,
                  onChanged: (value) async {
                    await _updateContextRequests(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationshipSettings() {
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
                  'Relationship Privacy Overrides',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set custom privacy levels for specific relationships.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // Sample relationship overrides
                _buildRelationshipOverride('friend_1', 'Close Friend'),
                _buildRelationshipOverride('family_1', 'Family Member'),
                _buildRelationshipOverride('colleague_1', 'Work Colleague'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationshipOverride(String userId, String displayName) {
    final currentLevel = _settings!.relationshipOverrides[userId] ?? _settings!.defaultLevel;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(displayName.split(' ').map((word) => word[0]).join()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Custom privacy setting',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              DropdownButton<PrivacyLevel>(
                value: currentLevel,
                items: PrivacyLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(_getPrivacyLevelDisplayName(level)),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await _updateRelationshipPrivacyLevel(userId, value);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () async {
                  await _removeRelationshipOverride(userId);
                },
                tooltip: 'Use default setting',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedContentSettings() {
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
                  'Shared Events',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage specific events shared with individual connections.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildSharedContentList('Events', _settings!.sharedEventIds),
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
                  'Shared Contexts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage specific contexts shared with individual connections.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildSharedContentList('Contexts', _settings!.sharedContextIds),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedContentList(String title, Map<String, Set<String>> sharedContent) {
    if (sharedContent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No shared $title yet. Share specific $title with your connections.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Column(
      children: sharedContent.entries.map((entry) {
        return Card(
          child: ExpansionTile(
            title: Text('Shared with ${entry.key}'),
            subtitle: Text('${entry.value.length} $title'),
            children: entry.value.take(5).map((contentId) {
              return ListTile(
                title: Text('Content ID: $contentId'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () async {
                    if (title == 'Events') {
                      await _unshareContent(entry.key, {contentId}, isEvent: true);
                    } else {
                      await _unshareContent(entry.key, {contentId}, isEvent: false);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateDefaultPrivacyLevel(PrivacyLevel level) async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user';
    final updatedSettings = _settings!.copyWith(defaultLevel: level);
    await service.updateSettings(currentUserId, updatedSettings);
    setState(() {
      _settings = updatedSettings;
    });
  }

  Future<void> _updateEventRequests(bool allow) async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user';
    final updatedSettings = _settings!.copyWith(allowEventRequests: allow);
    await service.updateSettings(currentUserId, updatedSettings);
    setState(() {
      _settings = updatedSettings;
    });
  }

  Future<void> _updateContextRequests(bool allow) async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user';
    final updatedSettings = _settings!.copyWith(allowContextRequests: allow);
    await service.updateSettings(currentUserId, updatedSettings);
    setState(() {
      _settings = updatedSettings;
    });
  }

  Future<void> _updateRelationshipPrivacyLevel(String targetId, PrivacyLevel level) async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user';
    await service.setRelationshipPrivacyLevel(currentUserId, targetId, level);
    await _loadSettings();
  }

  Future<void> _removeRelationshipOverride(String targetId) async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user';
    await service.removeRelationshipPrivacyOverride(currentUserId, targetId);
    await _loadSettings();
  }

  Future<void> _unshareContent(String targetId, Set<String> contentIds, {required bool isEvent}) async {
    final service = ref.read(privacySettingsServiceProvider);
    final currentUserId = 'current_user';
    
    if (isEvent) {
      await service.unshareEvents(currentUserId, targetId, contentIds);
    } else {
      await service.unshareContexts(currentUserId, targetId, contentIds);
    }
    
    await _loadSettings();
  }

  String _getPrivacyLevelDisplayName(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.private:
        return 'Private - Only me';
      case PrivacyLevel.friends:
        return 'Friends - Connections only';
      case PrivacyLevel.family:
        return 'Family - Family and friends';
      case PrivacyLevel.public:
        return 'Public - Everyone';
    }
  }
}
