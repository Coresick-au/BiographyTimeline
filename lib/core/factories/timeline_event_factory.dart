import '../../shared/models/context.dart';
import '../../shared/models/timeline_event.dart';
import '../../shared/models/fuzzy_date.dart';
import '../../shared/models/geo_location.dart';
import '../../shared/models/media_asset.dart';
import '../../shared/models/user.dart';
import '../validation/custom_attribute_validator.dart';

/// Factory for creating timeline events with context-appropriate defaults
class TimelineEventFactory {
  /// Creates a timeline event with context-specific defaults and validation
  static TimelineEvent createEvent({
    required String id,
    required String contextId,
    required String ownerId,
    required ContextType contextType,
    required DateTime timestamp,
    FuzzyDate? fuzzyDate,
    GeoLocation? location,
    String? eventType,
    Map<String, dynamic>? customAttributes,
    List<MediaAsset>? assets,
    String? title,
    String? description,
    List<String>? participantIds,
    PrivacyLevel? privacyLevel,
  }) {
    // Determine event type if not provided
    final finalEventType = eventType ?? _inferEventType(assets);
    
    // Get default custom attributes for the context and event type
    final defaultAttributes = _getDefaultCustomAttributes(contextType, finalEventType);
    
    // Merge provided attributes with defaults
    final finalCustomAttributes = <String, dynamic>{
      ...defaultAttributes,
      ...?customAttributes,
    };

    // Validate custom attributes
    final validationResult = CustomAttributeValidator.validateCustomAttributes(
      contextType: contextType,
      eventType: finalEventType,
      customAttributes: finalCustomAttributes,
    );

    if (!validationResult.isValid) {
      throw ArgumentError('Invalid custom attributes: ${validationResult.errors.join(', ')}');
    }

    return TimelineEvent.create(
      id: id,
      contextId: contextId,
      ownerId: ownerId,
      timestamp: timestamp,
      fuzzyDate: fuzzyDate,
      location: location,
      eventType: finalEventType,
      customAttributes: finalCustomAttributes,
      assets: assets,
      title: title,
      description: description,
      participantIds: participantIds,
      privacyLevel: privacyLevel,
    );
  }

  /// Creates a photo event with EXIF data integration
  static TimelineEvent createPhotoEvent({
    required String id,
    required String contextId,
    required String ownerId,
    required ContextType contextType,
    required List<MediaAsset> photoAssets,
    String? title,
    String? description,
    Map<String, dynamic>? customAttributes,
    List<String>? participantIds,
    PrivacyLevel? privacyLevel,
  }) {
    if (photoAssets.isEmpty) {
      throw ArgumentError('Photo event must have at least one photo asset');
    }

    // Extract timestamp and location from the first photo's EXIF data
    final firstPhoto = photoAssets.first;
    final exifData = firstPhoto.exifData;
    
    DateTime timestamp = firstPhoto.createdAt;
    GeoLocation? location;
    
    if (exifData != null) {
      timestamp = exifData.normalizedTimestamp ?? firstPhoto.createdAt;
      location = exifData.gpsLocation;
    }

    return createEvent(
      id: id,
      contextId: contextId,
      ownerId: ownerId,
      contextType: contextType,
      timestamp: timestamp,
      location: location,
      eventType: 'photo',
      customAttributes: customAttributes,
      assets: photoAssets,
      title: title,
      description: description,
      participantIds: participantIds,
      privacyLevel: privacyLevel,
    );
  }

  /// Creates a text-only event (quick entry)
  static TimelineEvent createTextEvent({
    required String id,
    required String contextId,
    required String ownerId,
    required ContextType contextType,
    required DateTime timestamp,
    FuzzyDate? fuzzyDate,
    required String text,
    String? title,
    Map<String, dynamic>? customAttributes,
    List<String>? participantIds,
    PrivacyLevel? privacyLevel,
  }) {
    return createEvent(
      id: id,
      contextId: contextId,
      ownerId: ownerId,
      contextType: contextType,
      timestamp: timestamp,
      fuzzyDate: fuzzyDate,
      eventType: 'text',
      customAttributes: customAttributes,
      assets: [],
      title: title,
      description: text,
      participantIds: participantIds,
      privacyLevel: privacyLevel,
    );
  }

