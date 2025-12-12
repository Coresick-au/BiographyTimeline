import 'package:flutter/material.dart';
import '../templates/template_definition.dart';
import '../templates/template_registry.dart';
import '../../shared/models/timeline_event.dart';
import '../../shared/models/context.dart';
import '../../shared/models/timeline_theme.dart';

/// Enhanced template renderer that uses the template registry system
class EnhancedTemplateRenderer {
  static final TemplateRegistry _registry = TemplateRegistry();

  /// Initialize the renderer
  static Future<void> initialize() async {
    await _registry.initialize();
  }

  /// Create an event card widget using the appropriate template
  static Widget createEventCard({
    required TimelineEvent event,
    required Context context,
    required TimelineTheme theme,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    Map<String, VoidCallback>? customActions,
  }) {
    // Find the best template for this event
    final template = _findBestTemplate(event, context);
    
    if (template != null) {
      return _TemplateCard(
        template: template,
        event: event,
        context: context,
        theme: theme,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        customActions: customActions,
      );
    }

    // Fallback to default card
    return _DefaultEventCard(
      event: event,
      context: context,
      theme: theme,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  /// Create an attribute editor widget using the template field definitions
  static Widget createAttributeEditor({
    required TimelineEvent event,
    required Context context,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) {
    final template = _findBestTemplate(event, context);
    
    if (template != null) {
      return _TemplateAttributeEditor(
        template: template,
        event: event,
        onAttributesChanged: onAttributesChanged,
      );
    }

    // Fallback to basic editor
    return _BasicAttributeEditor(
      event: event,
      onAttributesChanged: onAttributesChanged,
    );
  }

  /// Get available event types for a context
  static List<String> getAvailableEventTypes(ContextType contextType) {
    final templates = _registry.getTemplatesForContext(contextType);
    final eventTypes = <String>{};
    
    for (final template in templates) {
      eventTypes.addAll(template.supportedEventTypes);
    }
    
    return eventTypes.toList()..sort();
  }

  /// Get display name for an event type
  static String getEventTypeDisplayName(String eventType) {
    switch (eventType) {
      case 'photo':
        return 'Photo Event';
      case 'text':
        return 'Text Entry';
      case 'milestone':
        return 'Milestone';
      case 'travel':
        return 'Travel';
      case 'celebration':
        return 'Celebration';
      case 'pet_milestone':
        return 'Pet Milestone';
      case 'vet_visit':
        return 'Vet Visit';
      case 'weight_check':
        return 'Weight Check';
      case 'training':
        return 'Training Session';
      case 'renovation_progress':
        return 'Renovation Progress';
      case 'budget_update':
        return 'Budget Update';
      case 'completion':
        return 'Project Completion';
      case 'business_milestone':
        return 'Business Milestone';
      case 'revenue_update':
        return 'Revenue Update';
      case 'team_update':
        return 'Team Update';
      case 'launch':
        return 'Product Launch';
      default:
        return eventType.split('_').map((word) => 
          word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  /// Get the appropriate icon for an event type
  static IconData getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'photo':
        return Icons.photo;
      case 'text':
        return Icons.text_fields;
      case 'milestone':
        return Icons.flag;
      case 'travel':
        return Icons.flight;
      case 'celebration':
        return Icons.celebration;
      case 'pet_milestone':
        return Icons.pets;
      case 'vet_visit':
        return Icons.local_hospital;
      case 'weight_check':
        return Icons.monitor_weight;
      case 'training':
        return Icons.school;
      case 'renovation_progress':
        return Icons.construction;
      case 'budget_update':
        return Icons.attach_money;
      case 'completion':
        return Icons.check_circle;
      case 'business_milestone':
        return Icons.business;
      case 'revenue_update':
        return Icons.trending_up;
      case 'team_update':
        return Icons.group;
      case 'launch':
        return Icons.rocket_launch;
      default:
        return Icons.event;
    }
  }

  /// Find the best template for an event
  static TemplateDefinition? _findBestTemplate(TimelineEvent event, Context context) {
    final templates = _registry.getTemplatesForContext(context.type);
    
    // Find templates that support this event type
    final supportingTemplates = templates
        .where((template) => template.supportsEventType(event.eventType))
        .toList();
    
    if (supportingTemplates.isEmpty) return null;
    
    // Return the highest priority template
    supportingTemplates.sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
    return supportingTemplates.first;
  }
}

/// Widget that renders an event card using a template definition
class _TemplateCard extends StatelessWidget {
  final TemplateDefinition template;
  final TimelineEvent event;
  final Context context;
  final TimelineTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Map<String, VoidCallback>? customActions;

  const _TemplateCard({
    required this.template,
    required this.event,
    required this.context,
    required this.theme,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              ..._buildSections(),
              const SizedBox(height: 12),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          EnhancedTemplateRenderer.getEventTypeIcon(event.eventType),
          color: Color(theme.colorPalette['primary'] ?? Colors.blue.value),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title ?? EnhancedTemplateRenderer.getEventTypeDisplayName(event.eventType),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(event.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSections() {
    final sections = <Widget>[];
    
    for (final section in template.layout.sections) {
      sections.add(_buildSection(section));
      sections.add(const SizedBox(height: 12));
    }
    
    return sections;
  }

  Widget _buildSection(TemplateSection section) {
    switch (section.type) {
      case 'custom_attributes':
        return _buildCustomAttributesSection(section);
      case 'health_info':
        return _buildHealthInfoSection(section);
      case 'behavior_info':
        return _buildBehaviorInfoSection(section);
      case 'progress_info':
        return _buildProgressInfoSection(section);
      case 'financial_info':
        return _buildFinancialInfoSection(section);
      case 'milestone_info':
        return _buildMilestoneInfoSection(section);
      case 'business_metrics':
        return _buildBusinessMetricsSection(section);
      case 'team_info':
        return _buildTeamInfoSection(section);
      default:
        return _buildDefaultSection(section);
    }
  }

  Widget _buildCustomAttributesSection(TemplateSection section) {
    final relevantAttributes = <String, dynamic>{};
    
    for (final fieldKey in section.fieldKeys) {
      if (event.customAttributes.containsKey(fieldKey)) {
        relevantAttributes[fieldKey] = event.customAttributes[fieldKey];
      }
    }
    
    if (relevantAttributes.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...relevantAttributes.entries.map((entry) => 
          _buildAttributeRow(entry.key, entry.value)
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection(TemplateSection section) {
    final weight = event.customAttributes['weight_kg'];
    final vetName = event.customAttributes['vet_name'];
    final visitReason = event.customAttributes['visit_reason'];
    
    if (weight == null && vetName == null && visitReason == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (weight != null) _buildAttributeRow('Weight', '${weight}kg'),
        if (vetName != null) _buildAttributeRow('Veterinarian', vetName),
        if (visitReason != null) _buildAttributeRow('Visit Reason', visitReason),
      ],
    );
  }

  Widget _buildProgressInfoSection(TemplateSection section) {
    final phase = event.customAttributes['phase'];
    final completion = event.customAttributes['completion_percentage'];
    
    if (phase == null && completion == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (phase != null) _buildAttributeRow('Phase', phase),
        if (completion != null) ...[
          _buildAttributeRow('Completion', '${completion}%'),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (completion as num) / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(theme.colorPalette['primary'] ?? Colors.blue.value),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinancialInfoSection(TemplateSection section) {
    final cost = event.customAttributes['cost'];
    final contractor = event.customAttributes['contractor'];
    
    if (cost == null && contractor == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (cost != null) _buildAttributeRow('Cost', '\$${cost}'),
        if (contractor != null) _buildAttributeRow('Contractor', contractor),
      ],
    );
  }

  Widget _buildMilestoneInfoSection(TemplateSection section) {
    final milestone = event.customAttributes['milestone'];
    
    if (milestone == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildAttributeRow('Milestone', milestone),
      ],
    );
  }

  Widget _buildBusinessMetricsSection(TemplateSection section) {
    final revenue = event.customAttributes['revenue'];
    final growth = event.customAttributes['growth_percentage'];
    
    if (revenue == null && growth == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (revenue != null) _buildAttributeRow('Revenue', '\$${revenue}'),
        if (growth != null) _buildAttributeRow(
          'Growth', 
          '${growth > 0 ? '+' : ''}${growth}%',
          valueColor: growth > 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildTeamInfoSection(TemplateSection section) {
    final teamSize = event.customAttributes['team_size'];
    final newHires = event.customAttributes['new_hires'];
    
    if (teamSize == null && newHires == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (teamSize != null) _buildAttributeRow('Team Size', '${teamSize} people'),
        if (newHires != null) _buildAttributeRow('New Hires', newHires),
      ],
    );
  }

  Widget _buildBehaviorInfoSection(TemplateSection section) {
    final mood = event.customAttributes['mood'];
    
    if (mood == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildAttributeRow('Mood', mood),
      ],
    );
  }

  Widget _buildDefaultSection(TemplateSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (event.description != null)
          Text(event.description!),
      ],
    );
  }

  Widget _buildAttributeRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
          ),
        if (onDelete != null)
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        if (customActions != null)
          ...customActions!.entries.map((entry) =>
            TextButton.icon(
              onPressed: entry.value,
              icon: const Icon(Icons.more_horiz, size: 16),
              label: Text(entry.key),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Default event card for when no template is available
class _DefaultEventCard extends StatelessWidget {
  final TimelineEvent event;
  final Context context;
  final TimelineTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DefaultEventCard({
    required this.event,
    required this.context,
    required this.theme,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    EnhancedTemplateRenderer.getEventTypeIcon(event.eventType),
                    color: Color(theme.colorPalette['primary'] ?? Colors.blue.value),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title ?? EnhancedTemplateRenderer.getEventTypeDisplayName(event.eventType),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(event.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.description != null) ...[
                const SizedBox(height: 12),
                Text(event.description!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Template-based attribute editor
class _TemplateAttributeEditor extends StatelessWidget {
  final TemplateDefinition template;
  final TimelineEvent event;
  final Function(Map<String, dynamic>) onAttributesChanged;

  const _TemplateAttributeEditor({
    required this.template,
    required this.event,
    required this.onAttributesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final relevantFields = template.fields.where((field) =>
      event.customAttributes.containsKey(field.key) || 
      template.supportedEventTypes.contains(event.eventType)
    ).toList();

    if (relevantFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...relevantFields.map((field) => _buildFieldEditor(field)),
      ],
    );
  }

  Widget _buildFieldEditor(TemplateField field) {
    switch (field.type) {
      case TemplateFieldType.text:
        return _buildTextField(field);
      case TemplateFieldType.number:
        return _buildNumberField(field);
      case TemplateFieldType.select:
        return _buildSelectField(field);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(TemplateField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: event.customAttributes[field.key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.display['placeholder'],
        ),
        onChanged: (value) {
          final newAttributes = Map<String, dynamic>.from(event.customAttributes);
          newAttributes[field.key] = value;
          onAttributesChanged(newAttributes);
        },
      ),
    );
  }

  Widget _buildNumberField(TemplateField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: event.customAttributes[field.key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: field.label,
          prefixText: field.display['prefix'],
          suffixText: field.display['suffix'],
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final newAttributes = Map<String, dynamic>.from(event.customAttributes);
          newAttributes[field.key] = double.tryParse(value);
          onAttributesChanged(newAttributes);
        },
      ),
    );
  }

  Widget _buildSelectField(TemplateField field) {
    final options = field.display['options'] as List<String>? ?? [];
    final currentValue = event.customAttributes[field.key]?.toString();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: field.label,
        ),
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            final newAttributes = Map<String, dynamic>.from(event.customAttributes);
            newAttributes[field.key] = value;
            onAttributesChanged(newAttributes);
          }
        },
      ),
    );
  }
}

/// Basic attribute editor fallback
class _BasicAttributeEditor extends StatelessWidget {
  final TimelineEvent event;
  final Function(Map<String, dynamic>) onAttributesChanged;

  const _BasicAttributeEditor({
    required this.event,
    required this.onAttributesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...event.customAttributes.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: entry.value?.toString() ?? '',
              decoration: InputDecoration(
                labelText: _formatKeyName(entry.key),
              ),
              onChanged: (value) {
                final newAttributes = Map<String, dynamic>.from(event.customAttributes);
                newAttributes[entry.key] = value;
                onAttributesChanged(newAttributes);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatKeyName(String key) {
    return key.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
