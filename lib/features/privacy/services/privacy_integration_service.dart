import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/granular_privacy_service.dart';
import '../models/granular_privacy_models.dart';
import '../../timeline/services/timeline_data_service.dart';
import '../../social/services/relationship_service.dart';
import '../../shared/models/timeline_event.dart';

/// Provider for privacy integration service
final privacyIntegrationServiceProvider = Provider((ref) => PrivacyIntegrationService(
  granularPrivacyService: ref.read(granularPrivacyServiceProvider),
  timelineDataService: ref.read(timelineServiceProvider),
  relationshipService: ref.read(relationshipServiceProvider),
));

/// Service that integrates privacy controls with the timeline system
class PrivacyIntegrationService {
  final GranularPrivacyService _granularPrivacyService;
  final TimelineDataService _timelineDataService;
  final RelationshipService _relationshipService;

  PrivacyIntegrationService({
    required GranularPrivacyService granularPrivacyService,
    required TimelineDataService timelineDataService,
    required RelationshipService relationshipService,
  }) : _granularPrivacyService = granularPrivacyService,
       _timelineDataService = timelineDataService,
       _relationshipService = relationshipService;

  /// Get filtered timeline events for a viewer
  Future<List<TimelineEvent>> getFilteredTimelineEvents(
    String viewerId,
    String timelineId, {
    int? limit,
    int? offset,
  }) async {
    // Get all events from timeline
    final allEvents = await _timelineDataService.getEvents(
      timelineId: timelineId,
      limit: limit,
      offset: offset,
    );

    // Filter events based on privacy settings
    final filteredEvents = <TimelineEvent>[];
    
    for (final event in allEvents) {
      if (await _canUserViewEvent(viewerId, event, timelineId)) {
        final filteredEventData = _granularPrivacyService.getFilteredEventData(
          viewerId,
          event.toJson(),
          timelineId: timelineId,
        );
        
        if (filteredEventData.isNotEmpty) {
          filteredEvents.add(TimelineEvent.fromJson(filteredEventData));
        }
      }
    }

    return filteredEvents;
  }

  /// Check if a user can view a specific event
  Future<bool> _canUserViewEvent(
    String viewerId,
    TimelineEvent event,
    String timelineId,
  ) async {
    // Check basic visibility
    if (!_granularPrivacyService.canAccessEvent(
      viewerId,
      event.id,
      PrivacyControlType.visibility,
      timelineId: timelineId,
    )) {
      return false;
    }

    // Check if viewer is the owner
    if (event.ownerId == viewerId) {
      return true;
    }

    // Check if viewer is a participant
    if (event.participantIds.contains(viewerId)) {
      return true;
    }

    // Get relationship level between viewer and event owner
    final relationship = await _relationshipService.getRelationship(viewerId, event.ownerId);
    if (relationship == null) {
      // No relationship, check if public
      final eventSettings = _granularPrivacyService.getEventSettings(event.id);
      final visibilityLevel = eventSettings.privacyLevels[PrivacyControlType.visibility] ?? 
                            EnhancedPrivacyLevel.friends;
      return visibilityLevel == EnhancedPrivacyLevel.public;
    }

    // Check privacy level based on relationship
    final eventSettings = _granularPrivacyService.getEventSettings(event.id);
    final requiredLevel = eventSettings.privacyLevels[PrivacyControlType.visibility] ?? 
                        EnhancedPrivacyLevel.friends;
    
    return _isRelationshipLevelSatisfied(relationship, requiredLevel);
  }

  /// Get filtered event data for sharing
  Future<Map<String, dynamic>> getEventDataForSharing(
    String viewerId,
    String eventId,
    String timelineId,
  ) async {
    final event = await _timelineDataService.getEventById(eventId);
    if (event == null) {
      throw Exception('Event not found: $eventId');
    }

    // Check if user can share the event
    if (!_granularPrivacyService.canAccessEvent(
      viewerId,
      eventId,
      PrivacyControlType.sharing,
      timelineId: timelineId,
    )) {
      throw Exception('User does not have sharing permission for this event');
    }

    // Get filtered data
    return _granularPrivacyService.getFilteredEventData(
      viewerId,
      event.toJson(),
      timelineId: timelineId,
    );
  }

