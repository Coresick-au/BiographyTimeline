import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/granular_privacy_models.dart';
import '../../social/models/user_models.dart';
import '../../social/services/relationship_service.dart';

/// Provider for granular privacy service
final granularPrivacyServiceProvider = Provider((ref) => GranularPrivacyService());

/// Service for managing granular privacy controls
class GranularPrivacyService {
  final Map<String, EventPrivacySettings> _eventSettings = {};
  final Map<String, TimelinePrivacySettings> _timelineSettings = {};
  final Map<String, PrivacyTemplate> _templates = {};
  final List<PrivacyAuditEntry> _auditLog = [];
  
  final StreamController<EventPrivacySettings> _eventSettingsController = 
      StreamController<EventPrivacySettings>.broadcast();
  final StreamController<TimelinePrivacySettings> _timelineSettingsController = 
      StreamController<TimelinePrivacySettings>.broadcast();

  Stream<EventPrivacySettings> get eventSettingsStream => _eventSettingsController.stream;
  Stream<TimelinePrivacySettings> get timelineSettingsStream => _timelineSettingsController.stream;

  GranularPrivacyService() {
    _initializeDefaultTemplates();
  }

  /// Get privacy settings for a specific event
  EventPrivacySettings getEventSettings(String eventId) {
    return _eventSettings[eventId] ?? EventPrivacySettings(eventId: eventId);
  }

