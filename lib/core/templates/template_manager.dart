import 'package:flutter/material.dart';
import 'template_registry.dart';
import 'template_definition.dart';
import 'enhanced_template_renderer.dart';
import '../../shared/models/context.dart';
import '../../shared/models/timeline_event.dart';
import '../../shared/models/timeline_theme.dart';

/// High-level service for managing templates and template rendering
class TemplateManager {
  static final TemplateManager _instance = TemplateManager._internal();
  factory TemplateManager() => _instance;
  TemplateManager._internal();

  final TemplateRegistry _registry = TemplateRegistry();
  bool _isInitialized = false;

  /// Initialize the template system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _registry.initialize();
    await EnhancedTemplateRenderer.initialize();
    _isInitialized = true;
  }

  /// Get all available templates
  List<TemplateDefinition> getAllTemplates() {
    _ensureInitialized();
    return _registry.getAllTemplates();
  }

  /// Get templates for a specific context type
  List<TemplateDefinition> getTemplatesForContext(ContextType contextType) {
    _ensureInitialized();
    return _registry.getTemplatesForContext(contextType);
  }

  /// Get templates that support a specific event type
  List<TemplateDefinition> getTemplatesForEventType(String eventType) {
    _ensureInitialized();
    return _registry.getTemplatesForEventType(eventType);
  }

  /// Get a specific template by ID
  TemplateDefinition? getTemplateById(String id) {
    _ensureInitialized();
    return _registry.getTemplateById(id);
  }

  /// Search templates by query
  List<TemplateDefinition> searchTemplates(String query) {
    _ensureInitialized();
    return _registry.searchTemplates(query);
  }

  /// Register a new template
  void registerTemplate(TemplateDefinition template) {
    _ensureInitialized();
    _registry.registerTemplate(template);
  }

  /// Unregister a template
  void unregisterTemplate(String templateId) {
    _ensureInitialized();
    _registry.unregisterTemplate(templateId);
  }

  /// Create an event card widget using the best available template
  Widget createEventCard({
    required TimelineEvent event,
    required Context context,
    required TimelineTheme theme,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    Map<String, VoidCallback>? customActions,
  }) {
    _ensureInitialized();
    return EnhancedTemplateRenderer.createEventCard(
      event: event,
      context: context,
      theme: theme,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      customActions: customActions,
    );
  }

  /// Create an attribute editor widget using the appropriate template
  Widget createAttributeEditor({
    required TimelineEvent event,
    required Context context,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) {
    _ensureInitialized();
    return EnhancedTemplateRenderer.createAttributeEditor(
      event: event,
      context: context,
      onAttributesChanged: onAttributesChanged,
    );
  }

  /// Get available event types for a context
  List<String> getAvailableEventTypes(ContextType contextType) {
    _ensureInitialized();
    return EnhancedTemplateRenderer.getAvailableEventTypes(contextType);
  }

  /// Get display name for an event type
  String getEventTypeDisplayName(String eventType) {
    _ensureInitialized();
    return EnhancedTemplateRenderer.getEventTypeDisplayName(eventType);
  }

  /// Get icon for an event type
  IconData getEventTypeIcon(String eventType) {
    _ensureInitialized();
    return EnhancedTemplateRenderer.getEventTypeIcon(eventType);
  }

  /// Validate event data against a template
  TemplateValidationResult validateEventData({
    required TimelineEvent event,
    required TemplateDefinition template,
  }) {
    _ensureInitialized();
    
    final errors = <String>[];
    final warnings = <String>[];

    // Check if template supports this event type
    if (!template.supportsEventType(event.eventType)) {
      errors.add('Template ${template.name} does not support event type ${event.eventType}');
      return TemplateValidationResult(errors: errors, warnings: warnings);
    }

    // Validate required fields
    for (final field in template.fields) {
      final value = event.customAttributes[field.key];
      
      if (field.required && (value == null || value.toString().isEmpty)) {
        errors.add('Required field "${field.label}" is missing');
        continue;
      }

      if (value != null) {
        _validateFieldValue(field, value, errors, warnings);
      }
    }

    return TemplateValidationResult(errors: errors, warnings: warnings);
  }

  /// Get default attributes for an event type and context
  Map<String, dynamic> getDefaultAttributes({
    required String eventType,
    required ContextType contextType,
  }) {
    _ensureInitialized();
    
    final templates = getTemplatesForContext(contextType);
    final relevantTemplate = templates.firstWhere(
      (template) => template.supportsEventType(eventType),
      orElse: () => throw Exception('No template found for event type $eventType in context $contextType'),
    );

    final defaults = <String, dynamic>{};
    
    for (final field in relevantTemplate.fields) {
      if (field.defaultValue != null) {
        defaults[field.key] = field.defaultValue;
      }
    }

    return defaults;
  }

  /// Create a template from JSON configuration
  TemplateDefinition createTemplateFromJson(Map<String, dynamic> json) {
    _ensureInitialized();
    return TemplateDefinition.fromJson(json);
  }

  /// Export a template to JSON configuration
  Map<String, dynamic> exportTemplateToJson(TemplateDefinition template) {
    _ensureInitialized();
    return template.toJson();
  }

  /// Get template statistics
  TemplateStatistics getStatistics() {
    _ensureInitialized();
    
    final allTemplates = getAllTemplates();
    final contextCounts = <ContextType, int>{};
    
    for (final template in allTemplates) {
      contextCounts[template.contextType] = 
          (contextCounts[template.contextType] ?? 0) + 1;
    }

    return TemplateStatistics(
      totalTemplates: allTemplates.length,
      contextCounts: contextCounts,
      experimentalTemplates: allTemplates.where((t) => t.isExperimental).length,
    );
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('TemplateManager must be initialized before use. Call initialize() first.');
    }
  }

  void _validateFieldValue(
    TemplateField field,
    dynamic value,
    List<String> errors,
    List<String> warnings,
  ) {
    switch (field.type) {
      case TemplateFieldType.number:
        if (value is! num) {
          errors.add('Field "${field.label}" must be a number');
        } else {
          final validation = field.validation;
          if (validation['min'] != null && value < validation['min']) {
            errors.add('Field "${field.label}" must be at least ${validation['min']}');
          }
          if (validation['max'] != null && value > validation['max']) {
            errors.add('Field "${field.label}" must be at most ${validation['max']}');
          }
        }
        break;
      
      case TemplateFieldType.text:
        if (value is! String) {
          errors.add('Field "${field.label}" must be text');
        } else {
          final validation = field.validation;
          if (validation['maxLength'] != null && value.length > validation['maxLength']) {
            errors.add('Field "${field.label}" exceeds maximum length of ${validation['maxLength']}');
          }
          if (validation['minLength'] != null && value.length < validation['minLength']) {
            errors.add('Field "${field.label}" must be at least ${validation['minLength']} characters');
          }
        }
        break;
      
      case TemplateFieldType.select:
        final options = field.display['options'] as List<String>? ?? [];
        if (!options.contains(value)) {
          errors.add('Field "${field.label}" must be one of: ${options.join(', ')}');
        }
        break;
      
      case TemplateFieldType.boolean:
        if (value is! bool) {
          errors.add('Field "${field.label}" must be true or false');
        }
        break;
      
      case TemplateFieldType.date:
        if (value is! String && value is! DateTime) {
          errors.add('Field "${field.label}" must be a valid date');
        }
        break;
      
      case TemplateFieldType.multiselect:
        if (value is! List) {
          errors.add('Field "${field.label}" must be a list of values');
        } else {
          final options = field.display['options'] as List<String>? ?? [];
          for (final item in value) {
            if (!options.contains(item)) {
              errors.add('Field "${field.label}" contains invalid option: $item');
            }
          }
        }
        break;
      
      case TemplateFieldType.location:
        // Location field validation
        if (value is! String && value is! Map) {
          errors.add('Field "${field.label}" must be a location');
        }
        break;
      
      case TemplateFieldType.media:
        // Media field validation
        if (value is! String && value is! List) {
          errors.add('Field "${field.label}" must be media reference');
        }
        break;
      
      case TemplateFieldType.richText:
        // Rich text field validation
        if (value is! String) {
          errors.add('Field "${field.label}" must be rich text');
        }
        break;
    }
  }
}