  /// Apply privacy template to multiple events
  Future<void> applyTemplateToEvents(
    String userId,
    String templateId,
    List<String> eventIds, {
    String? reason,
  }) async {
    for (final eventId in eventIds) {
      try {
        await _granularPrivacyService.applyTemplateToEvent(userId, templateId, eventId, reason: reason);
      } catch (e) {
        // Log error but continue with other events
        print('Error applying template to event $eventId: $e');
      }
    }
  }

  /// Get privacy summary for a timeline
  Future<Map<String, dynamic>> getTimelinePrivacySummary(
    String timelineId,
  ) async {
    final timelineSettings = _granularPrivacyService.getTimelineSettings(timelineId);
    final events = await _timelineDataService.getEvents(timelineId: timelineId);
    
    int publicEvents = 0;
    int privateEvents = 0;
    int customEvents = 0;
    
    for (final event in events) {
      final eventSettings = _granularPrivacyService.getEventSettings(event.id);
      
      if (eventSettings.inheritFromTimeline) {
        final visibilityLevel = timelineSettings.defaultLevel;
        if (visibilityLevel == EnhancedPrivacyLevel.public) {
          publicEvents++;
        } else if (visibilityLevel == EnhancedPrivacyLevel.onlyMe) {
          privateEvents++;
        }
      } else {
        customEvents++;
      }
    }

    return {
      'totalEvents': events.length,
      'publicEvents': publicEvents,
      'privateEvents': privateEvents,
      'customEvents': customEvents,
      'defaultLevel': timelineSettings.defaultLevel.displayName,
      'allowEventRequests': timelineSettings.allowEventRequests,
      'allowContextRequests': timelineSettings.allowContextRequests,
      'showOnlineStatus': timelineSettings.showOnlineStatus,
      'showLastActive': timelineSettings.showLastActive,
      'showParticipationStats': timelineSettings.showParticipationStats,
    };
  }

  /// Get events that need privacy attention (expiring, etc.)
  Future<List<Map<String, dynamic>>> getEventsNeedingAttention(
    String timelineId,
  ) async {
    final expiringEvents = _granularPrivacyService.getExpiringEvents();
    final events = <Map<String, dynamic>>[];
    
    for (final eventId in expiringEvents) {
      try {
        final event = await _timelineDataService.getEventById(eventId);
        if (event != null) {
          final eventSettings = _granularPrivacyService.getEventSettings(eventId);
          events.add({
            'eventId': eventId,
            'eventTitle': event.title ?? 'Untitled Event',
            'eventDate': event.timestamp,
            'expiresAt': eventSettings.expiresAt,
            'daysUntilExpiry': eventSettings.expiresAt?.difference(DateTime.now()).inDays,
          });
        }
      } catch (e) {
        print('Error getting event details for $eventId: $e');
      }
    }
    
    return events;
  }

  /// Bulk update privacy settings for events
  Future<void> bulkUpdateEventPrivacy(
    String userId,
    List<String> eventIds,
    Map<PrivacyControlType, EnhancedPrivacyLevel> privacyLevels, {
    String? reason,
  }) async {
    for (final eventId in eventIds) {
      try {
        final eventSettings = _granularPrivacyService.getEventSettings(eventId);
        final updatedLevels = Map<PrivacyControlType, EnhancedPrivacyLevel>.from(
          eventSettings.privacyLevels
        );
        updatedLevels.addAll(privacyLevels);
        
        final updatedSettings = eventSettings.copyWith(
          privacyLevels: updatedLevels,
          inheritFromTimeline: false,
        );
        
        await _granularPrivacyService.updateEventSettings(
          userId,
          updatedSettings,
          reason: reason,
        );
      } catch (e) {
        print('Error updating privacy for event $eventId: $e');
      }
    }
  }

  /// Check if user can interact with an event (like, comment, etc.)
  Future<bool> canUserInteractWithEvent(
    String viewerId,
    String eventId,
    String timelineId,
  ) async {
    return _granularPrivacyService.canAccessEvent(
      viewerId,
      eventId,
      PrivacyControlType.interaction,
      timelineId: timelineId,
    );
  }

