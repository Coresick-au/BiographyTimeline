import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/user.dart';

part 'collaborative_models.g.dart';

/// Represents a collaborative contribution to a shared event
@JsonSerializable()
class EventContribution extends Equatable {
  final String id;
  final String eventId;
  final String contributorId;
  final String contributorName;
  final ContributionType type;
  final Map<String, dynamic> changes;
  final DateTime timestamp;
  final String? previousVersionId;
  final String? newVersionId;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final List<String> conflictsWith;
  final String? resolutionNote;

  const EventContribution({
    required this.id,
    required this.eventId,
    required this.contributorId,
    required this.contributorName,
    required this.type,
    required this.changes,
    required this.timestamp,
    this.previousVersionId,
    this.newVersionId,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.conflictsWith = const [],
    this.resolutionNote,
  });

  factory EventContribution.fromJson(Map<String, dynamic> json) =>
      _$EventContributionFromJson(json);

  Map<String, dynamic> toJson() => _$EventContributionToJson(this);

  EventContribution copyWith({
    String? id,
    String? eventId,
    String? contributorId,
    String? contributorName,
    ContributionType? type,
    Map<String, dynamic>? changes,
    DateTime? timestamp,
    String? previousVersionId,
    String? newVersionId,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    List<String>? conflictsWith,
    String? resolutionNote,
  }) {
    return EventContribution(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      contributorId: contributorId ?? this.contributorId,
      contributorName: contributorName ?? this.contributorName,
      type: type ?? this.type,
      changes: changes ?? this.changes,
      timestamp: timestamp ?? this.timestamp,
      previousVersionId: previousVersionId ?? this.previousVersionId,
      newVersionId: newVersionId ?? this.newVersionId,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      conflictsWith: conflictsWith ?? this.conflictsWith,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        contributorId,
        contributorName,
        type,
        changes,
        timestamp,
        previousVersionId,
        newVersionId,
        isApproved,
        approvedBy,
        approvedAt,
        conflictsWith,
        resolutionNote,
      ];
}

/// Types of contributions that can be made to shared events
enum ContributionType {
  @JsonValue('title_edit')
  titleEdit,
  @JsonValue('description_edit')
  descriptionEdit,
  @JsonValue('story_addition')
  storyAddition,
  @JsonValue('story_edit')
  storyEdit,
  @JsonValue('media_addition')
  mediaAddition,
  @JsonValue('media_removal')
  mediaRemoval,
  @JsonValue('location_update')
  locationUpdate,
  @JsonValue('attribute_change')
  attributeChange,
  @JsonValue('participant_add')
  participantAdd,
  @JsonValue('participant_remove')
  participantRemove,
}

/// Represents a version of a shared event with full attribution
@JsonSerializable()
class EventVersion extends Equatable {
  final String id;
  final String eventId;
  final int versionNumber;
  final TimelineEvent eventData;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<String> contributorIds;
  final List<String> contributorNames;
  final String? parentVersionId;
  final Map<String, dynamic> changeSummary;
  final bool isCurrent;
  final DateTime? archivedAt;

  const EventVersion({
    required this.id,
    required this.eventId,
    required this.versionNumber,
    required this.eventData,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.contributorIds,
    required this.contributorNames,
    this.parentVersionId,
    required this.changeSummary,
    this.isCurrent = true,
    this.archivedAt,
  });

  factory EventVersion.fromJson(Map<String, dynamic> json) =>
      _$EventVersionFromJson(json);

  Map<String, dynamic> toJson() => _$EventVersionToJson(this);

