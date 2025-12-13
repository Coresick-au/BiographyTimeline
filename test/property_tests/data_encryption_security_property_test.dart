import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../lib/features/security/services/encryption_service.dart';
import '../../lib/features/security/models/encryption_models.dart';

/// Property 25: Data Encryption and Security
/// 
/// This test validates that the data encryption and security systems work correctly:
/// 1. End-to-end encryption for sensitive user content
/// 2. Secure key management and data sovereignty controls
/// 3. Audit logging for privacy-sensitive operations
/// 4. Key rotation and lifecycle management
/// 5. Shared secret generation for multi-user scenarios
/// 6. Data integrity verification with HMAC

void main() {
  group('Property 25: Data Encryption and Security', () {
    late EncryptionService encryptionService;
    const uuid = Uuid();

    setUp(() {
      encryptionService = EncryptionService();
    });

    test('End-to-end encryption for sensitive user content', () async {
      // Arrange
      final sensitiveData = 'This is sensitive user content that must be encrypted';
      final encryptionKey = encryptionService.generateSecureKey();

      // Act - Encrypt the data
      final encryptedData = await encryptionService.encryptSymmetric(
        sensitiveData,
        encryptionKey,
        additionalData: {
          'content_type': 'user_timeline_event',
          'user_id': 'test_user_123',
        },
      );

      // Assert - Encrypted data should be different from original
      expect(encryptedData.data, isNot(equals(sensitiveData)));
      expect(encryptedData.data, isNotEmpty);
      expect(encryptedData.metadata.algorithm, equals('aes256Gcm'));
      expect(encryptedData.metadata.createdAt, isNotNull);
      expect(encryptedData.metadata.salt, isNotEmpty);
      expect(encryptedData.metadata.iv, isNotEmpty);
      expect(encryptedData.metadata.tag, isNotEmpty);

      // Act - Decrypt the data
      final decryptedData = await encryptionService.decryptSymmetric(
        encryptedData,
        encryptionKey,
      );

      // Assert - Decrypted data should match original
      expect(decryptedData, equals(sensitiveData));
    });

    test('Secure key management and data sovereignty controls', () async {
      // Arrange & Act - Generate asymmetric key pair
      final keyPair = await encryptionService.generateKeyPair(
        keyId: 'test_key_123',
        usageScopes: ['timeline_sharing', 'collaborative_editing'],
      );

      // Assert - Key pair should be properly generated
      expect(keyPair.keyId, equals('test_key_123'));
      expect(keyPair.publicKey, isNotEmpty);
      expect(keyPair.privateKey, isNotEmpty);
      expect(keyPair.algorithm, equals('RSA-2048'));
      expect(keyPair.createdAt, isNotNull);
      expect(keyPair.isActive, isTrue);
      expect(keyPair.usageScopes, contains('timeline_sharing'));
      expect(keyPair.usageScopes, contains('collaborative_editing'));

      // Act - Test asymmetric encryption
      final testData = 'Test data for asymmetric encryption';
      final encryptedData = await encryptionService.encryptWithPublicKey(
        testData,
        keyPair.publicKey,
      );

      // Assert - Data should be encrypted
      expect(encryptedData, isNot(equals(testData)));
      expect(encryptedData, isNotEmpty);

      // Act - Decrypt with private key
      final decryptedData = await encryptionService.decryptWithPrivateKey(
        encryptedData,
        keyPair.privateKey,
      );

      // Assert - Data should be properly decrypted
      expect(decryptedData, equals(testData));
    });

    test('Audit logging for privacy-sensitive operations', () async {
      // Arrange
      final testData = 'Sensitive audit test data';
      final encryptionKey = encryptionService.generateSecureKey();

      // Act - Perform multiple encryption operations
      await encryptionService.encryptSymmetric(testData, encryptionKey);
      
      final keyPair = await encryptionService.generateKeyPair();
      
      await encryptionService.encryptWithPublicKey(testData, keyPair.publicKey);

      // Get audit log
      final auditLog = encryptionService.getAuditLog();

      // Assert - All operations should be logged
      expect(auditLog, hasLength(3));

      // Check symmetric encryption was logged
      final symmetricEntry = auditLog.firstWhere(
        (entry) => entry.operation == EncryptionOperation.encrypt && 
                   entry.algorithm == 'aes256Gcm',
        orElse: () => throw Exception('Symmetric encryption entry not found'),
      );
      expect(symmetricEntry.success, isTrue);
      expect(symmetricEntry.timestamp, isNotNull);

      // Check key generation was logged
      final keyGenEntry = auditLog.firstWhere(
        (entry) => entry.operation == EncryptionOperation.keyGeneration,
        orElse: () => throw Exception('Key generation entry not found'),
      );
      expect(keyGenEntry.success, isTrue);
      expect(keyGenEntry.keyId, equals(keyPair.keyId));

      // Check asymmetric encryption was logged
      final asymmetricEntry = auditLog.firstWhere(
        (entry) => entry.operation == EncryptionOperation.encrypt && 
                   entry.algorithm == 'RSA-2048',
        orElse: () => throw Exception('Asymmetric encryption entry not found'),
      );
      expect(asymmetricEntry.success, isTrue);
    });

    test('Key rotation and lifecycle management', () async {
      // Arrange
      final userId = 'test_user_${uuid.v4()}';
      final lastRotation = DateTime.now().subtract(Duration(days: 95)); // 95 days ago

      // Act - Check if key rotation is needed
      final needsRotation = encryptionService.needsKeyRotation(lastRotation, 'test_key');

      // Assert - Should need rotation (default is 90 days)
      expect(needsRotation, isTrue);

      // Test with recent rotation
      final recentRotation = DateTime.now().subtract(Duration(days: 30));
      final doesNotNeedRotation = encryptionService.needsKeyRotation(recentRotation, 'test_key');

      // Assert - Should not need rotation
      expect(doesNotNeedRotation, isFalse);

      // Test key expiration
      final expiredKeyPair = EncryptionKeyPair(
        keyId: 'expired_key',
        publicKey: 'test_public',
        privateKey: 'test_private',
        algorithm: 'RSA-2048',
        createdAt: DateTime.now().subtract(Duration(days: 400)),
        expiresAt: DateTime.now().subtract(Duration(days: 10)), // Expired 10 days ago
      );

      expect(expiredKeyPair.isExpired, isTrue);

      // Test active key
      final activeKeyPair = EncryptionKeyPair(
        keyId: 'active_key',
        publicKey: 'test_public',
        privateKey: 'test_private',
        algorithm: 'RSA-2048',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 90)),
      );

      expect(activeKeyPair.isExpired, isFalse);
    });

    test('Shared secret generation for multi-user scenarios', () async {
      // Arrange
      final userId1 = 'user1_${uuid.v4()}';
      final userId2 = 'user2_${uuid.v4()}';

      final keyPair1 = await encryptionService.generateKeyPair();
      final keyPair2 = await encryptionService.generateKeyPair();

      // Act - Generate shared secret
      final sharedSecret = await encryptionService.generateSharedSecret(
        userId1,
        userId2,
        keyPair1.publicKey,
        keyPair2.publicKey,
      );

      // Assert - Shared secret should be properly generated
      expect(sharedSecret.secretId, isNotEmpty);
      expect(sharedSecret.userId1, equals(userId1));
      expect(sharedSecret.userId2, equals(userId2));
      expect(sharedSecret.encryptedSecret, isNotEmpty);
      expect(sharedSecret.algorithm, equals('AES-256-GCM'));
      expect(sharedSecret.createdAt, isNotNull);
      expect(sharedSecret.isActive, isTrue);

      // Act - Derive secret for user1
      final derivedSecret1 = await encryptionService.deriveSharedSecret(
        sharedSecret,
        userId1,
        keyPair1.privateKey,
      );

      // Act - Derive secret for user2
      final derivedSecret2 = await encryptionService.deriveSharedSecret(
        sharedSecret,
        userId2,
        keyPair2.privateKey,
      );

      // Assert - Both users should derive the same secret
      expect(derivedSecret1, equals(derivedSecret2));
      expect(derivedSecret1, isNotEmpty);
    });

    test('Data integrity verification with HMAC', () async {
      // Arrange
      final data = 'Important data that needs integrity verification';
      final key = 'verification_key_123';

      // Act - Generate HMAC signature
      final signature = encryptionService.generateHMAC(data, key);

      // Assert - Signature should be generated
      expect(signature, isNotEmpty);
      expect(signature.length, equals(64)); // SHA-256 produces 64 character hex string

      // Act - Verify data integrity
      final isValid = encryptionService.verifyHMAC(data, signature, key);

      // Assert - Data should be valid
      expect(isValid, isTrue);

      // Test with tampered data
      final tamperedData = 'Important data that needs integrity verification TAMPERED';
      final isTamperedValid = encryptionService.verifyHMAC(tamperedData, signature, key);

      // Assert - Tampered data should be invalid
      expect(isTamperedValid, isFalse);

      // Test with wrong key
      final wrongKey = 'wrong_verification_key';
      final isWrongKeyValid = encryptionService.verifyHMAC(data, signature, wrongKey);

      // Assert - Wrong key should make verification fail
      expect(isWrongKeyValid, isFalse);
    });

    test('Hashing for data integrity', () async {
      // Arrange
      final data = 'Data to be hashed for integrity checks';
      final sameData = 'Data to be hashed for integrity checks';
      final differentData = 'Different data for hash comparison';

      // Act - Generate hashes
      final hash1 = encryptionService.hashData(data);
      final hash2 = encryptionService.hashData(sameData);
      final hash3 = encryptionService.hashData(differentData);

      // Assert - Same data should produce same hash
      expect(hash1, equals(hash2));
      expect(hash1, hasLength(64)); // SHA-256 produces 64 character hex string

      // Different data should produce different hash
      expect(hash1, isNot(equals(hash3)));
    });

    test('Encryption configuration and algorithm support', () async {
      // Act - Get current configuration
      final config = encryptionService.config;

      // Assert - Configuration should be properly set
      expect(config.defaultAlgorithm, equals(EncryptionAlgorithm.aes256Gcm));
      expect(config.defaultKeyDerivation, equals(KeyDerivationFunction.pbkdf2));
      expect(config.defaultIterations, equals(100000));
      expect(config.keyRotationDays, equals(90));
      expect(config.enableForwardSecrecy, isTrue);
      expect(config.enableKeyEscrow, isFalse);
      expect(config.keyDerivationPepper, isNotEmpty);

      // Test algorithm extensions
      expect(EncryptionAlgorithm.aes256Gcm.displayName, equals('AES-256-GCM'));
      expect(EncryptionAlgorithm.aes256Gcm.description, contains('Advanced Encryption Standard'));
      expect(EncryptionAlgorithm.aes256Gcm.keySize, equals(32));
      expect(EncryptionAlgorithm.aes256Gcm.ivSize, equals(12));

      expect(KeyDerivationFunction.pbkdf2.displayName, equals('PBKDF2'));
      expect(KeyDerivationFunction.pbkdf2.description, contains('Password-Based Key Derivation'));
    });

    test('Error handling and failed operation auditing', () async {
      // Arrange
      final validData = 'Valid test data';
      final validKey = encryptionService.generateSecureKey();
      final invalidKey = 'invalid_key_too_short';

      // Act - Encrypt with valid key (should succeed)
      final encryptedData = await encryptionService.encryptSymmetric(validData, validKey);

      // Attempt to decrypt with wrong key (should fail)
      try {
        await encryptionService.decryptSymmetric(encryptedData, invalidKey);
        fail('Should have thrown an exception for invalid key');
      } catch (e) {
        // Expected behavior
      }

      // Get audit log
      final auditLog = encryptionService.getAuditLog();

      // Assert - Both success and failure should be logged
      expect(auditLog.length, greaterThanOrEqualTo(2));

      // Find successful encryption
      final successEntry = auditLog.firstWhere(
        (entry) => entry.operation == EncryptionOperation.encrypt && entry.success,
        orElse: () => throw Exception('Successful encryption entry not found'),
      );
      expect(successEntry.errorMessage, isNull);

      // Find failed decryption
      final failureEntry = auditLog.firstWhere(
        (entry) => entry.operation == EncryptionOperation.decrypt && !entry.success,
        orElse: () => throw Exception('Failed decryption entry not found'),
      );
      expect(failureEntry.errorMessage, isNotNull);
    });

    test('Secure random key generation', () async {
      // Act - Generate multiple keys
      final key1 = encryptionService.generateSecureKey();
      final key2 = encryptionService.generateSecureKey();
      final key3 = encryptionService.generateSecureKey(length: 16);

      // Assert - Keys should be unique and properly sized
      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key2, isNot(equals(key3)));

      // Default key should be 32 bytes (256 bits) base64 encoded
      expect(key1.length, greaterThan(40)); // Base64 encoding increases length

      // Custom length key should be smaller
      expect(key3.length, lessThan(key1.length));

      // Keys should be valid base64
      expect(() => base64.decode(key1), returnsNormally);
      expect(() => base64.decode(key2), returnsNormally);
      expect(() => base64.decode(key3), returnsNormally);
    });
  });
}
