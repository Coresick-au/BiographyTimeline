import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'granular_privacy_models.g.dart';

/// Enhanced privacy levels with more granular control
enum EnhancedPrivacyLevel {
  @JsonValue('only_me')
  onlyMe,
  @JsonValue('close_family')
  closeFamily,
  @JsonValue('extended_family')
  extendedFamily,
  @JsonValue('close_friends')
  closeFriends,
  @JsonValue('friends')
  friends,
  @JsonValue('colleagues')
  colleagues,
  @JsonValue('connections')
  connections,
  @JsonValue('public')
  public,
}

/// Privacy control types for different aspects of timeline content
enum PrivacyControlType {
  visibility,      // Who can see the content
  interaction,     // Who can interact (like, comment)
  sharing,         // Who can share the content
  download,        // Who can download media
  location,        // Who can see location data
  participants,    // Who can see participant information
  media,           // Who can see media assets
  story,           // Who can see story content
}

/// Granular privacy settings for a specific timeline event
@JsonSerializable()
class EventPrivacySettings extends Equatable {
  final String eventId;
  final Map<PrivacyControlType, EnhancedPrivacyLevel> privacyLevels;
  final List<String> allowedUsers; // Explicit user overrides
  final List<String> blockedUsers; // Explicit user blocks
  final Set<String> visibleAttributes; // Which attributes are visible
  final bool inheritFromTimeline;
  final DateTime? expiresAt;
  final String? customMessage;

  const EventPrivacySettings({
    required this.eventId,
    this.privacyLevels = const {},
    this.allowedUsers = const [],
    this.blockedUsers = const [],
    this.visibleAttributes = const {
      'title', 'description', 'timestamp', 'location', 'media', 'story'
    },
    this.inheritFromTimeline = true,
    this.expiresAt,
    this.customMessage,
  });

  factory EventPrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$EventPrivacySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$EventPrivacySettingsToJson(this);

  EventPrivacySettings copyWith({
    String? eventId,
    Map<PrivacyControlType, EnhancedPrivacyLevel>? privacyLevels,
    List<String>? allowedUsers,
    List<String>? blockedUsers,
    Set<String>? visibleAttributes,
    bool? inheritFromTimeline,
    DateTime? expiresAt,
    String? customMessage,
  }) {
    return EventPrivacySettings(
      eventId: eventId ?? this.eventId,
      privacyLevels: privacyLevels ?? this.privacyLevels,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      visibleAttributes: visibleAttributes ?? this.visibleAttributes,
      inheritFromTimeline: inheritFromTimeline ?? this.inheritFromTimeline,
      expiresAt: expiresAt ?? this.expiresAt,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  /// Check if a user has access to a specific privacy control type
  bool hasAccess(String userId, PrivacyControlType controlType, {
    EnhancedPrivacyLevel? userRelationshipLevel,
  }) {
    // Check explicit blocks first
    if (blockedUsers.contains(userId)) {
      return false;
    }

    // Check explicit allows
    if (allowedUsers.contains(userId)) {
      return true;
    }

    // Check expiration
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }

    // Check if attribute is visible
    final attributeName = _controlTypeToAttribute(controlType);
    if (attributeName != null && !visibleAttributes.contains(attributeName)) {
      return false;
    }

    // Check privacy level for this control type
    final requiredLevel = privacyLevels[controlType];
    if (requiredLevel != null && userRelationshipLevel != null) {
      return _isPrivacyLevelSatisfied(userRelationshipLevel, requiredLevel);
    }

    // Default to inherit from timeline if no specific setting
    return inheritFromTimeline;
  }

  /// Check if a specific attribute is visible to a user
  bool isAttributeVisible(String userId, String attributeName, {
    EnhancedPrivacyLevel? userRelationshipLevel,
  }) {
    if (blockedUsers.contains(userId)) {
      return false;
    }

    if (allowedUsers.contains(userId)) {
      return true;
    }

    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }

    return visibleAttributes.contains(attributeName);
  }

  String? _controlTypeToAttribute(PrivacyControlType controlType) {
    switch (controlType) {
      case PrivacyControlType.visibility:
        return null; // Overall visibility
      case PrivacyControlType.interaction:
        return 'interaction';
      case PrivacyControlType.sharing:
        return 'sharing';
      case PrivacyControlType.download:
        return 'download';
      case PrivacyControlType.location:
        return 'location';
      case PrivacyControlType.participants:
        return 'participants';
      case PrivacyControlType.media:
        return 'media';
      case PrivacyControlType.story:
        return 'story';
    }
  }

  bool _isPrivacyLevelSatisfied(
    EnhancedPrivacyLevel userLevel,
    EnhancedPrivacyLevel requiredLevel,
  ) {
    // Higher index = more restrictive
    return userLevel.index >= requiredLevel.index;
  }

  @override
  List<Object?> get props => [
        eventId,
        privacyLevels,
        allowedUsers,
        blockedUsers,
        visibleAttributes,
        inheritFromTimeline,
        expiresAt,
        customMessage,
      ];
}