  EventVersion copyWith({
    String? id,
    String? eventId,
    int? versionNumber,
    TimelineEvent? eventData,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    List<String>? contributorIds,
    List<String>? contributorNames,
    String? parentVersionId,
    Map<String, dynamic>? changeSummary,
    bool? isCurrent,
    DateTime? archivedAt,
  }) {
    return EventVersion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      versionNumber: versionNumber ?? this.versionNumber,
      eventData: eventData ?? this.eventData,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      contributorIds: contributorIds ?? this.contributorIds,
      contributorNames: contributorNames ?? this.contributorNames,
      parentVersionId: parentVersionId ?? this.parentVersionId,
      changeSummary: changeSummary ?? this.changeSummary,
      isCurrent: isCurrent ?? this.isCurrent,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        versionNumber,
        eventData,
        createdBy,
        createdByName,
        createdAt,
        contributorIds,
        contributorNames,
        parentVersionId,
        changeSummary,
        isCurrent,
        archivedAt,
      ];
}

/// Represents a conflict between concurrent edits
@JsonSerializable()
class EditConflict extends Equatable {
  final String id;
  final String eventId;
  final List<String> conflictingContributionIds;
  final List<String> conflictingUserIds;
  final ConflictType type;
  final Map<String, dynamic> conflictDetails;
  final DateTime detectedAt;
  final ConflictStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final ConflictResolution? resolution;
  final String? resolutionNote;

  const EditConflict({
    required this.id,
    required this.eventId,
    required this.conflictingContributionIds,
    required this.conflictingUserIds,
    required this.type,
    required this.conflictDetails,
    required this.detectedAt,
    this.status = ConflictStatus.pending,
    this.resolvedBy,
    this.resolvedAt,
    this.resolution,
    this.resolutionNote,
  });

  factory EditConflict.fromJson(Map<String, dynamic> json) =>
      _$EditConflictFromJson(json);

  Map<String, dynamic> toJson() => _$EditConflictToJson(this);

  EditConflict copyWith({
    String? id,
    String? eventId,
    List<String>? conflictingContributionIds,
    List<String>? conflictingUserIds,
    ConflictType? type,
    Map<String, dynamic>? conflictDetails,
    DateTime? detectedAt,
    ConflictStatus? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    ConflictResolution? resolution,
    String? resolutionNote,
  }) {
    return EditConflict(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      conflictingContributionIds: conflictingContributionIds ?? this.conflictingContributionIds,
      conflictingUserIds: conflictingUserIds ?? this.conflictingUserIds,
      type: type ?? this.type,
      conflictDetails: conflictDetails ?? this.conflictDetails,
      detectedAt: detectedAt ?? this.detectedAt,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        conflictingContributionIds,
        conflictingUserIds,
        type,
        conflictDetails,
        detectedAt,
        status,
        resolvedBy,
        resolvedAt,
        resolution,
        resolutionNote,
      ];
}

/// Types of conflicts that can occur during collaborative editing
enum ConflictType {
  @JsonValue('simultaneous_edit')
  simultaneousEdit,
  @JsonValue('data_integrity')
  dataIntegrity,
  @JsonValue('permission_denied')
  permissionDenied,
  @JsonValue('version_mismatch')
  versionMismatch,
}

/// Status of conflict resolution
enum ConflictStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('escalated')
  escalated,
}

/// Resolution strategies for conflicts
enum ConflictResolution {
  @JsonValue('accept_latest')
  acceptLatest,
  @JsonValue('accept_earliest')
  acceptEarliest,
  @JsonValue('merge_changes')
  mergeChanges,
  @JsonValue('manual_resolution')
  manualResolution,
  @JsonValue('reject_all')
  rejectAll,
}

/// Represents a collaborative editing session for a shared event
@JsonSerializable()
class CollaborativeSession extends Equatable {
  final String id;
  final String eventId;
  final List<String> participantIds;
  final List<String> activeEditorIds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final String? currentVersionId;
  final List<String> pendingContributionIds;
  final List<String> resolvedConflictIds;
  final Map<String, dynamic> sessionMetadata;

  const CollaborativeSession({
    required this.id,
    required this.eventId,
    required this.participantIds,
    required this.activeEditorIds,
    required this.startedAt,
    this.endedAt,
    this.status = SessionStatus.active,
    this.currentVersionId,
    this.pendingContributionIds = const [],
    this.resolvedConflictIds = const [],
    this.sessionMetadata = const {},
  });

  factory CollaborativeSession.fromJson(Map<String, dynamic> json) =>
      _$CollaborativeSessionFromJson(json);

