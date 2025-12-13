import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/encryption_models.dart';
import 'encryption_service.dart';

/// Provider for secure storage service
final secureStorageServiceProvider = Provider((ref) => SecureStorageService(
  encryptionService: ref.read(encryptionServiceProvider),
));

/// Service for secure storage of encryption keys and secrets
class SecureStorageService {
  final EncryptionService _encryptionService;
  
  // In-memory storage (in production, use secure platform storage)
  final Map<String, String> _secureStorage = {};
  final Map<String, EncryptionKeyPair> _keyPairs = {};
  final Map<String, SharedSecret> _sharedSecrets = {};
  final Map<String, SymmetricKey> _symmetricKeys = {};
  final Map<String, KeyRotationSchedule> _rotationSchedules = {};

  SecureStorageService({required EncryptionService encryptionService})
      : _encryptionService = encryptionService;

  /// Store user's master key (encrypted with device/biometric key)
  Future<void> storeMasterKey(String userId, String encryptedMasterKey) async {
    final key = 'master_key_$userId';
    _secureStorage[key] = encryptedMasterKey;
  }

  /// Retrieve user's master key
  Future<String?> getMasterKey(String userId) async {
    final key = 'master_key_$userId';
    return _secureStorage[key];
  }

  /// Store encryption key pair
  Future<void> storeKeyPair(EncryptionKeyPair keyPair) async {
    _keyPairs[keyPair.keyId] = keyPair;
    
    // Schedule key rotation
    if (keyPair.isActive) {
      final rotationSchedule = KeyRotationSchedule(
        keyId: keyPair.keyId,
        userId: 'user_${keyPair.keyId}', // This would come from auth context
        scheduledRotation: DateTime.now().add(Duration(days: 90)),
        rotationIntervalDays: 90,
      );
      _rotationSchedules[keyPair.keyId] = rotationSchedule;
    }
  }

  /// Retrieve encryption key pair
  Future<EncryptionKeyPair?> getKeyPair(String keyId) async {
    final keyPair = _keyPairs[keyId];
    
    // Check if key is expired
    if (keyPair != null && keyPair.isExpired) {
      await _deactivateKey(keyId);
      return null;
    }
    
    return keyPair;
  }

  /// Get all active key pairs for a user
  Future<List<EncryptionKeyPair>> getUserKeyPairs(String userId) async {
    return _keyPairs.values
        .where((keyPair) => 
            keyPair.isActive && 
            !keyPair.isExpired &&
            _rotationSchedules[keyPair.keyId]?.userId == userId)
        .toList();
  }

  /// Store shared secret
  Future<void> storeSharedSecret(SharedSecret sharedSecret) async {
    _sharedSecrets[sharedSecret.secretId] = sharedSecret;
  }

  /// Retrieve shared secret
  Future<SharedSecret?> getSharedSecret(String secretId) async {
    final secret = _sharedSecrets[secretId];
    
    // Check if secret is expired
    if (secret != null && secret.isExpired) {
      await _deactivateSharedSecret(secretId);
      return null;
    }
    
    return secret;
  }

  /// Get shared secrets between two users
  Future<List<SharedSecret>> getSharedSecretsBetweenUsers(
    String userId1,
    String userId2,
  ) async {
    return _sharedSecrets.values
        .where((secret) => 
            secret.isActive &&
            !secret.isExpired &&
            ((secret.userId1 == userId1 && secret.userId2 == userId2) ||
             (secret.userId1 == userId2 && secret.userId2 == userId1)))
        .toList();
  }

  /// Store symmetric key
  Future<void> storeSymmetricKey(SymmetricKey symmetricKey) async {
    _symmetricKeys[symmetricKey.keyId] = symmetricKey;
  }

  /// Retrieve symmetric key
  Future<SymmetricKey?> getSymmetricKey(String keyId) async {
    final key = _symmetricKeys[keyId];
    
    // Check if key is expired
    if (key != null && key.isExpired) {
      await _deactivateSymmetricKey(keyId);
      return null;
    }
    
    return key;
  }

