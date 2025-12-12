import 'dart:convert';
import 'package:flutter/services.dart';
import 'template_definition.dart';
import '../../shared/models/context.dart';

/// Registry for managing template definitions
class TemplateRegistry {
  static final TemplateRegistry _instance = TemplateRegistry._internal();
  factory TemplateRegistry() => _instance;
  TemplateRegistry._internal();

  final Map<String, TemplateDefinition> _templates = {};
  final Map<ContextType, List<TemplateDefinition>> _templatesByContext = {};

  /// Initialize the registry with built-in templates
  Future<void> initialize() async {
    await _loadBuiltinTemplates();
    await _loadCustomTemplates();
  }

  /// Get all templates
  List<TemplateDefinition> getAllTemplates() {
    return _templates.values.toList();
  }

  /// Get templates for a specific context type
  List<TemplateDefinition> getTemplatesForContext(ContextType contextType) {
    return _templatesByContext[contextType] ?? [];
  }

  /// Get a specific template by ID
  TemplateDefinition? getTemplateById(String id) {
    return _templates[id];
  }

  /// Get templates that support a specific event type
  List<TemplateDefinition> getTemplatesForEventType(String eventType) {
    return _templates.values
        .where((template) => template.supportsEventType(eventType))
        .toList();
  }

  /// Register a new template
  void registerTemplate(TemplateDefinition template) {
    _templates[template.id] = template;
    
    // Update context-based index
    final contextList = _templatesByContext[template.contextType] ?? [];
    contextList.add(template);
    contextList.sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
    _templatesByContext[template.contextType] = contextList;
  }

  /// Unregister a template
  void unregisterTemplate(String templateId) {
    final template = _templates.remove(templateId);
    if (template != null) {
      _templatesByContext[template.contextType]?.remove(template);
    }
  }

