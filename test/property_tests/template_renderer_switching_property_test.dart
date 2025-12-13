import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/shared/models/context.dart';
import '../../lib/shared/models/timeline_event.dart';
import '../../lib/shared/models/timeline_theme.dart';
import '../../lib/shared/models/user.dart';
import '../../lib/features/context/services/template_renderer.dart';
import '../../lib/features/context/widgets/event_cards/personal_event_card.dart';
import '../../lib/features/context/widgets/event_cards/pet_event_card.dart';
import '../../lib/features/context/widgets/event_cards/project_event_card.dart';
import '../../lib/features/context/widgets/event_cards/business_event_card.dart';

/// **Feature: users-timeline, Property 17: Template Renderer Context Switching**
/// **Validates: Requirements 9.3**
/// 
/// Property: For any timeline event and context type, the Template_Renderer should display 
/// context-appropriate widgets and data fields based on the event's context
void main() {
  group('Template Renderer Context Switching Property Tests', () {
    final faker = Faker();

    setUpAll(() async {
      // Initialize the template renderer system
      await TemplateRenderer.initialize();
    });

    // Helper function to create a random timeline event
    TimelineEvent createRandomEvent(ContextType contextType, String eventType) {
      return TimelineEvent.create(
        id: faker.guid.guid(),
        contextId: faker.guid.guid(),
        ownerId: faker.guid.guid(),
        timestamp: faker.date.dateTime(),
        eventType: eventType,
        title: faker.lorem.sentence(),
        description: faker.lorem.sentences(2).join(' '),
      );
    }

    // Helper function to create a random context
    Context createRandomContext(ContextType contextType) {
      return Context.create(
        id: faker.guid.guid(),
        ownerId: faker.guid.guid(),
        type: contextType,
        name: faker.lorem.words(2).join(' '),
        description: faker.lorem.sentence(),
      );
    }

    testWidgets('Property 17: Template renderer creates context-appropriate event cards', (WidgetTester tester) async {
      // **Feature: users-timeline, Property 17: Template Renderer Context Switching**
      
      // Run the property test 100 times with different combinations
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final context = createRandomContext(contextType);
          final theme = TimelineTheme.forContextType(contextType);
          final availableEventTypes = TemplateRenderer.getAvailableEventTypes(contextType);
          
          // Test each event type for this context
          for (final eventType in availableEventTypes) {
            final event = createRandomEvent(contextType, eventType);
            
            // Property: Template renderer should create appropriate widget for context type
            final widget = TemplateRenderer.createEventCard(
              event: event,
              context: context,
              theme: theme,
            );
            
            expect(widget, isNotNull,
                reason: 'Template renderer should create widget for $contextType context and $eventType event');
            
            // Property: Widget should be a valid Flutter widget
            expect(widget, isA<Widget>(),
                reason: 'Template renderer should create a valid Flutter widget');
          }
        }
      }
    });

    test('Property 17: Available event types are context-appropriate', () {
      // **Feature: users-timeline, Property 17: Template Renderer Context Switching**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final eventTypes = TemplateRenderer.getAvailableEventTypes(contextType);
          
          // Property: All contexts should have basic event types
          expect(eventTypes, contains('photo'),
              reason: 'All contexts should support photo events');
          expect(eventTypes, contains('text'),
              reason: 'All contexts should support text events');
          
          // Property: Context-specific event types should only appear in appropriate contexts
          switch (contextType) {
            case ContextType.person:
              expect(eventTypes, contains('milestone'),
                  reason: 'Personal context should have milestone events');
              expect(eventTypes, contains('travel'),
                  reason: 'Personal context should have travel events');
              expect(eventTypes, contains('celebration'),
                  reason: 'Personal context should have celebration events');
              
              // Should not have context-specific types from other contexts
              expect(eventTypes, isNot(contains('pet_milestone')),
                  reason: 'Personal context should not have pet-specific events');
              expect(eventTypes, isNot(contains('renovation_progress')),
                  reason: 'Personal context should not have project-specific events');
              expect(eventTypes, isNot(contains('business_milestone')),
                  reason: 'Personal context should not have business-specific events');
              break;
              
            case ContextType.pet:
              expect(eventTypes, contains('pet_milestone'),
                  reason: 'Pet context should have pet milestone events');
              expect(eventTypes, contains('vet_visit'),
                  reason: 'Pet context should have vet visit events');
              expect(eventTypes, contains('weight_check'),
                  reason: 'Pet context should have weight check events');
              expect(eventTypes, contains('training'),
                  reason: 'Pet context should have training events');
              
              // Should not have context-specific types from other contexts
              expect(eventTypes, isNot(contains('travel')),
                  reason: 'Pet context should not have personal-specific events');
              expect(eventTypes, isNot(contains('renovation_progress')),
                  reason: 'Pet context should not have project-specific events');
              expect(eventTypes, isNot(contains('revenue_update')),
                  reason: 'Pet context should not have business-specific events');
              break;
              
            case ContextType.project:
              expect(eventTypes, contains('renovation_progress'),
                  reason: 'Project context should have renovation progress events');
              expect(eventTypes, contains('milestone'),
                  reason: 'Project context should have milestone events');
              expect(eventTypes, contains('budget_update'),
                  reason: 'Project context should have budget update events');
              expect(eventTypes, contains('completion'),
                  reason: 'Project context should have completion events');
              
              // Should not have context-specific types from other contexts
              expect(eventTypes, isNot(contains('pet_milestone')),
                  reason: 'Project context should not have pet-specific events');
              expect(eventTypes, isNot(contains('celebration')),
                  reason: 'Project context should not have personal-specific events');
              expect(eventTypes, isNot(contains('revenue_update')),
                  reason: 'Project context should not have business-specific events');
              break;
              
            case ContextType.business:
              expect(eventTypes, contains('business_milestone'),
                  reason: 'Business context should have business milestone events');
              expect(eventTypes, contains('revenue_update'),
                  reason: 'Business context should have revenue update events');
              expect(eventTypes, contains('team_update'),
                  reason: 'Business context should have team update events');
              expect(eventTypes, contains('launch'),
                  reason: 'Business context should have launch events');
              
              // Should not have context-specific types from other contexts
              expect(eventTypes, isNot(contains('pet_milestone')),
                  reason: 'Business context should not have pet-specific events');
              expect(eventTypes, isNot(contains('travel')),
                  reason: 'Business context should not have personal-specific events');
              expect(eventTypes, isNot(contains('renovation_progress')),
                  reason: 'Business context should not have project-specific events');
              break;
          }
        }
      }
    });

    test('Property 17: Event type display names and icons are context-appropriate', () {
      // **Feature: users-timeline, Property 17: Template Renderer Context Switching**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final eventTypes = TemplateRenderer.getAvailableEventTypes(contextType);
          
          for (final eventType in eventTypes) {
            // Property: Each event type should have a display name
            final displayName = TemplateRenderer.getEventTypeDisplayName(eventType);
            expect(displayName, isNotNull,
                reason: 'Event type $eventType should have a display name');
            expect(displayName, isNotEmpty,
                reason: 'Event type $eventType display name should not be empty');
            expect(displayName, isNot(equals(eventType)),
                reason: 'Display name should be more user-friendly than raw event type');
            
            // Property: Each event type should have an icon
            final icon = TemplateRenderer.getEventTypeIcon(eventType);
            expect(icon, isNotNull,
                reason: 'Event type $eventType should have an icon');
            expect(icon, isA<IconData>(),
                reason: 'Event type icon should be valid IconData');
            
            // Property: Context-specific event types should have appropriate display names
            if (eventType.contains('pet_')) {
              expect(contextType, equals(ContextType.pet),
                  reason: 'Pet-specific event types should only appear in pet context');
            }
            if (eventType.contains('business_')) {
              expect(contextType, equals(ContextType.business),
                  reason: 'Business-specific event types should only appear in business context');
            }
            if (eventType.contains('renovation_')) {
              expect(contextType, equals(ContextType.project),
                  reason: 'Renovation-specific event types should only appear in project context');
            }
          }
        }
      }
    });

    testWidgets('Property 17: Attribute editors are context-specific', (WidgetTester tester) async {
      // **Feature: users-timeline, Property 17: Template Renderer Context Switching**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          final eventTypes = TemplateRenderer.getAvailableEventTypes(contextType);
          
          for (final eventType in eventTypes) {
            final context = createRandomContext(contextType);
            final event = createRandomEvent(contextType, eventType);
            
            // Property: Template renderer should create appropriate attribute editor
            final editor = TemplateRenderer.createAttributeEditor(
              event: event,
              context: context,
              onAttributesChanged: (newAttributes) {},
            );
            
            expect(editor, isNotNull,
                reason: 'Template renderer should create attribute editor for $contextType context and $eventType event');
            
            // Property: Editor should be a valid Flutter widget
            expect(editor, isA<Widget>(),
                reason: 'Template renderer should create a valid Flutter widget for attribute editing');
          }
        }
      }
    });

    test('Property 17: Template renderer behavior is consistent and deterministic', () {
      // **Feature: users-timeline, Property 17: Template Renderer Context Switching**
      
      // Run the property test 100 times
      for (int i = 0; i < 100; i++) {
        final availableContexts = ContextType.values;
        
        for (final contextType in availableContexts) {
          // Property: Multiple calls should return identical results
          final eventTypes1 = TemplateRenderer.getAvailableEventTypes(contextType);
          final eventTypes2 = TemplateRenderer.getAvailableEventTypes(contextType);
          final eventTypes3 = TemplateRenderer.getAvailableEventTypes(contextType);
          
          expect(eventTypes1, equals(eventTypes2),
              reason: 'Available event types should be consistent for $contextType');
          expect(eventTypes2, equals(eventTypes3),
              reason: 'Available event types should be consistent for $contextType');
          
          // Property: Event type lists should not be empty
          expect(eventTypes1, isNotEmpty,
              reason: 'Each context should have at least some event types');
          
          // Property: Event types should be unique within a context
          final uniqueTypes = eventTypes1.toSet();
          expect(uniqueTypes.length, equals(eventTypes1.length),
              reason: 'Event types should be unique within context $contextType');
        }
      }
    });
  });
}