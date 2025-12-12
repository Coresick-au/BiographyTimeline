import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../../../core/templates/enhanced_template_renderer.dart';
import '../widgets/event_cards/personal_event_card.dart';
import '../widgets/event_cards/pet_event_card.dart';
import '../widgets/event_cards/project_event_card.dart';
import '../widgets/event_cards/business_event_card.dart';

/// Factory for creating context-appropriate event card widgets
/// This now delegates to the enhanced template renderer
abstract class TemplateRenderer {
  /// Initialize the template system
  static Future<void> initialize() async {
    await EnhancedTemplateRenderer.initialize();
  }

  /// Creates an event card widget based on the context type and event
  /// Using the enhanced template renderer for better context awareness
  static Widget createEventCard({
    required TimelineEvent event,
    required Context context,
    required TimelineTheme theme,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return EnhancedTemplateRenderer.createEventCard(
      event: event,
      context: context,
      theme: theme,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  /// Creates a custom attribute editor widget based on context type
  /// Using the enhanced template renderer for better field definitions
  static Widget createAttributeEditor({
    required TimelineEvent event,
    required Context context,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) {
    return EnhancedTemplateRenderer.createAttributeEditor(
      event: event,
      context: context,
      onAttributesChanged: onAttributesChanged,
    );
  }

  /// Gets available event types for a context
  /// Using the enhanced template renderer for comprehensive event type management
  static List<String> getAvailableEventTypes(ContextType contextType) {
    return EnhancedTemplateRenderer.getAvailableEventTypes(contextType);
  }

  /// Gets display name for an event type
  /// Using the enhanced template renderer for consistent naming
  static String getEventTypeDisplayName(String eventType) {
    return EnhancedTemplateRenderer.getEventTypeDisplayName(eventType);
  }

  /// Gets the appropriate icon for an event type
  /// Using the enhanced template renderer for consistent iconography
  static IconData getEventTypeIcon(String eventType) {
    return EnhancedTemplateRenderer.getEventTypeIcon(eventType);
  }
}

/// Base class for attribute editors
abstract class AttributeEditor extends StatelessWidget {
  final String eventType;
  final Map<String, dynamic> attributes;
  final Function(Map<String, dynamic>) onAttributesChanged;

  const AttributeEditor({
    Key? key,
    required this.eventType,
    required this.attributes,
    required this.onAttributesChanged,
  }) : super(key: key);
}

/// Personal context attribute editor
class PersonalAttributeEditor extends AttributeEditor {
  const PersonalAttributeEditor({
    Key? key,
    required String eventType,
    required Map<String, dynamic> attributes,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) : super(
          key: key,
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );

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
        if (eventType == 'milestone') ...[
          TextFormField(
            initialValue: attributes['milestone_type'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Milestone Type',
              hintText: 'e.g., Birthday, Graduation, Achievement',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['milestone_type'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
        if (eventType == 'travel') ...[
          TextFormField(
            initialValue: attributes['destination'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'Where did you go?',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['destination'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
      ],
    );
  }
}

/// Pet context attribute editor
class PetAttributeEditor extends AttributeEditor {
  const PetAttributeEditor({
    Key? key,
    required String eventType,
    required Map<String, dynamic> attributes,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) : super(
          key: key,
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pet Event Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (eventType == 'weight_check') ...[
          TextFormField(
            initialValue: attributes['weight_kg']?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'Enter weight in kilograms',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['weight_kg'] = double.tryParse(value);
              onAttributesChanged(newAttributes);
            },
          ),
        ],
        if (eventType == 'vet_visit') ...[
          TextFormField(
            initialValue: attributes['vet_name'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Veterinarian',
              hintText: 'Dr. Smith',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['vet_name'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: attributes['visit_reason'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Reason for Visit',
              hintText: 'Checkup, vaccination, etc.',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['visit_reason'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
      ],
    );
  }
}

/// Project context attribute editor
class ProjectAttributeEditor extends AttributeEditor {
  const ProjectAttributeEditor({
    Key? key,
    required String eventType,
    required Map<String, dynamic> attributes,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) : super(
          key: key,
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (eventType == 'renovation_progress') ...[
          TextFormField(
            initialValue: attributes['room'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Room/Area',
              hintText: 'Kitchen, Bathroom, Living Room',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['room'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: attributes['phase'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Project Phase',
              hintText: 'Demolition, Framing, Finishing',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['phase'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
        if (eventType == 'budget_update') ...[
          TextFormField(
            initialValue: attributes['cost']?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Cost',
              hintText: 'Enter amount spent',
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['cost'] = double.tryParse(value);
              onAttributesChanged(newAttributes);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: attributes['contractor'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Contractor/Vendor',
              hintText: 'Who did the work?',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['contractor'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
      ],
    );
  }
}

/// Business context attribute editor
class BusinessAttributeEditor extends AttributeEditor {
  const BusinessAttributeEditor({
    Key? key,
    required String eventType,
    required Map<String, dynamic> attributes,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) : super(
          key: key,
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Event Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (eventType == 'revenue_update') ...[
          TextFormField(
            initialValue: attributes['revenue']?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Revenue',
              hintText: 'Enter revenue amount',
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['revenue'] = double.tryParse(value);
              onAttributesChanged(newAttributes);
            },
          ),
        ],
        if (eventType == 'team_update') ...[
          TextFormField(
            initialValue: attributes['team_size']?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Team Size',
              hintText: 'Number of team members',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['team_size'] = int.tryParse(value);
              onAttributesChanged(newAttributes);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: attributes['new_hires'] ?? '',
            decoration: const InputDecoration(
              labelText: 'New Hires',
              hintText: 'Names of new team members',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['new_hires'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
        if (eventType == 'business_milestone') ...[
          TextFormField(
            initialValue: attributes['milestone'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Milestone',
              hintText: 'MVP Launch, First Sale, Series A',
            ),
            onChanged: (value) {
              final newAttributes = Map<String, dynamic>.from(attributes);
              newAttributes['milestone'] = value;
              onAttributesChanged(newAttributes);
            },
          ),
        ],
      ],
    );
  }
}