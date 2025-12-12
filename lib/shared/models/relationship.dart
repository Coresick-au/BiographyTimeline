import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'relationship.g.dart';

@JsonSerializable()
class Relationship {
  final String id;
  final String userAId;
  final String userBId;
  final RelationshipType type;
  final List<String> sharedContextIds;
  final DateTime startDate;
  final DateTime? endDate;
  final RelationshipStatus status;
  final Map<String, PermissionScope> contextPermissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Relationship({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.type,
    required this.sharedContextIds,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.contextPermissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) =>
      _$RelationshipFromJson(json);
  Map<String, dynamic> toJson() => _$RelationshipToJson(this);

  /// Creates a new relationship between two users
  factory Relationship.create({
    required String id,
    required String userAId,
    required String userBId,
    required RelationshipType type,
    required List<String> sharedContextIds,
    required Map<String, PermissionScope> contextPermissions,
  }) {
    final now = DateTime.now();
    return Relationship(
      id: id,
      userAId: userAId,
      userBId: userBId,
      type: type,
      sharedContextIds: sharedContextIds,
      startDate: now,
      status: RelationshipStatus.active,
      contextPermissions: contextPermissions,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Checks if the relationship is currently active
  bool get isActive {
    return status == RelationshipStatus.active && 
           (endDate == null || endDate!.isAfter(DateTime.now()));
  }

  /// Gets the other user ID in the relationship
  String getOtherUserId(String currentUserId) {
    if (currentUserId == userAId) return userBId;
    if (currentUserId == userBId) return userAId;
    throw ArgumentError('User $currentUserId is not part of this relationship');
  }

  /// Checks if a user is part of this relationship
  bool includesUser(String userId) {
    return userId == userAId || userId == userBId;
  }

  /// Ends the relationship
  Relationship end({DateTime? endDate}) {
    return copyWith(
      endDate: endDate ?? DateTime.now(),
      status: RelationshipStatus.ended,
      updatedAt: DateTime.now(),
    );
  }

  /// Archives the relationship
  Relationship archive() {
    return copyWith(
      status: RelationshipStatus.archived,
      updatedAt: DateTime.now(),
    );
  }

  /// Gets permission scope for a specific context
  PermissionScope? getContextPermissions(String contextId) {
    return contextPermissions[contextId];
  }

  /// Checks if a context is shared in this relationship
  bool isContextShared(String contextId) {
    return sharedContextIds.contains(contextId);
  }

  Relationship copyWith({
    String? id,
    String? userAId,
    String? userBId,
    RelationshipType? type,
    List<String>? sharedContextIds,
    DateTime? startDate,
    DateTime? endDate,
    RelationshipStatus? status,
    Map<String, PermissionScope>? contextPermissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Relationship(
      id: id ?? this.id,
      userAId: userAId ?? this.userAId,
      userBId: userBId ?? this.userBId,
      type: type ?? this.type,
      sharedContextIds: sharedContextIds ?? this.sharedContextIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      contextPermissions: contextPermissions ?? this.contextPermissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Relationship &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userAId == other.userAId &&
          userBId == other.userBId &&
          type == other.type &&
          listEquals(sharedContextIds, other.sharedContextIds) &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          status == other.status &&
          _mapEquals(contextPermissions, other.contextPermissions) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userAId.hashCode ^
      userBId.hashCode ^
      type.hashCode ^
      sharedContextIds.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      status.hashCode ^
      contextPermissions.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}

@JsonSerializable()
class PermissionScope {
  final bool canViewTimeline;
  final bool canEditSharedEvents;
  final bool canViewPrivateEvents;
  final DateTime? startDateScope;
  final DateTime? endDateScope;
  final List<String>? allowedContentTypes;

  const PermissionScope({
    required this.canViewTimeline,
    required this.canEditSharedEvents,
    required this.canViewPrivateEvents,
    this.startDateScope,
    this.endDateScope,
    this.allowedContentTypes,
  });

  factory PermissionScope.fromJson(Map<String, dynamic> json) =>
      _$PermissionScopeFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionScopeToJson(this);

  /// Creates basic view-only permissions
  factory PermissionScope.viewOnly() {
    return const PermissionScope(
      canViewTimeline: true,
      canEditSharedEvents: false,
      canViewPrivateEvents: false,
    );
  }

  /// Creates full collaboration permissions
  factory PermissionScope.fullCollaboration() {
    return const PermissionScope(
      canViewTimeline: true,
      canEditSharedEvents: true,
      canViewPrivateEvents: false,
    );
  }

  /// Creates intimate partner permissions
  factory PermissionScope.intimate() {
    return const PermissionScope(
      canViewTimeline: true,
      canEditSharedEvents: true,
      canViewPrivateEvents: true,
    );
  }

  /// Checks if the permission scope allows access to a specific date
  bool allowsDateAccess(DateTime date) {
    if (startDateScope != null && date.isBefore(startDateScope!)) {
      return false;
    }
    if (endDateScope != null && date.isAfter(endDateScope!)) {
      return false;
    }
    return true;
  }

  PermissionScope copyWith({
    bool? canViewTimeline,
    bool? canEditSharedEvents,
    bool? canViewPrivateEvents,
    DateTime? startDateScope,
    DateTime? endDateScope,
    List<String>? allowedContentTypes,
  }) {
    return PermissionScope(
      canViewTimeline: canViewTimeline ?? this.canViewTimeline,
      canEditSharedEvents: canEditSharedEvents ?? this.canEditSharedEvents,
      canViewPrivateEvents: canViewPrivateEvents ?? this.canViewPrivateEvents,
      startDateScope: startDateScope ?? this.startDateScope,
      endDateScope: endDateScope ?? this.endDateScope,
      allowedContentTypes: allowedContentTypes ?? this.allowedContentTypes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionScope &&
          runtimeType == other.runtimeType &&
          canViewTimeline == other.canViewTimeline &&
          canEditSharedEvents == other.canEditSharedEvents &&
          canViewPrivateEvents == other.canViewPrivateEvents &&
          startDateScope == other.startDateScope &&
          endDateScope == other.endDateScope &&
          listEquals(allowedContentTypes, other.allowedContentTypes);

  @override
  int get hashCode =>
      canViewTimeline.hashCode ^
      canEditSharedEvents.hashCode ^
      canViewPrivateEvents.hashCode ^
      startDateScope.hashCode ^
      endDateScope.hashCode ^
      allowedContentTypes.hashCode;


}

enum RelationshipType {
  @JsonValue('friend')
  friend,
  @JsonValue('family')
  family,
  @JsonValue('partner')
  partner,
  @JsonValue('colleague')
  colleague,
}

enum RelationshipStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('ended')
  ended,
  @JsonValue('archived')
  archived,
}