import 'package:equatable/equatable.dart';

/// User profile for social features and connections
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isOnline;
  final UserSettings settings;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    required this.createdAt,
    required this.lastActiveAt,
    this.isOnline = false,
    required this.settings,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? profileImageUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isOnline,
    UserSettings? settings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isOnline: isOnline ?? this.isOnline,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        profileImageUrl,
        bio,
        createdAt,
        lastActiveAt,
        isOnline,
        settings,
      ];
}

/// User settings for privacy and preferences
class UserSettings extends Equatable {
  final PrivacyLevel defaultPrivacyLevel;
  final bool allowConnectionRequests;
  final bool showOnlineStatus;
  final bool allowTimelineSharing;
  final List<String> blockedUsers;
  final Map<String, PrivacyScope> contextPrivacy;

  const UserSettings({
    this.defaultPrivacyLevel = PrivacyLevel.friends,
    this.allowConnectionRequests = true,
    this.showOnlineStatus = true,
    this.allowTimelineSharing = true,
    this.blockedUsers = const [],
    this.contextPrivacy = const {},
  });

  UserSettings copyWith({
    PrivacyLevel? defaultPrivacyLevel,
    bool? allowConnectionRequests,
    bool? showOnlineStatus,
    bool? allowTimelineSharing,
    List<String>? blockedUsers,
    Map<String, PrivacyScope>? contextPrivacy,
  }) {
    return UserSettings(
      defaultPrivacyLevel: defaultPrivacyLevel ?? this.defaultPrivacyLevel,
      allowConnectionRequests: allowConnectionRequests ?? this.allowConnectionRequests,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowTimelineSharing: allowTimelineSharing ?? this.allowTimelineSharing,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      contextPrivacy: contextPrivacy ?? this.contextPrivacy,
    );
  }

  @override
  List<Object?> get props => [
        defaultPrivacyLevel,
        allowConnectionRequests,
        showOnlineStatus,
        allowTimelineSharing,
        blockedUsers,
        contextPrivacy,
      ];
}

/// Privacy levels for timeline content
enum PrivacyLevel {
  private,
  friends,
  family,
  public,
}

/// Privacy scope for specific content sharing
class PrivacyScope extends Equatable {
  final List<String> allowedUsers;
  final List<String> allowedContexts;
  final DateTimeRange? dateRange;
  final List<String> allowedContentTypes;

  const PrivacyScope({
    this.allowedUsers = const [],
    this.allowedContexts = const [],
    this.dateRange,
    this.allowedContentTypes = const [],
  });

  PrivacyScope copyWith({
    List<String>? allowedUsers,
    List<String>? allowedContexts,
    DateTimeRange? dateRange,
    List<String>? allowedContentTypes,
  }) {
    return PrivacyScope(
      allowedUsers: allowedUsers ?? this.allowedUsers,
      allowedContexts: allowedContexts ?? this.allowedContexts,
      dateRange: dateRange ?? this.dateRange,
      allowedContentTypes: allowedContentTypes ?? this.allowedContentTypes,
    );
  }

  @override
  List<Object?> get props => [
        allowedUsers,
        allowedContexts,
        dateRange,
        allowedContentTypes,
      ];
}

/// Date range for privacy controls
class DateTimeRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

/// Relationship between two users
class Relationship extends Equatable {
  final String id;
  final String userAId;
  final String userBId;
  final RelationshipType type;
  final RelationshipStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? updatedAt;
  final Map<String, PrivacyScope> contextPermissions;
  final String? initiatedBy;

  const Relationship({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.type,
    required this.status,
    required this.startDate,
    this.endDate,
    this.updatedAt,
    this.contextPermissions = const {},
    this.initiatedBy,
  });

  Relationship copyWith({
    String? id,
    String? userAId,
    String? userBId,
    RelationshipType? type,
    RelationshipStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
    Map<String, PrivacyScope>? contextPermissions,
    String? initiatedBy,
  }) {
    return Relationship(
      id: id ?? this.id,
      userAId: userAId ?? this.userAId,
      userBId: userBId ?? this.userBId,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      updatedAt: updatedAt ?? this.updatedAt,
      contextPermissions: contextPermissions ?? this.contextPermissions,
      initiatedBy: initiatedBy ?? this.initiatedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userAId,
        userBId,
        type,
        status,
        startDate,
        endDate,
        updatedAt,
        contextPermissions,
        initiatedBy,
      ];
}

/// Types of relationships between users
enum RelationshipType {
  friend,
  family,
  partner,
  colleague,
  collaborator,
}

/// Status of a relationship
enum RelationshipStatus {
  pending,
  active,
  terminated,
  archived,
  disconnected,
}

/// Connection request between users
class ConnectionRequest extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? message;
  final RelationshipType requestedType;
  final ConnectionRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  const ConnectionRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.message,
    required this.requestedType,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
  });

  ConnectionRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? message,
    RelationshipType? requestedType,
    ConnectionRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? responseMessage,
  }) {
    return ConnectionRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      message: message ?? this.message,
      requestedType: requestedType ?? this.requestedType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        message,
        requestedType,
        status,
        createdAt,
        respondedAt,
        responseMessage,
      ];
}