  /// Check if user can download media from an event
  Future<bool> canUserDownloadMedia(
    String viewerId,
    String eventId,
    String timelineId,
  ) async {
    return _granularPrivacyService.canAccessEvent(
      viewerId,
      eventId,
      PrivacyControlType.download,
      timelineId: timelineId,
    );
  }

  /// Get user's access level for an event
  Future<String> getUserAccessLevel(
    String viewerId,
    String eventId,
    String timelineId,
  ) async {
    final eventSettings = _granularPrivacyService.getEventSettings(eventId);
    
    if (eventSettings.allowedUsers.contains(viewerId)) {
      return 'explicit_access';
    }
    
    if (eventSettings.blockedUsers.contains(viewerId)) {
      return 'blocked';
    }
    
    final canView = _granularPrivacyService.canAccessEvent(
      viewerId,
      eventId,
      PrivacyControlType.visibility,
      timelineId: timelineId,
    );
    
    if (!canView) {
      return 'no_access';
    }
    
    final canInteract = _granularPrivacyService.canAccessEvent(
      viewerId,
      eventId,
      PrivacyControlType.interaction,
      timelineId: timelineId,
    );
    
    final canShare = _granularPrivacyService.canAccessEvent(
      viewerId,
      eventId,
      PrivacyControlType.sharing,
      timelineId: timelineId,
    );
    
    if (canShare) {
      return 'full_access';
    } else if (canInteract) {
      return 'interaction_access';
    } else {
      return 'view_only';
    }
  }

  /// Create privacy-aware event copy for sharing
  Future<TimelineEvent> createPrivacyAwareEventCopy(
    String viewerId,
    String eventId,
    String timelineId,
  ) async {
    final eventData = await getEventDataForSharing(viewerId, eventId, timelineId);
    return TimelineEvent.fromJson(eventData);
  }

  /// Validate privacy settings before saving
  Future<List<String>> validatePrivacySettings(
    EventPrivacySettings settings,
    String timelineId,
  ) async {
    final errors = <String>[];
    
    // Check if expiration is in the future
    if (settings.expiresAt != null && settings.expiresAt!.isBefore(DateTime.now())) {
      errors.add('Expiration date must be in the future');
    }
    
    // Check if there are conflicting settings
    if (settings.inheritFromTimeline && settings.privacyLevels.isNotEmpty) {
      errors.add('Cannot have custom privacy levels when inheriting from timeline');
    }
    
    // Check if all allowed users are not blocked
    final conflicts = settings.allowedUsers.where((user) => settings.blockedUsers.contains(user));
    if (conflicts.isNotEmpty) {
      errors.add('Users cannot be both allowed and blocked: ${conflicts.join(', ')}');
    }
    
    return errors;
  }

  bool _isRelationshipLevelSatisfied(
    UserRelationship relationship,
    EnhancedPrivacyLevel requiredLevel,
  ) {
    switch (requiredLevel) {
      case EnhancedPrivacyLevel.onlyMe:
        return false; // Only the owner can see it
      case EnhancedPrivacyLevel.closeFamily:
        return relationship.type == RelationshipType.family && 
               relationship.intensity >= RelationshipIntensity.close;
      case EnhancedPrivacyLevel.extendedFamily:
        return relationship.type == RelationshipType.family;
      case EnhancedPrivacyLevel.closeFriends:
        return relationship.type == RelationshipType.friend && 
               relationship.intensity >= RelationshipIntensity.close;
      case EnhancedPrivacyLevel.friends:
        return relationship.type == RelationshipType.friend;
      case EnhancedPrivacyLevel.colleagues:
        return relationship.type == RelationshipType.professional;
      case EnhancedPrivacyLevel.connections:
        return relationship.type == RelationshipType.acquaintance || 
               relationship.type == RelationshipType.professional ||
               relationship.type == RelationshipType.friend ||
               relationship.type == RelationshipType.family;
      case EnhancedPrivacyLevel.public:
        return true; // Everyone can see it
    }
  }
}
