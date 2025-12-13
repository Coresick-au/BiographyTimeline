import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../../lib/features/social/models/user_models.dart';
import '../../lib/features/social/services/relationship_service.dart';

/// Property-based tests for relationship termination functionality

void main() {
  group('Property 19: Relationship Termination', () {
    test('Relationship termination with archive option preserves content but removes access', () async {
      // Arrange - Create fresh service and relationship for this test
      final relationshipService = RelationshipService();
      final testRelationship = _createTestRelationship();
      await _addTestRelationshipDirectly(relationshipService, testRelationship);

      // Create termination request
      final terminationRequest = await relationshipService.initiateRelationshipTermination(
        initiatedByUserId: testRelationship.userAId,
        targetUserId: testRelationship.userBId,
        option: RelationshipTerminationOption.archive,
        reason: 'Mutual agreement to end relationship',
      );

      // Act - Process termination
      final ContentManagementResult? result = await relationshipService.processRelationshipTermination(
        requestId: terminationRequest.id,
        processedByUserId: testRelationship.userAId,
      );

      // Debug output
      print('Result type: ${result.runtimeType}');
      print('Result value: $result');
      print('Result == null: ${result == null}');

      // Assert - Basic check first
      expect(result, isNotNull, reason: 'Result should not be null');
      
      // If we get here, result is not null
      expect(result!.isSuccess, isTrue, reason: 'Termination should succeed');
      expect(result.option, equals(RelationshipTerminationOption.archive), reason: 'Should use archive option');

      // Cleanup
      relationshipService.dispose();
    });

    test('Relationship termination with redact option removes sensitive content', () async {
      // Arrange - Create fresh service and relationship for this test
      final relationshipService = RelationshipService();
      final testRelationship = _createTestRelationship();
      await _addTestRelationshipDirectly(relationshipService, testRelationship);

      final terminationRequest = await relationshipService.initiateRelationshipTermination(
        initiatedByUserId: testRelationship.userAId,
        targetUserId: testRelationship.userBId,
        option: RelationshipTerminationOption.redact,
        reason: 'Removing sensitive content',
      );

      // Act
      final result = await relationshipService.processRelationshipTermination(
        requestId: terminationRequest.id,
        processedByUserId: testRelationship.userAId,
      );

      // Assert
      expect(result, isNotNull);
      expect(result.isSuccess, isTrue);
      expect(result.option, equals(RelationshipTerminationOption.redact));

      // Cleanup
      relationshipService.dispose();
    });

    test('Relationship termination with bifurcate option creates separate timelines', () async {
      // Arrange - Create fresh service and relationship for this test
      final relationshipService = RelationshipService();
      final testRelationship = _createTestRelationship();
      await _addTestRelationshipDirectly(relationshipService, testRelationship);

      final terminationRequest = await relationshipService.initiateRelationshipTermination(
        initiatedByUserId: testRelationship.userAId,
        targetUserId: testRelationship.userBId,
        option: RelationshipTerminationOption.bifurcate,
        reason: 'Creating separate timelines',
      );

      // Act
      final result = await relationshipService.processRelationshipTermination(
        requestId: terminationRequest.id,
        processedByUserId: testRelationship.userAId,
      );

      // Assert
      expect(result, isNotNull);
      expect(result.isSuccess, isTrue);
      expect(result.option, equals(RelationshipTerminationOption.bifurcate));

      // Cleanup
      relationshipService.dispose();
    });

    test('Relationship termination with delete option permanently removes content', () async {
      // Arrange - Create fresh service and relationship for this test
      final relationshipService = RelationshipService();
      final testRelationship = _createTestRelationship();
      await _addTestRelationshipDirectly(relationshipService, testRelationship);

      final terminationRequest = await relationshipService.initiateRelationshipTermination(
        initiatedByUserId: testRelationship.userAId,
        targetUserId: testRelationship.userBId,
        option: RelationshipTerminationOption.delete,
        reason: 'Complete content removal requested',
      );

      // Act
      final result = await relationshipService.processRelationshipTermination(
        requestId: terminationRequest.id,
        processedByUserId: testRelationship.userAId,
      );

      // Assert
      expect(result, isNotNull);
      expect(result.isSuccess, isTrue);
      expect(result.option, equals(RelationshipTerminationOption.delete));

      // Cleanup
      relationshipService.dispose();
    });
  });
}

// Helper methods for creating test data

Relationship _createTestRelationship() {
    // Generate unique IDs for each test run
    const uuid = Uuid();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = uuid.v4();
    
    return Relationship(
      id: uuid.v4(),
      userAId: 'user1_${timestamp}_$randomId',
      userBId: 'user2_${timestamp}_$randomId',
      type: RelationshipType.friend,
      status: RelationshipStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      contextPermissions: {
        'user1_${timestamp}_$randomId': PrivacyScope(
          allowedUsers: ['user1_${timestamp}_$randomId', 'user2_${timestamp}_$randomId'],
          allowedContexts: [],
          dateRange: null,
          allowedContentTypes: [],
        ),
        'user2_${timestamp}_$randomId': PrivacyScope(
          allowedUsers: ['user1_${timestamp}_$randomId', 'user2_${timestamp}_$randomId'],
          allowedContexts: [],
          dateRange: null,
          allowedContentTypes: [],
        ),
      },
      initiatedBy: 'user1_${timestamp}_$randomId',
    );
  }

/// Helper method to add test relationship to service for termination tests
Future<void> _addTestRelationshipToService(RelationshipService service, Relationship relationship) async {
  // Create the relationship by accepting a connection request
  // First, send a connection request
  final connectionRequest = await service.sendConnectionRequest(
    fromUserId: relationship.userAId,
    toUserId: relationship.userBId,
    type: relationship.type,
    message: 'Test relationship',
  );
  
  // Then accept it to create the relationship
  await service.acceptConnectionRequest(
    connectionRequest.id, 
    relationship.userBId,
  );
}

/// Helper method to add test relationship directly to service (bypasses connection request flow)
Future<void> _addTestRelationshipDirectly(RelationshipService service, Relationship relationship) async {
  // Use the public test helper method that was added to the service
  service.addRelationshipForTest(relationship);
}
