import 'package:json_annotation/json_annotation.dart';
import '../../shared/models/context.dart';
import '../../shared/models/timeline_theme.dart';

part 'template_definition.g.dart';

/// Defines a template for rendering timeline events in specific contexts
@JsonSerializable()
class TemplateDefinition {
  final String id;
  final String name;
  final String description;
  final ContextType contextType;
  final List<String> supportedEventTypes;
  final TemplateMetadata metadata;
  final List<TemplateField> fields;
  final List<TemplateAction> actions;
  final TemplateLayout layout;

  const TemplateDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.contextType,
    required this.supportedEventTypes,
    required this.metadata,
    required this.fields,
    required this.actions,
    required this.layout,
  });

  factory TemplateDefinition.fromJson(Map<String, dynamic> json) =>
      _$TemplateDefinitionFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateDefinitionToJson(this);

  /// Checks if this template supports the given event type
  bool supportsEventType(String eventType) {
    return supportedEventTypes.contains(eventType);
  }

  /// Gets the display priority for sorting templates
  int get displayPriority => metadata.displayPriority;

  /// Checks if this template is experimental
  bool get isExperimental => metadata.isExperimental;
}

/// Metadata about a template
@JsonSerializable()
class TemplateMetadata {
  final String version;
  final String author;
  final DateTime createdAt;
  final DateTime? lastModified;
  final List<String> tags;
  final int displayPriority;
  final bool isExperimental;
  final Map<String, dynamic> configuration;

  const TemplateMetadata({
    required this.version,
    required this.author,
    required this.createdAt,
    this.lastModified,
    required this.tags,
    this.displayPriority = 0,
    this.isExperimental = false,
    required this.configuration,
  });

  factory TemplateMetadata.fromJson(Map<String, dynamic> json) =>
      _$TemplateMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateMetadataToJson(this);

  TemplateMetadata copyWith({
    String? version,
    String? author,
    DateTime? createdAt,
    DateTime? lastModified,
    List<String>? tags,
    int? displayPriority,
    bool? isExperimental,
    Map<String, dynamic>? configuration,
  }) {
    return TemplateMetadata(
      version: version ?? this.version,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      tags: tags ?? this.tags,
      displayPriority: displayPriority ?? this.displayPriority,
      isExperimental: isExperimental ?? this.isExperimental,
      configuration: configuration ?? this.configuration,
    );
  }
}

/// Defines a field in a template
@JsonSerializable()
class TemplateField {
  final String key;
  final String label;
  final String description;
  final TemplateFieldType type;
  final bool required;
  final dynamic defaultValue;
  final Map<String, dynamic> validation;
  final Map<String, dynamic> display;

  const TemplateField({
    required this.key,
    required this.label,
    required this.description,
    required this.type,
    this.required = false,
    this.defaultValue,
    required this.validation,
    required this.display,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) =>
      _$TemplateFieldFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateFieldToJson(this);
}

/// Types of template fields
enum TemplateFieldType {
  @JsonValue('text')
  text,
  @JsonValue('number')
  number,
  @JsonValue('boolean')
  boolean,
  @JsonValue('date')
  date,
  @JsonValue('select')
  select,
  @JsonValue('multiselect')
  multiselect,
  @JsonValue('location')
  location,
  @JsonValue('media')
  media,
  @JsonValue('rich_text')
  richText,
}

/// Defines an action available in a template
@JsonSerializable()
class TemplateAction {
  final String id;
  final String label;
  final String description;
  final String icon;
  final TemplateActionType type;
  final Map<String, dynamic> configuration;

  const TemplateAction({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.type,
    required this.configuration,
  });

  factory TemplateAction.fromJson(Map<String, dynamic> json) =>
      _$TemplateActionFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateActionToJson(this);
}

/// Types of template actions
enum TemplateActionType {
  @JsonValue('edit')
  edit,
  @JsonValue('delete')
  delete,
  @JsonValue('share')
  share,
  @JsonValue('duplicate')
  duplicate,
  @JsonValue('custom')
  custom,
}

/// Defines the layout structure of a template
@JsonSerializable()
class TemplateLayout {
  final String type;
  final Map<String, dynamic> configuration;
  final List<TemplateSection> sections;

  const TemplateLayout({
    required this.type,
    required this.configuration,
    required this.sections,
  });

  factory TemplateLayout.fromJson(Map<String, dynamic> json) =>
      _$TemplateLayoutFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateLayoutToJson(this);
}

/// Defines a section in a template layout
@JsonSerializable()
class TemplateSection {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> configuration;
  final List<String> fieldKeys;
  final int order;

  const TemplateSection({
    required this.id,
    required this.type,
    required this.title,
    required this.configuration,
    required this.fieldKeys,
    required this.order,
  });

  factory TemplateSection.fromJson(Map<String, dynamic> json) =>
      _$TemplateSectionFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateSectionToJson(this);
}
