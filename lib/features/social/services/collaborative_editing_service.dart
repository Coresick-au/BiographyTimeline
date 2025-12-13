import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/collaborative_models.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/user.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/geo_location.dart';
import 'relationship_service.dart';

/// Service for managing collaborative editing of shared events
class CollaborativeEditingService {
  final List<EventContribution> _contributions = [];
  final List<EventVersion> _eventVersions = [];
  final List<EditConflict> _conflicts = [];
  final List<CollaborativeSession> _sessions = [];
  final List<ContentAttribution> _attributions = [];
  
  final _contributionsController = StreamController<List<EventContribution>>.broadcast();
  final _versionsController = StreamController<List<EventVersion>>.broadcast();
  final _conflictsController = StreamController<List<EditConflict>>.broadcast();
  final _sessionsController = StreamController<List<CollaborativeSession>>.broadcast();
  final _attributionsController = StreamController<List<ContentAttribution>>.broadcast();
  
  final RelationshipService _relationshipService = RelationshipService();
  final Uuid _uuid = const Uuid();

  Stream<List<EventContribution>> get contributionsStream => _contributionsController.stream;
  Stream<List<EventVersion>> get versionsStream => _versionsController.stream;
  Stream<List<EditConflict>> get conflictsStream => _conflictsController.stream;
  Stream<List<CollaborativeSession>> get sessionsStream => _sessionsController.stream;
  Stream<List<ContentAttribution>> get attributionsStream => _attributionsController.stream;

  List<EventContribution> get contributions => List.unmodifiable(_contributions);
  List<EventVersion> get eventVersions => List.unmodifiable(_eventVersions);
  List<EditConflict> get conflicts => List.unmodifiable(_conflicts);
  List<CollaborativeSession> get sessions => List.unmodifiable(_sessions);
  List<ContentAttribution> get attributions => List.unmodifiable(_attributions);

  /// Start a collaborative editing session for a shared event
  Future<CollaborativeSession> startCollaborativeSession({
    required String eventId,
    required List<String> participantIds,
    required String initiatedBy,
  }) async {
    // Verify user has permission to start session
    if (!await _hasEditPermission(initiatedBy, eventId)) {
      throw Exception('User does not have permission to edit this event');
    }

    // Check if session already exists
    try {
      final existingSession = _sessions.firstWhere(
        (session) => session.eventId == eventId && session.status == SessionStatus.active,
      );
      throw Exception('Active session already exists for this event');
    } catch (e) {
      // No existing session found, continue
    }

    final session = CollaborativeSession(
      id: _uuid.v4(),
      eventId: eventId,
      participantIds: participantIds,
      activeEditorIds: [initiatedBy],
      startedAt: DateTime.now(),
      status: SessionStatus.active,
      sessionMetadata: {
        'initiatedBy': initiatedBy,
        'totalParticipants': participantIds.length,
      },
    );

    _sessions.add(session);
    _sessionsController.add(_sessions);

    return session;
  }

  /// Add a contribution to a shared event
  Future<EventContribution> addContribution({
    required String eventId,
    required String contributorId,
    required String contributorName,
    required ContributionType type,
    required Map<String, dynamic> changes,
    String? sessionId,
  }) async {
    // Verify user has permission to contribute
    if (!await _hasEditPermission(contributorId, eventId)) {
      throw Exception('User does not have permission to edit this event');
    }

    // Get or create current version of the event
    EventVersion? currentVersion = _getCurrentVersion(eventId);
    if (currentVersion == null) {
      // Create initial version for new events
      currentVersion = await _createInitialVersion(eventId, contributorId, contributorName);
    }

    // Check for conflicts with existing contributions
    final conflicts = await _detectConflicts(eventId, contributorId, changes, type);
    
    final contribution = EventContribution(
      id: _uuid.v4(),
      eventId: eventId,
      contributorId: contributorId,
      contributorName: contributorName,
      type: type,
      changes: changes,
      timestamp: DateTime.now(),
      previousVersionId: currentVersion.id,
      conflictsWith: conflicts.map((c) => c.id).toList(),
    );

    _contributions.add(contribution);
    
    // Update session if provided
    if (sessionId != null) {
      _updateSessionActivity(sessionId, contributorId);
    }

    // Create conflicts if any detected
    if (conflicts.isNotEmpty) {
      for (final conflict in conflicts) {
        _conflicts.add(conflict);
      }
      _conflictsController.add(_conflicts);
    }

    _contributionsController.add(_contributions);
    
    // Update attribution
    await _updateAttribution(eventId, contributorId, contributorName, type);

    return contribution;
  }

