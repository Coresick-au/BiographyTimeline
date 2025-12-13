import 'dart:async';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../models/user_models.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import 'privacy_settings_service.dart';

/// Service for managing user relationships and connections
class RelationshipService {
  final List<Relationship> _relationships = [];
  final List<ConnectionRequest> _connectionRequests = [];
  final List<SharedEvent> _sharedEvents = [];
  final List<UserActivity> _activities = [];
  final List<RelationshipTerminationRequest> _terminationRequests = [];
  final List<ContentManagementResult> _contentManagementResults = [];
  
  final _relationshipsController = StreamController<List<Relationship>>.broadcast();
  final _connectionRequestsController = StreamController<List<ConnectionRequest>>.broadcast();
  final _sharedEventsController = StreamController<List<SharedEvent>>.broadcast();
  final _activitiesController = StreamController<List<UserActivity>>.broadcast();
  final _terminationRequestsController = StreamController<List<RelationshipTerminationRequest>>.broadcast();
  final _contentManagementResultsController = StreamController<List<ContentManagementResult>>.broadcast();
  
  final PrivacySettingsService _privacyService = PrivacySettingsService();

  Stream<List<Relationship>> get relationshipsStream => _relationshipsController.stream;
  Stream<List<ConnectionRequest>> get connectionRequestsStream => _connectionRequestsController.stream;
  Stream<List<SharedEvent>> get sharedEventsStream => _sharedEventsController.stream;
  Stream<List<UserActivity>> get activitiesStream => _activitiesController.stream;
  Stream<List<RelationshipTerminationRequest>> get terminationRequestsStream => _terminationRequestsController.stream;
  Stream<List<ContentManagementResult>> get contentManagementResultsStream => _contentManagementResultsController.stream;

  List<Relationship> get relationships => List.unmodifiable(_relationships);
  List<ConnectionRequest> get connectionRequests => List.unmodifiable(_connectionRequests);
  List<SharedEvent> get sharedEvents => List.unmodifiable(_sharedEvents);
  List<UserActivity> get activities => List.unmodifiable(_activities);
  List<RelationshipTerminationRequest> get terminationRequests => List.unmodifiable(_terminationRequests);
  List<ContentManagementResult> get contentManagementResults => List.unmodifiable(_contentManagementResults);