  /// Get all symmetric keys for a user
  Future<List<SymmetricKey>> getUserSymmetricKeys(String userId) async {
    return _symmetricKeys.values
        .where((key) => 
            key.isActive && 
            !key.isExpired &&
            key.usageScopes.contains(userId))
        .toList();
  }

  /// Rotate encryption keys
  Future<EncryptionKeyPair> rotateKeyPair(
    String userId,
    String oldKeyId,
  ) async {
    try {
      // Get old key pair
      final oldKeyPair = await getKeyPair(oldKeyId);
      if (oldKeyPair == null) {
        throw Exception('Key pair not found: $oldKeyId');
      }

      // Generate new key pair
      final newKeyPair = await _encryptionService.generateKeyPair(
        usageScopes: oldKeyPair.usageScopes,
      );

      // Store new key pair
      await storeKeyPair(newKeyPair);

      // Update rotation schedule
      final schedule = _rotationSchedules[oldKeyId];
      if (schedule != null) {
        final newSchedule = schedule.copyWith(
          keyId: newKeyPair.keyId,
          scheduledRotation: DateTime.now().add(Duration(days: schedule.rotationIntervalDays)),
          lastRotation: DateTime.now(),
          nextKeyId: newKeyPair.keyId,
        );
        _rotationSchedules[newKeyPair.keyId] = newSchedule;
      }

      // Deactivate old key
      await _deactivateKey(oldKeyId);

      // Re-encrypt sensitive data with new key (this would be implemented in data service)
      await _reencryptDataWithNewKey(oldKeyPair, newKeyPair);

      return newKeyPair;

    } catch (e) {
      throw Exception('Key rotation failed: $e');
    }
  }

  /// Check for keys that need rotation
  Future<List<KeyRotationSchedule>> getKeysNeedingRotation() async {
    return _rotationSchedules.values
        .where((schedule) => schedule.isActive && schedule.isDueForRotation)
        .toList();
  }

  /// Perform automatic key rotation
  Future<void> performAutomaticKeyRotation() async {
    final schedulesNeedingRotation = await getKeysNeedingRotation();
    
    for (final schedule in schedulesNeedingRotation) {
      try {
        await rotateKeyPair(schedule.userId, schedule.keyId);
      } catch (e) {
        print('Failed to rotate key ${schedule.keyId}: $e');
        // Continue with other keys
      }
    }
  }

  /// Clean up expired keys and secrets
  Future<void> cleanupExpiredKeys() async {
    final now = DateTime.now();
    
    // Clean up expired key pairs
    final expiredKeyPairs = _keyPairs.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final keyId in expiredKeyPairs) {
      await _deactivateKey(keyId);
    }

