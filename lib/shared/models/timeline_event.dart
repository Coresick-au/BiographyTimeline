import 'package:json_annotation/json_annotation.dart';
import 'fuzzy_date.dart';
import 'geo_location.dart';
import 'media_asset.dart';
import 'story.dart';

part 'timeline_event.g.dart';

@JsonSerializable()
class TimelineEvent {
  final String id;
  final List<String> tags;
  final String ownerId;
  final DateTime timestamp;
  final FuzzyDate? fuzzyDate;
  final GeoLocation? location;
  final String eventType;
  final Map<String, dynamic> customAttributes;
  final List<MediaAsset> assets;
  final String? title;
  final String? description;
  final Story? story;
  final List<String> participantIds;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimelineEvent({
    required this.id,
    required this.tags,
    required this.ownerId,
    required this.timestamp,
    this.fuzzyDate,
    this.location,
    required this.eventType,
    required this.customAttributes,
    required this.assets,
    this.title,
    this.description,
    this.story,
    required this.participantIds,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
  Map<String, dynamic> toJson() => _$TimelineEventToJson(this);

  /// Creates a timeline event with default attributes
  factory TimelineEvent.create({
    required String id,
    List<String>? tags,
    required String ownerId,
    required DateTime timestamp,
    FuzzyDate? fuzzyDate,
    GeoLocation? location,
    required String eventType,
    Map<String, dynamic>? customAttributes,
    List<MediaAsset>? assets,
    String? title,
    String? description,
    List<String>? participantIds,
    bool? isPrivate,
  }) {
    final now = DateTime.now();
    return TimelineEvent(
      id: id,
      tags: tags ?? ['Family'],
      ownerId: ownerId,
      timestamp: timestamp,
      fuzzyDate: fuzzyDate,
      location: location,
      eventType: eventType,
      customAttributes: customAttributes ?? _getDefaultCustomAttributes(eventType),
      assets: assets ?? [],
      title: title,
      description: description,
      story: null,
      participantIds: participantIds ?? [],
      isPrivate: isPrivate ?? true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Gets default custom attributes for an event type
  static Map<String, dynamic> _getDefaultCustomAttributes(String eventType) {
    switch (eventType) {
      case 'renovation_progress':
        return {
          'cost': 0.0,
          'contractor': null,
          'room': null,
          'phase': null,
        };
      case 'pet_milestone':
        return {
          'weight_kg': null,
          'vaccine_type': null,
          'vet_visit': false,
          'mood': null,
        };
      case 'business_milestone':
        return {
          'milestone': null,
          'budget_spent': 0.0,
          'team_size': null,
        };
      case 'photo':
      case 'text':
      case 'mixed':
      default:
        return {};
    }
  }

  TimelineEvent copyWith({
    String? id,
    List<String>? tags,
    String? ownerId,
    DateTime? timestamp,
    FuzzyDate? fuzzyDate,
    GeoLocation? location,
    String? eventType,
    Map<String, dynamic>? customAttributes,
    List<MediaAsset>? assets,
    String? title,
    String? description,
    Story? story,
    List<String>? participantIds,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      tags: tags ?? this.tags,
      ownerId: ownerId ?? this.ownerId,
      timestamp: timestamp ?? this.timestamp,
      fuzzyDate: fuzzyDate ?? this.fuzzyDate,
      location: location ?? this.location,
      eventType: eventType ?? this.eventType,
      customAttributes: customAttributes ?? this.customAttributes,
      assets: assets ?? this.assets,
      title: title ?? this.title,
      description: description ?? this.description,
      story: story ?? this.story,
      participantIds: participantIds ?? this.participantIds,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _listEquals(tags, other.tags) &&
          ownerId == other.ownerId &&
          timestamp == other.timestamp &&
          fuzzyDate == other.fuzzyDate &&
          location == other.location &&
          eventType == other.eventType &&
          _mapEquals(customAttributes, other.customAttributes) &&
          _listEquals(assets, other.assets) &&
          title == other.title &&
          description == other.description &&
          story == other.story &&
          _listEquals(participantIds, other.participantIds) &&
          isPrivate == other.isPrivate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      tags.hashCode ^
      ownerId.hashCode ^
      timestamp.hashCode ^
      fuzzyDate.hashCode ^
      location.hashCode ^
      eventType.hashCode ^
      customAttributes.hashCode ^
      assets.hashCode ^
      title.hashCode ^
      description.hashCode ^
      story.hashCode ^
      participantIds.hashCode ^
      isPrivate.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}