  Map<String, dynamic> toJson() => _$CollaborativeSessionToJson(this);

  CollaborativeSession copyWith({
    String? id,
    String? eventId,
    List<String>? participantIds,
    List<String>? activeEditorIds,
    DateTime? startedAt,
    DateTime? endedAt,
    SessionStatus? status,
    String? currentVersionId,
    List<String>? pendingContributionIds,
    List<String>? resolvedConflictIds,
    Map<String, dynamic>? sessionMetadata,
  }) {
    return CollaborativeSession(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      participantIds: participantIds ?? this.participantIds,
      activeEditorIds: activeEditorIds ?? this.activeEditorIds,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      currentVersionId: currentVersionId ?? this.currentVersionId,
      pendingContributionIds: pendingContributionIds ?? this.pendingContributionIds,
      resolvedConflictIds: resolvedConflictIds ?? this.resolvedConflictIds,
      sessionMetadata: sessionMetadata ?? this.sessionMetadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        participantIds,
        activeEditorIds,
        startedAt,
        endedAt,
        status,
        currentVersionId,
        pendingContributionIds,
        resolvedConflictIds,
        sessionMetadata,
      ];
}

/// Status of collaborative editing sessions
enum SessionStatus {
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// Represents attribution data for collaborative content
@JsonSerializable()
class ContentAttribution extends Equatable {
  final String contentId;
  final String contentType;
  final List<ContributorAttribution> contributors;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final int totalContributions;
  final Map<String, int> contributionCounts;

  const ContentAttribution({
    required this.contentId,
    required this.contentType,
    required this.contributors,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.totalContributions,
    required this.contributionCounts,
  });

  factory ContentAttribution.fromJson(Map<String, dynamic> json) =>
      _$ContentAttributionFromJson(json);

  Map<String, dynamic> toJson() => _$ContentAttributionToJson(this);

  ContentAttribution copyWith({
    String? contentId,
    String? contentType,
    List<ContributorAttribution>? contributors,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    int? totalContributions,
    Map<String, int>? contributionCounts,
  }) {
    return ContentAttribution(
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      contributors: contributors ?? this.contributors,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      totalContributions: totalContributions ?? this.totalContributions,
      contributionCounts: contributionCounts ?? this.contributionCounts,
    );
  }

  @override
  List<Object?> get props => [
        contentId,
        contentType,
        contributors,
        createdAt,
        lastModifiedAt,
        totalContributions,
        contributionCounts,
      ];
}

/// Attribution information for individual contributors
@JsonSerializable()
class ContributorAttribution extends Equatable {
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final List<ContributionType> contributionTypes;
  final int contributionCount;
  final DateTime firstContributionAt;
  final DateTime lastContributionAt;
  final bool isPrimaryContributor;

  const ContributorAttribution({
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.contributionTypes,
    required this.contributionCount,
    required this.firstContributionAt,
    required this.lastContributionAt,
    this.isPrimaryContributor = false,
  });

  factory ContributorAttribution.fromJson(Map<String, dynamic> json) =>
      _$ContributorAttributionFromJson(json);

  Map<String, dynamic> toJson() => _$ContributorAttributionToJson(this);

  ContributorAttribution copyWith({
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    List<ContributionType>? contributionTypes,
    int? contributionCount,
    DateTime? firstContributionAt,
    DateTime? lastContributionAt,
    bool? isPrimaryContributor,
  }) {
    return ContributorAttribution(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      contributionTypes: contributionTypes ?? this.contributionTypes,
      contributionCount: contributionCount ?? this.contributionCount,
      firstContributionAt: firstContributionAt ?? this.firstContributionAt,
      lastContributionAt: lastContributionAt ?? this.lastContributionAt,
      isPrimaryContributor: isPrimaryContributor ?? this.isPrimaryContributor,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        userName,
        userProfileImageUrl,
        contributionTypes,
        contributionCount,
        firstContributionAt,
        lastContributionAt,
        isPrimaryContributor,
      ];
}