    // Clean up expired shared secrets
    final expiredSecrets = _sharedSecrets.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final secretId in expiredSecrets) {
      await _deactivateSharedSecret(secretId);
    }

    // Clean up expired symmetric keys
    final expiredSymmetricKeys = _symmetricKeys.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final keyId in expiredSymmetricKeys) {
      await _deactivateSymmetricKey(keyId);
    }
  }

  /// Export encrypted user data for backup
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final userKeyPairs = await getUserKeyPairs(userId);
    final userSymmetricKeys = await getUserSymmetricKeys(userId);
    
    return {
      'keyPairs': userKeyPairs.map((kp) => kp.toJson()).toList(),
      'symmetricKeys': userSymmetricKeys.map((sk) => sk.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
    };
  }

  /// Import encrypted user data from backup
  Future<void> importUserData(Map<String, dynamic> userData) async {
    try {
      final userId = userData['userId'] as String;
      
      // Import key pairs
      final keyPairsData = userData['keyPairs'] as List<dynamic>;
      for (final kpData in keyPairsData) {
        final keyPair = EncryptionKeyPair.fromJson(kpData as Map<String, dynamic>);
        await storeKeyPair(keyPair);
      }
      
      // Import symmetric keys
      final symmetricKeysData = userData['symmetricKeys'] as List<dynamic>;
      for (final skData in symmetricKeysData) {
        final symmetricKey = SymmetricKey.fromJson(skData as Map<String, dynamic>);
        await storeSymmetricKey(symmetricKey);
      }
      
    } catch (e) {
      throw Exception('Failed to import user data: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStatistics() async {
    final activeKeyPairs = _keyPairs.values.where((kp) => kp.isActive).length;
    final activeSharedSecrets = _sharedSecrets.values.where((s) => s.isActive).length;
    final activeSymmetricKeys = _symmetricKeys.values.where((sk) => sk.isActive).length;
    final expiredKeys = _keyPairs.values.where((kp) => kp.isExpired).length;
    final expiredSecrets = _sharedSecrets.values.where((s) => s.isExpired).length;
    final expiredSymmetricKeys = _symmetricKeys.values.where((sk) => sk.isExpired).length;
    
    return {
      'activeKeyPairs': activeKeyPairs,
      'activeSharedSecrets': activeSharedSecrets,
      'activeSymmetricKeys': activeSymmetricKeys,
      'expiredKeyPairs': expiredKeys,
      'expiredSharedSecrets': expiredSecrets,
      'expiredSymmetricKeys': expiredSymmetricKeys,
      'totalStorageEntries': _secureStorage.length,
      'rotationSchedules': _rotationSchedules.length,
      'keysNeedingRotation': (await getKeysNeedingRotation()).length,
    };
  }

  /// Clear all stored data (for testing or reset)
  Future<void> clearAllData() async {
    _secureStorage.clear();
    _keyPairs.clear();
    _sharedSecrets.clear();
    _symmetricKeys.clear();
    _rotationSchedules.clear();
  }

  /// Deactivate a key pair
  Future<void> _deactivateKey(String keyId) async {
    final keyPair = _keyPairs[keyId];
    if (keyPair != null) {
      _keyPairs[keyId] = keyPair.copyWith(isActive: false);
      
      // Deactivate rotation schedule
      final schedule = _rotationSchedules[keyId];
      if (schedule != null) {
        _rotationSchedules[keyId] = schedule.copyWith(isActive: false);
      }
    }
  }

  /// Deactivate a shared secret
  Future<void> _deactivateSharedSecret(String secretId) async {
    final secret = _sharedSecrets[secretId];
    if (secret != null) {
      _sharedSecrets[secretId] = secret.copyWith(isActive: false);
    }
  }

  /// Deactivate a symmetric key
  Future<void> _deactivateSymmetricKey(String keyId) async {
    final key = _symmetricKeys[keyId];
    if (key != null) {
      _symmetricKeys[keyId] = key.copyWith(isActive: false);
    }
  }

  /// Re-encrypt data with new key (placeholder for actual implementation)
  Future<void> _reencryptDataWithNewKey(
    EncryptionKeyPair oldKeyPair,
    EncryptionKeyPair newKeyPair,
  ) async {
    // This would integrate with the data service to re-encrypt all data
    // that was encrypted with the old key pair
    print('Re-encrypting data from key ${oldKeyPair.keyId} to ${newKeyPair.keyId}');
  }

  /// Initialize secure storage for a new user
  Future<void> initializeUserStorage(String userId) async {
    // Generate initial key pair for the user
    final initialKeyPair = await _encryptionService.generateKeyPair(
      usageScopes: [userId, 'timeline', 'events', 'media'],
    );
    
    await storeKeyPair(initialKeyPair);
    
    // Generate initial symmetric key for timeline data
    final symmetricKey = SymmetricKey(
      keyId: const Uuid().v4(),
      encryptedKey: _encryptionService.generateSecureKey(),
      algorithm: 'AES-256-GCM',
      createdAt: DateTime.now(),
      usageScopes: [userId, 'timeline'],
    );
    
    await storeSymmetricKey(symmetricKey);
  }
}