/// Result of template validation
class TemplateValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const TemplateValidationResult({
    required this.errors,
    required this.warnings,
  });

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Template statistics
class TemplateStatistics {
  final int totalTemplates;
  final Map<ContextType, int> contextCounts;
  final int experimentalTemplates;

  const TemplateStatistics({
    required this.totalTemplates,
    required this.contextCounts,
    required this.experimentalTemplates,
  });
}

/// Service for managing template lifecycle and operations
class TemplateService {
  final TemplateManager _manager = TemplateManager();

  /// Initialize the service
  Future<void> initialize() async {
    await _manager.initialize();
  }

  /// Create a new custom template
  Future<TemplateDefinition> createCustomTemplate({
    required String name,
    required String description,
    required ContextType contextType,
    required List<String> supportedEventTypes,
    required List<TemplateField> fields,
    String? author,
  }) async {
    final template = TemplateDefinition(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      contextType: contextType,
      supportedEventTypes: supportedEventTypes,
      metadata: TemplateMetadata(
        version: '1.0.0',
        author: author ?? 'User',
        createdAt: DateTime.now(),
        tags: ['custom'],
        configuration: {},
      ),
      fields: fields,
      actions: [
        const TemplateAction(
          id: 'edit',
          label: 'Edit',
          description: 'Edit this event',
          icon: 'edit',
          type: TemplateActionType.edit,
          configuration: {},
        ),
        const TemplateAction(
          id: 'delete',
          label: 'Delete',
          description: 'Delete this event',
          icon: 'delete',
          type: TemplateActionType.delete,
          configuration: {},
        ),
      ],
      layout: const TemplateLayout(
        type: 'card',
        configuration: {'style': 'custom'},
        sections: [
          TemplateSection(
            id: 'header',
            type: 'event_header',
            title: 'Event Details',
            configuration: {'showDate': true},
            fieldKeys: [],
            order: 1,
          ),
          TemplateSection(
            id: 'content',
            type: 'event_content',
            title: 'Content',
            configuration: {'showDescription': true},
            fieldKeys: [],
            order: 2,
          ),
          TemplateSection(
            id: 'attributes',
            type: 'custom_attributes',
            title: 'Details',
            configuration: {'showAll': true},
            fieldKeys: [],
            order: 3,
          ),
        ],
      ),
    );

    _manager.registerTemplate(template);
    
    // TODO: Save to persistent storage
    await _saveCustomTemplate(template);
    
    return template;
  }

  /// Update an existing template
  Future<void> updateTemplate(TemplateDefinition template) async {
    _manager.registerTemplate(template); // This will overwrite existing
    
    // TODO: Update in persistent storage
    await _updateCustomTemplate(template);
  }

  /// Delete a custom template
  Future<void> deleteCustomTemplate(String templateId) async {
    _manager.unregisterTemplate(templateId);
    
    // TODO: Remove from persistent storage
    await _deleteCustomTemplate(templateId);
  }

  /// Get all custom templates
  List<TemplateDefinition> getCustomTemplates() {
    return _manager.getAllTemplates()
        .where((template) => template.metadata.tags.contains('custom'))
        .toList();
  }

  Future<void> _saveCustomTemplate(TemplateDefinition template) async {
    // TODO: Implement persistent storage
  }

  Future<void> _updateCustomTemplate(TemplateDefinition template) async {
    // TODO: Implement persistent storage
  }

  Future<void> _deleteCustomTemplate(String templateId) async {
    // TODO: Implement persistent storage
  }
}