  /// Update privacy settings for an event
  Future<void> updateEventSettings(
    String userId,
    EventPrivacySettings settings, {
    String? reason,
  }) async {
    final previousSettings = _eventSettings[settings.eventId];
    _eventSettings[settings.eventId] = settings;
    _eventSettingsController.add(settings);

    // Add audit entry
    _addAuditEntry(PrivacyAuditEntry(
      id: const Uuid().v4(),
      eventId: settings.eventId,
      userId: userId,
      action: previousSettings == null ? PrivacyAction.created : PrivacyAction.updated,
      previousSettings: previousSettings?.toJson() ?? {},
      newSettings: settings.toJson(),
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  /// Get privacy settings for a timeline
  TimelinePrivacySettings getTimelineSettings(String timelineId) {
    return _timelineSettings[timelineId] ?? TimelinePrivacySettings(timelineId: timelineId);
  }

  /// Update privacy settings for a timeline
  Future<void> updateTimelineSettings(
    String userId,
    TimelinePrivacySettings settings, {
    String? reason,
  }) async {
    final previousSettings = _timelineSettings[settings.timelineId];
    _timelineSettings[settings.timelineId] = settings;
    _timelineSettingsController.add(settings);

    // Add audit entry
    _addAuditEntry(PrivacyAuditEntry(
      id: const Uuid().v4(),
      eventId: settings.timelineId,
      userId: userId,
      action: previousSettings == null ? PrivacyAction.created : PrivacyAction.updated,
      previousSettings: previousSettings?.toJson() ?? {},
      newSettings: settings.toJson(),
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  /// Check if a user can access an event with specific control type
  bool canAccessEvent(
    String viewerId,
    String eventId,
    PrivacyControlType controlType, {
    String? timelineId,
  }) {
    final eventSettings = getEventSettings(eventId);
    
    // Get user's relationship level with the event owner
    final relationshipLevel = _getUserRelationshipLevel(viewerId, timelineId);
    
    return eventSettings.hasAccess(viewerId, controlType, userRelationshipLevel: relationshipLevel);
  }

  /// Get filtered event data based on privacy settings
  Map<String, dynamic> getFilteredEventData(
    String viewerId,
    Map<String, dynamic> eventData, {
    String? timelineId,
  }) {
    final eventId = eventData['id'] as String;
    final eventSettings = getEventSettings(eventId);
    final relationshipLevel = _getUserRelationshipLevel(viewerId, timelineId);
    
    if (!eventSettings.hasAccess(viewerId, PrivacyControlType.visibility, userRelationshipLevel: relationshipLevel)) {
      return {}; // No access at all
    }

    final filteredData = <String, dynamic>{};
    
    // Filter based on visible attributes
    for (final entry in eventData.entries) {
      if (eventSettings.isAttributeVisible(viewerId, entry.key, userRelationshipLevel: relationshipLevel)) {
        filteredData[entry.key] = entry.value;
      }
    }

    // Additional filtering based on control types
    if (!eventSettings.hasAccess(viewerId, PrivacyControlType.location, userRelationshipLevel: relationshipLevel)) {
      filteredData.remove('location');
    }

    if (!eventSettings.hasAccess(viewerId, PrivacyControlType.participants, userRelationshipLevel: relationshipLevel)) {
      filteredData.remove('participantIds');
    }

    if (!eventSettings.hasAccess(viewerId, PrivacyControlType.media, userRelationshipLevel: relationshipLevel)) {
      filteredData.remove('assets');
    }

    if (!eventSettings.hasAccess(viewerId, PrivacyControlType.story, userRelationshipLevel: relationshipLevel)) {
      filteredData.remove('story');
    }

    return filteredData;
  }

  /// Apply a privacy template to an event
  Future<void> applyTemplateToEvent(
    String userId,
    String templateId,
    String eventId, {
    String? reason,
  }) async {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final eventSettings = template.applyToEvent(eventId);
    await updateEventSettings(userId, eventSettings, reason: reason);

    // Add template application audit entry
    _addAuditEntry(PrivacyAuditEntry(
      id: const Uuid().v4(),
      eventId: eventId,
      userId: userId,
      action: PrivacyAction.template_applied,
      previousSettings: {},
      newSettings: {'templateId': templateId},
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  /// Create a new privacy template
  Future<void> createTemplate(String userId, PrivacyTemplate template) async {
    _templates[template.id] = template;
    
    _addAuditEntry(PrivacyAuditEntry(
      id: const Uuid().v4(),
      eventId: template.id,
      userId: userId,
      action: PrivacyAction.created,
      previousSettings: {},
      newSettings: template.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Get all available templates
  List<PrivacyTemplate> getTemplates() {
    return _templates.values.toList();
  }

  /// Get privacy audit log for an event
  List<PrivacyAuditEntry> getEventAuditLog(String eventId) {
    return _auditLog.where((entry) => entry.eventId == eventId).toList();
  }

  /// Get privacy audit log for a user
  List<PrivacyAuditEntry> getUserAuditLog(String userId) {
    return _auditLog.where((entry) => entry.userId == userId).toList();
  }

  /// Grant explicit access to a user for an event
  Future<void> grantAccess(
    String userId,
    String targetUserId,
    String eventId, {
    String? reason,
  }) async {
    final eventSettings = getEventSettings(eventId);
    final updatedSettings = eventSettings.copyWith(
      allowedUsers: [...eventSettings.allowedUsers, targetUserId],
    );
    
    await updateEventSettings(userId, updatedSettings, reason: reason);
  }

  /// Revoke access from a user for an event
  Future<void> revokeAccess(
    String userId,
    String targetUserId,
    String eventId, {
    String? reason,
  }) async {
    final eventSettings = getEventSettings(eventId);
    final updatedSettings = eventSettings.copyWith(
      allowedUsers: eventSettings.allowedUsers.where((id) => id != targetUserId).toList(),
      blockedUsers: [...eventSettings.blockedUsers, targetUserId],
    );
    
    await updateEventSettings(userId, updatedSettings, reason: reason);
  }

  /// Set privacy level for a specific control type on an event
  Future<void> setEventPrivacyLevel(
    String userId,
    String eventId,
    PrivacyControlType controlType,
    EnhancedPrivacyLevel level, {
    String? reason,
  }) async {
    final eventSettings = getEventSettings(eventId);
    final updatedPrivacyLevels = Map<PrivacyControlType, EnhancedPrivacyLevel>.from(eventSettings.privacyLevels);
    updatedPrivacyLevels[controlType] = level;
    
    final updatedSettings = eventSettings.copyWith(privacyLevels: updatedPrivacyLevels);
    await updateEventSettings(userId, updatedSettings, reason: reason);
  }

  /// Set visibility of specific attributes for an event
  Future<void> setEventAttributeVisibility(
    String userId,
    String eventId,
    Set<String> visibleAttributes, {
    String? reason,
  }) async {
    final eventSettings = getEventSettings(eventId);
    final updatedSettings = eventSettings.copyWith(visibleAttributes: visibleAttributes);
    await updateEventSettings(userId, updatedSettings, reason: reason);
  }

  /// Set expiration for event privacy settings
  Future<void> setEventPrivacyExpiration(
    String userId,
    String eventId,
    DateTime? expiresAt, {
    String? reason,
  }) async {
    final eventSettings = getEventSettings(eventId);
    final updatedSettings = eventSettings.copyWith(expiresAt: expiresAt);
    await updateEventSettings(userId, updatedSettings, reason: reason);
  }

  /// Get events that are expiring soon
  List<String> getExpiringEvents({Duration within = const Duration(days: 7)}) {
    final now = DateTime.now();
    final expiryThreshold = now.add(within);
    
    return _eventSettings.entries
        .where((entry) => 
            entry.value.expiresAt != null && 
            entry.value.expiresAt!.isBefore(expiryThreshold))
        .map((entry) => entry.key)
        .toList();
  }

  /// Clean up expired privacy settings
  Future<void> cleanupExpiredSettings() async {
    final now = DateTime.now();
    final expiredEvents = _eventSettings.entries
        .where((entry) => 
            entry.value.expiresAt != null && 
            entry.value.expiresAt!.isBefore(now))
        .map((entry) => entry.key)
        .toList();

    for (final eventId in expiredEvents) {
      final settings = _eventSettings[eventId]!;
      _addAuditEntry(PrivacyAuditEntry(
        id: const Uuid().v4(),
        eventId: eventId,
        userId: 'system',
        action: PrivacyAction.expired,
        previousSettings: settings.toJson(),
        newSettings: {},
        reason: 'Privacy settings expired',
        timestamp: now,
      ));
      
      _eventSettings.remove(eventId);
      _eventSettingsController.add(settings);
    }
  }

  void _initializeDefaultTemplates() {
    final now = DateTime.now();
    
    // Private template
    _templates['private'] = const PrivacyTemplate(
      id: 'private',
      name: 'Completely Private',
      description: 'Only visible to you',
      privacyLevels: {
        PrivacyControlType.visibility: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.interaction: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.sharing: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.download: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.location: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.participants: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.media: EnhancedPrivacyLevel.onlyMe,
        PrivacyControlType.story: EnhancedPrivacyLevel.onlyMe,
      },
      visibleAttributes: {'title', 'description', 'timestamp'},
      isDefault: false,
      createdAt: now,
    );

    // Close friends template
    _templates['close_friends'] = const PrivacyTemplate(
      id: 'close_friends',
      name: 'Close Friends Only',
      description: 'Share with your closest friends',
      privacyLevels: {
        PrivacyControlType.visibility: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.interaction: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.sharing: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.download: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.location: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.participants: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.media: EnhancedPrivacyLevel.closeFriends,
        PrivacyControlType.story: EnhancedPrivacyLevel.closeFriends,
      },
      visibleAttributes: {'title', 'description', 'timestamp', 'location', 'media', 'story'},
      isDefault: false,
      createdAt: now,
    );

    // Family template
    _templates['family'] = const PrivacyTemplate(
      id: 'family',
      name: 'Family & Close Friends',
      description: 'Share with family and close friends',
      privacyLevels: {
        PrivacyControlType.visibility: EnhancedPrivacyLevel.extendedFamily,
        PrivacyControlType.interaction: EnhancedPrivacyLevel.extendedFamily,
        PrivacyControlType.sharing: EnhancedPrivacyLevel.closeFamily,
        PrivacyControlType.download: EnhancedPrivacyLevel.closeFamily,
        PrivacyControlType.location: EnhancedPrivacyLevel.extendedFamily,
        PrivacyControlType.participants: EnhancedPrivacyLevel.extendedFamily,
        PrivacyControlType.media: EnhancedPrivacyLevel.extendedFamily,
        PrivacyControlType.story: EnhancedPrivacyLevel.extendedFamily,
      },
      visibleAttributes: {'title', 'description', 'timestamp', 'location', 'media', 'story'},
      isDefault: false,
      createdAt: now,
    );

    // Public template
    _templates['public'] = const PrivacyTemplate(
      id: 'public',
      name: 'Public',
      description: 'Share with everyone',
      privacyLevels: {
        PrivacyControlType.visibility: EnhancedPrivacyLevel.public,
        PrivacyControlType.interaction: EnhancedPrivacyLevel.public,
        PrivacyControlType.sharing: EnhancedPrivacyLevel.public,
        PrivacyControlType.download: EnhancedPrivacyLevel.friends,
        PrivacyControlType.location: EnhancedPrivacyLevel.friends,
        PrivacyControlType.participants: EnhancedPrivacyLevel.public,
        PrivacyControlType.media: EnhancedPrivacyLevel.public,
        PrivacyControlType.story: EnhancedPrivacyLevel.public,
      },
      visibleAttributes: {'title', 'description', 'timestamp', 'location', 'media', 'story'},
      isDefault: false,
      createdAt: now,
    );
  }

  EnhancedPrivacyLevel _getUserRelationshipLevel(String viewerId, String? timelineId) {
    // This would integrate with the relationship service
    // For now, return a default level
    // In a real implementation, this would check the actual relationship
    return EnhancedPrivacyLevel.friends;
  }

  void _addAuditEntry(PrivacyAuditEntry entry) {
    _auditLog.add(entry);
    
    // Keep audit log size manageable (keep last 1000 entries per event)
    if (_auditLog.length > 10000) {
      _auditLog.removeRange(0, _auditLog.length - 10000);
    }
  }

  void dispose() {
    _eventSettingsController.close();
    _timelineSettingsController.close();
  }
}

/// Extension methods for enhanced privacy levels
extension EnhancedPrivacyLevelExtension on EnhancedPrivacyLevel {
  String get displayName {
    switch (this) {
      case EnhancedPrivacyLevel.onlyMe:
        return 'Only Me';
      case EnhancedPrivacyLevel.closeFamily:
        return 'Close Family';
      case EnhancedPrivacyLevel.extendedFamily:
        return 'Extended Family';
      case EnhancedPrivacyLevel.closeFriends:
        return 'Close Friends';
      case EnhancedPrivacyLevel.friends:
        return 'Friends';
      case EnhancedPrivacyLevel.colleagues:
        return 'Colleagues';
      case EnhancedPrivacyLevel.connections:
        return 'Connections';
      case EnhancedPrivacyLevel.public:
        return 'Public';
    }
  }

  String get description {
    switch (this) {
      case EnhancedPrivacyLevel.onlyMe:
        return 'Only you can see this content';
      case EnhancedPrivacyLevel.closeFamily:
        return 'Only your close family members can see this';
      case EnhancedPrivacyLevel.extendedFamily:
        return 'Your family and close friends can see this';
      case EnhancedPrivacyLevel.closeFriends:
        return 'Only your closest friends can see this';
      case EnhancedPrivacyLevel.friends:
        return 'Your friends and connections can see this';
      case EnhancedPrivacyLevel.colleagues:
        return 'Your work colleagues can see this';
      case EnhancedPrivacyLevel.connections:
        return 'Your connections can see this';
      case EnhancedPrivacyLevel.public:
        return 'Anyone can see this content';
    }
  }

  String get iconName {
    switch (this) {
      case EnhancedPrivacyLevel.onlyMe:
        return 'lock';
      case EnhancedPrivacyLevel.closeFamily:
        return 'family_restroom';
      case EnhancedPrivacyLevel.extendedFamily:
        return 'people';
      case EnhancedPrivacyLevel.closeFriends:
        return 'favorite';
      case EnhancedPrivacyLevel.friends:
        return 'group';
      case EnhancedPrivacyLevel.colleagues:
        return 'business_center';
      case EnhancedPrivacyLevel.connections:
        return 'share';
      case EnhancedPrivacyLevel.public:
        return 'public';
    }
  }
}

/// Extension methods for privacy control types
extension PrivacyControlTypeExtension on PrivacyControlType {
  String get displayName {
    switch (this) {
      case PrivacyControlType.visibility:
        return 'Visibility';
      case PrivacyControlType.interaction:
        return 'Interaction';
      case PrivacyControlType.sharing:
        return 'Sharing';
      case PrivacyControlType.download:
        return 'Download';
      case PrivacyControlType.location:
        return 'Location';
      case PrivacyControlType.participants:
        return 'Participants';
      case PrivacyControlType.media:
        return 'Media';
      case PrivacyControlType.story:
        return 'Story';
    }
  }

  String get description {
    switch (this) {
      case PrivacyControlType.visibility:
        return 'Who can see this content';
      case PrivacyControlType.interaction:
        return 'Who can like and comment';
      case PrivacyControlType.sharing:
        return 'Who can share this content';
      case PrivacyControlType.download:
        return 'Who can download media';
      case PrivacyControlType.location:
        return 'Who can see location data';
      case PrivacyControlType.participants:
        return 'Who can see participants';
      case PrivacyControlType.media:
        return 'Who can see media assets';
      case PrivacyControlType.story:
        return 'Who can see story content';
    }
  }
}