  /// Search templates by name or description
  List<TemplateDefinition> searchTemplates(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _templates.values.where((template) =>
        template.name.toLowerCase().contains(lowercaseQuery) ||
        template.description.toLowerCase().contains(lowercaseQuery) ||
        template.metadata.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Load built-in templates from assets
  Future<void> _loadBuiltinTemplates() async {
    final builtinTemplates = [
      _createPersonalEventTemplate(),
      _createPetEventTemplate(),
      _createProjectEventTemplate(),
      _createBusinessEventTemplate(),
    ];

    for (final template in builtinTemplates) {
      registerTemplate(template);
    }
  }

  /// Load custom templates from storage (placeholder for future implementation)
  Future<void> _loadCustomTemplates() async {
    // TODO: Implement loading from local storage or remote
  }

  /// Create personal event template
  TemplateDefinition _createPersonalEventTemplate() {
    return TemplateDefinition(
      id: 'personal_event',
      name: 'Personal Event',
      description: 'Template for personal life events and milestones',
      contextType: ContextType.person,
      supportedEventTypes: ['photo', 'text', 'milestone', 'travel', 'celebration'],
      metadata: TemplateMetadata(
        version: '1.0.0',
        author: 'Timeline Biography App',
        createdAt: DateTime.now(),
        tags: ['personal', 'life', 'milestone'],
        displayPriority: 1,
        configuration: {},
      ),
      fields: [
        const TemplateField(
          key: 'milestone_type',
          label: 'Milestone Type',
          description: 'Type of personal milestone',
          type: TemplateFieldType.select,
          validation: {'required': false},
          display: {
            'options': ['Birthday', 'Graduation', 'Achievement', 'Anniversary', 'Other']
          },
        ),
        const TemplateField(
          key: 'destination',
          label: 'Destination',
          description: 'Travel destination',
          type: TemplateFieldType.text,
          validation: {'maxLength': 100},
          display: {'placeholder': 'Where did you go?'},
        ),
        const TemplateField(
          key: 'celebration_type',
          label: 'Celebration Type',
          description: 'Type of celebration',
          type: TemplateFieldType.text,
          validation: {'maxLength': 50},
          display: {'placeholder': 'Birthday party, wedding, etc.'},
        ),
      ],
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
        const TemplateAction(
          id: 'share',
          label: 'Share',
          description: 'Share this event',
          icon: 'share',
          type: TemplateActionType.share,
          configuration: {},
        ),
      ],
      layout: const TemplateLayout(
        type: 'card',
        configuration: {'style': 'modern', 'compact': false},
        sections: [
          TemplateSection(
            id: 'header',
            type: 'event_header',
            title: 'Event Details',
            configuration: {'showDate': true, 'showLocation': true},
            fieldKeys: [],
            order: 1,
          ),
          TemplateSection(
            id: 'content',
            type: 'event_content',
            title: 'Content',
            configuration: {'showDescription': true, 'showMedia': true},
            fieldKeys: [],
            order: 2,
          ),
          TemplateSection(
            id: 'attributes',
            type: 'custom_attributes',
            title: 'Details',
            configuration: {'showAll': false},
            fieldKeys: ['milestone_type', 'destination', 'celebration_type'],
            order: 3,
          ),
        ],
      ),
    );
  }

  /// Create pet event template
  TemplateDefinition _createPetEventTemplate() {
    return TemplateDefinition(
      id: 'pet_event',
      name: 'Pet Event',
      description: 'Template for pet-related events and milestones',
      contextType: ContextType.pet,
      supportedEventTypes: ['photo', 'text', 'pet_milestone', 'vet_visit', 'weight_check', 'training'],
      metadata: TemplateMetadata(
        version: '1.0.0',
        author: 'Timeline Biography App',
        createdAt: DateTime.now(),
        tags: ['pet', 'animal', 'health', 'training'],
        displayPriority: 2,
        configuration: {},
      ),
      fields: [
        const TemplateField(
          key: 'weight_kg',
          label: 'Weight (kg)',
          description: 'Pet weight in kilograms',
          type: TemplateFieldType.number,
          validation: {'min': 0.1, 'max': 200.0},
          display: {'step': 0.1, 'suffix': 'kg'},
        ),
        const TemplateField(
          key: 'vet_name',
          label: 'Veterinarian',
          description: 'Name of the veterinarian',
          type: TemplateFieldType.text,
          validation: {'maxLength': 100},
          display: {'placeholder': 'Dr. Smith'},
        ),
        const TemplateField(
          key: 'visit_reason',
          label: 'Visit Reason',
          description: 'Reason for vet visit',
          type: TemplateFieldType.select,
          validation: {'required': false},
          display: {
            'options': ['Checkup', 'Vaccination', 'Illness', 'Injury', 'Surgery', 'Other']
          },
        ),
        const TemplateField(
          key: 'mood',
          label: 'Pet Mood',
          description: 'How the pet is feeling',
          type: TemplateFieldType.select,
          validation: {'required': false},
          display: {
            'options': ['Happy', 'Playful', 'Sleepy', 'Anxious', 'Excited', 'Calm']
          },
        ),
      ],
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
        configuration: {'style': 'playful', 'showPetAvatar': true},
        sections: [
          TemplateSection(
            id: 'header',
            type: 'event_header',
            title: 'Pet Event',
            configuration: {'showDate': true, 'showPetIcon': true},
            fieldKeys: [],
            order: 1,
          ),
          TemplateSection(
            id: 'health',
            type: 'health_info',
            title: 'Health Information',
            configuration: {'showWeight': true, 'showVetInfo': true},
            fieldKeys: ['weight_kg', 'vet_name', 'visit_reason'],
            order: 2,
          ),
          TemplateSection(
            id: 'behavior',
            type: 'behavior_info',
            title: 'Behavior',
            configuration: {'showMood': true},
            fieldKeys: ['mood'],
            order: 3,
          ),
        ],
      ),
    );
  }

