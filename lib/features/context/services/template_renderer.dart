import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../widgets/event_cards/personal_event_card.dart';
import '../widgets/event_cards/pet_event_card.dart';
import '../widgets/event_cards/project_event_card.dart';
import '../widgets/event_cards/business_event_card.dart';

/// Factory for creating context-appropriate event card widgets
abstract class TemplateRenderer {
  /// Creates an event card widget based on the context type and event
  static Widget createEventCard({
    required TimelineEvent event,
    required ContextType contextType,
    required TimelineTheme theme,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    switch (contextType) {
      case ContextType.person:
        return PersonalEventCard(
          event: event,
          theme: theme,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      case ContextType.pet:
        return PetEventCard(
          event: event,
          theme: theme,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      case ContextType.project:
        return ProjectEventCard(
          event: event,
          theme: theme,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      case ContextType.business:
        return BusinessEventCard(
          event: event,
          theme: theme,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
    }
  }

  /// Creates a custom attribute editor widget based on context type
  static Widget createAttributeEditor({
    required String eventType,
    required ContextType contextType,
    required Map<String, dynamic> attributes,
    required Function(Map<String, dynamic>) onAttributesChanged,
  }) {
    switch (contextType) {
      case ContextType.person:
        return PersonalAttributeEditor(
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );
      case ContextType.pet:
        return PetAttributeEditor(
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );
      case ContextType.project:
        return ProjectAttributeEditor(
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );
      case ContextType.business:
        return BusinessAttributeEditor(
          eventType: eventType,
          attributes: attributes,
          onAttributesChanged: onAttributesChanged,
        );
    }
  }

  /// Gets available event types for a context
  static List<String> getAvailableEventTypes(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return ['photo', 'text', 'milestone', 'travel', 'celebration'];
      case ContextType.pet:
        return ['photo', 'text', 'pet_milestone', 'vet_visit', 'weight_check', 'training'];
      case ContextType.project:
        return ['photo', 'text', 'renovation_progress', 'milestone', 'budget_update', 'completion'];
      case ContextType.business:
        return ['photo', 'text', 'business_milestone', 'revenue_update', 'team_update', 'launch'];
    }
  }

  /// Gets display name for an event type
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
        return eventType;
    }
  }

  /// Gets the appropriate icon for an event type
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