import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'encryption_models.g.dart';

/// Encryption algorithms supported by the system
enum EncryptionAlgorithm {
  @JsonValue('aes256_gcm')
  aes256Gcm,
  @JsonValue('xchacha20_poly1305')
  xchacha20Poly1305,
  @JsonValue('chacha20_poly1305')
  chacha20Poly1305,
}

/// Key derivation functions
enum KeyDerivationFunction {
  @JsonValue('pbkdf2')
  pbkdf2,
  @JsonValue('scrypt')
  scrypt,
  @JsonValue('argon2id')
  argon2id,
}

/// Encryption metadata for encrypted data
@JsonSerializable()
class EncryptionMetadata extends Equatable {
  final String algorithm;
  final String keyDerivationFunction;
  final int iterations;
  final String salt;
  final String iv; // Initialization vector
  final String tag; // Authentication tag
  final DateTime createdAt;
  final String? keyId;
  final Map<String, dynamic>? additionalData;

  const EncryptionMetadata({
    required this.algorithm,
    required this.keyDerivationFunction,
    required this.iterations,
    required this.salt,
    required this.iv,
    required this.tag,
    required this.createdAt,
    this.keyId,
    this.additionalData,
  });

  factory EncryptionMetadata.fromJson(Map<String, dynamic> json) =>
      _$EncryptionMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptionMetadataToJson(this);