/// Privacy template for quick application to multiple events
@JsonSerializable()
class PrivacyTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final Map<PrivacyControlType, EnhancedPrivacyLevel> privacyLevels;
  final Set<String> visibleAttributes;
  final bool isDefault;
  final DateTime createdAt;

  const PrivacyTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.privacyLevels = const {},
    this.visibleAttributes = const {
      'title', 'description', 'timestamp', 'location', 'media', 'story'
    },
    this.isDefault = false,
    required this.createdAt,
  });

  factory PrivacyTemplate.fromJson(Map<String, dynamic> json) =>
      _$PrivacyTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacyTemplateToJson(this);

  PrivacyTemplate copyWith({
    String? id,
    String? name,
    String? description,
    Map<PrivacyControlType, EnhancedPrivacyLevel>? privacyLevels,
    Set<String>? visibleAttributes,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PrivacyTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      privacyLevels: privacyLevels ?? this.privacyLevels,
      visibleAttributes: visibleAttributes ?? this.visibleAttributes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Apply this template to an event
  EventPrivacySettings applyToEvent(String eventId) {
    return EventPrivacySettings(
      eventId: eventId,
      privacyLevels: privacyLevels,
      visibleAttributes: visibleAttributes,
      inheritFromTimeline: false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        privacyLevels,
        visibleAttributes,
        isDefault,
        createdAt,
      ];
}

/// Privacy audit entry for tracking changes
@JsonSerializable()
class PrivacyAuditEntry extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final PrivacyAction action;
  final Map<String, dynamic> previousSettings;
  final Map<String, dynamic> newSettings;
  final String? reason;
  final DateTime timestamp;

  const PrivacyAuditEntry({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.action,
    required this.previousSettings,
    required this.newSettings,
    this.reason,
    required this.timestamp,
  });

  factory PrivacyAuditEntry.fromJson(Map<String, dynamic> json) =>
      _$PrivacyAuditEntryFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacyAuditEntryToJson(this);

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        action,
        previousSettings,
        newSettings,
        reason,
        timestamp,
      ];
}

/// Privacy actions for audit tracking
enum PrivacyAction {
  created,
  updated,
  access_granted,
  access_revoked,
  template_applied,
  expired,
  shared,
  unshared,
}

/// Privacy settings for timeline sharing with enhanced controls
@JsonSerializable()
class TimelinePrivacySettings extends Equatable {
  final String timelineId;
  final EnhancedPrivacyLevel defaultLevel;
  final Map<String, EnhancedPrivacyLevel> relationshipOverrides;
  final Map<String, Set<String>> sharedEventIds;
  final Map<String, Set<String>> sharedContextIds;
  final bool allowEventRequests;
  final bool allowContextRequests;
  final bool allowTagging;
  final bool allowMentions;
  final bool showOnlineStatus;
  final bool showLastActive;
  final bool showParticipationStats;
  final Map<PrivacyControlType, EnhancedPrivacyLevel> defaultControlLevels;
  final DateTime? lastUpdated;

  const TimelinePrivacySettings({
    required this.timelineId,
    this.defaultLevel = EnhancedPrivacyLevel.friends,
    this.relationshipOverrides = const {},
    this.sharedEventIds = const {},
    this.sharedContextIds = const {},
    this.allowEventRequests = true,
    this.allowContextRequests = true,
    this.allowTagging = true,
    this.allowMentions = true,
    this.showOnlineStatus = false,
    this.showLastActive = false,
    this.showParticipationStats = true,
    this.defaultControlLevels = const {},
    this.lastUpdated,
  });

  factory TimelinePrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$TimelinePrivacySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$TimelinePrivacySettingsToJson(this);

  TimelinePrivacySettings copyWith({
    String? timelineId,
    EnhancedPrivacyLevel? defaultLevel,
    Map<String, EnhancedPrivacyLevel>? relationshipOverrides,
    Map<String, Set<String>>? sharedEventIds,
    Map<String, Set<String>>? sharedContextIds,
    bool? allowEventRequests,
    bool? allowContextRequests,
    bool? allowTagging,
    bool? allowMentions,
    bool? showOnlineStatus,
    bool? showLastActive,
    bool? showParticipationStats,
    Map<PrivacyControlType, EnhancedPrivacyLevel>? defaultControlLevels,
    DateTime? lastUpdated,
  }) {
    return TimelinePrivacySettings(
      timelineId: timelineId ?? this.timelineId,
      defaultLevel: defaultLevel ?? this.defaultLevel,
      relationshipOverrides: relationshipOverrides ?? this.relationshipOverrides,
      sharedEventIds: sharedEventIds ?? this.sharedEventIds,
      sharedContextIds: sharedContextIds ?? this.sharedContextIds,
      allowEventRequests: allowEventRequests ?? this.allowEventRequests,
      allowContextRequests: allowContextRequests ?? this.allowContextRequests,
      allowTagging: allowTagging ?? this.allowTagging,
      allowMentions: allowMentions ?? this.allowMentions,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastActive: showLastActive ?? this.showLastActive,
      showParticipationStats: showParticipationStats ?? this.showParticipationStats,
      defaultControlLevels: defaultControlLevels ?? this.defaultControlLevels,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        timelineId,
        defaultLevel,
        relationshipOverrides,
        sharedEventIds,
        sharedContextIds,
        allowEventRequests,
        allowContextRequests,
        allowTagging,
        allowMentions,
        showOnlineStatus,
        showLastActive,
        showParticipationStats,
        defaultControlLevels,
        lastUpdated,
      ];
}