  /// Create project event template
  TemplateDefinition _createProjectEventTemplate() {
    return TemplateDefinition(
      id: 'project_event',
      name: 'Project Event',
      description: 'Template for project-related events and progress updates',
      contextType: ContextType.project,
      supportedEventTypes: ['photo', 'text', 'renovation_progress', 'milestone', 'budget_update', 'completion'],
      metadata: TemplateMetadata(
        version: '1.0.0',
        author: 'Timeline Biography App',
        createdAt: DateTime.now(),
        tags: ['project', 'renovation', 'construction', 'budget'],
        displayPriority: 3,
        configuration: {},
      ),
      fields: [
        const TemplateField(
          key: 'room',
          label: 'Room/Area',
          description: 'Area of the project',
          type: TemplateFieldType.text,
          validation: {'maxLength': 50},
          display: {'placeholder': 'Kitchen, Bathroom, Living Room'},
        ),
        const TemplateField(
          key: 'phase',
          label: 'Project Phase',
          description: 'Current phase of the project',
          type: TemplateFieldType.select,
          validation: {'required': false},
          display: {
            'options': ['Planning', 'Demolition', 'Framing', 'Electrical', 'Plumbing', 'Finishing']
          },
        ),
        const TemplateField(
          key: 'cost',
          label: 'Cost',
          description: 'Cost incurred for this update',
          type: TemplateFieldType.number,
          validation: {'min': 0},
          display: {'prefix': '\$', 'step': 0.01},
        ),
        const TemplateField(
          key: 'contractor',
          label: 'Contractor/Vendor',
          description: 'Who performed the work',
          type: TemplateFieldType.text,
          validation: {'maxLength': 100},
          display: {'placeholder': 'Company or individual name'},
        ),
        const TemplateField(
          key: 'completion_percentage',
          label: 'Completion %',
          description: 'Percentage of project completion',
          type: TemplateFieldType.number,
          validation: {'min': 0, 'max': 100},
          display: {'suffix': '%', 'step': 1},
        ),
      ],
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
          id: 'duplicate',
          label: 'Duplicate',
          description: 'Create similar event',
          icon: 'content_copy',
          type: TemplateActionType.duplicate,
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
        configuration: {'style': 'professional', 'showProgress': true},
        sections: [
          TemplateSection(
            id: 'header',
            type: 'event_header',
            title: 'Project Update',
            configuration: {'showDate': true, 'showProjectIcon': true},
            fieldKeys: [],
            order: 1,
          ),
          TemplateSection(
            id: 'progress',
            type: 'progress_info',
            title: 'Progress',
            configuration: {'showCompletion': true, 'showPhase': true},
            fieldKeys: ['phase', 'completion_percentage'],
            order: 2,
          ),
          TemplateSection(
            id: 'financial',
            type: 'financial_info',
            title: 'Financial',
            configuration: {'showCost': true, 'showContractor': true},
            fieldKeys: ['cost', 'contractor'],
            order: 3,
          ),
        ],
      ),
    );
  }

  /// Create business event template
  TemplateDefinition _createBusinessEventTemplate() {
    return TemplateDefinition(
      id: 'business_event',
      name: 'Business Event',
      description: 'Template for business-related events and milestones',
      contextType: ContextType.business,
      supportedEventTypes: ['photo', 'text', 'business_milestone', 'revenue_update', 'team_update', 'launch'],
      metadata: TemplateMetadata(
        version: '1.0.0',
        author: 'Timeline Biography App',
        createdAt: DateTime.now(),
        tags: ['business', 'startup', 'revenue', 'team'],
        displayPriority: 4,
        configuration: {},
      ),
      fields: [
        const TemplateField(
          key: 'milestone',
          label: 'Milestone',
          description: 'Business milestone achieved',
          type: TemplateFieldType.text,
          validation: {'maxLength': 100},
          display: {'placeholder': 'MVP Launch, First Sale, Series A'},
        ),
        const TemplateField(
          key: 'revenue',
          label: 'Revenue',
          description: 'Revenue amount',
          type: TemplateFieldType.number,
          validation: {'min': 0},
          display: {'prefix': '\$', 'step': 0.01},
        ),
        const TemplateField(
          key: 'team_size',
          label: 'Team Size',
          description: 'Number of team members',
          type: TemplateFieldType.number,
          validation: {'min': 1},
          display: {'suffix': ' people'},
        ),
        const TemplateField(
          key: 'new_hires',
          label: 'New Hires',
          description: 'Names of new team members',
          type: TemplateFieldType.multiselect,
          validation: {'required': false},
          display: {'placeholder': 'Enter names separated by commas'},
        ),
        const TemplateField(
          key: 'growth_percentage',
          label: 'Growth %',
          description: 'Percentage growth',
          type: TemplateFieldType.number,
          validation: {'min': -100, 'max': 1000},
          display: {'suffix': '%', 'step': 0.1},
        ),
      ],
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
          id: 'share',
          label: 'Share',
          description: 'Share with team',
          icon: 'share',
          type: TemplateActionType.share,
          configuration: {'channels': ['email', 'slack', 'teams']},
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
        configuration: {'style': 'corporate', 'showMetrics': true},
        sections: [
          TemplateSection(
            id: 'header',
            type: 'event_header',
            title: 'Business Update',
            configuration: {'showDate': true, 'showBusinessIcon': true},
            fieldKeys: [],
            order: 1,
          ),
          TemplateSection(
            id: 'milestone',
            type: 'milestone_info',
            title: 'Milestone',
            configuration: {'showDescription': true},
            fieldKeys: ['milestone'],
            order: 2,
          ),
          TemplateSection(
            id: 'metrics',
            type: 'business_metrics',
            title: 'Metrics',
            configuration: {'showRevenue': true, 'showGrowth': true},
            fieldKeys: ['revenue', 'growth_percentage'],
            order: 3,
          ),
          TemplateSection(
            id: 'team',
            type: 'team_info',
            title: 'Team',
            configuration: {'showSize': true, 'showNewHires': true},
            fieldKeys: ['team_size', 'new_hires'],
            order: 4,
          ),
        ],
      ),
    );
  }
}