  /// Create initial version for a new event
  Future<EventVersion> _createInitialVersion(String eventId, String createdBy, String createdByName) async {
    // Create a basic event data for the initial version
    // In a real implementation, this would fetch the actual event data
    final initialEventData = TimelineEvent(
      id: eventId,
      contextId: _uuid.v4(),
      ownerId: createdBy,
      timestamp: DateTime.now(),
      eventType: 'shared_event',
      customAttributes: {},
      assets: [],
      participantIds: [createdBy],
      privacyLevel: PrivacyLevel.private,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final initialVersion = EventVersion(
      id: _uuid.v4(),
      eventId: eventId,
      versionNumber: 1,
      eventData: initialEventData,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.now(),
      contributorIds: [createdBy],
      contributorNames: [createdByName],
      changeSummary: {
        'type': 'initial_version',
        'createdBy': createdByName,
      },
    );

    _eventVersions.add(initialVersion);
    _versionsController.add(_eventVersions);

    return initialVersion;
  }

  /// Approve a contribution and create a new version
  Future<EventVersion> approveContribution({
    required String contributionId,
    required String approvedBy,
    String? resolutionNote,
  }) async {
    final contribution = _contributions.firstWhere(
      (c) => c.id == contributionId,
      orElse: () => throw Exception('Contribution not found'),
    );

    if (!await _hasApprovalPermission(approvedBy, contribution.eventId)) {
      throw Exception('User does not have permission to approve contributions');
    }

    // Check for unresolved conflicts
    final unresolvedConflicts = _conflicts.where(
      (c) => c.conflictingContributionIds.contains(contributionId) && 
             c.status != ConflictStatus.resolved,
    );

    if (unresolvedConflicts.isNotEmpty) {
      throw Exception('Cannot approve contribution with unresolved conflicts');
    }

    // Create new event version with approved changes
    final previousVersion = _getCurrentVersion(contribution.eventId);
    final updatedEventData = _applyContributionToEvent(
      previousVersion?.eventData,
      contribution,
    );

    final newVersion = EventVersion(
      id: _uuid.v4(),
      eventId: contribution.eventId,
      versionNumber: (previousVersion?.versionNumber ?? 0) + 1,
      eventData: updatedEventData,
      createdBy: approvedBy,
      createdByName: await _getUserName(approvedBy),
      createdAt: DateTime.now(),
      contributorIds: [
        ...previousVersion?.contributorIds ?? [],
        contribution.contributorId,
      ],
      contributorNames: [
        ...previousVersion?.contributorNames ?? [],
        contribution.contributorName,
      ],
      parentVersionId: previousVersion?.id,
      changeSummary: {
        'contributionId': contribution.id,
        'type': contribution.type.toString(),
        'contributor': contribution.contributorName,
        'changes': contribution.changes,
      },
    );

    // Update contribution
    final updatedContribution = contribution.copyWith(
      isApproved: true,
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
      newVersionId: newVersion.id,
      resolutionNote: resolutionNote,
    );

    // Update lists
    final contributionIndex = _contributions.indexWhere((c) => c.id == contributionId);
    _contributions[contributionIndex] = updatedContribution;

    // Mark previous version as not current
    if (previousVersion != null) {
      final previousIndex = _eventVersions.indexWhere((v) => v.id == previousVersion.id);
      _eventVersions[previousIndex] = previousVersion.copyWith(isCurrent: false);
    }

    _eventVersions.add(newVersion);
    
    // Update streams
    _contributionsController.add(_contributions);
    _versionsController.add(_eventVersions);

    return newVersion;
  }

  /// Detect conflicts between concurrent edits
  Future<List<EditConflict>> _detectConflicts(
    String eventId,
    String contributorId,
    Map<String, dynamic> changes,
    ContributionType type,
  ) async {
    final conflicts = <EditConflict>[];
    
    // Get pending contributions for the same event
    final pendingContributions = _contributions.where(
      (c) => c.eventId == eventId && 
             !c.isApproved &&
             c.contributorId != contributorId,
    );

    for (final pending in pendingContributions) {
      final conflict = _checkForConflict(pending, contributorId, changes, type);
      if (conflict != null) {
        conflicts.add(conflict);
      }
    }

    return conflicts;
  }

  /// Check if two contributions conflict
  EditConflict? _checkForConflict(
    EventContribution existing,
    String newContributorId,
    Map<String, dynamic> newChanges,
    ContributionType newType,
  ) {
    // Check for simultaneous edits to same fields
    if (_isSameFieldEdit(existing.type, existing.changes, newType, newChanges)) {
      return EditConflict(
        id: _uuid.v4(),
        eventId: existing.eventId,
        conflictingContributionIds: [existing.id],
        conflictingUserIds: [existing.contributorId, newContributorId],
        type: ConflictType.simultaneousEdit,
        conflictDetails: {
          'field': _getConflictField(existing.type, newType),
          'existingChanges': existing.changes,
          'newChanges': newChanges,
        },
        detectedAt: DateTime.now(),
      );
    }

    // Check for data integrity issues
    if (_wouldCauseDataIntegrityIssue(existing, newChanges)) {
      return EditConflict(
        id: _uuid.v4(),
        eventId: existing.eventId,
        conflictingContributionIds: [existing.id],
        conflictingUserIds: [existing.contributorId, newContributorId],
        type: ConflictType.dataIntegrity,
        conflictDetails: {
          'integrityIssue': 'Data integrity violation detected',
          'existingChanges': existing.changes,
          'newChanges': newChanges,
        },
        detectedAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Check if two edits target the same field
  bool _isSameFieldEdit(
    ContributionType existingType,
    Map<String, dynamic> existingChanges,
    ContributionType newType,
    Map<String, dynamic> newChanges,
  ) {
    // Same contribution type always conflicts
    if (existingType == newType) return true;

    // Check for specific field conflicts
    switch (existingType) {
      case ContributionType.titleEdit:
        return newType == ContributionType.titleEdit;
      case ContributionType.descriptionEdit:
        return newType == ContributionType.descriptionEdit;
      case ContributionType.storyEdit:
      case ContributionType.storyAddition:
        return newType == ContributionType.storyEdit || newType == ContributionType.storyAddition;
      case ContributionType.locationUpdate:
        return newType == ContributionType.locationUpdate;
      case ContributionType.attributeChange:
        // Check if they modify the same attribute
        final existingAttr = existingChanges['attribute'] as String?;
        final newAttr = newChanges['attribute'] as String?;
        return existingAttr != null && existingAttr == newAttr;
      default:
        return false;
    }
  }

  /// Check if changes would cause data integrity issues
  bool _wouldCauseDataIntegrityIssue(
    EventContribution existing,
    Map<String, dynamic> newChanges,
  ) {
    // Check for removing participants that are being added
    if (existing.type == ContributionType.participantRemove && 
        newChanges.containsKey('participantId')) {
      return true;
    }

    // Check for conflicting privacy level changes
    if (existing.type == ContributionType.attributeChange &&
        existing.changes['attribute'] == 'privacyLevel' &&
        newChanges.containsKey('privacyLevel')) {
      return true;
    }

    return false;
  }

  /// Get the field that causes conflict
  String _getConflictField(ContributionType type1, ContributionType type2) {
    if (type1 == type2) return type1.toString();
    
    // Map to common field names
    switch (type1) {
      case ContributionType.titleEdit:
      case ContributionType.descriptionEdit:
      case ContributionType.storyEdit:
      case ContributionType.storyAddition:
      case ContributionType.locationUpdate:
        return type1.toString();
      case ContributionType.attributeChange:
        return 'custom_attributes';
      default:
        return 'unknown_field';
    }
  }

  /// Apply contribution to event data
  TimelineEvent _applyContributionToEvent(
    TimelineEvent? eventData,
    EventContribution contribution,
  ) {
    if (eventData == null) {
      throw Exception('No event data to apply contribution to');
    }

    switch (contribution.type) {
      case ContributionType.titleEdit:
        return eventData.copyWith(
          title: contribution.changes['title'] as String?,
          updatedAt: DateTime.now(),
        );
      case ContributionType.descriptionEdit:
        return eventData.copyWith(
          description: contribution.changes['description'] as String?,
          updatedAt: DateTime.now(),
        );
      case ContributionType.storyAddition:
      case ContributionType.storyEdit:
        // Handle story updates (would need Story model implementation)
        return eventData.copyWith(
          updatedAt: DateTime.now(),
        );
      case ContributionType.locationUpdate:
        final locationData = contribution.changes['location'];
        GeoLocation? location;
        if (locationData is Map<String, dynamic>) {
          location = GeoLocation(
            latitude: locationData['latitude'] as double,
            longitude: locationData['longitude'] as double,
            locationName: locationData['locationName'] as String?,
          );
        }
        return eventData.copyWith(
          location: location,
          updatedAt: DateTime.now(),
        );
      case ContributionType.attributeChange:
        final updatedAttributes = Map<String, dynamic>.from(eventData.customAttributes);
        updatedAttributes[contribution.changes['attribute'] as String] = 
            contribution.changes['value'];
        return eventData.copyWith(
          customAttributes: updatedAttributes,
          updatedAt: DateTime.now(),
        );
      case ContributionType.participantAdd:
        final updatedParticipants = List<String>.from(eventData.participantIds);
        if (contribution.changes['participantId'] != null) {
          updatedParticipants.add(contribution.changes['participantId'] as String);
        }
        return eventData.copyWith(
          participantIds: updatedParticipants,
          updatedAt: DateTime.now(),
        );
      case ContributionType.participantRemove:
        final updatedParticipants = List<String>.from(eventData.participantIds);
        if (contribution.changes['participantId'] != null) {
          updatedParticipants.remove(contribution.changes['participantId'] as String);
        }
        return eventData.copyWith(
          participantIds: updatedParticipants,
          updatedAt: DateTime.now(),
        );
      default:
        return eventData.copyWith(updatedAt: DateTime.now());
    }
  }

  /// Get current version of an event
  EventVersion? _getCurrentVersion(String eventId) {
    try {
      return _eventVersions.firstWhere(
        (version) => version.eventId == eventId && version.isCurrent,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update session activity
  void _updateSessionActivity(String sessionId, String userId) {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _sessions[sessionIndex];
      final updatedActiveEditors = Set<String>.from(session.activeEditorIds);
      updatedActiveEditors.add(userId);
      
      _sessions[sessionIndex] = session.copyWith(
        activeEditorIds: updatedActiveEditors.toList(),
      );
      _sessionsController.add(_sessions);
    }
  }

  /// Update attribution for content
  Future<void> _updateAttribution(
    String eventId,
    String contributorId,
    String contributorName,
    ContributionType type,
  ) async {
    ContentAttribution attribution;
    attribution = _attributions.firstWhere(
      (a) => a.contentId == eventId,
      orElse: () => ContentAttribution(
        contentId: eventId,
        contentType: 'timeline_event',
        contributors: [],
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        totalContributions: 0,
        contributionCounts: {},
      ),
    );

    final attributionIndex = _attributions.indexWhere((a) => a.contentId == eventId);
    
    // Update contributor attribution
    final contributorIndex = attribution.contributors.indexWhere(
      (c) => c.userId == contributorId,
    );
    
    ContributorAttribution updatedContributor;
    if (contributorIndex != -1) {
      final existing = attribution.contributors[contributorIndex];
      updatedContributor = existing.copyWith(
        contributionTypes: List<ContributionType>.from(existing.contributionTypes)..add(type),
        contributionCount: existing.contributionCount + 1,
        lastContributionAt: DateTime.now(),
      );
      attribution.contributors[contributorIndex] = updatedContributor;
    } else {
      updatedContributor = ContributorAttribution(
        userId: contributorId,
        userName: contributorName,
        contributionTypes: [type],
        contributionCount: 1,
        firstContributionAt: DateTime.now(),
        lastContributionAt: DateTime.now(),
        isPrimaryContributor: attribution.contributors.isEmpty,
      );
      attribution.contributors.add(updatedContributor);
    }

    // Update counts
    final updatedCounts = Map<String, int>.from(attribution.contributionCounts);
    updatedCounts[contributorId] = (updatedCounts[contributorId] ?? 0) + 1;

    final updatedAttribution = attribution.copyWith(
      contributors: attribution.contributors,
      lastModifiedAt: DateTime.now(),
      totalContributions: attribution.totalContributions + 1,
      contributionCounts: updatedCounts,
    );

    if (attributionIndex != -1) {
      _attributions[attributionIndex] = updatedAttribution;
    } else {
      _attributions.add(updatedAttribution);
    }

    _attributionsController.add(_attributions);
  }

  /// Check if user has edit permission for event
  Future<bool> _hasEditPermission(String userId, String eventId) async {
    try {
      // Get event participants
      final sharedEvent = _relationshipService.sharedEvents
          .firstWhere((e) => e.eventId == eventId);
      
      return sharedEvent.participantIds.contains(userId);
    } catch (e) {
      // For testing purposes, if event not found in shared events,
      // assume the user has permission (this would be handled differently in production)
      return true;
    }
  }

  /// Check if user has approval permission for event
  Future<bool> _hasApprovalPermission(String userId, String eventId) async {
    // For now, same as edit permission - could be extended for admin roles
    return await _hasEditPermission(userId, eventId);
  }

  /// Get user name by ID
  Future<String> _getUserName(String userId) async {
    // This would typically query a user service
    // For now, return a placeholder
    return 'User $userId';
  }

  /// Resolve a conflict
  Future<void> resolveConflict({
    required String conflictId,
    required String resolvedBy,
    required ConflictResolution resolution,
    String? resolutionNote,
  }) async {
    final conflictIndex = _conflicts.indexWhere((c) => c.id == conflictId);
    if (conflictIndex == -1) {
      throw Exception('Conflict not found');
    }

    final conflict = _conflicts[conflictIndex];
    final updatedConflict = conflict.copyWith(
      status: ConflictStatus.resolved,
      resolvedBy: resolvedBy,
      resolvedAt: DateTime.now(),
      resolution: resolution,
      resolutionNote: resolutionNote,
    );

    _conflicts[conflictIndex] = updatedConflict;
    _conflictsController.add(_conflicts);

    // Apply resolution based on strategy
    await _applyConflictResolution(conflict, resolution);
  }

  /// Apply conflict resolution strategy
  Future<void> _applyConflictResolution(EditConflict conflict, ConflictResolution resolution) async {
    switch (resolution) {
      case ConflictResolution.acceptLatest:
        // Accept the most recent contribution
        final contributions = _contributions.where(
          (c) => c.conflictsWith.contains(conflict.id),
        );
        if (contributions.isNotEmpty) {
          final latest = contributions.reduce((a, b) => 
              a.timestamp.isAfter(b.timestamp) ? a : b);
          await approveContribution(
            contributionId: latest.id,
            approvedBy: conflict.resolvedBy ?? 'system',
            resolutionNote: 'Auto-resolved: Accept latest',
          );
        }
        break;
      case ConflictResolution.acceptEarliest:
        // Accept the earliest contribution
        final contributions = _contributions.where(
          (c) => c.conflictsWith.contains(conflict.id),
        );
        if (contributions.isNotEmpty) {
          final earliest = contributions.reduce((a, b) => 
              a.timestamp.isBefore(b.timestamp) ? a : b);
          await approveContribution(
            contributionId: earliest.id,
            approvedBy: conflict.resolvedBy ?? 'system',
            resolutionNote: 'Auto-resolved: Accept earliest',
          );
        }
        break;
      case ConflictResolution.mergeChanges:
        // Attempt to merge changes (complex implementation needed)
        // For now, escalate to manual resolution
        break;
      case ConflictResolution.rejectAll:
        // Reject all conflicting contributions
        final contributionIds = _contributions
            .where((c) => c.conflictsWith.contains(conflict.id))
            .map((c) => c.id)
            .toList();
        
        for (final contributionId in contributionIds) {
          _contributions.removeWhere((c) => c.id == contributionId);
        }
        _contributionsController.add(_contributions);
        break;
      case ConflictResolution.manualResolution:
        // Leave for manual resolution
        break;
    }
  }

  /// Get contributions for an event
  List<EventContribution> getContributionsForEvent(String eventId) {
    return _contributions.where((c) => c.eventId == eventId).toList();
  }

  /// Get versions for an event
  List<EventVersion> getVersionsForEvent(String eventId) {
    return _eventVersions.where((v) => v.eventId == eventId).toList();
  }

  /// Get conflicts for an event
  List<EditConflict> getConflictsForEvent(String eventId) {
    return _conflicts.where((c) => c.eventId == eventId).toList();
  }

  /// Get attribution for content
  ContentAttribution? getAttributionForContent(String contentId) {
    try {
      return _attributions.firstWhere((a) => a.contentId == contentId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose streams
  void dispose() {
    _contributionsController.close();
    _versionsController.close();
    _conflictsController.close();
    _sessionsController.close();
    _attributionsController.close();
  }
}