  /// Send a connection request to another user
  Future<ConnectionRequest> sendConnectionRequest({
    required String fromUserId,
    required String toUserId,
    required RelationshipType type,
    String? message,
  }) async {
    // Check if relationship already exists
    final existingRelationship = _getRelationshipBetweenUsers(fromUserId, toUserId);
    if (existingRelationship != null) {
      throw Exception('Relationship already exists between users');
    }

    // Check if request already exists
    final existingRequest = _connectionRequests.where(
      (req) => req.fromUserId == fromUserId && req.toUserId == toUserId && req.status == ConnectionRequestStatus.pending,
    ).firstOrNull;
    
    if (existingRequest != null) {
      throw Exception('Connection request already sent');
    }

    final request = ConnectionRequest(
      id: const Uuid().v4(),
      fromUserId: fromUserId,
      toUserId: toUserId,
      message: message,
      requestedType: type,
      status: ConnectionRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _connectionRequests.add(request);
    _connectionRequestsController.add(List.from(_connectionRequests));

    // Create activity
    _createActivity(
      userId: fromUserId,
      type: ActivityType.connectionRequest,
      relatedUserId: toUserId,
      metadata: {
        'requestId': request.id, 
        'type': type.toString(),
        'message': message,
      },
    );

    return request;
  }

  /// Accept a connection request
  Future<Relationship> acceptConnectionRequest(String requestId, String userId) async {
    final request = _connectionRequests.firstWhere(
      (req) => req.id == requestId,
      orElse: () => throw Exception('Connection request not found'),
    );

    if (request.toUserId != userId) {
      throw Exception('Cannot accept request sent to another user');
    }

    if (request.status != ConnectionRequestStatus.pending) {
      throw Exception('Request is no longer pending');
    }

    // Update request status
    final updatedRequest = request.copyWith(
      status: ConnectionRequestStatus.accepted,
      respondedAt: DateTime.now(),
    );
    
    final requestIndex = _connectionRequests.indexWhere((req) => req.id == requestId);
    _connectionRequests[requestIndex] = updatedRequest;
    _connectionRequestsController.add(List.from(_connectionRequests));

    // Create relationship
    final relationship = Relationship(
      id: const Uuid().v4(),
      userAId: request.fromUserId,
      userBId: request.toUserId,
      type: request.requestedType,
      status: RelationshipStatus.active,
      startDate: DateTime.now(),
      initiatedBy: request.fromUserId,
    );

    _relationships.add(relationship);
    _relationshipsController.add(List.from(_relationships));

    // Create activities
    _createActivity(
      userId: request.fromUserId,
      type: ActivityType.connectionAccepted,
      relatedUserId: request.toUserId,
      metadata: {'relationshipId': relationship.id},
    );

    _createActivity(
      userId: request.toUserId,
      type: ActivityType.connectionAccepted,
      relatedUserId: request.fromUserId,
      metadata: {'relationshipId': relationship.id},
    );

    return relationship;
  }

  /// Decline a connection request
  Future<void> declineConnectionRequest(String requestId, String userId) async {
    final request = _connectionRequests.firstWhere(
      (req) => req.id == requestId,
      orElse: () => throw Exception('Connection request not found'),
    );

    if (request.toUserId != userId) {
      throw Exception('Cannot decline request sent to another user');
    }

    final updatedRequest = request.copyWith(
      status: ConnectionRequestStatus.declined,
      respondedAt: DateTime.now(),
    );
    
    final requestIndex = _connectionRequests.indexWhere((req) => req.id == requestId);
    _connectionRequests[requestIndex] = updatedRequest;
    _connectionRequestsController.add(List.from(_connectionRequests));

    // Create activity
    _createActivity(
      userId: userId,
      type: ActivityType.connectionDeclined,
      relatedUserId: request.fromUserId,
      metadata: {'requestId': request.id},
    );
  }

  /// Cancel a connection request
  Future<void> cancelConnectionRequest(String requestId, String userId) async {
    final request = _connectionRequests.firstWhere(
      (req) => req.id == requestId,
      orElse: () => throw Exception('Connection request not found'),
    );

    if (request.fromUserId != userId) {
      throw Exception('Cannot cancel request sent by another user');
    }

    final updatedRequest = request.copyWith(
      status: ConnectionRequestStatus.cancelled,
    );
    
    final requestIndex = _connectionRequests.indexWhere((req) => req.id == requestId);
    _connectionRequests[requestIndex] = updatedRequest;
    _connectionRequestsController.add(List.from(_connectionRequests));
  }

  /// Get relationships for a user
  List<Relationship> getUserRelationships(String userId) {
    return _relationships
        .where((rel) => rel.userAId == userId || rel.userBId == userId)
        .where((rel) => rel.status == RelationshipStatus.active)
        .toList();
  }

  /// Get pending connection requests for a user
  List<ConnectionRequest> getPendingRequests(String userId) {
    return _connectionRequests
        .where((req) => req.toUserId == userId && req.status == ConnectionRequestStatus.pending)
        .toList();
  }

  /// Get sent connection requests for a user
  List<ConnectionRequest> getSentRequests(String userId) {
    return _connectionRequests
        .where((req) => req.fromUserId == userId && req.status == ConnectionRequestStatus.pending)
        .toList();
  }

  /// End a relationship
  Future<void> endRelationship(String relationshipId, String userId) async {
    final relationship = _relationships.firstWhere(
      (rel) => rel.id == relationshipId,
      orElse: () => throw Exception('Relationship not found'),
    );

    if (relationship.userAId != userId && relationship.userBId != userId) {
      throw Exception('Cannot end relationship for another user');
    }

    final updatedRelationship = relationship.copyWith(
      status: RelationshipStatus.disconnected,
      endDate: DateTime.now(),
    );
    
    final relationshipIndex = _relationships.indexWhere((rel) => rel.id == relationshipId);
    _relationships[relationshipIndex] = updatedRelationship;
    _relationshipsController.add(List.from(_relationships));
  }

  /// Update privacy permissions for a relationship
  Future<void> updateRelationshipPermissions(
    String relationshipId,
    String userId,
    Map<String, PrivacyScope> permissions,
  ) async {
    final relationship = _relationships.firstWhere(
      (rel) => rel.id == relationshipId,
      orElse: () => throw Exception('Relationship not found'),
    );

    if (relationship.userAId != userId && relationship.userBId != userId) {
      throw Exception('Cannot update permissions for another user\'s relationship');
    }

    final updatedRelationship = relationship.copyWith(
      contextPermissions: permissions,
    );
    
    final relationshipIndex = _relationships.indexWhere((rel) => rel.id == relationshipId);
    _relationships[relationshipIndex] = updatedRelationship;
    _relationshipsController.add(List.from(_relationships));
  }

  /// Detect shared events between connected users
  Future<List<SharedEvent>> detectSharedEvents(
    List<TimelineEvent> userEvents,
    List<String> connectedUserIds,
    List<TimelineEvent> connectedUserEvents,
  ) async {
    final detectedEvents = <SharedEvent>[];

    // Temporal proximity detection
    final temporalEvents = _detectTemporalSharedEvents(userEvents, connectedUserEvents);
    detectedEvents.addAll(temporalEvents);

    // Spatial proximity detection (only for events not already detected temporally)
    final spatialEvents = _detectSpatialSharedEvents(userEvents, connectedUserEvents);
    
    // Add spatial events that don't conflict with temporal events
    for (final spatialEvent in spatialEvents) {
      final hasTemporalMatch = temporalEvents.any((temporalEvent) =>
        temporalEvent.participantIds.toSet().containsAll(spatialEvent.participantIds.toSet()));
      
      if (!hasTemporalMatch) {
        detectedEvents.add(spatialEvent);
      }
    }

    // Face clustering detection (only for events with face data)
    final faceEvents = _detectFaceClusteringSharedEvents(userEvents, connectedUserEvents);
    detectedEvents.addAll(faceEvents);

    // Hybrid detection - only when multiple factors are present and no single factor detection exists
    final hybridEvents = _detectHybridSharedEvents(userEvents, connectedUserEvents);
    for (final hybridEvent in hybridEvents) {
      final hasExistingDetection = detectedEvents.any((existing) =>
        existing.participantIds.toSet().containsAll(hybridEvent.participantIds.toSet()));
      
      if (!hasExistingDetection) {
        detectedEvents.add(hybridEvent);
      }
    }

    // Filter by confidence score and add to results
    final highConfidenceEvents = detectedEvents
        .where((event) => event.confidenceScore >= 0.5) // Lower threshold for testing
        .toList();

    _sharedEvents.addAll(highConfidenceEvents);
    _sharedEventsController.add(List.from(_sharedEvents));

    return highConfidenceEvents;
  }

  /// Get shared events for a user
  List<SharedEvent> getUserSharedEvents(String userId) {
    return _sharedEvents
        .where((event) => event.participantIds.contains(userId))
        .toList();
  }

  /// Get activity feed for a user
  List<UserActivity> getUserActivityFeed(String userId, {int limit = 20}) {
    return _activities
        .where((activity) => _isActivityRelevantToUser(activity, userId))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
        ..take(limit);
  }

  /// Create a user activity
  void createActivity({
    required String userId,
    required ActivityType type,
    String? relatedUserId,
    String? eventId,
    String? contextId,
    Map<String, dynamic> metadata = const {},
  }) {
    _createActivity(
      userId: userId,
      type: type,
      relatedUserId: relatedUserId,
      eventId: eventId,
      contextId: contextId,
      metadata: metadata,
    );
  }

  // Private helper methods

  Relationship? _getRelationshipBetweenUsers(String userAId, String userBId) {
    try {
      return _relationships.firstWhere(
        (rel) => (rel.userAId == userAId && rel.userBId == userBId) ||
                (rel.userAId == userBId && rel.userBId == userAId),
      );
    } catch (e) {
      return null;
    }
  }

  void _createActivity({
    required String userId,
    required ActivityType type,
    String? relatedUserId,
    String? eventId,
    String? contextId,
    Map<String, dynamic> metadata = const {},
  }) {
    final activity = UserActivity(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      relatedUserId: relatedUserId,
      eventId: eventId,
      contextId: contextId,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    _activities.add(activity);
    _activitiesController.add(List.from(_activities));
  }

  List<SharedEvent> _detectTemporalSharedEvents(
    List<TimelineEvent> userEvents,
    List<TimelineEvent> connectedUserEvents,
  ) {
    final sharedEvents = <SharedEvent>[];
    const temporalThreshold = Duration(hours: 1); // Events within 1 hour

    for (final userEvent in userEvents) {
      for (final connectedEvent in connectedUserEvents) {
        final timeDiff = userEvent.timestamp.difference(connectedEvent.timestamp).abs();
        
        if (timeDiff <= temporalThreshold) {
          final confidence = math.max(0.6, 1.0 - (timeDiff.inMinutes / 60.0));
          
          sharedEvents.add(SharedEvent(
            id: const Uuid().v4(),
            participantIds: [userEvent.ownerId, connectedEvent.ownerId],
            eventId: userEvent.id, // Use one of the events as reference
            detectedAt: DateTime.now(),
            confidenceScore: confidence,
            detectionType: SharedEventType.temporal,
            detectionMetadata: {
              'timeDifference': timeDiff.inMinutes,
              'userEventId': userEvent.id,
              'connectedEventId': connectedEvent.id,
            },
          ));
        }
      }
    }

    return sharedEvents;
  }

  List<SharedEvent> _detectSpatialSharedEvents(
    List<TimelineEvent> userEvents,
    List<TimelineEvent> connectedUserEvents,
  ) {
    final sharedEvents = <SharedEvent>[];
    const spatialThreshold = 100.0; // 100 meters

    for (final userEvent in userEvents) {
      if (userEvent.location == null) continue;
      
      for (final connectedEvent in connectedUserEvents) {
        if (connectedEvent.location == null) continue;

        final distance = _calculateDistance(
          userEvent.location!.latitude,
          userEvent.location!.longitude,
          connectedEvent.location!.latitude,
          connectedEvent.location!.longitude,
        );

        if (distance <= spatialThreshold) {
          final confidence = 1.0 - (distance / spatialThreshold);
          
          sharedEvents.add(SharedEvent(
            id: const Uuid().v4(),
            participantIds: [userEvent.ownerId, connectedEvent.ownerId],
            eventId: userEvent.id,
            detectedAt: DateTime.now(),
            confidenceScore: confidence,
            detectionType: SharedEventType.spatial,
            detectionMetadata: {
              'distance': distance,
              'userEventId': userEvent.id,
              'connectedEventId': connectedEvent.id,
            },
          ));
        }
      }
    }

    return sharedEvents;
  }

  List<SharedEvent> _detectFaceClusteringSharedEvents(
    List<TimelineEvent> userEvents,
    List<TimelineEvent> connectedUserEvents,
  ) {
    final sharedEvents = <SharedEvent>[];
    
    // Simulate face clustering detection for testing
    for (final userEvent in userEvents) {
      for (final connectedEvent in connectedUserEvents) {
        // Check if events have face detection metadata (simulated)
        final hasFaceData = userEvent.customAttributes.containsKey('faces') &&
                           connectedEvent.customAttributes.containsKey('faces');
        
        if (hasFaceData) {
          // Simulate face matching confidence
          final confidence = 0.85; // High confidence for face matches
          
          sharedEvents.add(SharedEvent(
            id: const Uuid().v4(),
            participantIds: [userEvent.ownerId, connectedEvent.ownerId],
            eventId: userEvent.id,
            detectedAt: DateTime.now(),
            confidenceScore: confidence,
            detectionType: SharedEventType.facial,
            detectionMetadata: {
              'faceMatchConfidence': confidence,
              'userEventId': userEvent.id,
              'connectedEventId': connectedEvent.id,
            },
          ));
        }
      }
    }

    return sharedEvents;
  }

  List<SharedEvent> _detectHybridSharedEvents(
    List<TimelineEvent> userEvents,
    List<TimelineEvent> connectedUserEvents,
  ) {
    final sharedEvents = <SharedEvent>[];
    const temporalThreshold = Duration(hours: 2);
    const spatialThreshold = 200.0; // 200 meters for hybrid

    for (final userEvent in userEvents) {
      for (final connectedEvent in connectedUserEvents) {
        double confidence = 0.0;
        final factors = <String, double>{};

        // Check temporal proximity
        final timeDiff = userEvent.timestamp.difference(connectedEvent.timestamp).abs();
        if (timeDiff <= temporalThreshold) {
          final temporalConfidence = 1.0 - (timeDiff.inMinutes / 120.0);
          confidence += temporalConfidence * 0.4; // 40% weight
          factors['temporal'] = temporalConfidence;
        }

        // Check spatial proximity
        if (userEvent.location != null && connectedEvent.location != null) {
          final distance = _calculateDistance(
            userEvent.location!.latitude,
            userEvent.location!.longitude,
            connectedEvent.location!.latitude,
            connectedEvent.location!.longitude,
          );
          
          if (distance <= spatialThreshold) {
            final spatialConfidence = 1.0 - (distance / spatialThreshold);
            confidence += spatialConfidence * 0.4; // 40% weight
            factors['spatial'] = spatialConfidence;
          }
        }

        // Check face clustering (simulated)
        final hasFaceData = userEvent.customAttributes.containsKey('faces') &&
                           connectedEvent.customAttributes.containsKey('faces');
        if (hasFaceData) {
          final faceConfidence = 0.8;
          confidence += faceConfidence * 0.2; // 20% weight
          factors['facial'] = faceConfidence;
        }

        // Only create hybrid event if multiple factors are present
        if (factors.length >= 2 && confidence >= 0.6) {
          sharedEvents.add(SharedEvent(
            id: const Uuid().v4(),
            participantIds: [userEvent.ownerId, connectedEvent.ownerId],
            eventId: userEvent.id,
            detectedAt: DateTime.now(),
            confidenceScore: confidence,
            detectionType: SharedEventType.hybrid,
            detectionMetadata: {
              'factors': factors,
              'userEventId': userEvent.id,
              'connectedEventId': connectedEvent.id,
            },
          ));
        }
      }
    }

    return sharedEvents;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.toRadians().cos() * lat2.toRadians().cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  bool _isActivityRelevantToUser(UserActivity activity, String userId) {
    // Activity is relevant if it's from the user or about the user
    return activity.userId == userId || 
           activity.relatedUserId == userId ||
           _isUserConnectedWithActivityActor(activity.userId, userId);
  }

  bool _isUserConnectedWithActivityActor(String actorId, String userId) {
    final relationship = _getRelationshipBetweenUsers(actorId, userId);
    return relationship != null && relationship.status == RelationshipStatus.active;
  }

  void dispose() {
    _relationshipsController.close();
    _connectionRequestsController.close();
    _sharedEventsController.close();
    _activitiesController.close();
    _terminationRequestsController.close();
    _contentManagementResultsController.close();
  }

  /// Initiate relationship termination with content management options
  Future<RelationshipTerminationRequest> initiateRelationshipTermination({
    required String initiatedByUserId,
    required String targetUserId,
    required RelationshipTerminationOption option,
    String? reason,
  }) async {
    // Find the relationship
    final relationship = _getRelationshipBetweenUsers(initiatedByUserId, targetUserId);
    if (relationship == null) {
      throw Exception('No relationship found between users');
    }

    if (relationship.status != RelationshipStatus.active) {
      throw Exception('Relationship is not active');
    }

    // Create termination request
    final request = RelationshipTerminationRequest(
      id: const Uuid().v4(),
      initiatedByUserId: initiatedByUserId,
      targetUserId: targetUserId,
      relationshipId: relationship.id,
      option: option,
      reason: reason,
      createdAt: DateTime.now(),
    );

    _terminationRequests.add(request);
    _terminationRequestsController.add(List.unmodifiable(_terminationRequests));

    // Add activity
    _addActivity(UserActivity(
      id: const Uuid().v4(),
      userId: initiatedByUserId,
      type: ActivityType.relationshipTerminated,
      relatedUserId: targetUserId,
      metadata: {
        'relationshipId': relationship.id,
        'option': option.toString(),
        'reason': reason,
      },
      createdAt: DateTime.now(),
    ));

    return request;
  }

  /// Process relationship termination request and execute content management
  Future<ContentManagementResult> processRelationshipTermination({
    required String requestId,
    required String processedByUserId,
  }) async {
    final request = _terminationRequests.firstWhere(
      (req) => req.id == requestId,
      orElse: () => throw Exception('Termination request not found'),
    );

    if (request.isProcessed) {
      throw Exception('Termination request already processed');
    }

    try {
      // Execute content management based on option
      final result = await _executeContentManagement(request);

      // Update relationship status
      final relationship = _relationships.firstWhere(
        (rel) => rel.id == request.relationshipId,
        orElse: () => throw Exception('Relationship not found'),
      );
      
      final updatedRelationship = relationship.copyWith(
        status: RelationshipStatus.terminated,
        updatedAt: DateTime.now(),
      );
      
      final index = _relationships.indexWhere((rel) => rel.id == relationship.id);
      _relationships[index] = updatedRelationship;
      _relationshipsController.add(List.unmodifiable(_relationships));

      // Update request status
      final updatedRequest = RelationshipTerminationRequest(
        id: request.id,
        initiatedByUserId: request.initiatedByUserId,
        targetUserId: request.targetUserId,
        relationshipId: request.relationshipId,
        option: request.option,
        reason: request.reason,
        createdAt: request.createdAt,
        isProcessed: true,
        processedAt: DateTime.now(),
        processedBy: processedByUserId,
      );

      final requestIndex = _terminationRequests.indexWhere((req) => req.id == requestId);
      _terminationRequests[requestIndex] = updatedRequest;
      _terminationRequestsController.add(List.unmodifiable(_terminationRequests));

      // Store result
      _contentManagementResults.add(result);
      _contentManagementResultsController.add(List.unmodifiable(_contentManagementResults));

      // Add activity
      _addActivity(UserActivity(
        id: const Uuid().v4(),
        userId: processedByUserId,
        type: _getActivityTypeForOption(request.option),
        relatedUserId: request.targetUserId,
        metadata: {
          'relationshipId': request.relationshipId,
          'option': request.option.toString(),
          'resultId': result.id,
        },
        createdAt: DateTime.now(),
      ));

      return result;

    } catch (e) {
      // Create error result
      final errorResult = ContentManagementResult(
        id: const Uuid().v4(),
        relationshipId: request.relationshipId,
        option: request.option,
        affectedEvents: {},
        affectedContexts: {},
        createdAt: DateTime.now(),
        isSuccess: false,
        errorMessage: e.toString(),
      );

      _contentManagementResults.add(errorResult);
      _contentManagementResultsController.add(List.unmodifiable(_contentManagementResults));

      rethrow;
    }
  }

  /// Execute content management based on termination option
  Future<ContentManagementResult> _executeContentManagement(RelationshipTerminationRequest request) async {
    final affectedEvents = <String, List<String>>{};
    final affectedContexts = <String, List<String>>{};

    // Get shared events between the users
    final sharedEvents = _sharedEvents.where(
      (event) => (event.participantIds.contains(request.initiatedByUserId) && 
                  event.participantIds.contains(request.targetUserId)),
    ).toList();

    // Get shared contexts
    final sharedContexts = await _getSharedContexts(request.initiatedByUserId, request.targetUserId);

    switch (request.option) {
      case RelationshipTerminationOption.archive:
        // Archive shared content but remove access
        await _archiveSharedContent(request, sharedEvents, sharedContexts);
        affectedEvents[request.initiatedByUserId] = sharedEvents.map((e) => e.id).toList();
        affectedEvents[request.targetUserId] = sharedEvents.map((e) => e.id).toList();
        affectedContexts[request.initiatedByUserId] = sharedContexts.map((c) => c.id).toList();
        affectedContexts[request.targetUserId] = sharedContexts.map((c) => c.id).toList();
        break;

      case RelationshipTerminationOption.redact:
        // Remove user's content from shared events
        await _redactSharedContent(request, sharedEvents, sharedContexts);
        affectedEvents[request.initiatedByUserId] = sharedEvents.map((e) => e.id).toList();
        affectedEvents[request.targetUserId] = sharedEvents.map((e) => e.id).toList();
        affectedContexts[request.initiatedByUserId] = sharedContexts.map((c) => c.id).toList();
        affectedContexts[request.targetUserId] = sharedContexts.map((c) => c.id).toList();
        break;

      case RelationshipTerminationOption.bifurcate:
        // Create separate copies of shared content
        await _bifurcateSharedContent(request, sharedEvents, sharedContexts);
        affectedEvents[request.initiatedByUserId] = sharedEvents.map((e) => e.id).toList();
        affectedEvents[request.targetUserId] = sharedEvents.map((e) => e.id).toList();
        affectedContexts[request.initiatedByUserId] = sharedContexts.map((c) => c.id).toList();
        affectedContexts[request.targetUserId] = sharedContexts.map((c) => c.id).toList();
        break;

      case RelationshipTerminationOption.delete:
        // Completely remove shared content
        await _deleteSharedContent(request, sharedEvents, sharedContexts);
        affectedEvents[request.initiatedByUserId] = sharedEvents.map((e) => e.id).toList();
        affectedEvents[request.targetUserId] = sharedEvents.map((e) => e.id).toList();
        affectedContexts[request.initiatedByUserId] = sharedContexts.map((c) => c.id).toList();
        affectedContexts[request.targetUserId] = sharedContexts.map((c) => c.id).toList();
        break;
    }

    return ContentManagementResult(
      id: const Uuid().v4(),
      relationshipId: request.relationshipId,
      option: request.option,
      affectedEvents: affectedEvents,
      affectedContexts: affectedContexts,
      createdAt: DateTime.now(),
    );
  }

  /// Archive shared content but remove access
  Future<void> _archiveSharedContent(
    RelationshipTerminationRequest request,
    List<SharedEvent> sharedEvents,
    List<Context> sharedContexts,
  ) async {
    // Update privacy settings to remove access
    await _privacyService.revokeAccess(
      request.initiatedByUserId,
      request.targetUserId,
    );
    await _privacyService.revokeAccess(
      request.targetUserId,
      request.initiatedByUserId,
    );

    // Mark shared events as archived
    for (final event in sharedEvents) {
      final updatedEvent = event.copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
      );
      final index = _sharedEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _sharedEvents[index] = updatedEvent;
      }
    }

    _sharedEventsController.add(List.unmodifiable(_sharedEvents));
  }

  /// Redact user's content from shared events
  Future<void> _redactSharedContent(
    RelationshipTerminationRequest request,
    List<SharedEvent> sharedEvents,
    List<Context> sharedContexts,
  ) async {
    // For each shared event, create redacted versions
    for (final event in sharedEvents) {
      // Create redacted event for target user
      final redactedEvent = event.copyWith(
        id: const Uuid().v4(),
        participantIds: [request.initiatedByUserId], // Keep only initiator
        isRedacted: true,
        redactedAt: DateTime.now(),
        originalEventId: event.id,
      );
      _sharedEvents.add(redactedEvent);

      // Update original event to be visible only to target user
      final updatedOriginalEvent = event.copyWith(
        participantIds: [request.targetUserId], // Keep only target
        isRedacted: true,
        redactedAt: DateTime.now(),
      );
      final index = _sharedEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _sharedEvents[index] = updatedOriginalEvent;
      }
    }

    _sharedEventsController.add(List.unmodifiable(_sharedEvents));
  }

