import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:users_timeline/core/templates/template_manager.dart';
import 'package:users_timeline/core/templates/template_definition.dart';
import 'package:users_timeline/shared/models/context.dart';
import 'package:users_timeline/shared/models/timeline_event.dart';
import 'package:users_timeline/shared/models/timeline_theme.dart';
import 'package:users_timeline/shared/models/user.dart';

void main() {
  group('Template System Tests', () {
    late TemplateManager templateManager;

    setUpAll(() async {
      templateManager = TemplateManager();
      await templateManager.initialize();
    });

    test('Template manager initializes correctly', () {
      expect(templateManager.getAllTemplates().isNotEmpty, isTrue);
    });

    test('Get templates for context type', () {
      final personalTemplates = templateManager.getTemplatesForContext(ContextType.person);
      expect(personalTemplates.isNotEmpty, isTrue);
      
      final petTemplates = templateManager.getTemplatesForContext(ContextType.pet);
      expect(petTemplates.isNotEmpty, isTrue);
      
      final projectTemplates = templateManager.getTemplatesForContext(ContextType.project);
      expect(projectTemplates.isNotEmpty, isTrue);
      
      final businessTemplates = templateManager.getTemplatesForContext(ContextType.business);
      expect(businessTemplates.isNotEmpty, isTrue);
    });

    test('Get templates for event type', () {
      final photoTemplates = templateManager.getTemplatesForEventType('photo');
      expect(photoTemplates.length, equals(4)); // Should be available for all contexts
      
      final petMilestoneTemplates = templateManager.getTemplatesForEventType('pet_milestone');
      expect(petMilestoneTemplates.length, equals(1)); // Only pet context
      
      final renovationTemplates = templateManager.getTemplatesForEventType('renovation_progress');
      expect(renovationTemplates.length, equals(1)); // Only project context
    });

    test('Get available event types for context', () {
      final personalEventTypes = templateManager.getAvailableEventTypes(ContextType.person);
      expect(personalEventTypes.contains('photo'), isTrue);
      expect(personalEventTypes.contains('milestone'), isTrue);
      expect(personalEventTypes.contains('pet_milestone'), isFalse);
      
      final petEventTypes = templateManager.getAvailableEventTypes(ContextType.pet);
      expect(petEventTypes.contains('pet_milestone'), isTrue);
      expect(petEventTypes.contains('vet_visit'), isTrue);
      expect(petEventTypes.contains('renovation_progress'), isFalse);
    });

    test('Event type display names and icons', () {
      expect(templateManager.getEventTypeDisplayName('photo'), equals('Photo Event'));
      expect(templateManager.getEventTypeDisplayName('pet_milestone'), equals('Pet Milestone'));
      expect(templateManager.getEventTypeDisplayName('renovation_progress'), equals('Renovation Progress'));
      
      expect(templateManager.getEventTypeIcon('photo'), equals(Icons.photo));
      expect(templateManager.getEventTypeIcon('pet_milestone'), equals(Icons.pets));
      expect(templateManager.getEventTypeIcon('renovation_progress'), equals(Icons.construction));
    });

    test('Validate event data against template', () {
      final personalTemplate = templateManager.getTemplatesForContext(ContextType.person).first;
      
      // Valid event
      final validEvent = TimelineEvent.create(
        id: 'test-1',
        contextId: 'context-1',
        ownerId: 'user-1',
        timestamp: DateTime.now(),
        eventType: 'photo',
        title: 'Test Photo',
        description: 'A test photo',
      );
      
      final validationResult = templateManager.validateEventData(
        event: validEvent,
        template: personalTemplate,
      );
      expect(validationResult.isValid, isTrue);
      expect(validationResult.errors.isEmpty, isTrue);
    });

    test('Get default attributes for event type', () {
      final personalDefaults = templateManager.getDefaultAttributes(
        eventType: 'milestone',
        contextType: ContextType.person,
      );
      
      // Should have default structure even if empty
      expect(personalDefaults, isA<Map<String, dynamic>>());
      
      final petDefaults = templateManager.getDefaultAttributes(
        eventType: 'weight_check',
        contextType: ContextType.pet,
      );
      
      expect(petDefaults, isA<Map<String, dynamic>>());
    });

    test('Create event card widget', () {
      final event = TimelineEvent.create(
        id: 'test-2',
        contextId: 'context-2',
        ownerId: 'user-2',
        timestamp: DateTime.now(),
        eventType: 'photo',
        title: 'Test Photo',
        description: 'A test photo',
      );
      
      final context = Context(
        id: 'context-2',
        ownerId: 'user-2',
        type: ContextType.person,
        name: 'Personal Timeline',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final theme = TimelineTheme(
        id: 'default',
        name: 'Default Theme',
        contextType: ContextType.person,
        colorPalette: {
          'primary': Colors.blue.value,
          'background': Colors.white.value,
          'text': Colors.black.value,
          'card': Colors.grey[100]!.value,
        },
        iconSet: {'default': 'material'},
        typography: {
          'body': {'fontSize': 14.0, 'fontWeight': 'normal'},
          'header': {'fontSize': 16.0, 'fontWeight': 'bold'},
        },
        widgetFactories: {'card': true, 'list': true},
        enableGhostCamera: false,
        enableBudgetTracking: false,
        enableProgressComparison: false,
      );
      
      final cardWidget = templateManager.createEventCard(
        event: event,
        context: context,
        theme: theme,
      );
      
      expect(cardWidget, isA<Widget>());
    });

    test('Create attribute editor widget', () {
      final event = TimelineEvent.create(
        id: 'test-3',
        contextId: 'context-3',
        ownerId: 'user-3',
        timestamp: DateTime.now(),
        eventType: 'vet_visit',
        title: 'Vet Visit',
        customAttributes: {
          'vet_name': 'Dr. Smith',
          'visit_reason': 'Checkup',
        },
      );
      
      final context = Context(
        id: 'context-3',
        ownerId: 'user-3',
        type: ContextType.pet,
        name: 'Pet Timeline',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final editorWidget = templateManager.createAttributeEditor(
        event: event,
        context: context,
        onAttributesChanged: (attributes) {},
      );
      
      expect(editorWidget, isA<Widget>());
    });

    test('Search templates', () {
      final personalResults = templateManager.searchTemplates('personal');
      expect(personalResults.isNotEmpty, isTrue);
      expect(personalResults.every((t) => t.contextType == ContextType.person), isTrue);
      
      final petResults = templateManager.searchTemplates('pet');
      expect(petResults.isNotEmpty, isTrue);
      expect(petResults.every((t) => t.contextType == ContextType.pet), isTrue);
    });

    test('Template statistics', () {
      final stats = templateManager.getStatistics();
      expect(stats.totalTemplates, greaterThan(0));
      expect(stats.contextCounts.keys, contains(ContextType.person));
      expect(stats.contextCounts.keys, contains(ContextType.pet));
      expect(stats.contextCounts.keys, contains(ContextType.project));
      expect(stats.contextCounts.keys, contains(ContextType.business));
    });

    test('Template creation and registration', () {
      final customTemplate = TemplateDefinition(
        id: 'test-custom',
        name: 'Custom Test Template',
        description: 'A custom template for testing',
        contextType: ContextType.person,
        supportedEventTypes: ['custom_event'],
        metadata: TemplateMetadata(
          version: '1.0.0',
          author: 'Test',
          createdAt: DateTime.now(), // Will be set properly
          tags: ['test', 'custom'],
          configuration: {},
        ),
        fields: [
          const TemplateField(
            key: 'test_field',
            label: 'Test Field',
            description: 'A test field',
            type: TemplateFieldType.text,
            validation: {'maxLength': 50},
            display: {'placeholder': 'Enter test value'},
          ),
        ],
        actions: [
          const TemplateAction(
            id: 'test_action',
            label: 'Test Action',
            description: 'A test action',
            icon: 'test',
            type: TemplateActionType.custom,
            configuration: {},
          ),
        ],
        layout: const TemplateLayout(
          type: 'card',
          configuration: {'style': 'test'},
          sections: [
            TemplateSection(
              id: 'test_section',
              type: 'test',
              title: 'Test Section',
              configuration: {},
              fieldKeys: ['test_field'],
              order: 1,
            ),
          ],
        ),
      );

      templateManager.registerTemplate(customTemplate);
      
      final retrievedTemplate = templateManager.getTemplateById('test-custom');
      expect(retrievedTemplate, isNotNull);
      expect(retrievedTemplate!.name, equals('Custom Test Template'));
      expect(retrievedTemplate.supportedEventTypes, contains('custom_event'));
      
      // Clean up
      templateManager.unregisterTemplate('test-custom');
    });
  });
}