  /// Creates a context-specific milestone event
  static TimelineEvent createMilestoneEvent({
    required String id,
    required String contextId,
    required String ownerId,
    required ContextType contextType,
    required DateTime timestamp,
    required String milestoneTitle,
    String? description,
    Map<String, dynamic>? milestoneAttributes,
    List<MediaAsset>? assets,
    List<String>? participantIds,
    PrivacyLevel? privacyLevel,
  }) {
    final eventType = _getMilestoneEventType(contextType);
    
    return createEvent(
      id: id,
      contextId: contextId,
      ownerId: ownerId,
      contextType: contextType,
      timestamp: timestamp,
      eventType: eventType,
      customAttributes: milestoneAttributes,
      assets: assets,
      title: milestoneTitle,
      description: description,
      participantIds: participantIds,
      privacyLevel: privacyLevel,
    );
  }

  /// Infers event type from assets
  static String _inferEventType(List<MediaAsset>? assets) {
    if (assets == null || assets.isEmpty) {
      return 'text';
    }
    
    final hasPhotos = assets.any((asset) => asset.type == AssetType.photo);
    final hasVideos = assets.any((asset) => asset.type == AssetType.video);
    final hasAudio = assets.any((asset) => asset.type == AssetType.audio);
    
    if (hasPhotos && (hasVideos || hasAudio)) {
      return 'mixed';
    } else if (hasPhotos) {
      return 'photo';
    } else {
      return 'mixed';
    }
  }

  /// Gets default custom attributes for context and event type
  static Map<String, dynamic> _getDefaultCustomAttributes(ContextType contextType, String eventType) {
    switch (contextType) {
      case ContextType.person:
        return _getPersonalEventDefaults(eventType);
      case ContextType.pet:
        return _getPetEventDefaults(eventType);
      case ContextType.project:
        return _getProjectEventDefaults(eventType);
      case ContextType.business:
        return _getBusinessEventDefaults(eventType);
    }
  }

  static Map<String, dynamic> _getPersonalEventDefaults(String eventType) {
    switch (eventType) {
      case 'milestone':
        return {
          'milestone_type': null,
          'significance': 'medium',
        };
      default:
        return {};
    }
  }

  static Map<String, dynamic> _getPetEventDefaults(String eventType) {
    switch (eventType) {
      case 'pet_milestone':
        return {
          'weight_kg': null,
          'vaccine_type': null,
          'vet_visit': false,
          'mood': null,
        };
      default:
        return {};
    }
  }

  static Map<String, dynamic> _getProjectEventDefaults(String eventType) {
    switch (eventType) {
      case 'renovation_progress':
        return {
          'cost': 0.0,
          'contractor': null,
          'room': null,
          'phase': null,
        };
      default:
        return {};
    }
  }

  static Map<String, dynamic> _getBusinessEventDefaults(String eventType) {
    switch (eventType) {
      case 'business_milestone':
        return {
          'milestone': null,
          'budget_spent': 0.0,
          'team_size': null,
        };
      default:
        return {};
    }
  }

  /// Gets the milestone event type for a context
  static String _getMilestoneEventType(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return 'milestone';
      case ContextType.pet:
        return 'pet_milestone';
      case ContextType.project:
        return 'renovation_progress';
      case ContextType.business:
        return 'business_milestone';
    }
  }

  /// Validates that an event type is supported for a context type
  static bool isEventTypeSupported(ContextType contextType, String eventType) {
    final supportedTypes = _getSupportedEventTypes(contextType);
    return supportedTypes.contains(eventType);
  }

  /// Gets supported event types for a context type
  static List<String> _getSupportedEventTypes(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return ['photo', 'text', 'mixed', 'milestone'];
      case ContextType.pet:
        return ['photo', 'text', 'mixed', 'pet_milestone'];
      case ContextType.project:
        return ['photo', 'text', 'mixed', 'renovation_progress'];
      case ContextType.business:
        return ['photo', 'text', 'mixed', 'business_milestone'];
    }
  }

  /// Registers a new event type for extensibility (future use)
  static void registerEventType({
    required ContextType contextType,
    required String eventType,
    required Map<String, dynamic> defaultAttributes,
  }) {
    // In a real implementation, this would store the event type configuration
    // For now, this is a placeholder for future extensibility
    print('Registering event type: $eventType for context: $contextType');
  }
}