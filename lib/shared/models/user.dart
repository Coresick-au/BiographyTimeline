import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final PrivacySettings privacySettings;
  final List<String> contextIds;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.privacySettings,
    required this.contextIds,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? profileImageUrl,
    PrivacySettings? privacySettings,
    List<String>? contextIds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      privacySettings: privacySettings ?? this.privacySettings,
      contextIds: contextIds ?? this.contextIds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          profileImageUrl == other.profileImageUrl &&
          privacySettings == other.privacySettings &&
          _listEquals(contextIds, other.contextIds) &&
          createdAt == other.createdAt &&
          lastActiveAt == other.lastActiveAt;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      profileImageUrl.hashCode ^
      privacySettings.hashCode ^
      contextIds.hashCode ^
      createdAt.hashCode ^
      lastActiveAt.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

@JsonSerializable()
class PrivacySettings {
  final bool allowTimelineMerging;
  final bool allowLocationSharing;
  final bool allowFaceDetection;
  final bool defaultEventIsPrivate;

  const PrivacySettings({
    required this.allowTimelineMerging,
    required this.allowLocationSharing,
    required this.allowFaceDetection,
    required this.defaultEventIsPrivate,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  PrivacySettings copyWith({
    bool? allowTimelineMerging,
    bool? allowLocationSharing,
    bool? allowFaceDetection,
    bool? defaultEventIsPrivate,
  }) {
    return PrivacySettings(
      allowTimelineMerging: allowTimelineMerging ?? this.allowTimelineMerging,
      allowLocationSharing: allowLocationSharing ?? this.allowLocationSharing,
      allowFaceDetection: allowFaceDetection ?? this.allowFaceDetection,
      defaultEventIsPrivate: defaultEventIsPrivate ?? this.defaultEventIsPrivate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacySettings &&
          runtimeType == other.runtimeType &&
          allowTimelineMerging == other.allowTimelineMerging &&
          allowLocationSharing == other.allowLocationSharing &&
          allowFaceDetection == other.allowFaceDetection &&
          defaultEventIsPrivate == other.defaultEventIsPrivate;

  @override
  int get hashCode =>
      allowTimelineMerging.hashCode ^
      allowLocationSharing.hashCode ^
      allowFaceDetection.hashCode ^
      defaultEventIsPrivate.hashCode;
}

/// Legacy privacy level enum - kept temporarily for migration
/// Will be removed once all references are updated
enum PrivacyLevel {
  @JsonValue('private')
  private,
  @JsonValue('shared')
  shared,
  @JsonValue('public')
  public,
}