/// Status of a connection request
enum ConnectionRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

/// Shared event between connected users
class SharedEvent extends Equatable {
  final String id;
  final List<String> participantIds;
  final String eventId;
  final DateTime detectedAt;
  final double confidenceScore;
  final SharedEventType detectionType;
  final Map<String, dynamic> detectionMetadata;
  
  // Lifecycle management fields
  final bool isArchived;
  final DateTime? archivedAt;
  final bool isRedacted;
  final DateTime? redactedAt;
  final bool isBifurcated;
  final DateTime? bifurcatedAt;
  final String? originalEventId;

  const SharedEvent({
    required this.id,
    required this.participantIds,
    required this.eventId,
    required this.detectedAt,
    required this.confidenceScore,
    required this.detectionType,
    this.detectionMetadata = const {},
    this.isArchived = false,
    this.archivedAt,
    this.isRedacted = false,
    this.redactedAt,
    this.isBifurcated = false,
    this.bifurcatedAt,
    this.originalEventId,
  });

  SharedEvent copyWith({
    String? id,
    List<String>? participantIds,
    String? eventId,
    DateTime? detectedAt,
    double? confidenceScore,
    SharedEventType? detectionType,
    Map<String, dynamic>? detectionMetadata,
    bool? isArchived,
    DateTime? archivedAt,
    bool? isRedacted,
    DateTime? redactedAt,
    bool? isBifurcated,
    DateTime? bifurcatedAt,
    String? originalEventId,
  }) {
    return SharedEvent(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      eventId: eventId ?? this.eventId,
      detectedAt: detectedAt ?? this.detectedAt,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectionType: detectionType ?? this.detectionType,
      detectionMetadata: detectionMetadata ?? this.detectionMetadata,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      isRedacted: isRedacted ?? this.isRedacted,
      redactedAt: redactedAt ?? this.redactedAt,
      isBifurcated: isBifurcated ?? this.isBifurcated,
      bifurcatedAt: bifurcatedAt ?? this.bifurcatedAt,
      originalEventId: originalEventId ?? this.originalEventId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        eventId,
        detectedAt,
        confidenceScore,
        detectionType,
        detectionMetadata,
        isArchived,
        archivedAt,
        isRedacted,
        redactedAt,
        isBifurcated,
        bifurcatedAt,
        originalEventId,
      ];
}

/// Types of shared event detection
enum SharedEventType {
  temporal,
  spatial,
  facial,
  hybrid,
}

/// User activity for feed and notifications
class UserActivity extends Equatable {
  final String id;
  final String userId;
  final ActivityType type;
  final String? relatedUserId;
  final String? eventId;
  final String? contextId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    this.relatedUserId,
    this.eventId,
    this.contextId,
    this.metadata = const {},
    required this.createdAt,
  });

  UserActivity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    String? relatedUserId,
    String? eventId,
    String? contextId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      eventId: eventId ?? this.eventId,
      contextId: contextId ?? this.contextId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        relatedUserId,
        eventId,
        contextId,
        metadata,
        createdAt,
      ];
}

/// Types of user activities
enum ActivityType {
  connectionRequest,
  connectionAccepted,
  connectionDeclined,
  timelineShared,
  eventCommented,
  eventLiked,
  contextCreated,
  milestoneReached,
  relationshipTerminated,
  contentArchived,
  contentRedacted,
  contentBifurcated,
}

/// Relationship termination options
enum RelationshipTerminationOption {
  archive, // Keep shared content but remove access
  redact, // Remove user's content from shared events
  bifurcate, // Create separate copies of shared content
  delete, // Completely remove shared content
}

/// Relationship termination request
class RelationshipTerminationRequest extends Equatable {
  final String id;
  final String initiatedByUserId;
  final String targetUserId;
  final String relationshipId;
  final RelationshipTerminationOption option;
  final String? reason;
  final DateTime createdAt;
  final bool isProcessed;
  final DateTime? processedAt;
  final String? processedBy;

  const RelationshipTerminationRequest({
    required this.id,
    required this.initiatedByUserId,
    required this.targetUserId,
    required this.relationshipId,
    required this.option,
    this.reason,
    required this.createdAt,
    this.isProcessed = false,
    this.processedAt,
    this.processedBy,
  });

  @override
  List<Object?> get props => [
        id,
        initiatedByUserId,
        targetUserId,
        relationshipId,
        option,
        reason,
        createdAt,
        isProcessed,
        processedAt,
        processedBy,
      ];
}

/// Content management action result
class ContentManagementResult extends Equatable {
  final String id;
  final String relationshipId;
  final RelationshipTerminationOption option;
  final Map<String, List<String>> affectedEvents; // userId -> eventIds
  final Map<String, List<String>> affectedContexts; // userId -> contextIds
  final DateTime createdAt;
  final bool isSuccess;
  final String? errorMessage;

  const ContentManagementResult({
    required this.id,
    required this.relationshipId,
    required this.option,
    required this.affectedEvents,
    required this.affectedContexts,
    required this.createdAt,
    this.isSuccess = true,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        relationshipId,
        option,
        affectedEvents,
        affectedContexts,
        createdAt,
        isSuccess,
        errorMessage,
      ];
}