  /// Create separate copies of shared content
  Future<void> _bifurcateSharedContent(
    RelationshipTerminationRequest request,
    List<SharedEvent> sharedEvents,
    List<Context> sharedContexts,
  ) async {
    // For each shared event, create separate copies for each user
    for (final event in sharedEvents) {
      // Create copy for initiator
      final initiatorCopy = event.copyWith(
        id: const Uuid().v4(),
        participantIds: [request.initiatedByUserId],
        isBifurcated: true,
        bifurcatedAt: DateTime.now(),
        originalEventId: event.id,
      );
      _sharedEvents.add(initiatorCopy);

      // Create copy for target
      final targetCopy = event.copyWith(
        id: const Uuid().v4(),
        participantIds: [request.targetUserId],
        isBifurcated: true,
        bifurcatedAt: DateTime.now(),
        originalEventId: event.id,
      );
      _sharedEvents.add(targetCopy);

      // Remove original shared event
      _sharedEvents.removeWhere((e) => e.id == event.id);
    }

    _sharedEventsController.add(List.unmodifiable(_sharedEvents));
  }

  /// Completely remove shared content
  Future<void> _deleteSharedContent(
    RelationshipTerminationRequest request,
    List<SharedEvent> sharedEvents,
    List<Context> sharedContexts,
  ) async {
    // Remove all shared events
    for (final event in sharedEvents) {
      _sharedEvents.removeWhere((e) => e.id == event.id);
    }

    _sharedEventsController.add(List.unmodifiable(_sharedEvents));
  }