  EncryptionMetadata copyWith({
    String? algorithm,
    String? keyDerivationFunction,
    int? iterations,
    String? salt,
    String? iv,
    String? tag,
    DateTime? createdAt,
    String? keyId,
    Map<String, dynamic>? additionalData,
  }) {
    return EncryptionMetadata(
      algorithm: algorithm ?? this.algorithm,
      keyDerivationFunction: keyDerivationFunction ?? this.keyDerivationFunction,
      iterations: iterations ?? this.iterations,
      salt: salt ?? this.salt,
      iv: iv ?? this.iv,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      keyId: keyId ?? this.keyId,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  List<Object?> get props => [
        algorithm,
        keyDerivationFunction,
        iterations,
        salt,
        iv,
        tag,
        createdAt,
        keyId,
        additionalData,
      ];
}

/// Encrypted data container
@JsonSerializable()
class EncryptedData extends Equatable {
  final String data; // Base64 encoded encrypted data
  final EncryptionMetadata metadata;

  const EncryptedData({
    required this.data,
    required this.metadata,
  });

  factory EncryptedData.fromJson(Map<String, dynamic> json) =>
      _$EncryptedDataFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedDataToJson(this);

  @override
  List<Object?> get props => [data, metadata];
}

/// Key pair for asymmetric encryption
@JsonSerializable()
class EncryptionKeyPair extends Equatable {
  final String keyId;
  final String publicKey;
  final String privateKey; // Encrypted at rest
  final String algorithm;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String> usageScopes; // Where this key can be used

  const EncryptionKeyPair({
    required this.keyId,
    required this.publicKey,
    required this.privateKey,
    required this.algorithm,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.usageScopes = const [],
  });

  factory EncryptionKeyPair.fromJson(Map<String, dynamic> json) =>
      _$EncryptionKeyPairFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptionKeyPairToJson(this);

  EncryptionKeyPair copyWith({
    String? keyId,
    String? publicKey,
    String? privateKey,
    String? algorithm,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    List<String>? usageScopes,
  }) {
    return EncryptionKeyPair(
      keyId: keyId ?? this.keyId,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      algorithm: algorithm ?? this.algorithm,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      usageScopes: usageScopes ?? this.usageScopes,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
        keyId,
        publicKey,
        privateKey,
        algorithm,
        createdAt,
        expiresAt,
        isActive,
        usageScopes,
      ];
}

/// Shared secret for symmetric encryption between users
@JsonSerializable()
class SharedSecret extends Equatable {
  final String secretId;
  final String userId1;
  final String userId2;
  final String encryptedSecret; // Encrypted with both users' public keys
  final String algorithm;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  const SharedSecret({
    required this.secretId,
    required this.userId1,
    required this.userId2,
    required this.encryptedSecret,
    required this.algorithm,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory SharedSecret.fromJson(Map<String, dynamic> json) =>
      _$SharedSecretFromJson(json);
  Map<String, dynamic> toJson() => _$SharedSecretToJson(this);

  SharedSecret copyWith({
    String? secretId,
    String? userId1,
    String? userId2,
    String? encryptedSecret,
    String? algorithm,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return SharedSecret(
      secretId: secretId ?? this.secretId,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      encryptedSecret: encryptedSecret ?? this.encryptedSecret,
      algorithm: algorithm ?? this.algorithm,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
        secretId,
        userId1,
        userId2,
        encryptedSecret,
        algorithm,
        createdAt,
        expiresAt,
        isActive,
      ];
}

/// Encryption key for symmetric operations
@JsonSerializable()
class SymmetricKey extends Equatable {
  final String keyId;
  final String encryptedKey; // Encrypted with user's master key
  final String algorithm;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String> usageScopes;

  const SymmetricKey({
    required this.keyId,
    required this.encryptedKey,
    required this.algorithm,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.usageScopes = const [],
  });

  factory SymmetricKey.fromJson(Map<String, dynamic> json) =>
      _$SymmetricKeyFromJson(json);
  Map<String, dynamic> toJson() => _$SymmetricKeyToJson(this);

  SymmetricKey copyWith({
    String? keyId,
    String? encryptedKey,
    String? algorithm,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    List<String>? usageScopes,
  }) {
    return SymmetricKey(
      keyId: keyId ?? this.keyId,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      algorithm: algorithm ?? this.algorithm,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      usageScopes: usageScopes ?? this.usageScopes,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
        keyId,
        encryptedKey,
        algorithm,
        createdAt,
        expiresAt,
        isActive,
        usageScopes,
      ];
}

/// Encryption audit entry
@JsonSerializable()
class EncryptionAuditEntry extends Equatable {
  final String id;
  final String userId;
  final EncryptionOperation operation;
  final String? targetId; // Event ID, user ID, etc.
  final String? keyId;
  final String algorithm;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const EncryptionAuditEntry({
    required this.id,
    required this.userId,
    required this.operation,
    this.targetId,
    this.keyId,
    required this.algorithm,
    required this.success,
    this.errorMessage,
    required this.timestamp,
    this.metadata,
  });

  factory EncryptionAuditEntry.fromJson(Map<String, dynamic> json) =>
      _$EncryptionAuditEntryFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptionAuditEntryToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        operation,
        targetId,
        keyId,
        algorithm,
        success,
        errorMessage,
        timestamp,
        metadata,
      ];
}

/// Types of encryption operations for auditing
enum EncryptionOperation {
  @JsonValue('encrypt')
  encrypt,
  @JsonValue('decrypt')
  decrypt,
  @JsonValue('key_generation')
  keyGeneration,
  @JsonValue('key_rotation')
  keyRotation,
  @JsonValue('key_derivation')
  keyDerivation,
  @JsonValue('secret_sharing')
  secretSharing,
  @JsonValue('secret_derivation')
  secretDerivation,
}

/// Encryption configuration for the application
@JsonSerializable()
class EncryptionConfig extends Equatable {
  final EncryptionAlgorithm defaultAlgorithm;
  final KeyDerivationFunction defaultKeyDerivation;
  final int defaultIterations;
  final int keyRotationDays;
  final bool enableForwardSecrecy;
  final bool enableKeyEscrow;
  final String keyDerivationPepper;
  final Map<String, dynamic> algorithmParameters;

  const EncryptionConfig({
    required this.defaultAlgorithm,
    required this.defaultKeyDerivation,
    required this.defaultIterations,
    required this.keyRotationDays,
    required this.enableForwardSecrecy,
    required this.enableKeyEscrow,
    required this.keyDerivationPepper,
    this.algorithmParameters = const {},
  });

  factory EncryptionConfig.fromJson(Map<String, dynamic> json) =>
      _$EncryptionConfigFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptionConfigToJson(this);

  EncryptionConfig copyWith({
    EncryptionAlgorithm? defaultAlgorithm,
    KeyDerivationFunction? defaultKeyDerivation,
    int? defaultIterations,
    int? keyRotationDays,
    bool? enableForwardSecrecy,
    bool? enableKeyEscrow,
    String? keyDerivationPepper,
    Map<String, dynamic>? algorithmParameters,
  }) {
    return EncryptionConfig(
      defaultAlgorithm: defaultAlgorithm ?? this.defaultAlgorithm,
      defaultKeyDerivation: defaultKeyDerivation ?? this.defaultKeyDerivation,
      defaultIterations: defaultIterations ?? this.defaultIterations,
      keyRotationDays: keyRotationDays ?? this.keyRotationDays,
      enableForwardSecrecy: enableForwardSecrecy ?? this.enableForwardSecrecy,
      enableKeyEscrow: enableKeyEscrow ?? this.enableKeyEscrow,
      keyDerivationPepper: keyDerivationPepper ?? this.keyDerivationPepper,
      algorithmParameters: algorithmParameters ?? this.algorithmParameters,
    );
  }

  @override
  List<Object?> get props => [
        defaultAlgorithm,
        defaultKeyDerivation,
        defaultIterations,
        keyRotationDays,
        enableForwardSecrecy,
        enableKeyEscrow,
        keyDerivationPepper,
        algorithmParameters,
      ];
}

/// Key rotation schedule
@JsonSerializable()
class KeyRotationSchedule extends Equatable {
  final String keyId;
  final String userId;
  final DateTime scheduledRotation;
  final DateTime? lastRotation;
  final int rotationIntervalDays;
  final bool isActive;
  final String? nextKeyId;

  const KeyRotationSchedule({
    required this.keyId,
    required this.userId,
    required this.scheduledRotation,
    this.lastRotation,
    required this.rotationIntervalDays,
    this.isActive = true,
    this.nextKeyId,
  });

  factory KeyRotationSchedule.fromJson(Map<String, dynamic> json) =>
      _$KeyRotationScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$KeyRotationScheduleToJson(this);

  KeyRotationSchedule copyWith({
    String? keyId,
    String? userId,
    DateTime? scheduledRotation,
    DateTime? lastRotation,
    int? rotationIntervalDays,
    bool? isActive,
    String? nextKeyId,
  }) {
    return KeyRotationSchedule(
      keyId: keyId ?? this.keyId,
      userId: userId ?? this.userId,
      scheduledRotation: scheduledRotation ?? this.scheduledRotation,
      lastRotation: lastRotation ?? this.lastRotation,
      rotationIntervalDays: rotationIntervalDays ?? this.rotationIntervalDays,
      isActive: isActive ?? this.isActive,
      nextKeyId: nextKeyId ?? this.nextKeyId,
    );
  }

  bool get isDueForRotation => DateTime.now().isAfter(scheduledRotation);

  @override
  List<Object?> get props => [
        keyId,
        userId,
        scheduledRotation,
        lastRotation,
        rotationIntervalDays,
        isActive,
        nextKeyId,
      ];
}
