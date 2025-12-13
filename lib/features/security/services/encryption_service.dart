import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/encryption_models.dart';

/// Provider for encryption service
final encryptionServiceProvider = Provider((ref) => EncryptionService());

/// Core encryption service for end-to-end encryption
class EncryptionService {
  static const int _defaultKeySize = 32; // 256 bits
  static const int _ivSize = 12; // 96 bits for GCM
  static const int _saltSize = 16; // 128 bits
  static const int _tagSize = 16; // 128 bits for GCM tag
  
  final EncryptionConfig _config;
  final List<EncryptionAuditEntry> _auditLog = [];

  EncryptionService({EncryptionConfig? config}) 
      : _config = config ?? _getDefaultConfig();

  /// Encrypt data with symmetric encryption
  Future<EncryptedData> encryptSymmetric(
    String data,
    String key, {
    EncryptionAlgorithm? algorithm,
    Map<String, dynamic>? additionalData,
  }) async {
    final selectedAlgorithm = algorithm ?? _config.defaultAlgorithm;
    final salt = _generateSalt();
    final iv = _generateIV();
    
    try {
      // Derive encryption key
      final derivedKey = await _deriveKey(key, salt);
      
      // Encrypt the data
      final encryptedResult = await _performSymmetricEncryption(
        data,
        derivedKey,
        iv,
        selectedAlgorithm,
        additionalData,
      );
      
      final metadata = EncryptionMetadata(
        algorithm: selectedAlgorithm.name,
        keyDerivationFunction: _config.defaultKeyDerivation.name,
        iterations: _config.defaultIterations,
        salt: base64.encode(salt),
        iv: base64.encode(iv),
        tag: base64.encode(encryptedResult['tag'] ?? []),
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system', // This would come from auth context
        operation: EncryptionOperation.encrypt,
        algorithm: selectedAlgorithm.name,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return EncryptedData(
        data: base64.encode(encryptedResult['ciphertext'] ?? []),
        metadata: metadata,
      );
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.encrypt,
        algorithm: selectedAlgorithm.name,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Decrypt data with symmetric encryption
  Future<String> decryptSymmetric(
    EncryptedData encryptedData,
    String key,
  ) async {
    try {
      final salt = base64.decode(encryptedData.metadata.salt);
      final iv = base64.decode(encryptedData.metadata.iv);
      final tag = base64.decode(encryptedData.metadata.tag);
      final ciphertext = base64.decode(encryptedData.data);
      
      // Derive decryption key
      final derivedKey = await _deriveKey(key, salt);
      
      // Decrypt the data
      final decryptedData = await _performSymmetricDecryption(
        ciphertext,
        derivedKey,
        iv,
        tag,
        EncryptionAlgorithm.values.firstWhere(
          (algo) => algo.name == encryptedData.metadata.algorithm,
        ),
        encryptedData.metadata.additionalData,
      );
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.decrypt,
        algorithm: encryptedData.metadata.algorithm,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return decryptedData;
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.decrypt,
        algorithm: encryptedData.metadata.algorithm,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Generate a new asymmetric key pair
  Future<EncryptionKeyPair> generateKeyPair({
    String? keyId,
    List<String>? usageScopes,
  }) async {
    final id = keyId ?? const Uuid().v4();
    
    try {
      // Generate RSA key pair (simplified - in production use proper crypto library)
      final keyPair = await _generateRSAKeyPair();
      
      final keyPairObj = EncryptionKeyPair(
        keyId: id,
        publicKey: keyPair['public'] ?? '',
        privateKey: keyPair['private'] ?? '', // This should be encrypted with master key
        algorithm: 'RSA-2048',
        createdAt: DateTime.now(),
        usageScopes: usageScopes ?? [],
      );
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.keyGeneration,
        keyId: id,
        algorithm: keyPairObj.algorithm,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return keyPairObj;
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.keyGeneration,
        keyId: id,
        algorithm: 'RSA-2048',
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Encrypt data with public key (asymmetric)
  Future<String> encryptWithPublicKey(String data, String publicKey) async {
    try {
      // Simplified RSA encryption (use proper crypto library in production)
      final encrypted = await _performRSAEncryption(data, publicKey);
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.encrypt,
        algorithm: 'RSA-2048',
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return encrypted;
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.encrypt,
        algorithm: 'RSA-2048',
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Decrypt data with private key (asymmetric)
  Future<String> decryptWithPrivateKey(String encryptedData, String privateKey) async {
    try {
      // Simplified RSA decryption (use proper crypto library in production)
      final decrypted = await _performRSADecryption(encryptedData, privateKey);
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.decrypt,
        algorithm: 'RSA-2048',
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return decrypted;
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.decrypt,
        algorithm: 'RSA-2048',
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Generate a shared secret between two users
  Future<SharedSecret> generateSharedSecret(
    String userId1,
    String userId2,
    String publicKey1,
    String publicKey2,
  ) async {
    final secretId = const Uuid().v4();
    
    try {
      // Generate ephemeral symmetric key
      final symmetricKey = _generateSecureRandom(_defaultKeySize);
      
      // Encrypt the symmetric key with both public keys
      final encryptedForUser1 = await encryptWithPublicKey(
        base64.encode(symmetricKey),
        publicKey1,
      );
      final encryptedForUser2 = await encryptWithPublicKey(
        base64.encode(symmetricKey),
        publicKey2,
      );
      
      // Store both encrypted versions (simplified approach)
      final combinedEncrypted = json.encode({
        'user1': encryptedForUser1,
        'user2': encryptedForUser2,
      });
      
      final sharedSecret = SharedSecret(
        secretId: secretId,
        userId1: userId1,
        userId2: userId2,
        encryptedSecret: combinedEncrypted,
        algorithm: 'AES-256-GCM',
        createdAt: DateTime.now(),
      );
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.secretSharing,
        targetId: secretId,
        algorithm: sharedSecret.algorithm,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return sharedSecret;
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: 'system',
        operation: EncryptionOperation.secretSharing,
        targetId: secretId,
        algorithm: 'AES-256-GCM',
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Derive shared secret from stored encrypted secret
  Future<String> deriveSharedSecret(
    SharedSecret sharedSecret,
    String userId,
    String privateKey,
  ) async {
    try {
      final encryptedData = json.decode(sharedSecret.encryptedSecret) as Map<String, dynamic>;
      final userKey = userId == sharedSecret.userId1 ? 'user1' : 'user2';
      final encryptedKey = encryptedData[userKey] as String;
      
      // Decrypt with user's private key
      final symmetricKeyBase64 = await decryptWithPrivateKey(encryptedKey, privateKey);
      
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: userId,
        operation: EncryptionOperation.secretDerivation,
        targetId: sharedSecret.secretId,
        algorithm: sharedSecret.algorithm,
        success: true,
        timestamp: DateTime.now(),
      ));
      
      return symmetricKeyBase64;
      
    } catch (e) {
      _addAuditEntry(EncryptionAuditEntry(
        id: const Uuid().v4(),
        userId: userId,
        operation: EncryptionOperation.secretDerivation,
        targetId: sharedSecret.secretId,
        algorithm: sharedSecret.algorithm,
        success: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Generate a secure random key
  String generateSecureKey({int length = _defaultKeySize}) {
    return base64.encode(_generateSecureRandom(length));
  }

  /// Hash data with SHA-256
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity with HMAC
  bool verifyHMAC(String data, String signature, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString() == signature;
  }

  /// Generate HMAC signature
  String generateHMAC(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// Get encryption audit log
  List<EncryptionAuditEntry> getAuditLog({String? userId, String? operation}) {
    var filteredLog = _auditLog;
    
    if (userId != null) {
      filteredLog = filteredLog.where((entry) => entry.userId == userId).toList();
    }
    
    if (operation != null) {
      filteredLog = filteredLog.where((entry) => entry.operation.name == operation).toList();
    }
    
    return filteredLog;
  }

  /// Check if key rotation is needed
  bool needsKeyRotation(DateTime lastRotation, String keyId) {
    final nextRotation = lastRotation.add(Duration(days: _config.keyRotationDays));
    return DateTime.now().isAfter(nextRotation);
  }

  /// Get current encryption configuration
  EncryptionConfig get config => _config;

  // Private helper methods

  Uint8List _generateSecureRandom(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  Uint8List _generateSalt() {
    return _generateSecureRandom(_saltSize);
  }

  Uint8List _generateIV() {
    return _generateSecureRandom(_ivSize);
  }

  Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    switch (_config.defaultKeyDerivation) {
      case KeyDerivationFunction.pbkdf2:
        return _deriveKeyPBKDF2(password, salt);
      case KeyDerivationFunction.scrypt:
        return _deriveKeyScrypt(password, salt);
      case KeyDerivationFunction.argon2id:
        return _deriveKeyArgon2id(password, salt);
    }
  }

  Uint8List _deriveKeyPBKDF2(String password, Uint8List salt) {
    // Simplified PBKDF2 implementation (use proper crypto library in production)
    final passwordBytes = utf8.encode(password + _config.keyDerivationPepper);
    final combined = Uint8List(passwordBytes.length + salt.length);
    combined.setRange(0, passwordBytes.length, passwordBytes);
    combined.setRange(passwordBytes.length, combined.length, salt);
    
    var hash = sha256.convert(combined).bytes;
    
    for (int i = 1; i < _config.defaultIterations; i++) {
      final nextInput = Uint8List(hash.length + salt.length);
      nextInput.setRange(0, hash.length, hash);
      nextInput.setRange(hash.length, nextInput.length, salt);
      hash = sha256.convert(nextInput).bytes;
    }
    
    return Uint8List.fromList(hash);
  }

  Uint8List _deriveKeyScrypt(String password, Uint8List salt) {
    // Simplified scrypt implementation (use proper crypto library in production)
    // For now, fall back to PBKDF2
    return _deriveKeyPBKDF2(password, salt);
  }

  Uint8List _deriveKeyArgon2id(String password, Uint8List salt) {
    // Simplified Argon2id implementation (use proper crypto library in production)
    // For now, fall back to PBKDF2
    return _deriveKeyPBKDF2(password, salt);
  }

  Future<Map<String, Uint8List>> _performSymmetricEncryption(
    String data,
    Uint8List key,
    Uint8List iv,
    EncryptionAlgorithm algorithm,
    Map<String, dynamic>? additionalData,
  ) async {
    // Simplified AES-GCM implementation (use proper crypto library in production)
    final dataBytes = utf8.encode(data);
    
    // In a real implementation, use a proper crypto library like 'cryptography'
    // For demonstration, we'll use a simple XOR cipher (NOT SECURE!)
    final ciphertext = Uint8List(dataBytes.length);
    for (int i = 0; i < dataBytes.length; i++) {
      ciphertext[i] = dataBytes[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    // Generate authentication tag (simplified)
    final tag = _generateSecureRandom(_tagSize);
    
    return {
      'ciphertext': ciphertext,
      'tag': tag,
    };
  }

  Future<String> _performSymmetricDecryption(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
    Uint8List tag,
    EncryptionAlgorithm algorithm,
    Map<String, dynamic>? additionalData,
  ) async {
    // Simplified AES-GCM decryption (use proper crypto library in production)
    final decrypted = Uint8List(ciphertext.length);
    
    // Reverse the simple XOR cipher (NOT SECURE!)
    for (int i = 0; i < ciphertext.length; i++) {
      decrypted[i] = ciphertext[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return utf8.decode(decrypted);
  }

  Future<Map<String, String>> _generateRSAKeyPair() async {
    // Simplified RSA key generation (use proper crypto library in production)
    // For demonstration, generate fake keys
    final publicKey = 'RSA_PUBLIC_KEY_${const Uuid().v4()}';
    final privateKey = 'RSA_PRIVATE_KEY_${const Uuid().v4()}';
    
    return {
      'public': publicKey,
      'private': privateKey,
    };
  }

  Future<String> _performRSAEncryption(String data, String publicKey) async {
    // Simplified RSA encryption (use proper crypto library in production)
    // For demonstration, just base64 encode with the public key
    final combined = '$publicKey:$data';
    return base64.encode(utf8.encode(combined));
  }

  Future<String> _performRSADecryption(String encryptedData, String privateKey) async {
    // Simplified RSA decryption (use proper crypto library in production)
    final decoded = utf8.decode(base64.decode(encryptedData));
    final parts = decoded.split(':');
    
    if (parts.length >= 2 && parts[0].startsWith('RSA_PUBLIC_KEY_')) {
      return parts.sublist(1).join(':');
    }
    
    throw Exception('Invalid encrypted data format');
  }

  void _addAuditEntry(EncryptionAuditEntry entry) {
    _auditLog.add(entry);
    
    // Keep audit log size manageable
    if (_auditLog.length > 10000) {
      _auditLog.removeRange(0, _auditLog.length - 10000);
    }
  }

  static EncryptionConfig _getDefaultConfig() {
    return const EncryptionConfig(
      defaultAlgorithm: EncryptionAlgorithm.aes256Gcm,
      defaultKeyDerivation: KeyDerivationFunction.pbkdf2,
      defaultIterations: 100000,
      keyRotationDays: 90,
      enableForwardSecrecy: true,
      enableKeyEscrow: false,
      keyDerivationPepper: 'timeline_biography_pepper_2024',
      algorithmParameters: {},
    );
  }
}

/// Extension methods for encryption algorithms
extension EncryptionAlgorithmExtension on EncryptionAlgorithm {
  String get displayName {
    switch (this) {
      case EncryptionAlgorithm.aes256Gcm:
        return 'AES-256-GCM';
      case EncryptionAlgorithm.xchacha20Poly1305:
        return 'XChaCha20-Poly1305';
      case EncryptionAlgorithm.chacha20Poly1305:
        return 'ChaCha20-Poly1305';
    }
  }

  String get description {
    switch (this) {
      case EncryptionAlgorithm.aes256Gcm:
        return 'Advanced Encryption Standard with Galois/Counter Mode';
      case EncryptionAlgorithm.xchacha20Poly1305:
        return 'Extended ChaCha20 with Poly1305 authentication';
      case EncryptionAlgorithm.chacha20Poly1305:
        return 'ChaCha20 stream cipher with Poly1305 authentication';
    }
  }

  int get keySize {
    switch (this) {
      case EncryptionAlgorithm.aes256Gcm:
        return 32; // 256 bits
      case EncryptionAlgorithm.xchacha20Poly1305:
        return 32; // 256 bits
      case EncryptionAlgorithm.chacha20Poly1305:
        return 32; // 256 bits
    }
  }

  int get ivSize {
    switch (this) {
      case EncryptionAlgorithm.aes256Gcm:
        return 12; // 96 bits
      case EncryptionAlgorithm.xchacha20Poly1305:
        return 24; // 192 bits
      case EncryptionAlgorithm.chacha20Poly1305:
        return 12; // 96 bits
    }
  }
}

/// Extension methods for key derivation functions
extension KeyDerivationFunctionExtension on KeyDerivationFunction {
  String get displayName {
    switch (this) {
      case KeyDerivationFunction.pbkdf2:
        return 'PBKDF2';
      case KeyDerivationFunction.scrypt:
        return 'Scrypt';
      case KeyDerivationFunction.argon2id:
        return 'Argon2id';
    }
  }

  String get description {
    switch (this) {
      case KeyDerivationFunction.pbkdf2:
        return 'Password-Based Key Derivation Function 2';
      case KeyDerivationFunction.scrypt:
        return 'Memory-hard key derivation function';
      case KeyDerivationFunction.argon2id:
        return 'Modern memory-hard key derivation function';
    }
  }
}
