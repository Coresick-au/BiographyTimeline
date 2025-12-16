import 'package:json_annotation/json_annotation.dart';

part 'context.g.dart';

@JsonSerializable()
class Context {
  final String id;
  final String ownerId;
  final ContextType type;
  final String name;
  final String? description;
  final Map<String, dynamic> moduleConfiguration;
  final String themeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Context({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.name,
    this.description,
    required this.moduleConfiguration,
    required this.themeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Context.fromJson(Map<String, dynamic> json) => _$ContextFromJson(json);
  Map<String, dynamic> toJson() => _$ContextToJson(this);

  /// Creates a new context with default configuration for the type
  factory Context.create({
    required String id,
    required String ownerId,
    required ContextType type,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    return Context(
      id: id,
      ownerId: ownerId,
      type: type,
      name: name,
      description: description,
      moduleConfiguration: _getDefaultModuleConfiguration(type),
      themeId: _getDefaultThemeId(type),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Public wrapper for getting default module configuration
  static Map<String, dynamic> getDefaultModuleConfiguration(ContextType type) =>
      _getDefaultModuleConfiguration(type);

  /// Gets default module configuration for a context type
  static Map<String, dynamic> _getDefaultModuleConfiguration(ContextType type) {
    switch (type) {
      case ContextType.person:
        return {
          'enableGhostCamera': false,
          'enableBudgetTracking': false,
          'enableProgressComparison': false,
          'enableMilestoneTracking': true,
          'enableLocationTracking': true,
          'enableFaceDetection': true,
        };
      case ContextType.pet:
        return {
          'enableGhostCamera': true,
          'enableBudgetTracking': false,
          'enableProgressComparison': true,
          'enableMilestoneTracking': true,
          'enableWeightTracking': true,
          'enableVetVisitTracking': true,
        };
      case ContextType.project:
        return {
          'enableGhostCamera': true,
          'enableBudgetTracking': true,
          'enableProgressComparison': true,
          'enableMilestoneTracking': true,
          'enableTaskTracking': true,
          'enableTeamTracking': true,
        };
      case ContextType.business:
        return {
          'enableGhostCamera': false,
          'enableBudgetTracking': true,
          'enableProgressComparison': false,
          'enableMilestoneTracking': true,
          'enableRevenueTracking': true,
          'enableTeamTracking': true,
        };
    }
  }

  /// Gets default theme ID for a context type
  static String _getDefaultThemeId(ContextType type) {
    switch (type) {
      case ContextType.person:
        return 'personal_theme';
      case ContextType.pet:
        return 'pet_theme';
      case ContextType.project:
        return 'renovation_theme';
      case ContextType.business:
        return 'business_theme';
    }
  }

  Context copyWith({
    String? id,
    String? ownerId,
    ContextType? type,
    String? name,
    String? description,
    Map<String, dynamic>? moduleConfiguration,
    String? themeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Context(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      moduleConfiguration: moduleConfiguration ?? this.moduleConfiguration,
      themeId: themeId ?? this.themeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Context &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          type == other.type &&
          name == other.name &&
          description == other.description &&
          _mapEquals(moduleConfiguration, other.moduleConfiguration) &&
          themeId == other.themeId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      type.hashCode ^
      name.hashCode ^
      description.hashCode ^
      moduleConfiguration.hashCode ^
      themeId.hashCode ^
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

enum ContextType {
  @JsonValue('person')
  person,
  @JsonValue('pet')
  pet,
  @JsonValue('project')
  project,
  @JsonValue('business')
  business,
}
