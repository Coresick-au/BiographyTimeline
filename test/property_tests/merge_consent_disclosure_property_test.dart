import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../../lib/features/consent/services/consent_service.dart';
import '../../lib/features/consent/models/consent_models.dart';

/// Property 24: Merge Consent and Disclosure
/// 
/// This test validates that merge consent and disclosure systems work correctly:
/// 1. Explicit consent flows are required for timeline merging
/// 2. Clear data sharing disclosure interfaces work properly
/// 3. Consent withdrawal and data isolation mechanisms function
/// 4. Merge consent templates provide proper disclosure
/// 5. Granular permission control for merge operations
/// 6. Audit logging tracks all consent activities

void main() {
  group('Property 24: Merge Consent and Disclosure', () {
    late ConsentService consentService;
    const uuid = Uuid();

    setUp(() {
      consentService = ConsentService();
    });

    tearDown(() {
      consentService.dispose();
    });

    test('Explicit consent flows are required for timeline merging', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final partnerId = 'partner_${uuid.v4()}';

      // Act - Request consent for collaborative features (timeline merging)
      final consentRequest = await consentService.requestConsent(
        userId: userId,
        templateId: 'collaborative_features',
        featureId: 'timeline_merge',
        context: 'Merging with $partnerId',
        metadata: {
          'partnerId': partnerId,
          'mergeType': 'bidirectional',
        },
      );

      // Assert
      expect(consentRequest, isNotNull);
      expect(consentRequest.userId, equals(userId));
      expect(consentRequest.consentType, equals(ConsentType.collaborativeFeatures));
      expect(consentRequest.featureId, equals('timeline_merge'));
      expect(consentRequest.status, equals(ConsentRequestStatus.pending));
      expect(consentRequest.requestMessage, contains('collaborative'));
    });

    test('Clear data sharing disclosure interfaces work properly', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Act - Get the collaborative features template
      final template = consentService.getTemplate('collaborative_features');

      // Assert - Template should have clear disclosure information
      expect(template, isNotNull);
      expect(template!.name, equals('Collaborative Features'));
      expect(template.detailedDescription, contains('share'));
      expect(template.detailedDescription, contains('edit'));
      expect(template.privacyPolicyUrl, isNotEmpty);
      expect(template.termsOfServiceUrl, isNotEmpty);
      expect(template.legalBasis, isNotEmpty);
      
      // Required permissions should be clearly disclosed
      expect(template.requiredPermissions, contains('share_events'));
      expect(template.requiredPermissions, contains('collaborative_editing'));
      
      // Optional permissions should be disclosed
      expect(template.optionalPermissions, contains('public_sharing'));
      expect(template.optionalPermissions, contains('find_connections'));
    });

    test('Consent withdrawal and data isolation mechanisms function', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final partnerId = 'partner_${uuid.v4()}';

      // Grant consent first
      final consentRequest = await consentService.requestConsent(
        userId: userId,
        templateId: 'collaborative_features',
        featureId: 'timeline_merge',
        context: 'Merging with $partnerId',
      );

      final consentRecord = await consentService.respondToConsentRequest(
        requestId: consentRequest.id,
        response: ConsentStatus.granted,
        grantedPermissions: ['share_events', 'collaborative_editing'],
      );

      // Verify consent is granted
      expect(consentRecord.status, equals(ConsentStatus.granted));
      expect(consentService.hasConsent(userId, ConsentType.collaborativeFeatures), isTrue);

      // Act - Withdraw consent
      await consentService.withdrawConsent(
        consentRecord.id,
        reason: 'User requested data isolation',
      );

      // Assert - Consent should be withdrawn (getUserConsents only returns valid consents)
      // So we check that hasConsent returns false and check audit log
      expect(consentService.hasConsent(userId, ConsentType.collaborativeFeatures), isFalse);
      
      // Check audit log for withdrawal
      final auditLog = consentService.getAuditLog(userId: userId);
      final withdrawalEntry = auditLog.firstWhere(
        (e) => e.action == ConsentAuditAction.withdrawn,
        orElse: () => throw Exception('Withdrawal entry not found'),
      );
      expect(withdrawalEntry.reason, equals('User requested data isolation'));
    });

    test('Merge consent templates provide proper disclosure', () async {
      // Arrange & Act - Get all templates
      final templates = consentService.getTemplates();

      // Assert - Collaborative features template should exist and be active
      final collaborativeTemplate = templates.firstWhere(
        (t) => t.consentType == ConsentType.collaborativeFeatures,
        orElse: () => throw Exception('Collaborative features template not found'),
      );
      
      expect(collaborativeTemplate.isActive, isTrue);
      expect(collaborativeTemplate.isGranular, isTrue);
      expect(collaborativeTemplate.defaultExpiration, isNotNull);
      
      // Should disclose what data is shared
      expect(collaborativeTemplate.detailedDescription, contains('timeline events'));
      expect(collaborativeTemplate.detailedDescription, contains('connect with other users'));
      
      // Should have proper legal basis
      expect(collaborativeTemplate.legalBasis, equals('Explicit consent'));
    });

    test('Granular permission control for merge operations', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final partnerId = 'partner_${uuid.v4()}';

      // Act - Request and grant consent with specific permissions
      final consentRequest = await consentService.requestConsent(
        userId: userId,
        templateId: 'collaborative_features',
        featureId: 'timeline_merge',
        context: 'Merging with $partnerId',
      );

      final consentRecord = await consentService.respondToConsentRequest(
        requestId: consentRequest.id,
        response: ConsentStatus.granted,
        grantedPermissions: ['share_events'], // Only grant basic sharing
        deniedPermissions: ['public_sharing', 'find_connections'], // Deny optional
        responseDetails: 'Only share events privately, no public features',
      );

      // Assert - Granular permissions should be recorded
      expect(consentRecord.grantedPermissions, contains('share_events'));
      expect(consentRecord.grantedPermissions, isNot(contains('public_sharing')));
      expect(consentRecord.deniedPermissions, contains('public_sharing'));
      expect(consentRecord.deniedPermissions, contains('find_connections'));
      expect(consentRecord.isGranular, isTrue);
      expect(consentRecord.responseDetails, contains('private'));
    });

    test('Audit logging tracks all consent activities', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Act - Perform multiple consent operations
      final request = await consentService.requestConsent(
        userId: userId,
        templateId: 'collaborative_features',
      );

      final record = await consentService.respondToConsentRequest(
        requestId: request.id,
        response: ConsentStatus.granted,
      );

      await consentService.withdrawConsent(record.id);

      // Assert - All activities should be logged
      final auditLog = consentService.getAuditLog(userId: userId);
      
      expect(auditLog, hasLength(3));
      
      // Check request was logged
      final requestEntry = auditLog.firstWhere(
        (e) => e.action == ConsentAuditAction.requested,
        orElse: () => throw Exception('Request entry not found'),
      );
      expect(requestEntry.consentType, equals(ConsentType.collaborativeFeatures));
      
      // Check grant was logged
      final grantEntry = auditLog.firstWhere(
        (e) => e.action == ConsentAuditAction.granted,
        orElse: () => throw Exception('Grant entry not found'),
      );
      expect(grantEntry.newStatus, equals(ConsentStatus.granted));
      
      // Check withdrawal was logged
      final withdrawEntry = auditLog.firstWhere(
        (e) => e.action == ConsentAuditAction.withdrawn,
        orElse: () => throw Exception('Withdraw entry not found'),
      );
      expect(withdrawEntry.previousStatus, equals(ConsentStatus.granted));
      expect(withdrawEntry.newStatus, equals(ConsentStatus.withdrawn));
    });

    test('Consent preferences control default behaviors', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Act - Update user preferences to block collaborative features
      final preferences = consentService.getUserPreferences(userId);
      final updatedPreferences = preferences.copyWith(
        defaultPreferences: {
          ...preferences.defaultPreferences,
          ConsentType.collaborativeFeatures: ConsentStatus.denied,
        },
        blockedConsentTypes: [ConsentType.marketing], // Block marketing too
      );
      
      await consentService.updateUserPreferences(updatedPreferences);

      // Assert - Preferences should be updated
      final retrievedPreferences = consentService.getUserPreferences(userId);
      expect(
        retrievedPreferences.getDefaultPreference(ConsentType.collaborativeFeatures),
        equals(ConsentStatus.denied),
      );
      expect(
        retrievedPreferences.isConsentTypeBlocked(ConsentType.marketing),
        isTrue,
      );
    });

    test('Consent expiration and renewal work correctly', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Create a consent 
      final request = await consentService.requestConsent(
        userId: userId,
        templateId: 'collaborative_features',
      );

      final record = await consentService.respondToConsentRequest(
        requestId: request.id,
        response: ConsentStatus.granted,
      );

      // Act - Renew consent
      final renewedRecord = await consentService.renewConsent(
        record.id,
        newDuration: const Duration(days: 30),
      );

      // Assert - Consent should be renewed
      expect(renewedRecord, isNotNull);
      expect(renewedRecord.expiresAt, isNotNull);
      expect(renewedRecord.status, equals(ConsentStatus.granted));
      
      // Verify renewal was logged in audit
      final auditLog = consentService.getAuditLog(userId: userId);
      final renewalEntry = auditLog.firstWhere(
        (e) => e.action == ConsentAuditAction.renewed,
        orElse: () => throw Exception('Renewal entry not found'),
      );
      expect(renewalEntry, isNotNull);
    });

    test('Export and delete user data works (GDPR compliance)', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Create some consent data
      await consentService.requestConsent(
        userId: userId,
        templateId: 'collaborative_features',
      );

      final preferences = consentService.getUserPreferences(userId);
      await consentService.updateUserPreferences(preferences);

      // Act - Export user data
      final exportedData = consentService.exportUserData(userId);

      // Assert - Export should contain all user data
      expect(exportedData['userId'], equals(userId));
      expect(exportedData['consentRecords'], isA<List>());
      expect(exportedData['preferences'], isA<Map>());
      expect(exportedData['auditLog'], isA<List>());
      expect(exportedData['exportedAt'], isNotNull);

      // Act - Delete user data
      await consentService.deleteUserData(userId);

      // Assert - All user data should be removed
      expect(consentService.getUserConsents(userId), isEmpty);
      expect(consentService.getPendingRequests(userId), isEmpty);
      
      // Audit log should only contain deletion entry (others are removed)
      final remainingAudit = consentService.getAuditLog(userId: userId);
      expect(remainingAudit.length, greaterThanOrEqualTo(1));
      expect(remainingAudit.last.action, equals(ConsentAuditAction.deleted));
    });

    test('Statistics provide insight into consent usage', () async {
      // Arrange
      final userId1 = 'user1_${uuid.v4()}';
      final userId2 = 'user2_${uuid.v4()}';

      // Create various consent states
      final request1 = await consentService.requestConsent(
        userId: userId1,
        templateId: 'collaborative_features',
      );
      await consentService.respondToConsentRequest(
        requestId: request1.id,
        response: ConsentStatus.granted,
      );

      final request2 = await consentService.requestConsent(
        userId: userId2,
        templateId: 'analytics',
      );
      await consentService.respondToConsentRequest(
        requestId: request2.id,
        response: ConsentStatus.denied,
      );

      // Act - Get statistics
      final stats = consentService.getConsentStatistics();

      // Assert - Statistics should reflect the created consents
      expect(stats['totalConsentRecords'], greaterThan(0));
      expect(stats['grantedConsents'], greaterThan(0));
      expect(stats['deniedConsents'], greaterThan(0));
      expect(stats['activeTemplates'], greaterThan(0));
      expect(stats['totalTemplates'], greaterThan(0));
    });

    test('Consent validation prevents invalid operations', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Act & Assert - Should not be able to withdraw non-existent consent
      expect(
        () => consentService.withdrawConsent('non_existent_id'),
        throwsA(isA<Exception>()),
      );

      // Act & Assert - Should not be able to respond to non-existent request
      expect(
        () => consentService.respondToConsentRequest(
          requestId: 'non_existent_id',
          response: ConsentStatus.granted,
        ),
        throwsA(isA<Exception>()),
      );

      // Act & Assert - Should not be able to use non-existent template
      expect(
        () => consentService.requestConsent(
          userId: userId,
          templateId: 'non_existent_template',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
