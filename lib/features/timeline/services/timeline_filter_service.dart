import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/user.dart';
import '../../social/services/privacy_settings_service.dart';

/// Service responsible for filtering timeline events based on various criteria.
class TimelineFilterService {
  final PrivacySettingsService _privacyService;

  TimelineFilterService(this._privacyService);

  /// Filters events based on the provided configuration.
  List<TimelineEvent> filterEvents({
    required List<TimelineEvent> events,
    required bool showPrivateEvents,
    String? activeContextId,
    DateTime? startDate,
    DateTime? endDate,
    String? eventFilter,
    String? currentViewerId,
    String? timelineOwnerId,
  }) {
    var filteredEvents = List<TimelineEvent>.from(events);

    // Apply privacy filtering
    filteredEvents = _getPrivacyFilteredEvents(
      events: filteredEvents,
      currentViewerId: currentViewerId,
      timelineOwnerId: timelineOwnerId,
    );

    // Filter by private events setting
    if (!showPrivateEvents) {
      filteredEvents = filteredEvents.where((event) => 
        event.privacyLevel != PrivacyLevel.private).toList();
    }

    // Filter by active context
    if (activeContextId != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.contextId == activeContextId).toList();
    }

    // Filter by date range
    if (startDate != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.timestamp.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    // Filter by event type
    if (eventFilter != null) {
       switch (eventFilter) {
        case 'photos':
          filteredEvents = filteredEvents.where((event) => 
            event.eventType == 'photo').toList();
          break;
        case 'milestones':
          filteredEvents = filteredEvents.where((event) => 
            event.eventType == 'milestone').toList();
          break;
        case 'text':
          filteredEvents = filteredEvents.where((event) => 
            event.eventType == 'text').toList();
          break;
        case 'all':
        default:
          // No filtering
          break;
      }
    }

    return filteredEvents;
  }

  /// Filters contexts based on privacy settings.
  List<Context> filterContexts({
    required List<Context> contexts,
    String? currentViewerId,
    String? timelineOwnerId,
  }) {
    if (currentViewerId == null || timelineOwnerId == null) return contexts;
    if (currentViewerId == timelineOwnerId) return contexts;
    
    if (!_canAccessTimeline(currentViewerId, timelineOwnerId)) return [];
    
    final accessibleContextIds = _privacyService.getAccessibleContexts(
      currentViewerId, 
      timelineOwnerId
    );
    
    if (accessibleContextIds.isEmpty) return contexts;
    
    return contexts.where((context) => accessibleContextIds.contains(context.id)).toList();
  }

  /// Check if a viewer can access the timeline
  bool _canAccessTimeline(String viewerId, String ownerId) {
    if (viewerId == ownerId) return true;
    return _privacyService.canAccessTimeline(viewerId, ownerId);
  }

  /// Get events filtered by privacy settings
  List<TimelineEvent> _getPrivacyFilteredEvents({
    required List<TimelineEvent> events,
    String? currentViewerId,
    String? timelineOwnerId,
  }) {
    if (currentViewerId == null || timelineOwnerId == null) return events;
    if (currentViewerId == timelineOwnerId) return events;
    
    if (!_canAccessTimeline(currentViewerId, timelineOwnerId)) return [];
    
    final accessibleEventIds = _privacyService.getAccessibleEvents(
      currentViewerId, 
      timelineOwnerId
    );
    
    if (accessibleEventIds.isEmpty) return events;
    
    return events.where((event) => accessibleEventIds.contains(event.id)).toList();
  }
}

/// Provider for TimelineFilterService
final timelineFilterServiceProvider = Provider<TimelineFilterService>((ref) {
  // Assuming PrivacySettingsService doesn't need external dependencies for now 
  // or we instantiate it here. If it becomes a provider, we watch it.
  return TimelineFilterService(PrivacySettingsService());
});
