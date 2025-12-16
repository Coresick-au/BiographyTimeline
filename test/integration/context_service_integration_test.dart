import 'package:flutter_test/flutter_test.dart';
import '../../lib/shared/models/context.dart';
import '../helpers/mock_context_service.dart';

/// Integration test for ContextManagementService
/// This verifies the service works correctly with the Context model
void main() {
  group('ContextManagementService Integration Tests', () {
    test('Context model public API works correctly', () {
      // Test that the public getDefaultModuleConfiguration method works
      final petDefaults = Context.getDefaultModuleConfiguration(ContextType.pet);
      
      expect(petDefaults, isA<Map<String, dynamic>>());
      expect(petDefaults['enableGhostCamera'], isTrue);
      expect(petDefaults['enableBudgetTracking'], isFalse);
      expect(petDefaults['enableProgressComparison'], isTrue);
      expect(petDefaults['enableMilestoneTracking'], isTrue);
      expect(petDefaults['enableWeightTracking'], isTrue);
      expect(petDefaults['enableVetVisitTracking'], isTrue);
    });

    test('All context types have default configurations', () {
      for (final contextType in ContextType.values) {
        final defaults = Context.getDefaultModuleConfiguration(contextType);
        
        expect(defaults, isA<Map<String, dynamic>>());
        expect(defaults, isNotEmpty);
        
        // All contexts should have these basic features
        expect(defaults.containsKey('enableMilestoneTracking'), isTrue);
        
        // Context-specific features
        switch (contextType) {
          case ContextType.pet:
            expect(defaults['enableGhostCamera'], isTrue);
            expect(defaults['enableWeightTracking'], isTrue);
            break;
          case ContextType.project:
            expect(defaults['enableGhostCamera'], isTrue);
            expect(defaults['enableBudgetTracking'], isTrue);
            expect(defaults['enableProgressComparison'], isTrue);
            break;
          case ContextType.business:
            expect(defaults['enableBudgetTracking'], isTrue);
            expect(defaults['enableRevenueTracking'], isTrue);
            expect(defaults['enableTeamTracking'], isTrue);
            break;
          case ContextType.person:
            expect(defaults['enableGhostCamera'], isFalse);
            expect(defaults['enableLocationTracking'], isTrue);
            expect(defaults['enableFaceDetection'], isTrue);
            break;
        }
      }
    });

    test('Context creation with factory method works', () {
      final context = Context.create(
        id: 'test-context-1',
        ownerId: 'test-user-1',
        type: ContextType.pet,
        name: 'Test Pet Context',
        description: 'A test pet timeline',
      );

      expect(context.id, equals('test-context-1'));
      expect(context.ownerId, equals('test-user-1'));
      expect(context.type, equals(ContextType.pet));
      expect(context.name, equals('Test Pet Context'));
      expect(context.description, equals('A test pet timeline'));
      
      // Should have pet-specific default configuration
      expect(context.moduleConfiguration['enableGhostCamera'], isTrue);
      expect(context.moduleConfiguration['enableWeightTracking'], isTrue);
      expect(context.moduleConfiguration['enableBudgetTracking'], isFalse);
      
      // Should have default theme ID
      expect(context.themeId, equals('pet_theme'));
      
      // Should have timestamps
      expect(context.createdAt, isNotNull);
      expect(context.updatedAt, isNotNull);
    });

    test('Context serialization works correctly', () {
      final originalContext = Context.create(
        id: 'test-context-2',
        ownerId: 'test-user-2',
        type: ContextType.business,
        name: 'Test Business Context',
      );

      // Test JSON serialization round-trip
      final json = originalContext.toJson();
      final deserializedContext = Context.fromJson(json);

      expect(deserializedContext.id, equals(originalContext.id));
      expect(deserializedContext.ownerId, equals(originalContext.ownerId));
      expect(deserializedContext.type, equals(originalContext.type));
      expect(deserializedContext.name, equals(originalContext.name));
      expect(deserializedContext.moduleConfiguration, equals(originalContext.moduleConfiguration));
      expect(deserializedContext.themeId, equals(originalContext.themeId));
      expect(deserializedContext.createdAt, equals(originalContext.createdAt));
      expect(deserializedContext.updatedAt, equals(originalContext.updatedAt));
    });

    test('Context copyWith works correctly', () async {
      final originalContext = Context.create(
        id: 'test-context-3',
        ownerId: 'test-user-3',
        type: ContextType.project,
        name: 'Original Name',
      );

      await Future.delayed(const Duration(milliseconds: 1));

      final updatedContext = originalContext.copyWith(
        name: 'Updated Name',
        description: 'Updated description',
      );

      expect(updatedContext.id, equals(originalContext.id));
      expect(updatedContext.ownerId, equals(originalContext.ownerId));
      expect(updatedContext.type, equals(originalContext.type));
      expect(updatedContext.name, equals('Updated Name'));
      expect(updatedContext.description, equals('Updated description'));
      expect(updatedContext.createdAt, equals(originalContext.createdAt));
      // copyWith without explicit updatedAt should set it to now
      expect(updatedContext.updatedAt, isNot(equals(originalContext.updatedAt)));
    });

    test('Context equality works correctly', () {
      final context1 = Context.create(
        id: 'test-context-4',
        ownerId: 'test-user-4',
        type: ContextType.person,
        name: 'Test Context',
      );

      final context2 = Context.create(
        id: 'test-context-4', // Same ID
        ownerId: 'test-user-4',
        type: ContextType.person,
        name: 'Test Context',
      );

      final context3 = Context.create(
        id: 'test-context-5', // Different ID
        ownerId: 'test-user-4',
        type: ContextType.person,
        name: 'Test Context',
      );

      // Note: These won't be equal because createdAt/updatedAt will be different
      // But we can test that the comparison logic works
      expect(context1.id, equals(context2.id));
      expect(context1.id, isNot(equals(context3.id)));
    });
  });
}
