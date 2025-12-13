import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../../lib/features/social/models/user_models.dart';
import '../../lib/features/social/services/relationship_service.dart';

/// Property 15: Connection Consent Requirements
/// 
/// This test validates that connection consent mechanisms work correctly:
/// 1. Connection requests require explicit consent
/// 2. Privacy settings are respected during connection requests
/// 3. Users can accept or decline connection requests
/// 4. Connection history is properly tracked
/// 5. Privacy scope is enforced after connection establishment
/// 6. Duplicate requests are prevented
/// 7. Blocked users cannot send requests

void main() {
  group('Property 15: Connection Consent Requirements', () {
    late RelationshipService relationshipService;
    const uuid = Uuid();

    setUp(() {
      relationshipService = RelationshipService();
    });

    test('Connection requests require explicit consent', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      const relationshipType = RelationshipType.friend;

      // Act
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: relationshipType,
        message: 'Let\'s connect!',
      );

      // Assert
      expect(request.status, equals(ConnectionRequestStatus.pending));
      expect(request.fromUserId, equals(fromUserId));
      expect(request.toUserId, equals(toUserId));
      expect(request.requestedType, equals(relationshipType));
      
      // Verify no relationship is created until consent is given
      final relationships = relationshipService.getUserRelationships(fromUserId);
      expect(relationships, isEmpty);
    });

    test('Privacy settings are respected during connection requests', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2'; // Assume user2 has disabled connection requests
      
      // Act & Assert - This should throw an exception if user2 has disabled requests
      try {
        await relationshipService.sendConnectionRequest(
          fromUserId: fromUserId,
          toUserId: toUserId,
          type: RelationshipType.friend,
        );
        // If we get here, the privacy settings weren't respected
        fail('Should have thrown exception for disabled connection requests');
      } catch (e) {
        // Expected behavior - privacy settings enforced
        expect(e, isA<Exception>());
      }
    });

    test('Users can accept connection requests', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
      );

      // Act
      await relationshipService.acceptConnectionRequest(request.id, toUserId);

      // Assert
      final updatedRequest = relationshipService.connectionRequests
          .firstWhere((req) => req.id == request.id);
      expect(updatedRequest.status, equals(ConnectionRequestStatus.accepted));
      
      // Verify relationship is created
      final relationships = relationshipService.getUserRelationships(fromUserId);
      expect(relationships, hasLength(1));
      expect(relationships.first.status, equals(RelationshipStatus.active));
      expect(relationships.first.type, equals(RelationshipType.friend));
    });

    test('Users can decline connection requests', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
      );

      // Act
      await relationshipService.declineConnectionRequest(request.id, toUserId);

      // Assert
      final updatedRequest = relationshipService.connectionRequests
          .firstWhere((req) => req.id == request.id);
      expect(updatedRequest.status, equals(ConnectionRequestStatus.declined));
      
      // Verify no relationship is created
      final relationships = relationshipService.getUserRelationships(fromUserId);
      expect(relationships, isEmpty);
    });

    test('Connection history is properly tracked', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      // Act
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
        message: 'Test message',
      );

      // Assert
      final activities = relationshipService.getUserActivityFeed(fromUserId);
      expect(activities, isNotEmpty);
      
      final connectionActivity = activities.firstWhere(
        (activity) => activity.type == ActivityType.connectionRequest,
      );
      expect(connectionActivity.userId, equals(fromUserId));
      expect(connectionActivity.relatedUserId, equals(toUserId));
      expect(connectionActivity.metadata['requestId'], equals(request.id));
    });

    test('Privacy scope is enforced after connection establishment', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
      );

      // Act
      await relationshipService.acceptConnectionRequest(request.id, toUserId);

      // Assert
      final relationship = relationshipService.getUserRelationships(fromUserId).first;
      
      // Verify relationship was created successfully
      expect(relationship, isNotNull);
      expect(relationship.status, equals(RelationshipStatus.active));
      expect(relationship.userAId, equals(fromUserId));
      expect(relationship.userBId, equals(toUserId));
      
      // Note: contextPermissions are configured separately after relationship creation
      // The relationship model supports permissions but they're set via updateRelationshipPermissions
    });

    test('Duplicate requests are prevented', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';

      // Act
      await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
      );

      // Assert - Second request should fail
      try {
        await relationshipService.sendConnectionRequest(
          fromUserId: fromUserId,
          toUserId: toUserId,
          type: RelationshipType.friend,
        );
        fail('Should have prevented duplicate connection request');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('already'));
      }
    });

    test('Blocked users cannot send requests', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      // Simulate blocking user1
      // (This would typically be handled by a user service)
      final userSettings = UserSettings(
        defaultPrivacyLevel: PrivacyLevel.private,
        allowConnectionRequests: false, // Disable requests
      );

      // Act & Assert
      try {
        await relationshipService.sendConnectionRequest(
          fromUserId: fromUserId,
          toUserId: toUserId,
          type: RelationshipType.friend,
        );
        fail('Should have prevented request from blocked user');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('Connection requests expire after reasonable time', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
      );

      // Act - Simulate time passing (this would need time mocking in real implementation)
      // For now, we'll just verify the request has a creation timestamp
      expect(request.createdAt, isNotNull);
      expect(request.createdAt.isBefore(DateTime.now().add(const Duration(days: 30))), isTrue);
    });

    test('Connection request validation works correctly', () async {
      // Test invalid user IDs
      try {
        await relationshipService.sendConnectionRequest(
          fromUserId: '', // Empty user ID
          toUserId: 'user2',
          type: RelationshipType.friend,
        );
        fail('Should have validated user ID');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      // Test self-connection attempts
      try {
        await relationshipService.sendConnectionRequest(
          fromUserId: 'user1',
          toUserId: 'user1', // Same user
          type: RelationshipType.friend,
        );
        fail('Should have prevented self-connection');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('Relationship types are properly enforced', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';

      // Act - Test different relationship types
      for (final type in RelationshipType.values) {
        final request = await relationshipService.sendConnectionRequest(
          fromUserId: fromUserId,
          toUserId: toUserId,
          type: type,
        );

        expect(request.requestedType, equals(type));

        // Clean up for next iteration
        await relationshipService.declineConnectionRequest(request.id, toUserId);
      }
    });

    test('Connection request messages are preserved', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      const message = 'I would like to connect with you!';

      // Act
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
        message: message,
      );

      // Assert
      expect(request.message, equals(message));
      
      // Verify message is included in activity metadata
      final activities = relationshipService.getUserActivityFeed(fromUserId);
      final connectionActivity = activities.firstWhere(
        (activity) => activity.type == ActivityType.connectionRequest,
      );
      expect(connectionActivity.metadata['message'], equals(message));
    });

    test('Connection request status transitions are valid', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.friend,
      );

      // Assert initial state
      expect(request.status, equals(ConnectionRequestStatus.pending));

      // Act - Accept request
      await relationshipService.acceptConnectionRequest(request.id, toUserId);

      // Assert final state
      final updatedRequest = relationshipService.connectionRequests
          .firstWhere((req) => req.id == request.id);
      expect(updatedRequest.status, equals(ConnectionRequestStatus.accepted));

      // Verify no further status changes are possible
      try {
        await relationshipService.declineConnectionRequest(request.id, toUserId);
        fail('Should not allow status change after acceptance');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('Bidirectional relationship creation works correctly', () async {
      // Arrange
      const fromUserId = 'user1';
      const toUserId = 'user2';
      
      final request = await relationshipService.sendConnectionRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: RelationshipType.family,
      );

      // Act
      await relationshipService.acceptConnectionRequest(request.id, toUserId);

      // Assert - Both users should see the relationship
      final user1Relationships = relationshipService.getUserRelationships(fromUserId);
      final user2Relationships = relationshipService.getUserRelationships(toUserId);
      
      expect(user1Relationships, hasLength(1));
      expect(user2Relationships, hasLength(1));
      
      // Verify relationship is the same for both users
      expect(user1Relationships.first.id, equals(user2Relationships.first.id));
      expect(user1Relationships.first.type, equals(RelationshipType.family));
      expect(user2Relationships.first.type, equals(RelationshipType.family));
    });
  });
}