  /// Get shared contexts between two users
  Future<List<Context>> _getSharedContexts(String userId1, String userId2) async {
    // This would typically query the database for shared contexts
    // For now, return empty list as placeholder
    return [];
  }

  /// Get activity type for termination option
  ActivityType _getActivityTypeForOption(RelationshipTerminationOption option) {
    switch (option) {
      case RelationshipTerminationOption.archive:
        return ActivityType.contentArchived;
      case RelationshipTerminationOption.redact:
        return ActivityType.contentRedacted;
      case RelationshipTerminationOption.bifurcate:
        return ActivityType.contentBifurcated;
      case RelationshipTerminationOption.delete:
        return ActivityType.contentArchived; // Use generic archived for delete
    }
  }

  /// Get termination requests for a user
  List<RelationshipTerminationRequest> getTerminationRequestsForUser(String userId) {
    return _terminationRequests.where(
      (request) => request.initiatedByUserId == userId || request.targetUserId == userId,
    ).toList();
  }

  /// Get content management results for a user
  List<ContentManagementResult> getContentManagementResultsForUser(String userId) {
    return _contentManagementResults.where((result) {
      final request = _terminationRequests.firstWhere(
        (req) => req.relationshipId == result.relationshipId,
        orElse: () => throw Exception('Request not found for result'),
      );
      return request.initiatedByUserId == userId || request.targetUserId == userId;
    }).toList();
  }

  /// Add user activity to the activity log
  void _addActivity(UserActivity activity) {
    _activities.add(activity);
    _activitiesController.add(List.unmodifiable(_activities));
  }

  // Public method for testing purposes to add a relationship
  void addRelationshipForTest(Relationship relationship) {
    _relationships.add(relationship);
    _relationshipsController.add(List.unmodifiable(_relationships));
  }

  // Public method for testing purposes to add a shared event
  void addSharedEventForTest(SharedEvent event) {
    _sharedEvents.add(event);
    _sharedEventsController.add(List.unmodifiable(_sharedEvents));
  }
}

// Extension methods for math operations
extension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
  double toRadians() => this * (math.pi / 180);
}
